#include <stdatomic.h>
#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static atomic_t(uint64_t) async_next_task_id = 1;

[[direct_members]]
@interface Task ()

- (AsyncPromiseCompletion *)_completionForBlockExecution;

@end

@implementation TaskReturnedNilException


- (instancetype)initWithTask: (Task *)task
{
    self = [super initWithPromise: task];
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
    self = [super initWithPromise: task];
    _task = task;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"TaskCancelledException: %@ observed a cancellation checkpoint", self.task];
}

@end

@implementation Task {
    AsyncScheduler *_scheduler;
    AsyncScope *_scope;
    Coroutine<id> *_coroutine;
    id (^_block)(void);
    OFString *nillable _name;
    uint64_t _taskID;
    OFMutex *_stateLock;
    enum AsyncTaskExecutionState _executionState;
    OFString *nillable _waitReason;
    AsyncTaskWaitRegistration *nillable _waitRegistration;
    bool _cancellationRequested;
    size_t _cancellationSuppressionDepth;
    unretained AsyncScope *nillable _currentExecutionScope;
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

+ (OFString *)describeExecutionState: (enum AsyncTaskExecutionState)state
{
    switch (state) {
        case AsyncTaskExecutionState_READY: return @"READY";
        case AsyncTaskExecutionState_RUNNING: return @"RUNNING";
        case AsyncTaskExecutionState_WAITING: return @"WAITING";
        case AsyncTaskExecutionState_RESOLVED: return @"RESOLVED";
    }
}

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler scope: (AsyncScope *nillable)scope name: (OFString *nillable)name block: (id (^)(void))block
{
    self = [super _initInternal];
    _scheduler = scheduler;
    _scope = scope;
    _block = [block copy];
    _name = [name copy];
    _taskID = atomic_fetch_add_explicit(&async_next_task_id, 1, memory_order_relaxed);
    _stateLock = [OFMutex mutex];
    _executionState = AsyncTaskExecutionState_READY;
    _cancellationRequested = false;
    _cancellationSuppressionDepth = 0;
    _currentExecutionScope = scope;

    unretained Task *unsafeSelf = self;
    _coroutine = [[Coroutine alloc] initWithBlock: ^id(unretained Coroutine *co) {
        (void)co;
        return [unsafeSelf _completionForBlockExecution];
    } stackSize: Task.defaultStackSize];

    if (scope != nilptr)
        [scope _registerChildTask: self];
    [_scheduler _enqueueTask: self];
    return self;
}

- (AsyncPromiseCompletion *)_completionForBlockExecution
{
    @try {
        id value = _block();

        if (value == nilptr)
            return [[AsyncPromiseCompletion alloc] initWithException: [[TaskReturnedNilException alloc] initWithTask: self]];

        return [[AsyncPromiseCompletion alloc] initWithValue: value];
    } @catch (OFException *exception) {
        return [[AsyncPromiseCompletion alloc] initWithException: exception];
    }
}

- (void)cancel
{
    [self _requestCancellation];
}

- (void)_setScope: (AsyncScope *nillable)scope
{
    [_stateLock lock];
    @try {
        _scope = scope;
    } @finally {
        [_stateLock unlock];
    }
}

- (enum AsyncTaskExecutionState)executionState
{
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
    OFString *waitReason;

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
    AsyncScope *scope = async_current_scope;

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

    while (scope != nilptr) {
        if (scope.isCancellationRequested)
            return true;
        scope = scope.parentScope;
    }

    return false;
}

- (bool)_isCancellationRequested
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

- (void)_requestCancellation
{
    AsyncTaskWaitRegistration *waitRegistration = nilptr;
    bool shouldCancelWait = false;
    bool cancellationSuppressed = false;

    [_stateLock lock];
    @try {
        if (self.isResolved or _cancellationRequested)
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
        if (self.isResolved)
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

- (AsyncScope *nillable)_resumeScopeContext
{
    AsyncScope *scope;

    [_stateLock lock];
    @try {
        scope = _currentExecutionScope;
    } @finally {
        [_stateLock unlock];
    }

    return scope;
}

- (void)_captureCurrentScopeContext
{
    [_stateLock lock];
    @try {
        _currentExecutionScope = async_current_scope;
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
        _currentExecutionScope = nilptr;
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
    AsyncScope *scope = self.scope;

    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [self _resolveWithValue: value];
    if (scope != nilptr)
        [scope _task: self didCompleteWithException: nilptr];
    [self _cleanupResolvedState];
    [self.scheduler _recordTaskResolutionForTask: self];
}

- (void)_rejectTaskWithException: (OFException *)exception
{
    AsyncScope *scope = self.scope;

    [self _setExecutionState: AsyncTaskExecutionState_RESOLVED waitReason: nilptr];
    [self _rejectWithException: exception];
    if (scope != nilptr)
        [scope _task: self didCompleteWithException: exception];
    [self _cleanupResolvedState];
    [self.scheduler _recordTaskResolutionForTask: self];
}

- (void)_resolveFromCompletion: (AsyncPromiseCompletion *)completion
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

    if (name != nilptr)
        return [OFString stringWithFormat: @"<Task %p #%llu %@ %@>", self, (unsigned long long)self.taskID, name, [Task describeExecutionState: self.executionState]];

    return [OFString stringWithFormat: @"<Task %p #%llu %@>", self, (unsigned long long)self.taskID, [Task describeExecutionState: self.executionState]];
}

@end

#pragma clang assume_nonnull end
