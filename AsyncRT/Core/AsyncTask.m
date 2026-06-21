#include <stdatomic.h>
#import <AsyncRT/Core/AsyncRuntimeInternal.h>

#pragma clang assume_nonnull begin

static atomic_t(uint64_t) async_next_task_id = 1;

@implementation AsyncTaskReturnedNilException

- (instancetype)initWithTask: (AsyncTask *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncTaskReturnedNilException: %@ returned nilptr instead of a nonnull value", self.task];
}

@end

@implementation AsyncTaskCancelledException

- (instancetype)initWithTask: (AsyncTask *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncTaskCancelledException: %@ observed a cancellation checkpoint", self.task];
}

@end

[[direct_members]]
@implementation AsyncTask {
    AsyncCompletionSource<id> *_resultCompletionSource;
    AsyncTaskState<id> *nillable _wrappedTaskState;
    AsyncScheduler *_scheduler;
    AsyncCoroutine<id> *_coroutine;
    id (^_block)(void);
    OFString *nillable _name;
    uint64_t _taskID;
    OFMutex *_stateLock;
    enum AsyncTaskExecutionState _executionState;
    OFString *nillable _waitReason;
    AsyncTaskWaitRegistration *nillable _waitRegistration;
    bool _cancellationRequested;
    bool _isReadyQueued;
}

+ (AsyncTask *nillable)currentTask
{
    return async_current_task;
}

+ (size_t)defaultStackSize
{
    return AsyncCoroutine.defaultStackSize;
}

+ (void)setDefaultStackSize: (size_t)defaultStackSize
{
    AsyncCoroutine.defaultStackSize = defaultStackSize;
}

+ (void)checkCancellation
{
    AsyncTask *currentTask = self.currentTask;

    if (currentTask == nilptr)
        return;
    if ([currentTask _shouldDeliverCancellationCheckpoint])
        @throw [[AsyncTaskCancelledException alloc] initWithTask: currentTask];
}

+ (OFString *)describeStatus: (enum AsyncTaskStatus)status
{
    return [AsyncTaskState describeStatus: status];
}

+ (OFString *)describeExecutionState: (enum AsyncTaskExecutionState)state
{
    switch (state) {
        case AsyncTaskExecutionState_READY: return @"READY";
        case AsyncTaskExecutionState_RUNNING: return @"RUNNING";
        case AsyncTaskExecutionState_WAITING: return @"WAITING";
        case AsyncTaskExecutionState_RESOLVED: return @"RESOLVED";
    }
}

+ (AsyncTask<id> *)_taskWrappingPromise: (AsyncTaskState<id> *)promise
{
    return [[AsyncTask<id> alloc] initWithTaskState: promise];
}

+ (AsyncTask<id> *)resolved: (id)value
{
    return [self _taskWrappingPromise: [AsyncTaskState resolved: value]];
}

+ (AsyncTask<id> *)rejected: (OFException *)exception
{
    return [self _taskWrappingPromise: [AsyncTaskState rejected: exception]];
}

+ (AsyncTask<OFArray<id> *> *)all: (OFArray<AsyncTask *> *)tasks
{
    return (AsyncTask<OFArray<id> *> *)[self _taskWrappingPromise: [AsyncTaskState allTasks: tasks]];
}

+ (AsyncTask<id> *)race: (OFArray<AsyncTask *> *)tasks
{
    return [self _taskWrappingPromise: [AsyncTaskState raceTasks: tasks]];
}

- (AsyncTaskState<id> *)_internalTaskState
{
    if (_wrappedTaskState != nilptr)
        return $assert_nonnil(_wrappedTaskState);

    return [_resultCompletionSource _internalTaskState];
}

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler name: (OFString *nillable)name block: (id (^)(void))block
{
    self = [super init];
    _resultCompletionSource = [[AsyncCompletionSource<id> alloc] init];
    [[_resultCompletionSource _internalTaskState] _setAssociatedTask: self];
    [[_resultCompletionSource _internalTaskState] _setProducingTask: self];
    _scheduler = scheduler;
    _block = [block copy];
    _name = [name copy];
    _taskID = atomic_fetch_add_explicit(&async_next_task_id, 1, memory_order_relaxed);
    _stateLock = [OFMutex mutex];
    _executionState = AsyncTaskExecutionState_READY;
    _cancellationRequested = false;
    _isReadyQueued = false;

    unretained AsyncTask *unsafeSelf = self;
    _coroutine = [[AsyncCoroutine alloc] initWithBlock: ^id(unretained AsyncCoroutine *co) {
        (void)co;
        return [unsafeSelf _completionForBlockExecution];
    } stackSize: AsyncTask.defaultStackSize];

    [_scheduler _enqueueTask: self];
    return self;
}

- (instancetype)initWithTaskState: (AsyncTaskState *)promise
{
    self = [super init];
    _wrappedTaskState = promise;
    _taskID = atomic_fetch_add_explicit(&async_next_task_id, 1, memory_order_relaxed);
    _stateLock = [OFMutex mutex];
    _executionState = (promise.isCompleted ? AsyncTaskExecutionState_RESOLVED : AsyncTaskExecutionState_WAITING);
    _cancellationRequested = false;
    _isReadyQueued = false;
    [promise _setAssociatedTask: self];
    return self;
}

- (enum AsyncTaskStatus)status
{
    return self._internalTaskState.status;
}

- (bool)isCompleted
{
    return self._internalTaskState.isCompleted;
}

- (OFException *)failureException
{
    return self._internalTaskState.failureException;
}

- (AsyncTask<id> *)map: (id (^)(id value))transform
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState map: transform]];
}

- (AsyncTask<id> *)flatMap: (AsyncTask * (^)(id value))transform
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatMapTask: transform]];
}

- (AsyncTask<id> *)recover: (id (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState recover: handler]];
}

- (AsyncTask<id> *)flatRecover: (AsyncTask * (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatRecoverTask: handler]];
}

- (AsyncTask<id> *)ensure: (void (^)(void))block
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState ensure: block]];
}

- (id)await
{
    if (AsyncTask.currentTask == self)
        @throw [[AsyncTaskSelfAwaitException alloc] initWithTask: self];

    return self._internalTaskState.await;
}

- (AsyncTaskExecutionCompletion *)_completionForBlockExecution
{
    @try {
        id value = _block();

        if (value == nilptr)
            return [[AsyncTaskExecutionCompletion alloc] initWithException: [[AsyncTaskReturnedNilException alloc] initWithTask: self]];

        return [[AsyncTaskExecutionCompletion alloc] initWithValue: value];
    } @catch (id exception) {
        if ([$assert_nonnil(exception) isKindOfClass: OFException.class])
            return [[AsyncTaskExecutionCompletion alloc] initWithException: (OFException *)$assert_nonnil(exception)];

        return [[AsyncTaskExecutionCompletion alloc] initWithException: [OFInvalidArgumentException exception]];
    }
}

- (void)cancel
{
    AsyncTask *producingTask = [self._internalTaskState _producingTask];

    if (producingTask != nilptr and producingTask != self) {
        [producingTask cancel];
        return;
    }

    [self _requestCancellation];
}

- (enum AsyncTaskExecutionState)executionState
{
    if (_wrappedTaskState != nilptr)
        return (_wrappedTaskState.isCompleted ? AsyncTaskExecutionState_RESOLVED : AsyncTaskExecutionState_WAITING);

    enum AsyncTaskExecutionState executionState;

    [_stateLock lock];
    @try {
        executionState = _executionState;
    } @finally {
        [_stateLock unlock];
    }

    return executionState;
}

- (OFString *nillable)waitReason
{
    OFString *nillable waitReason;

    [_stateLock lock];
    @try {
        waitReason = _waitReason;
    } @finally {
        [_stateLock unlock];
    }

    return waitReason;
}

- (bool)isCancellationRequested
{
    [_stateLock lock];
    bool cancellationRequested = false;
    @try {
        cancellationRequested = _cancellationRequested;
    } @finally {
        [_stateLock unlock];
    }

    return cancellationRequested;
}

- (bool)_shouldDeliverCancellationCheckpoint
{
    [_stateLock lock];
    bool taskCancellationRequested = false;
    @try {
        taskCancellationRequested = _cancellationRequested;
    } @finally {
        [_stateLock unlock];
    }

    return taskCancellationRequested;
}

- (bool)_isCancellationRequested
{
    return self.isCancellationRequested;
}

- (bool)_markReadyQueued
{
    bool shouldEnqueue = false;

    [_stateLock lock];
    @try {
        shouldEnqueue = (not self._internalTaskState.isCompleted and not _isReadyQueued);
        if (shouldEnqueue)
            _isReadyQueued = true;
    } @finally {
        [_stateLock unlock];
    }

    return shouldEnqueue;
}

- (void)_clearReadyQueued
{
    [_stateLock lock];
    @try {
        _isReadyQueued = false;
    } @finally {
        [_stateLock unlock];
    }
}

- (void)_requestCancellation
{
    AsyncTaskWaitRegistration *waitRegistration = nilptr;
    bool shouldCancelWait = false;

    [_stateLock lock];
    @try {
        if (self._internalTaskState.isCompleted or _cancellationRequested)
            return;

        _cancellationRequested = true;
        if (_executionState == AsyncTaskExecutionState_WAITING and _waitRegistration != nilptr) {
            waitRegistration = _waitRegistration;
            shouldCancelWait = true;
        }
    } @finally {
        [_stateLock unlock];
    }

    if (shouldCancelWait)
        [waitRegistration cancel];
}

- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason
{
    [_stateLock lock];
    @try {
        _executionState = AsyncTaskExecutionState_WAITING;
        _waitReason = [waitReason copy];
        _waitRegistration = registration;
    } @finally {
        [_stateLock unlock];
    }

    [_coroutine yield: [[AsyncWaitInstruction alloc] initWithRegistration: registration waitReason: waitReason]];
}

- (bool)_resumeFromWaitRegistration: (AsyncTaskWaitRegistration *)registration
{
    bool didResume = false;

    [_stateLock lock];
    @try {
        if (_executionState == AsyncTaskExecutionState_WAITING and _waitRegistration == registration) {
            _executionState = AsyncTaskExecutionState_READY;
            _waitReason = nilptr;
            _waitRegistration = nilptr;
            didResume = true;
        }
    } @finally {
        [_stateLock unlock];
    }

    return didResume;
}

- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason
{
    [_stateLock lock];
    @try {
        _executionState = executionState;
        _waitReason = [waitReason copy];
        if (executionState != AsyncTaskExecutionState_WAITING)
            _waitRegistration = nilptr;
    } @finally {
        [_stateLock unlock];
    }
}

- (void)_cleanupResolvedState
{
    [_stateLock lock];
    @try {
        _block = nilptr;
        AsyncRetainForTSAN(_coroutine);
        _coroutine = nilptr;
        _waitReason = nilptr;
        _waitRegistration = nilptr;
    } @finally {
        [_stateLock unlock];
    }
}

- (AsyncCoroutine<id> *)_coroutineObject
{
    return _coroutine;
}

- (void)_fulfillTaskWithValue: (id)value
{
    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [_resultCompletionSource fulfill: value];
    [self _cleanupResolvedState];
    [self.scheduler _recordTaskResolutionForTask: self];
}

- (void)_rejectTaskWithException: (OFException *)exception
{
    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [_resultCompletionSource reject: exception];
    [self _cleanupResolvedState];
    [self.scheduler _recordTaskResolutionForTask: self];
}

- (void)_resolveFromCompletion: (AsyncTaskExecutionCompletion *)completion
{
    OFException *exception = completion.exception;

    if (exception != nilptr)
        [self _rejectTaskWithException: exception];
    else
        [self _fulfillTaskWithValue: $assert_nonnil(completion.value)];
}

- (OFString *)description
{
    OFString *name = self.name;
    OFString *executionStateDescription = [AsyncTask describeExecutionState: self.executionState];
    OFString *statusDescription = [AsyncTask describeStatus: self.status];

    if (name != nilptr)
        return [OFString stringWithFormat: @"<AsyncTask %p #%llu %@ %@ %@>", self, (unsigned long long)self.taskID, name, executionStateDescription, statusDescription];

    return [OFString stringWithFormat: @"<AsyncTask %p #%llu %@ %@>", self, (unsigned long long)self.taskID, executionStateDescription, statusDescription];
}

@end

#pragma clang assume_nonnull end
