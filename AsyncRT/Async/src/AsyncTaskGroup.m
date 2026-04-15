#import "AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@implementation AsyncTaskGroupTimeoutException

- (instancetype)initWithTaskGroup: (AsyncTaskGroup *)taskGroup deadline: (OFDate *)deadline
{
    self = [super init];
    _taskGroup = taskGroup;
    _deadline = [deadline copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncTaskGroupTimeoutException: %@ exceeded deadline %@", self.taskGroup, self.deadline];
}

@end

[[direct_members]]
@implementation AsyncTaskGroup {
    OFMutex *_lock;
    OFMutableSet<Task *> *_liveTasks;
    AsyncCompletionSource<AsyncUnit *> *_completionSource;
    OFTimer *nillable _deadlineTimer;
    OFException *nillable _primaryFailure;
    bool _bodyFinished;
    bool _cancellationRequested;
}

+ (AsyncTaskGroup *nillable)currentTaskGroup
{
    return async_current_task_group;
}

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler ownerTask: (Task *)ownerTask parentTaskGroup: (AsyncTaskGroup *nillable)parentTaskGroup name: (OFString *nillable)name deadline: (OFDate *nillable)deadline
{
    self = [super init];
    _scheduler = scheduler;
    _parentTaskGroup = parentTaskGroup;
    _ownerTask = ownerTask;
    _name = [name copy];
    _deadline = [deadline copy];
    _lock = [OFMutex mutex];
    _liveTasks = [OFMutableSet set];
    _completionSource = [[AsyncCompletionSource<AsyncUnit *> alloc] init];
    _bodyFinished = false;
    _cancellationRequested = false;
    return self;
}

- (bool)isCancellationRequested
{
    [_lock lock];
    bool cancellationRequested = false;
    @try {
        cancellationRequested = _cancellationRequested;
    } @finally {
        [_lock unlock];
    }

    return cancellationRequested;
}

- (void)_resolveCompletionIfNeeded
{
    bool shouldResolve = false;

    [_lock lock];
    @try {
        shouldResolve = (_bodyFinished and _liveTasks.count == 0);
    } @finally {
        [_lock unlock];
    }

    if (not shouldResolve)
        return;

    @try {
        [_completionSource fulfill: AsyncUnit.unit];
    } @catch (AsyncTaskAlreadyResolvedException *) {
    }
}

- (void)_recordFailureIfNeeded: (OFException *)exception
{
    bool shouldCancel = false;

    if ([exception isKindOfClass: TaskCancelledException.class])
        return;

    [_lock lock];
    @try {
        if (_primaryFailure == nilptr) {
            _primaryFailure = exception;
            shouldCancel = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (shouldCancel)
        [self cancel];
}

- (void)_registerChildTask: (Task *)task
{
    [_lock lock];
    @try {
        if (_bodyFinished or _cancellationRequested)
            @throw [OFInvalidArgumentException exception];
        [_liveTasks addObject: task];
    } @finally {
        [_lock unlock];
    }
}

- (void)_task: (Task *)task didCompleteWithException: (OFException *nillable)exception
{
    [_lock lock];
    @try {
        [_liveTasks removeObject: task];
    } @finally {
        [_lock unlock];
    }

    if (exception != nilptr)
        [self _recordFailureIfNeeded: $assert_nonnil(exception)];

    [self _resolveCompletionIfNeeded];
}

- (void)_cancelOwnedTasks
{
    OFArray<Task *> *liveTasks;

    [_lock lock];
    @try {
        liveTasks = _liveTasks.allObjects;
    } @finally {
        [_lock unlock];
    }

    for (Task *task in liveTasks)
        [task cancel];
}

- (void)cancel
{
    bool didRequestCancellation = false;

    [_lock lock];
    @try {
        if (not _cancellationRequested) {
            _cancellationRequested = true;
            didRequestCancellation = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (not didRequestCancellation)
        return;

    [self _cancelOwnedTasks];
    [self.ownerTask _interruptForScopeCancellation];
}

- (void)_cancelFromTimeoutWithDeadline: (OFDate *)deadline
{
    bool shouldCancel = false;

    [_lock lock];
    @try {
        if (not _cancellationRequested) {
            _cancellationRequested = true;
            shouldCancel = true;
        }
        if (_primaryFailure == nilptr)
            _primaryFailure = [[AsyncTaskGroupTimeoutException alloc] initWithTaskGroup: self deadline: deadline];
    } @finally {
        [_lock unlock];
    }

    if (not shouldCancel)
        return;

    [self _cancelOwnedTasks];
    [self.ownerTask _interruptForScopeCancellation];
}

- (void)_installDeadlineTimerIfNeeded
{
    OFDate *deadline = self.deadline;

    if (deadline == nilptr)
        return;

    if ([deadline compare: OFDate.date] != OFOrderedDescending) {
        [self _cancelFromTimeoutWithDeadline: deadline];
        return;
    }

    unretained AsyncTaskGroup *unsafeSelf = self;
    _deadlineTimer = [[OFTimer alloc] initWithFireDate: deadline interval: 0 repeats: false block: ^(OFTimer *) {
        [unsafeSelf _cancelFromTimeoutWithDeadline: deadline];
    }];
    [self.scheduler.runLoop addTimer: $assert_nonnil(_deadlineTimer) forMode: self.scheduler.mode];
}

- (void)_invalidateDeadlineTimerIfNeeded
{
    OFTimer *deadlineTimer = _deadlineTimer;

    _deadlineTimer = nilptr;
    if (deadlineTimer != nilptr and deadlineTimer.isValid)
        [deadlineTimer invalidate];
}

- (void)_waitForChildrenToFinish
{
    [self.ownerTask _pushCancellationSuppression];
    @try {
        if (self->_completionSource.task.isCompleted)
            return;

        [self->_completionSource.task await];
    } @finally {
        [self.ownerTask _popCancellationSuppression];
    }
}

- (Task<id> *)spawnTask: (id (^)(void))block
{
    return [self spawnTask: block name: nilptr];
}

- (Task<id> *)spawnTask: (id (^)(void))block name: (OFString *nillable)name
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];
    return [[Task alloc] initWithScheduler: self.scheduler taskGroup: self name: name block: block];
}

- (Task<id> *)spawnTaskInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block name: (OFString *nillable)name
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    auto childTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentTaskGroup: self name: name deadline: self.deadline];
    return [childTaskGroup _runTaskGroupBody: block];
}

- (Task<id> *)spawnTaskInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block
{
    return [self spawnTaskInChildTaskGroup: block name: nilptr];
}

- (Task<OFArray<id> *> *)spawnAllTasks: (OFArray<id (^)(void)> *)blocks
{
    return [self spawnAllTasks: blocks name: nilptr];
}

- (Task<OFArray<id> *> *)spawnAllTasks: (OFArray<id (^)(void)> *)blocks name: (OFString *nillable)name
{
    OFArray<id (^)(void)> *taskBlocks = [blocks copy];

    return (Task<OFArray<id> *> *)[self spawnTask: ^{
        auto tasks = [OFMutableArray<Task *> arrayWithCapacity: taskBlocks.count];

        for (size_t index = 0; index < taskBlocks.count; index++) {
            OFString *nillable childName = nilptr;

            if (name != nilptr)
                childName = [OFString stringWithFormat: @"%@[%zu]", name, index];

            [tasks addObject: [self spawnTask: taskBlocks[index] name: childName]];
        }

        return [Task all: tasks].await;
    } name: name];
}

- (id)performInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block
{
    return [self performInChildTaskGroupNamed: nilptr block: block];
}

- (id)performInChildTaskGroupNamed: (OFString *nillable)name block: (id (^)(AsyncTaskGroup *taskGroup))block
{
    auto currentTask = Task.currentTask;
    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    auto childTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentTaskGroup: self name: name deadline: self.deadline];
    return [childTaskGroup _runTaskGroupBody: block];
}

- (id)performWithTimeout: (OFTimeInterval)timeout block: (id (^)(AsyncTaskGroup *taskGroup))block
{
    auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: timeout];
    return [self performWithDeadline: deadline block: block];
}

- (id)performWithDeadline: (OFDate *)deadline block: (id (^)(AsyncTaskGroup *taskGroup))block
{
    auto currentTask = Task.currentTask;
    OFDate *parentDeadline = self.deadline;
    OFDate *effectiveDeadline = deadline;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    if (parentDeadline != nilptr and [parentDeadline compare: deadline] == OFOrderedAscending)
        effectiveDeadline = parentDeadline;

    auto childTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentTaskGroup: self name: nilptr deadline: effectiveDeadline];
    return [childTaskGroup _runTaskGroupBody: block];
}

- (id)_runTaskGroupBody: (id (^)(AsyncTaskGroup *taskGroup))block
{
    id result = nilptr;
    OFException *nillable bodyException = nilptr;
    AsyncTaskGroup *previousTaskGroup = async_current_task_group;
    Task *currentTask = Task.currentTask;
    OFException *nillable primaryFailure = nilptr;

    [self _installDeadlineTimerIfNeeded];

    async_current_task_group = self;
    @try {
        result = block(self);
    } @catch (OFException *exception) {
        bodyException = exception;
    } @finally {
        async_current_task_group = previousTaskGroup;
        if (currentTask != nilptr)
            [currentTask _captureCurrentScopeContext];
    }

    if (bodyException != nilptr and not [bodyException isKindOfClass: TaskCancelledException.class]) {
        [self _recordFailureIfNeeded: $assert_nonnil(bodyException)];
        [self cancel];
    } else if (bodyException != nilptr) {
        [self cancel];
    }

    [_lock lock];
    @try {
        _bodyFinished = true;
    } @finally {
        [_lock unlock];
    }

    [self _resolveCompletionIfNeeded];
    [self _waitForChildrenToFinish];
    [self _invalidateDeadlineTimerIfNeeded];

    [_lock lock];
    @try {
        primaryFailure = _primaryFailure;
    } @finally {
        [_lock unlock];
    }

    if (primaryFailure != nilptr)
        @throw $assert_nonnil(primaryFailure);
    if (bodyException != nilptr)
        @throw $assert_nonnil(bodyException);

    return result;
}

- (OFString *nillable)_taskGroupNameForSnapshots
{
    return self.name;
}

- (OFString *)description
{
    if (self.name != nilptr)
        return [OFString stringWithFormat: @"<AsyncTaskGroup %p %@>", self, self.name];

    return [OFString stringWithFormat: @"<AsyncTaskGroup %p>", self];
}

@end

#pragma clang assume_nonnull end
