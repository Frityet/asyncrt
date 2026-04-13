#include <stdatomic.h>
#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static atomic_t(uint64_t) async_next_task_id = 1;

[[direct_members]]
@interface Task ()

- (AsyncTaskExecutionCompletion *)_completionForBlockExecution;

@end

@implementation TaskReturnedNilException

- (instancetype)initWithTask: (Task *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"TaskReturnedNilException: %@ returned nilptr instead of a nonnull value", self.task];
}

@end

@implementation TaskCancelledException

- (instancetype)initWithTask: (Task *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"TaskCancelledException: %@ observed a cancellation checkpoint", self.task];
}

@end

@implementation Task {
    AsyncCompletionSource<id> *_resultCompletionSource;
    AsyncTaskState<id> *nillable _wrappedTaskState;
    AsyncScheduler *_scheduler;
    AsyncTaskGroup *nillable _taskGroup;
    Coroutine<id> *_coroutine;
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

+ (Task *nillable)currentTask
{
    return async_current_task;
}

+ (size_t)defaultStackSize
{
    return Coroutine.defaultStackSize;
}

+ (void)setDefaultStackSize: (size_t)defaultStackSize
{
    Coroutine.defaultStackSize = defaultStackSize;
}

+ (void)checkCancellation
{
    Task *currentTask = self.currentTask;

    if (currentTask == nilptr)
        return;
    if ([currentTask _shouldDeliverCancellationCheckpoint])
        @throw [[TaskCancelledException alloc] initWithTask: currentTask];
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

+ (Task<id> *)_taskWrappingPromise: (AsyncTaskState<id> *)promise
{
    return [[Task<id> alloc] initWithTaskState: promise];
}

+ (Task<id> *)resolved: (id)value
{
    return [self _taskWrappingPromise: [AsyncTaskState resolved: value]];
}

+ (Task<id> *)rejected: (OFException *)exception
{
    return [self _taskWrappingPromise: [AsyncTaskState rejected: exception]];
}

+ (Task<OFArray<id> *> *)all: (OFArray<Task *> *)tasks
{
    return (Task<OFArray<id> *> *)[self _taskWrappingPromise: [AsyncTaskState allTasks: tasks]];
}

+ (Task<id> *)race: (OFArray<Task *> *)tasks
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

    unretained Task *unsafeSelf = self;
    _coroutine = [[Coroutine alloc] initWithBlock: ^id(unretained Coroutine *co) {
        (void)co;
        return [unsafeSelf _completionForBlockExecution];
    } stackSize: Task.defaultStackSize];

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

- (id)value
{
    return self._internalTaskState.value;
}

- (OFException *)failureException
{
    return self._internalTaskState.failureException;
}

- (Task<id> *)map: (id (^)(id value))transform
{
    return [Task _taskWrappingPromise: [self._internalTaskState map: transform]];
}

- (Task<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(id value))transform
{
    return [Task _taskWrappingPromise: [self._internalTaskState mapOnScheduler: scheduler transform: transform]];
}

- (Task<id> *)flatMap: (Task * (^)(id value))transform
{
    return [Task _taskWrappingPromise: [self._internalTaskState flatMapTask: transform]];
}

- (Task<id> *)flatMapOnScheduler: (AsyncScheduler *)scheduler transform: (Task * (^)(id value))transform
{
    return [Task _taskWrappingPromise: [self._internalTaskState flatMapTaskOnScheduler: scheduler transform: transform]];
}

- (Task<id> *)recover: (id (^)(OFException *exception))handler
{
    return [Task _taskWrappingPromise: [self._internalTaskState recover: handler]];
}

- (Task<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler
{
    return [Task _taskWrappingPromise: [self._internalTaskState recoverOnScheduler: scheduler handler: handler]];
}

- (Task<id> *)flatRecover: (Task * (^)(OFException *exception))handler
{
    return [Task _taskWrappingPromise: [self._internalTaskState flatRecoverTask: handler]];
}

- (Task<id> *)flatRecoverOnScheduler: (AsyncScheduler *)scheduler handler: (Task * (^)(OFException *exception))handler
{
    return [Task _taskWrappingPromise: [self._internalTaskState flatRecoverTaskOnScheduler: scheduler handler: handler]];
}

- (Task<id> *)ensure: (void (^)(void))block
{
    return [Task _taskWrappingPromise: [self._internalTaskState ensure: block]];
}

- (Task<id> *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block
{
    return [Task _taskWrappingPromise: [self._internalTaskState ensureOnScheduler: scheduler block: block]];
}

- (id)await
{
    if (Task.currentTask == self)
        @throw [[AsyncTaskSelfAwaitException alloc] initWithTask: self];

    return self._internalTaskState.await;
}

- (AsyncTaskExecutionCompletion *)_completionForBlockExecution
{
    @try {
        id value = _block();

        if (value == nilptr)
            return [[AsyncTaskExecutionCompletion alloc] initWithException: [[TaskReturnedNilException alloc] initWithTask: self]];

        return [[AsyncTaskExecutionCompletion alloc] initWithValue: value];
    } @catch (OFException *exception) {
        return [[AsyncTaskExecutionCompletion alloc] initWithException: exception];
    }
}

- (void)cancel
{
    Task *producingTask = [self._internalTaskState _producingTask];

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
    bool cancellationRequested;

    [_stateLock lock];
    @try {
        cancellationRequested = _cancellationRequested;
    } @finally {
        [_stateLock unlock];
    }

    return cancellationRequested;
}

- (bool)_shouldDeliverCancellationCheckpoint
{
    bool taskCancellationRequested;
    bool cancellationSuppressed;
    AsyncTaskGroup *taskGroup = async_current_task_group;

    [_stateLock lock];
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

- (Coroutine<id> *)_coroutineObject
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
    OFString *executionStateDescription = [Task describeExecutionState: self.executionState];
    OFString *statusDescription = [Task describeStatus: self.status];

    if (name != nilptr)
        return [OFString stringWithFormat: @"<Task %p #%llu %@ %@ %@>", self, (unsigned long long)self.taskID, name, executionStateDescription, statusDescription];

    return [OFString stringWithFormat: @"<Task %p #%llu %@ %@>", self, (unsigned long long)self.taskID, executionStateDescription, statusDescription];
}

@end

#pragma clang assume_nonnull end
