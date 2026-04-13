#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@interface AsyncScope ()

- (void)_resolveCompletionIfNeeded;
- (void)_recordFailureIfNeeded: (OFException *)exception;
- (void)_cancelOwnedTasks;
- (void)_installDeadlineTimerIfNeeded;
- (void)_invalidateDeadlineTimerIfNeeded;
- (void)_waitForChildrenToFinish;

@end

@implementation AsyncScopeException


- (instancetype)initWithScope: (AsyncScope *)scope exceptions: (OFArray<OFException *> *)exceptions
{
    if (exceptions.count == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _scope = scope;
    _exceptions = [exceptions copy];
    return self;
}

- (OFException *)primaryException
{
    return $assert_nonnil(self.exceptions.firstObject);
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncScopeException: %@ failed with %zu exception(s), primary=%@", self.scope, self.exceptions.count, self.primaryException];
}

@end

@implementation AsyncTimeoutException


- (instancetype)initWithScope: (AsyncScope *)scope deadline: (OFDate *)deadline
{
    self = [super init];
    _scope = scope;
    _deadline = [deadline copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncTimeoutException: %@ exceeded deadline %@", self.scope, self.deadline];
}

@end

@implementation AsyncScope {
    OFMutex *_lock;
    OFMutableSet<Task *> *_liveTasks;
    OFMutableArray<OFException *> *_failures;
    PromiseResolver<AsyncUnit *> *_completionResolver;
    OFTimer *nillable _deadlineTimer;
    bool _bodyFinished;
    bool _cancellationRequested;
}


+ (AsyncScope *nillable)currentScope
{
    return async_current_scope;
}

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler ownerTask: (Task *)ownerTask parentScope: (AsyncScope *nillable)parentScope name: (OFString *nillable)name deadline: (OFDate *nillable)deadline
{
    self = [super init];
    _scheduler = scheduler;
    _parentScope = parentScope;
    _ownerTask = ownerTask;
    _name = [name copy];
    _deadline = [deadline copy];
    _lock = [OFMutex mutex];
    _liveTasks = [OFMutableSet set];
    _failures = [OFMutableArray array];
    _completionResolver = [[PromiseResolver alloc] init];
    _bodyFinished = false;
    _cancellationRequested = false;
    return self;
}

- (bool)isCancellationRequested
{
    block_reference bool cancellationRequested;

    [_lock lock];
    @try {
        cancellationRequested = _cancellationRequested;
    } @finally {
        [_lock unlock];
    }

    return cancellationRequested;
}

- (OFString *nillable)_debugName
{
    if (self.name != nilptr)
        return self.name;

    return nilptr;
}

- (OFString *nillable)_scopeNameForSnapshots
{
    return self._debugName;
}

- (void)_resolveCompletionIfNeeded
{
    block_reference bool shouldResolve = false;

    [_lock lock];
    @try {
        shouldResolve = (_bodyFinished and _liveTasks.count == 0);
    } @finally {
        [_lock unlock];
    }

    if (not shouldResolve)
        return;

    @try {
        [self->_completionResolver resolve: AsyncUnit.unit];
    } @catch (PromiseAlreadyResolvedException *) {
    }
}

- (void)_recordFailureIfNeeded: (OFException *)exception
{
    block_reference bool shouldCancel = false;

    if ([exception isKindOfClass: TaskCancelledException.class])
        return;

    [_lock lock];
    @try {
        [_failures addObject: exception];
        shouldCancel = (_failures.count == 1);
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
    block_reference OFArray<Task *> *liveTasks;

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
    block_reference bool didRequestCancellation = false;

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
    block_reference bool shouldAddTimeout = false;

    [_lock lock];
    @try {
        if (not _cancellationRequested) {
            _cancellationRequested = true;
            shouldAddTimeout = true;
            [_failures insertObject: [[AsyncTimeoutException alloc] initWithScope: self deadline: deadline] atIndex: 0];
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldAddTimeout)
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

    unretained AsyncScope *unsafeSelf = self;
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
        if (self->_completionResolver.promise.isResolved)
            return;

        [self->_completionResolver.promise await];
    } @finally {
        [self.ownerTask _popCancellationSuppression];
    }
}

- (Task<id> *)spawn: (id (^)(void))block
{
    return [self spawn: block name: nilptr];
}

- (Task<id> *)spawn: (id (^)(void))block name: (OFString *nillable)name
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];
    return [[Task alloc] initWithScheduler: self.scheduler scope: self name: name block: block];
}

- (Task<id> *)spawnInChildScope: (id (^)(AsyncScope *scope))block name: (OFString *nillable)name
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    auto childScope = [[AsyncScope alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentScope: self name: name deadline: self.deadline];
    return [childScope _runScopeBody: block];
}

- (Task<id> *)spawnInChildScope: (id (^)(AsyncScope *scope))block
{
    return [self spawnInChildScope: block name: nilptr];
}

- (Task<OFArray<id> *> *)spawnAll: (OFArray<id (^)(void)> *)blocks
{
    return [self spawnAll: blocks name: nilptr];
}

- (Task<OFArray<id> *> *)spawnAll: (OFArray<id (^)(void)> *)blocks name: (OFString *nillable)name
{
    OFArray<id (^)(void)> *taskBlocks = [blocks copy];

    return (Task<OFArray<id> *> *)[self spawn: ^{
        auto promises = [OFMutableArray<id<PromiseLike>> arrayWithCapacity: taskBlocks.count];

        for (size_t index = 0; index < taskBlocks.count; index++) {
            OFString *nillable childName = nilptr;

            if (name != nilptr)
                childName = [OFString stringWithFormat: @"%@[%zu]", name, index];

            [promises addObject: [self spawn: taskBlocks[index] name: childName]];
        }

        return [Promise all: promises].await;
    } name: name];
}

- (id)withChildScope: (id (^)(AsyncScope *scope))block
{
    return [self withChildScopeNamed: nilptr block: block];
}

- (id)withChildScopeNamed: (OFString *nillable)name block: (id (^)(AsyncScope *scope))block
{
    auto currentTask = Task.currentTask;
    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (currentTask.scheduler != self.scheduler)
        @throw [OFInvalidArgumentException exception];

    auto childScope = [[AsyncScope alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentScope: self name: name deadline: self.deadline];
    return [childScope _runScopeBody: block];
}

- (id)withTimeout: (OFTimeInterval)timeout block: (id (^)(AsyncScope *scope))block
{
    auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: timeout];
    return [self withDeadline: deadline block: block];
}

- (id)withDeadline: (OFDate *)deadline block: (id (^)(AsyncScope *scope))block
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

    auto childScope = [[AsyncScope alloc] initWithScheduler: self.scheduler ownerTask: $assert_nonnil(currentTask) parentScope: self name: nilptr deadline: effectiveDeadline];
    return [childScope _runScopeBody: block];
}

- (id)_runScopeBody: (id (^)(AsyncScope *scope))block
{
    id result = nilptr;
    OFException *nillable bodyException = nilptr;
    AsyncScope *previousScope = async_current_scope;
    Task *currentTask = Task.currentTask;
    block_reference OFArray<OFException *> *failures;

    [self _installDeadlineTimerIfNeeded];

    async_current_scope = self;
    @try {
        result = block(self);
    } @catch (OFException *exception) {
        bodyException = exception;
    } @finally {
        async_current_scope = previousScope;
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
        failures = [_failures copy];
    } @finally {
        [_lock unlock];
    }

    if (failures.count == 1) {
        OFException *failure = $assert_nonnil(failures.firstObject);

        if ([failure isKindOfClass: AsyncTimeoutException.class])
            @throw failure;
    }
    if (failures.count > 0)
        @throw [[AsyncScopeException alloc] initWithScope: self exceptions: failures];
    if (bodyException != nilptr)
        @throw $assert_nonnil(bodyException);

    return result;
}

- (OFString *)description
{
    OFString *name = self._debugName;

    if (name != nilptr)
        return [OFString stringWithFormat: @"<AsyncScope %p %@>", self, name];

    return [OFString stringWithFormat: @"<AsyncScope %p>", self];
}

@end

#pragma clang assume_nonnull end
