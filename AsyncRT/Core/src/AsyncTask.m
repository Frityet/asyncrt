#include <AsyncTask.h>

#import <AsyncExecutor.h>
#import <AsyncTask+Private.h>
#import <Coroutine.h>
#import <ThreadPool.h>

#pragma clang assume_nonnull begin

typedef void (^AsyncTaskContinuationBlock)(void);

static thread_local unretained AsyncTask *nillable currentTask;
static thread_local unretained Coroutine *nillable currentTaskCoroutine;

@implementation AsyncTaskCancelledException

- (instancetype)initWithTask: (AsyncTask *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"Async task %@ was cancelled", _task];
}

@end

@implementation AsyncTask

- (void)_initializeStorage [[direct]]
{
    _condition = [OFCondition condition];
    _continuations = [[OFMutableArray alloc] initWithCapacity: 4];
}

- (instancetype)initResolvedWithResult: (id nillability_unspecified)result
{
    self = [super init];
    [self _initializeStorage];
    _status = AsyncTaskStatus_RESOLVED;
    _result = result;
    _executor = AsyncExecutor.current;
    return self;
}

- (instancetype)initRejectedWithError: (OFException *)error
{
    self = [super init];
    [self _initializeStorage];
    _status = AsyncTaskStatus_REJECTED;
    _error = error;
    _executor = AsyncExecutor.current;
    return self;
}

+ (instancetype)resolvedWithResult: (id nillability_unspecified)result
{ return [[self alloc] initResolvedWithResult: result]; }

+ (instancetype)rejectedWithError: (OFException *)error
{ return [[self alloc] initRejectedWithError: error]; }

- (enum AsyncTaskStatus)status
{
    [_condition lock];
    @try {
        return _status;
    } @finally {
        [_condition unlock];
    }
}

- (bool)isComplete
{
    auto status = self.status;
    return status == AsyncTaskStatus_RESOLVED
        or status == AsyncTaskStatus_REJECTED
        or status == AsyncTaskStatus_CANCELLED;
}

- (bool)isPending
{ return self.status == AsyncTaskStatus_PENDING; }

- (bool)isCancelled
{ return self.status == AsyncTaskStatus_CANCELLED; }

- (AsyncExecutor *)executor
{
    [_condition lock];
    @try {
        return _executor;
    } @finally {
        [_condition unlock];
    }
}

- (void)setExecutor: (AsyncExecutor *)executor
{
    [_condition lock];
    @try {
        _executor = executor;
    } @finally {
        [_condition unlock];
    }
}

- (void)_scheduleResumeOnExecutor: (AsyncExecutor *)executor [[direct]]
{
    bool shouldSchedule = false;

    [_condition lock];
    @try {
        if (_status == AsyncTaskStatus_PENDING and not _resumeScheduled) {
            _resumeScheduled = true;
            shouldSchedule = true;
        }
    } @finally {
        [_condition unlock];
    }

    if (shouldSchedule) {
        [executor enqueue: ^{
            [self _resumeCoroutine];
        }];
    }
}

- (instancetype)initExecutingBlock: (id nillability_unspecified (^)())block
{
    self = [super init];
    [self _initializeStorage];
    _status = AsyncTaskStatus_PENDING;
    _executor = AsyncExecutor.current;
    _block = [block copy];
    [self _scheduleResumeOnExecutor: _executor];
    return self;
}

+ (instancetype)spawn: (id nillability_unspecified (^)())block
{ return [[self alloc] initExecutingBlock: block]; }

+ (instancetype)offload: (id nillability_unspecified (^)())block ontoPool: (ThreadPool *)pool
{
    block_reference auto comp = [[AsyncTaskCompletionSource alloc] init];

    [pool.tasks addObject: ^{
        @try {
            id nillability_unspecified result = block();
            [comp resolveWithResult: result];
        } @catch (OFException *error) {
            [comp rejectWithError: error];
        }
    }];

    return comp.task;
}

+ (AsyncTask<OFArray *> *)all: (OFArray<AsyncTask *> *)tasks
{
    OFArray<AsyncTask *> *taskList = [tasks copy];
    auto source = [[AsyncTaskCompletionSource<OFArray *> alloc] init];
    auto results = [OFMutableArray<Optional<id> *> arrayWithCapacity: tasks.count];

    for (size_t index = 0; index < tasks.count; index++)
        [results addObject: Optional.none];

    if (tasks.count == 0) {
        [source resolveWithResult: [results copy]];
        return source.task;
    }

    block_reference size_t pending = tasks.count;
    block_reference bool completed = false;
    auto executor = source.executor;

    for (size_t index = 0; index < tasks.count; index++) {
        auto resultIndex = index;
        auto task = taskList[index];
        unretained AsyncTask *unretainedTask = task;

        [task _addContinuationOnExecutor: executor block: ^{
            (void)taskList;
            if (completed)
                return;

            @try {
                id result = [unretainedTask await];
                results[resultIndex] = [Optional some: result];
                pending--;

                if (pending == 0) {
                    auto finalResults = [OFMutableArray arrayWithCapacity:
                        results.count];
                    for (Optional<id> *optional in results)
                        [finalResults addObject: optional.value];

                    completed = true;
                    [source resolveWithResult: [finalResults copy]];
                }
            } @catch (OFException *exception) {
                completed = true;
                [source rejectWithError: exception];
            }
        }];
    }

    return source.task;
}

+ (AsyncTask<OFNumber *> *)any: (OFArray<AsyncTask *> *)tasks
{
    if (tasks.count == 0)
        return [AsyncTask<OFNumber *> rejectedWithError:
            [OFInvalidArgumentException exception]];

    OFArray<AsyncTask *> *taskList = [tasks copy];
    auto source = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];
    block_reference bool completed = false;
    auto executor = source.executor;

    for (size_t index = 0; index < taskList.count; index++) {
        auto taskIndex = index;
        unretained AsyncTask *unretainedTask = taskList[index];

        [unretainedTask _addContinuationOnExecutor: executor block: ^{
            (void)taskList;
            if (completed)
                return;

            @try {
                (void)[unretainedTask await];
                completed = true;
                [source resolveWithResult: @(taskIndex)];
            } @catch (OFException *exception) {
                completed = true;
                [source rejectWithError: exception];
            }
        }];
    }

    return source.task;
}

- (void)_waitUntilComplete [[direct]]
{
    if (self.isComplete)
        return;

    AsyncTask *nillable waitingTask = currentTask;
    Coroutine *nillable waitingCoroutine = currentTaskCoroutine;

    if (waitingTask != nilptr and waitingCoroutine != nilptr) {
        if (waitingTask == self)
            @throw [OFInvalidArgumentException exception];

        while (not self.isComplete) {
            AsyncExecutor *executor = waitingTask.executor;
            void (^continuation)(void) = [self _addContinuationOnExecutor: executor block: ^{
                [waitingTask _scheduleResumeOnExecutor: executor];
            }];

            [waitingCoroutine yield];
            [self _removeContinuation: continuation];
        }

        return;
    }

    [self.executor runUntil: ^{ return self.isComplete; }];
}

- (id nillability_unspecified)_resultOrThrow [[direct]]
{
    enum AsyncTaskStatus status;
    id nillability_unspecified result;
    OFException *nillable error;

    [_condition lock];
    @try {
        status = _status;
        result = _result;
        error = _error;
    } @finally {
        [_condition unlock];
    }

    switch (status) {
        case AsyncTaskStatus_RESOLVED:
            return result;
        case AsyncTaskStatus_REJECTED:
            @throw $assert_nonnil(error);
        case AsyncTaskStatus_CANCELLED:
            @throw [[AsyncTaskCancelledException alloc] initWithTask: self];
        case AsyncTaskStatus_PENDING:
            @throw [OFInvalidArgumentException exception];
    }
}

- (id nillability_unspecified)await
{
    [self _waitUntilComplete];
    return [self _resultOrThrow];
}

- (id nillability_unspecified)runUntilCompletion
{
    return [self await];
}

- (instancetype)_initPendingWithExecutor: (AsyncExecutor *)executor
{
    self = [super init];
    [self _initializeStorage];
    _status = AsyncTaskStatus_PENDING;
    _executor = executor;
    return self;
}

- (bool)_completeWithStatus: (enum AsyncTaskStatus)status
                     result: (id nillability_unspecified)result
                      error: (OFException *nillable)error [[direct]]
{
    OFArray<AsyncTaskContinuationBlock> *nillable continuations = nilptr;
    AsyncExecutor *nillable executor = nilptr;

    [_condition lock];
    @try {
        if (_status != AsyncTaskStatus_PENDING)
            return false;

        _result = result;
        _error = error;
        _status = status;
        _block = nilptr;
        _coroutine = nilptr;
        executor = _executor;
        continuations = [_continuations copy];
        [_continuations removeAllObjects];
        [_condition broadcast];
    } @finally {
        [_condition unlock];
    }

    for (id continuationObject in continuations) {
        AsyncTaskContinuationBlock continuation = continuationObject;
        continuation();
    }

    /*
     * A non-coroutine waiter services its executor's run loop rather than
     * blocking on _condition.  Completion can arrive from another thread
     * (for example, transport-driven cancellation), so enqueue a no-op to
     * wake that run loop even when there are no registered continuations.
     */
    if (executor != nilptr)
        [$assert_nonnil(executor) enqueue: ^{}];

    return true;
}

- (bool)_tryResolveWithResult: (id nillability_unspecified)result
{ return [self _completeWithStatus: AsyncTaskStatus_RESOLVED result: result error: nilptr]; }

- (bool)_tryRejectWithError: (OFException *)error
{ return [self _completeWithStatus: AsyncTaskStatus_REJECTED result: nilptr error: error]; }

- (bool)_tryCancel
{ return [self _completeWithStatus: AsyncTaskStatus_CANCELLED result: nilptr error: nilptr]; }

- (Coroutine *)_coroutineCreatingIfNeeded [[direct]]
{
    if (_coroutine != nilptr)
        return $assert_nonnil(_coroutine);

    _coroutine = [[Coroutine alloc] initWithBlock: ^(unretained Coroutine *) {
        @try {
            [self _tryResolveWithResult: _block()];
        } @catch (OFException *error) {
            [self _tryRejectWithError: error];
        } @catch (id) {
            [self _tryRejectWithError: [OFException exception]];
        }

        return nilptr;
    }];

    return $assert_nonnil(_coroutine);
}

- (void)_resumeCoroutine
{
    Coroutine *nillable coroutine = nilptr;

    [_condition lock];
    @try {
        _resumeScheduled = false;

        if (_status == AsyncTaskStatus_PENDING)
            coroutine = [self _coroutineCreatingIfNeeded];
    } @finally {
        [_condition unlock];
    }

    if (coroutine == nilptr
        or coroutine.status == CoroutineStatus_DEAD
        or coroutine.status == CoroutineStatus_RUNNING)
        return;

    AsyncTask *nillable previousTask = currentTask;
    Coroutine *nillable previousCoroutine = currentTaskCoroutine;

    @try {
        currentTask = self;
        currentTaskCoroutine = coroutine;
        [coroutine resume];
    } @catch (OFException *error) {
        [self _tryRejectWithError: error];
    } @catch (id) {
        [self _tryRejectWithError: [OFException exception]];
    } @finally {
        currentTask = previousTask;
        currentTaskCoroutine = previousCoroutine;

        [_condition lock];
        @try {
            if (_status != AsyncTaskStatus_PENDING) {
                _block = nilptr;
                _coroutine = nilptr;
            }
        } @finally {
            [_condition unlock];
        }
    }
}

- (void(^)(void))_addContinuationOnExecutor: (AsyncExecutor *)executor block: (void (^)(void))block
{
    AsyncTaskContinuationBlock continuation = [^{
        [executor enqueue: block];
    } copy];
    bool shouldRunNow = false;

    [_condition lock];
    @try {
        if (_status == AsyncTaskStatus_PENDING)
            [_continuations addObject: continuation];
        else
            shouldRunNow = true;
    } @finally {
        [_condition unlock];
    }

    if (shouldRunNow)
        continuation();

    return continuation;
}

- (void)_removeContinuation: (void(^)(void))continuation
{
    [_condition lock];
    @try {
        if (_status == AsyncTaskStatus_PENDING)
            [_continuations removeObjectIdenticalTo: continuation];
    } @finally {
        [_condition unlock];
    }
}

@end

@implementation AsyncTaskCompletionSource

- (instancetype)init
{
    self = [super init];
    _task = [[AsyncTask alloc] _initPendingWithExecutor: AsyncExecutor.current];
    return self;
}

- (AsyncExecutor *)executor
{ return _task.executor; }

- (void)setExecutor: (AsyncExecutor *)executor
{ _task.executor = executor; }

- (void)resolveWithResult: (id nillability_unspecified)result
{
    if (not [_task _tryResolveWithResult: result])
        @throw [OFInvalidArgumentException exception];
}

- (void)rejectWithError: (OFException *)error
{
    if (not [_task _tryRejectWithError: error])
        @throw [OFInvalidArgumentException exception];
}

- (void)cancel
{
    if (not [_task _tryCancel])
        @throw [OFInvalidArgumentException exception];
}

@end

#pragma clang assume_nonnull end
