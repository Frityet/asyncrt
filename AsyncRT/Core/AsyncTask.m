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
    AsyncTaskGroup *nillable _taskGroup;
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
    size_t _cancellationSuppressionDepth;
    unretained AsyncTaskGroup *nillable _currentExecutionTaskGroup;
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

- (AsyncTaskGroup *nillable)taskGroup
{
    AsyncTaskGroup *nillable taskGroup;

    [_stateLock lock];
    @try {
        taskGroup = _taskGroup;
    } @finally {
        [_stateLock unlock];
    }

    return taskGroup;
}

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler taskGroup: (AsyncTaskGroup *nillable)taskGroup name: (OFString *nillable)name block: (id (^)(void))block
{
    self = [super init];
    _resultCompletionSource = [[AsyncCompletionSource<id> alloc] init];
    [[_resultCompletionSource _internalTaskState] _setAssociatedTask: self];
    [[_resultCompletionSource _internalTaskState] _setProducingTask: self];
    _scheduler = scheduler;
    _taskGroup = taskGroup;
    _block = [block copy];
    _name = [name copy];
    _taskID = atomic_fetch_add_explicit(&async_next_task_id, 1, memory_order_relaxed);
    _stateLock = [OFMutex mutex];
    _executionState = AsyncTaskExecutionState_READY;
    _cancellationRequested = false;
    _isReadyQueued = false;
    _cancellationSuppressionDepth = 0;
    _currentExecutionTaskGroup = taskGroup;

    unretained AsyncTask *unsafeSelf = self;
    _coroutine = [[AsyncCoroutine alloc] initWithBlock: ^id(unretained AsyncCoroutine *co) {
        (void)co;
        return [unsafeSelf _completionForBlockExecution];
    } stackSize: AsyncTask.defaultStackSize];

    if (taskGroup != nilptr)
        [taskGroup _registerChildTask: self];
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
    _cancellationSuppressionDepth = 0;
    _currentExecutionTaskGroup = nilptr;
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

- (AsyncTask<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(id value))transform
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState mapOnScheduler: scheduler transform: transform]];
}

- (AsyncTask<id> *)flatMap: (AsyncTask * (^)(id value))transform
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatMapTask: transform]];
}

- (AsyncTask<id> *)flatMapOnScheduler: (AsyncScheduler *)scheduler transform: (AsyncTask * (^)(id value))transform
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatMapTaskOnScheduler: scheduler transform: transform]];
}

- (AsyncTask<id> *)recover: (id (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState recover: handler]];
}

- (AsyncTask<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState recoverOnScheduler: scheduler handler: handler]];
}

- (AsyncTask<id> *)flatRecover: (AsyncTask * (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatRecoverTask: handler]];
}

- (AsyncTask<id> *)flatRecoverOnScheduler: (AsyncScheduler *)scheduler handler: (AsyncTask * (^)(OFException *exception))handler
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState flatRecoverTaskOnScheduler: scheduler handler: handler]];
}

- (AsyncTask<id> *)ensure: (void (^)(void))block
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState ensure: block]];
}

- (AsyncTask<id> *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block
{
    return [AsyncTask _taskWrappingPromise: [self._internalTaskState ensureOnScheduler: scheduler block: block]];
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

- (void)_setTaskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    [_stateLock lock];
    @try {
        _taskGroup = taskGroup;
    } @finally {
        [_stateLock unlock];
    }
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
    AsyncTaskGroup *taskGroup = async_current_task_group;

    [_stateLock lock];
    bool taskCancellationRequested = false;
    bool cancellationSuppressed = false;
    @try {
        taskCancellationRequested = _cancellationRequested;
        cancellationSuppressed = (_cancellationSuppressionDepth > 0);
    } @finally {
        [_stateLock unlock];
    }

    if (cancellationSuppressed)
        return false;
    if (taskCancellationRequested)
        return true;

    while (taskGroup != nilptr) {
        if (taskGroup.isCancellationRequested)
            return true;
        taskGroup = taskGroup.parentTaskGroup;
    }

    return false;
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
    bool cancellationSuppressed = false;

    [_stateLock lock];
    @try {
        if (self._internalTaskState.isCompleted or _cancellationRequested)
            return;

        _cancellationRequested = true;
        cancellationSuppressed = (_cancellationSuppressionDepth > 0);
        if (_executionState == AsyncTaskExecutionState_WAITING and _waitRegistration != nilptr) {
            waitRegistration = _waitRegistration;
            shouldCancelWait = not cancellationSuppressed;
        }
    } @finally {
        [_stateLock unlock];
    }

    if (shouldCancelWait)
        [waitRegistration cancel];
}

- (void)_interruptForScopeCancellation
{
    AsyncTaskWaitRegistration *waitRegistration = nilptr;
    bool cancellationSuppressed = false;

    [_stateLock lock];
    @try {
        if (self._internalTaskState.isCompleted)
            return;

        cancellationSuppressed = (_cancellationSuppressionDepth > 0);
        if (_executionState == AsyncTaskExecutionState_WAITING)
            waitRegistration = _waitRegistration;
    } @finally {
        [_stateLock unlock];
    }

    if (waitRegistration != nilptr and not cancellationSuppressed)
        [waitRegistration cancel];
}

- (void)_pushCancellationSuppression
{
    [_stateLock lock];
    @try {
        _cancellationSuppressionDepth++;
    } @finally {
        [_stateLock unlock];
    }
}

- (void)_popCancellationSuppression
{
    [_stateLock lock];
    @try {
        if (_cancellationSuppressionDepth == 0)
            @throw [OFOutOfRangeException exception];
        _cancellationSuppressionDepth--;
    } @finally {
        [_stateLock unlock];
    }
}

- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason
{
    [self _captureCurrentScopeContext];

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

- (AsyncTaskGroup *nillable)_resumeTaskGroupContext
{
    AsyncTaskGroup *nillable taskGroup;

    [_stateLock lock];
    @try {
        taskGroup = _currentExecutionTaskGroup;
    } @finally {
        [_stateLock unlock];
    }

    return taskGroup;
}

- (void)_captureCurrentScopeContext
{
    [_stateLock lock];
    @try {
        _currentExecutionTaskGroup = async_current_task_group;
    } @finally {
        [_stateLock unlock];
    }
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
        _currentExecutionTaskGroup = nilptr;
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
    AsyncTaskGroup *taskGroup = self.taskGroup;

    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [_resultCompletionSource fulfill: value];
    if (taskGroup != nilptr)
        [taskGroup _task: self didCompleteWithException: nilptr];
    [self _cleanupResolvedState];
    [self.scheduler _recordTaskResolutionForTask: self];
}

- (void)_rejectTaskWithException: (OFException *)exception
{
    AsyncTaskGroup *taskGroup = self.taskGroup;

    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [_resultCompletionSource reject: exception];
    if (taskGroup != nilptr)
        [taskGroup _task: self didCompleteWithException: exception];
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
