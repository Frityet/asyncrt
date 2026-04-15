#import "AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@protocol AsyncTaskStateObserver

- (void)promise: (AsyncTaskState *)promise didResolveWithValue: (id)value;
- (void)promise: (AsyncTaskState *)promise didRejectWithException: (OFException *)exception;

@end

[[subclassing_restricted]]
@interface AsyncTaskStateWaitRegistration : AsyncTaskWaitRegistration<AsyncTaskStateObserver>

@property(readonly, nonatomic) AsyncTaskState *promise;

- (instancetype)initWithTaskState: (AsyncTaskState *)promise scheduler: (AsyncScheduler *)scheduler task: (Task *)task [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (bool)_finishOnce [[direct]];
- (void)signal [[direct]];

@end

[[subclassing_restricted]]
@interface AsyncTaskStateBlockObserver : OFObject<AsyncTaskStateObserver>

- (instancetype)initWithTaskState: (AsyncTaskState *)promise
                      onResolve: (void (^)(AsyncTaskState *promise, id value))onResolve
                       onReject: (void (^)(AsyncTaskState *promise, OFException *exception))onReject [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attach [[direct]];
- (void)invalidate [[direct]];

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskStatePendingValueMarker : OFObject

+ (instancetype)sharedMarker [[direct]];

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskCollectionAllState : OFObject

- (instancetype)initWithTasks: (OFArray<Task *> *)tasks
                       completionSource: (AsyncCompletionSource<OFArray<id> *> *)completionSource [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (bool)_isFinished;
- (void)_cleanupObservers;
- (void)_recordValue: (id)value atIndex: (size_t)index;
- (void)_rejectWithException: (OFException *)exception;
- (void)start;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskCollectionRaceState : OFObject

- (instancetype)initWithTasks: (OFArray<Task *> *)tasks
                        completionSource: (AsyncCompletionSource<id> *)completionSource [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (bool)_isFinished;
- (bool)_finishOnce;
- (void)_cleanupObservers;
- (void)_resolveWithValue: (id)value;
- (void)_rejectWithException: (OFException *)exception;
- (void)start;

@end

@implementation AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task
{
    self = [super init];
    _task = task;
    return self;
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskException: %@", taskDescription];
}

@end

@implementation AsyncTaskAlreadyResolvedException

- (instancetype)initWithTask: (Task *nillable)task currentStatus: (enum AsyncTaskStatus)currentStatus attemptedStatus: (enum AsyncTaskStatus)attemptedStatus
{
    self = [super initWithTask: task];
    _currentStatus = currentStatus;
    _attemptedStatus = attemptedStatus;
    return self;
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskAlreadyResolvedException: %@ is already %@ and cannot transition to %@", taskDescription, [Task describeStatus: self.currentStatus], [Task describeStatus: self.attemptedStatus]];
}

@end

@implementation AsyncTaskNilResolutionValueException

- (instancetype)initWithTask: (Task *nillable)task
{
    return [super initWithTask: task];
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskNilResolutionValueException: %@ cannot be fulfilled with nilptr", taskDescription];
}

@end

@implementation AsyncTaskNilRejectionException

- (instancetype)initWithTask: (Task *nillable)task
{
    return [super initWithTask: task];
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskNilRejectionException: %@ cannot be rejected with nilptr", taskDescription];
}

@end

@implementation AsyncTaskInvalidStateAccessException

- (instancetype)initWithTask: (Task *nillable)task operation: (OFString *)operation status: (enum AsyncTaskStatus)status
{
    self = [super initWithTask: task];
    _operation = [operation copy];
    _status = status;
    return self;
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskInvalidStateAccessException: %@ cannot %@ while %@", taskDescription, self.operation, [Task describeStatus: self.status]];
}

@end

@implementation AsyncTaskAwaitOutsideTaskException

- (instancetype)initWithTask: (Task *nillable)task
{
    return [super initWithTask: task];
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskAwaitOutsideTaskException: %@ cannot be awaited outside a Task", taskDescription];
}

@end

@implementation AsyncTaskSelfAwaitException

- (instancetype)initWithTask: (Task *nillable)task
{
    return [super initWithTask: task];
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskSelfAwaitException: %@ cannot await itself", taskDescription];
}

@end

@implementation AsyncTaskContinuationOutsideTaskException

- (instancetype)initWithTask: (Task *nillable)task
{
    return [super initWithTask: task];
}

- (OFString *)description
{
    OFString *taskDescription = (self.task == nilptr ? @"<nil>" : self.task.description);
    return [OFString stringWithFormat: @"AsyncTaskContinuationOutsideTaskException: %@ requires an explicit scheduler outside a Task", taskDescription];
}

@end

[[direct_members]]
@implementation AsyncTaskState {
    OFMutex *_lock;
    enum AsyncTaskStatus _status;
    id nillable _value;
    OFException *nillable _failureException;
    OFMutableArray<id<AsyncTaskStateObserver>> *_observers;
    void (^nillable _pendingCancellationCallback)(void);
    bool _didFirePendingCancellationCallback;
    unretained Task *nillable _producingTask;
    unretained Task *nillable _associatedTask;
}

+ (void)_scheduleBlock: (void (^)(void))block
          onScheduler: (AsyncScheduler *)scheduler
{
    [scheduler _enqueueBlock: block];
}

+ (void)_rejectCompletionSourceIfPending: (AsyncCompletionSource<id> *)completionSource
                               exception: (OFException *)exception
{
    @try {
        [completionSource reject: exception];
    } @catch (AsyncTaskAlreadyResolvedException *) {
    }
}

+ (void)_fulfillCompletionSourceOrReject: (AsyncCompletionSource<id> *)completionSource
                                   value: (id)value
{
    @try {
        [completionSource fulfill: value];
    } @catch (OFException *exception) {
        [self _rejectCompletionSourceIfPending: completionSource exception: exception];
    }
}

+ (AsyncTaskState *)_taskStateFromTask: (Task *nillable)task
{
    if (task == nilptr or not [task isKindOfClass: Task.class])
        @throw [OFInvalidArgumentException exception];

    return $assert_nonnil([task _internalTaskState]);
}

+ (AsyncScheduler *)_continuationSchedulerOrThrowForTaskState: (AsyncTaskState *)promise
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [[AsyncTaskContinuationOutsideTaskException alloc] initWithTask: promise._taskForExceptions];

    return currentTask.scheduler;
}

+ (void)_cancelUnresolvedProducingTasksInTaskStates: (OFArray<AsyncTaskState *> *)promises
{
    for (AsyncTaskState *promise in promises) {
        Task *producingTask = [promise _producingTask];

        if (producingTask != nilptr and not promise.isCompleted)
            [producingTask cancel];
    }
}

+ (void)_pipeTaskState: (AsyncTaskState *)promise
 intoCompletionSource: (AsyncCompletionSource<id> *)completionSource
{
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: promise
              onResolve: ^(AsyncTaskState *, id value) {
                  [self _fulfillCompletionSourceOrReject: completionSource value: value];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [self _rejectCompletionSourceIfPending: completionSource exception: exception];
              }];

    [observer attach];
}

+ (OFString *)describeStatus: (enum AsyncTaskStatus)status
{
    switch (status) {
        case AsyncTaskStatus_PENDING: return @"PENDING";
        case AsyncTaskStatus_FULFILLED: return @"FULFILLED";
        case AsyncTaskStatus_REJECTED: return @"REJECTED";
    }
}

- (instancetype)_initInternal
{
    self = [super init];
    _lock = [OFMutex mutex];
    _status = AsyncTaskStatus_PENDING;
    _observers = [OFMutableArray array];
    _didFirePendingCancellationCallback = false;
    _producingTask = nilptr;
    _associatedTask = nilptr;
    return self;
}

+ (AsyncTaskState *)resolved: (id)value
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    [completionSource fulfill: value];
    return [completionSource _internalTaskState];
}

+ (AsyncTaskState *)rejected: (OFException *)exception
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    [completionSource reject: exception];
    return [completionSource _internalTaskState];
}

+ (AsyncTaskState<OFArray<id> *> *)allTasks: (OFArray<Task *> *)tasks
{
    auto completionSource = [[AsyncCompletionSource<OFArray<id> *> alloc] init];

    if (tasks.count == 0) {
        [completionSource fulfill: [OFArray array]];
        return [completionSource _internalTaskState];
    }

    [[[AsyncTaskCollectionAllState alloc] initWithTasks: tasks completionSource: completionSource] start];
    return [completionSource _internalTaskState];
}

+ (AsyncTaskState *)raceTasks: (OFArray<Task *> *)tasks
{
    if (tasks.count == 0)
        @throw [OFInvalidArgumentException exception];

    auto completionSource = [[AsyncCompletionSource alloc] init];
    [[[AsyncTaskCollectionRaceState alloc] initWithTasks: tasks completionSource: completionSource] start];
    return [completionSource _internalTaskState];
}

- (AsyncTaskState<id> *)map: (id (^)(id value))transform
{
    return [self mapOnScheduler: [AsyncTaskState _continuationSchedulerOrThrowForTaskState: self] transform: transform];
}

- (AsyncTaskState<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(id value))transform
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: self
              onResolve: ^(AsyncTaskState *, id value) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          [AsyncTaskState _fulfillCompletionSourceOrReject: completionSource value: transform(value)];
                      } @catch (OFException *exception) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [AsyncTaskState _scheduleBlock: ^{
                      [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return [completionSource _internalTaskState];
}

- (AsyncTaskState<id> *)flatMapTask: (Task * (^)(id value))transform
{
    return [self flatMapTaskOnScheduler: [AsyncTaskState _continuationSchedulerOrThrowForTaskState: self] transform: transform];
}

- (AsyncTaskState<id> *)flatMapTaskOnScheduler: (AsyncScheduler *)scheduler transform: (Task * (^)(id value))transform
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: self
              onResolve: ^(AsyncTaskState *, id value) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          [AsyncTaskState _pipeTaskState: [AsyncTaskState _taskStateFromTask: transform(value)] intoCompletionSource: completionSource];
                      } @catch (OFException *exception) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [AsyncTaskState _scheduleBlock: ^{
                      [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return [completionSource _internalTaskState];
}

- (AsyncTaskState<id> *)recover: (id (^)(OFException *exception))handler
{
    return [self recoverOnScheduler: [AsyncTaskState _continuationSchedulerOrThrowForTaskState: self] handler: handler];
}

- (AsyncTaskState<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: self
              onResolve: ^(AsyncTaskState *, id value) {
                  [AsyncTaskState _scheduleBlock: ^{
                      [AsyncTaskState _fulfillCompletionSourceOrReject: completionSource value: value];
                  } onScheduler: scheduler];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          [AsyncTaskState _fulfillCompletionSourceOrReject: completionSource value: handler(exception)];
                      } @catch (OFException *caughtException) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return [completionSource _internalTaskState];
}

- (AsyncTaskState<id> *)flatRecoverTask: (Task * (^)(OFException *exception))handler
{
    return [self flatRecoverTaskOnScheduler: [AsyncTaskState _continuationSchedulerOrThrowForTaskState: self] handler: handler];
}

- (AsyncTaskState<id> *)flatRecoverTaskOnScheduler: (AsyncScheduler *)scheduler handler: (Task * (^)(OFException *exception))handler
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: self
              onResolve: ^(AsyncTaskState *, id value) {
                  [AsyncTaskState _scheduleBlock: ^{
                      [AsyncTaskState _fulfillCompletionSourceOrReject: completionSource value: value];
                  } onScheduler: scheduler];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          [AsyncTaskState _pipeTaskState: [AsyncTaskState _taskStateFromTask: handler(exception)] intoCompletionSource: completionSource];
                      } @catch (OFException *caughtException) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return [completionSource _internalTaskState];
}

- (AsyncTaskState *)ensure: (void (^)(void))block
{
    return [self ensureOnScheduler: [AsyncTaskState _continuationSchedulerOrThrowForTaskState: self] block: block];
}

- (AsyncTaskState *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block
{
    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto observer = [[AsyncTaskStateBlockObserver alloc]
        initWithTaskState: self
              onResolve: ^(AsyncTaskState *, id value) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          block();
                          [AsyncTaskState _fulfillCompletionSourceOrReject: completionSource value: value];
                      } @catch (OFException *exception) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(AsyncTaskState *, OFException *exception) {
                  [AsyncTaskState _scheduleBlock: ^{
                      @try {
                          block();
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: exception];
                      } @catch (OFException *caughtException) {
                          [AsyncTaskState _rejectCompletionSourceIfPending: completionSource exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return [completionSource _internalTaskState];
}

- (enum AsyncTaskStatus)status
{
    enum AsyncTaskStatus status;

    [_lock lock];
    @try {
        status = _status;
    } @finally {
        [_lock unlock];
    }

    return status;
}

- (bool)isCompleted
{
    return self.status != AsyncTaskStatus_PENDING;
}

- (id)value
{
    enum AsyncTaskStatus status;
    id nillable value;

    [_lock lock];
    @try {
        status = _status;
        value = _value;
    } @finally {
        [_lock unlock];
    }

    if (status != AsyncTaskStatus_FULFILLED)
        @throw [[AsyncTaskInvalidStateAccessException alloc] initWithTask: self._taskForExceptions operation: @"read value" status: status];

    return $assert_nonnil(value);
}

- (OFException *)failureException
{
    enum AsyncTaskStatus status;
    OFException *nillable exception;

    [_lock lock];
    @try {
        status = _status;
        exception = _failureException;
    } @finally {
        [_lock unlock];
    }

    if (status != AsyncTaskStatus_REJECTED)
        @throw [[AsyncTaskInvalidStateAccessException alloc] initWithTask: self._taskForExceptions operation: @"read failureException" status: status];

    return $assert_nonnil(exception);
}

- (id)await
{
    enum AsyncTaskStatus status;
    id nillable value;
    OFException *nillable exception;
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [[AsyncTaskAwaitOutsideTaskException alloc] initWithTask: self._taskForExceptions];
    if ([currentTask _internalTaskState] == self)
        @throw [[AsyncTaskSelfAwaitException alloc] initWithTask: currentTask];

    [Task checkCancellation];

    [_lock lock];
    @try {
        status = _status;
        value = _value;
        exception = _failureException;
    } @finally {
        [_lock unlock];
    }

    if (status == AsyncTaskStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == AsyncTaskStatus_REJECTED)
        @throw $assert_nonnil(exception);

    auto registration = [[AsyncTaskStateWaitRegistration alloc] initWithTaskState: self scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"await task"];
    [Task checkCancellation];

    [_lock lock];
    @try {
        status = _status;
        value = _value;
        exception = _failureException;
    } @finally {
        [_lock unlock];
    }

    if (status == AsyncTaskStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == AsyncTaskStatus_REJECTED)
        @throw $assert_nonnil(exception);

    @throw [[AsyncTaskInvalidStateAccessException alloc] initWithTask: self._taskForExceptions operation: @"finish await" status: status];
}

- (void)_resolveWithValue: (id nonnil)value
{
    OFArray<id<AsyncTaskStateObserver>> *observers;

    [_lock lock];
    @try {
        if (_status != AsyncTaskStatus_PENDING)
            @throw [[AsyncTaskAlreadyResolvedException alloc] initWithTask: self._taskForExceptions currentStatus: _status attemptedStatus: AsyncTaskStatus_FULFILLED];

        _status = AsyncTaskStatus_FULFILLED;
        _value = value;
        _failureException = nilptr;
        _pendingCancellationCallback = nilptr;
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (id<AsyncTaskStateObserver> observer in observers)
        [observer promise: self didResolveWithValue: value];
}

- (void)_rejectWithException: (OFException *nonnil)exception
{
    OFArray<id<AsyncTaskStateObserver>> *observers;

    [_lock lock];
    @try {
        if (_status != AsyncTaskStatus_PENDING)
            @throw [[AsyncTaskAlreadyResolvedException alloc] initWithTask: self._taskForExceptions currentStatus: _status attemptedStatus: AsyncTaskStatus_REJECTED];

        _status = AsyncTaskStatus_REJECTED;
        _value = nilptr;
        _failureException = exception;
        _pendingCancellationCallback = nilptr;
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (id<AsyncTaskStateObserver> observer in observers)
        [observer promise: self didRejectWithException: exception];
}

- (void)_addObserver: (id<AsyncTaskStateObserver>)observer
{
    enum AsyncTaskStatus status = AsyncTaskStatus_PENDING;
    id nillable value = nilptr;
    OFException *nillable exception = nilptr;

    [_lock lock];
    @try {
        if (_status == AsyncTaskStatus_PENDING)
            [_observers addObject: observer];
        else {
            status = _status;
            value = _value;
            exception = _failureException;
        }
    } @finally {
        [_lock unlock];
    }

    if (status == AsyncTaskStatus_FULFILLED)
        [observer promise: self didResolveWithValue: $assert_nonnil(value)];
    else if (status == AsyncTaskStatus_REJECTED)
        [observer promise: self didRejectWithException: $assert_nonnil(exception)];
}

- (void)_removeObserver: (id<AsyncTaskStateObserver>)observer
{
    void (^nillable pendingCancellationCallback)(void) = nilptr;

    [_lock lock];
    @try {
        [_observers removeObjectIdenticalTo: observer];
        if (_status == AsyncTaskStatus_PENDING and _observers.count == 0 and _pendingCancellationCallback != nilptr and not _didFirePendingCancellationCallback) {
            _didFirePendingCancellationCallback = true;
            pendingCancellationCallback = _pendingCancellationCallback;
        }
    } @finally {
        [_lock unlock];
    }

    if (pendingCancellationCallback != nilptr)
        pendingCancellationCallback();
}

- (void)_addWaitRegistration: (AsyncTaskStateWaitRegistration *)registration
{
    [self _addObserver: registration];
}

- (void)_removeWaitRegistration: (AsyncTaskStateWaitRegistration *)registration
{
    [self _removeObserver: registration];
}

- (void)_setPendingCancellationCallback: (void (^nillable)(void))cancellationCallback
{
    [_lock lock];
    @try {
        if (_status == AsyncTaskStatus_PENDING) {
            _pendingCancellationCallback = [cancellationCallback copy];
            _didFirePendingCancellationCallback = false;
        }
    } @finally {
        [_lock unlock];
    }
}

- (Task *nillable)_producingTask
{
    return _producingTask;
}

- (void)_setProducingTask: (Task *nillable)task
{
    _producingTask = task;
}

- (Task *nillable)_associatedTask
{
    return _associatedTask;
}

- (void)_setAssociatedTask: (Task *nillable)task
{
    _associatedTask = task;
}

- (Task *nillable)_taskForExceptions
{
    if (_associatedTask != nilptr)
        return _associatedTask;

    return _producingTask;
}

- (OFString *)description
{
    return self.describe;
}

- (OFString *)describe
{
    return [OFString stringWithFormat: @"%p (%@)", self, [AsyncTaskState describeStatus: self.status]];
}

@end

[[direct_members]]
@implementation AsyncCompletionSource {
    AsyncTaskState<id> *_promise;
    Task<id> *nillable _task;
}

- (instancetype)init
{
    self = [super init];
    _promise = [[AsyncTaskState alloc] _initInternal];
    _task = [[Task alloc] initWithTaskState: _promise];
    return self;
}

- (void)fulfill: (id)value
{
    [_promise _resolveWithValue: value];
}

- (AsyncTaskState *)_internalTaskState
{
    return _promise;
}

- (Task<id> *)task
{
    return $assert_nonnil(_task);
}

- (void)reject: (OFException *)exception
{
    [_promise _rejectWithException: exception];
}

- (void)setPendingTaskCancellationHandler: (void (^nillable)(void))cancellationHandler
{
    [_promise _setPendingCancellationCallback: cancellationHandler];
}

@end

[[direct_members]]
@implementation AsyncTaskStateWaitRegistration {
    AsyncTaskState *_promise;
    OFMutex *_lock;
    bool _completed;
}

- (instancetype)initWithTaskState: (AsyncTaskState *)promise scheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _promise = promise;
    _lock = [OFMutex mutex];
    _completed = false;
    return self;
}

- (AsyncTaskState *)promise
{
    return _promise;
}

- (bool)_finishOnce
{
    [_lock lock];
    bool shouldFinish = false;
    @try {
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (void)arm
{
    [self.promise _addWaitRegistration: self];
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    [self.promise _removeWaitRegistration: self];
    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signal
{
    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)promise: (AsyncTaskState *)promise didResolveWithValue: (id)value
{
    (void)promise;
    (void)value;
    [self signal];
}

- (void)promise: (AsyncTaskState *)promise didRejectWithException: (OFException *)exception
{
    (void)promise;
    (void)exception;
    [self signal];
}

@end

[[direct_members]]
@implementation AsyncTaskStateBlockObserver {
    OFMutex *_lock;
    AsyncTaskState *nillable _promise;
    void (^nillable _resolveBlock)(AsyncTaskState *promise, id value);
    void (^nillable _rejectBlock)(AsyncTaskState *promise, OFException *exception);
    bool _completed;
}

- (instancetype)initWithTaskState: (AsyncTaskState *)promise
                      onResolve: (void (^)(AsyncTaskState *promise, id value))onResolve
                       onReject: (void (^)(AsyncTaskState *promise, OFException *exception))onReject
{
    self = [super init];
    _lock = [OFMutex mutex];
    _promise = promise;
    _resolveBlock = [onResolve copy];
    _rejectBlock = [onReject copy];
    _completed = false;
    return self;
}

- (void)attach
{
    [self->_promise _addObserver: self];
}

- (void)invalidate
{
    AsyncTaskState *nillable promise = nilptr;

    [_lock lock];
    @try {
        if (_completed)
            return;

        _completed = true;
        promise = _promise;
        _promise = nilptr;
        _resolveBlock = nilptr;
        _rejectBlock = nilptr;
    } @finally {
        [_lock unlock];
    }

    if (promise != nilptr)
        [promise _removeObserver: self];
}

- (void)promise: (AsyncTaskState *)promise didResolveWithValue: (id)value
{
    void (^resolveBlock)(AsyncTaskState *promise, id value) = nilptr;
    AsyncTaskState *nillable observedPromise = nilptr;

    [_lock lock];
    @try {
        if (_completed)
            return;

        _completed = true;
        observedPromise = _promise;
        resolveBlock = _resolveBlock;
        _promise = nilptr;
        _resolveBlock = nilptr;
        _rejectBlock = nilptr;
    } @finally {
        [_lock unlock];
    }

    if (resolveBlock != nilptr)
        resolveBlock((observedPromise != nilptr ? $assert_nonnil(observedPromise) : promise), value);
}

- (void)promise: (AsyncTaskState *)promise didRejectWithException: (OFException *)exception
{
    void (^rejectBlock)(AsyncTaskState *promise, OFException *exception) = nilptr;
    AsyncTaskState *nillable observedPromise = nilptr;

    [_lock lock];
    @try {
        if (_completed)
            return;

        _completed = true;
        observedPromise = _promise;
        rejectBlock = _rejectBlock;
        _promise = nilptr;
        _resolveBlock = nilptr;
        _rejectBlock = nilptr;
    } @finally {
        [_lock unlock];
    }

    if (rejectBlock != nilptr)
        rejectBlock((observedPromise != nilptr ? $assert_nonnil(observedPromise) : promise), exception);
}

@end

[[direct_members]]
@implementation AsyncTaskStatePendingValueMarker

+ (instancetype)sharedMarker
{
    static AsyncTaskStatePendingValueMarker *sharedMarker = nilptr;

    if (sharedMarker == nilptr)
        sharedMarker = [[self alloc] init];

    return sharedMarker;
}

@end

[[direct_members]]
@implementation AsyncTaskCollectionAllState {
    OFMutex *_lock;
    AsyncCompletionSource<OFArray<id> *> *_completionSource;
    OFArray<AsyncTaskState *> *_promises;
    OFMutableArray<id> *_values;
    OFMutableArray<AsyncTaskStateBlockObserver *> *_observers;
    size_t _remainingCount;
    bool _finished;
}

- (instancetype)initWithTasks: (OFArray<Task *> *)tasks
                       completionSource: (AsyncCompletionSource<OFArray<id> *> *)completionSource
{
    self = [super init];

    auto normalizedPromises = [OFMutableArray<AsyncTaskState *> arrayWithCapacity: tasks.count];
    for (Task *task in tasks)
        [normalizedPromises addObject: [AsyncTaskState _taskStateFromTask: task]];

    _lock = [OFMutex mutex];
    _completionSource = completionSource;
    _promises = [normalizedPromises copy];
    _values = [OFMutableArray arrayWithCapacity: tasks.count];
    for (size_t index = 0; index < tasks.count; index++)
        [_values addObject: AsyncTaskStatePendingValueMarker.sharedMarker];
    _observers = [OFMutableArray arrayWithCapacity: tasks.count];
    _remainingCount = tasks.count;
    _finished = false;
    return self;
}

- (bool)_isFinished
{
    [_lock lock];
    bool finished = false;
    @try {
        finished = _finished;
    } @finally {
        [_lock unlock];
    }

    return finished;
}

- (void)_cleanupObservers
{
    OFArray<AsyncTaskStateBlockObserver *> *observers;

    [_lock lock];
    @try {
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (AsyncTaskStateBlockObserver *observer in observers)
        [observer invalidate];
}

- (void)_recordValue: (id)value atIndex: (size_t)index
{
    bool shouldResolve = false;
    OFArray<id> *nillable orderedValues = nilptr;

    [_lock lock];
    @try {
        if (_finished)
            return;

        [_values replaceObjectAtIndex: index withObject: value];
        _remainingCount--;
        if (_remainingCount == 0) {
            _finished = true;
            orderedValues = [_values copy];
            shouldResolve = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldResolve)
        return;

    [self _cleanupObservers];
    [AsyncTaskState _fulfillCompletionSourceOrReject: (AsyncCompletionSource<id> *)_completionSource value: $assert_nonnil(orderedValues)];
}

- (void)_rejectWithException: (OFException *)exception
{
    bool shouldReject = false;

    [_lock lock];
    @try {
        if (not _finished) {
            _finished = true;
            shouldReject = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldReject)
        return;

    [self _cleanupObservers];
    [AsyncTaskState _cancelUnresolvedProducingTasksInTaskStates: _promises];
    [AsyncTaskState _rejectCompletionSourceIfPending: (AsyncCompletionSource<id> *)_completionSource exception: exception];
}

- (void)start
{
    for (size_t index = 0; index < _promises.count; index++) {
        if ([self _isFinished])
            break;

        AsyncTaskState *promise = _promises[index];
        auto observer = [[AsyncTaskStateBlockObserver alloc]
            initWithTaskState: promise
                  onResolve: ^(AsyncTaskState *, id value) {
                      [self _recordValue: value atIndex: index];
                  }
                   onReject: ^(AsyncTaskState *, OFException *exception) {
                      [self _rejectWithException: exception];
                  }];

        [_observers addObject: observer];
        [observer attach];
    }
}

@end

[[direct_members]]
@implementation AsyncTaskCollectionRaceState {
    OFMutex *_lock;
    AsyncCompletionSource<id> *_completionSource;
    OFArray<AsyncTaskState *> *_promises;
    OFMutableArray<AsyncTaskStateBlockObserver *> *_observers;
    bool _finished;
}

- (instancetype)initWithTasks: (OFArray<Task *> *)tasks
                        completionSource: (AsyncCompletionSource<id> *)completionSource
{
    self = [super init];

    auto normalizedPromises = [OFMutableArray<AsyncTaskState *> arrayWithCapacity: tasks.count];
    for (Task *task in tasks)
        [normalizedPromises addObject: [AsyncTaskState _taskStateFromTask: task]];

    _lock = [OFMutex mutex];
    _completionSource = completionSource;
    _promises = [normalizedPromises copy];
    _observers = [OFMutableArray arrayWithCapacity: tasks.count];
    _finished = false;
    return self;
}

- (bool)_isFinished
{
    [_lock lock];
    bool finished = false;
    @try {
        finished = _finished;
    } @finally {
        [_lock unlock];
    }

    return finished;
}

- (bool)_finishOnce
{
    bool shouldFinish = false;

    [_lock lock];
    @try {
        if (not _finished) {
            _finished = true;
            shouldFinish = true;
        }
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (void)_cleanupObservers
{
    OFArray<AsyncTaskStateBlockObserver *> *observers;

    [_lock lock];
    @try {
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (AsyncTaskStateBlockObserver *observer in observers)
        [observer invalidate];
}

- (void)_resolveWithValue: (id)value
{
    if (not [self _finishOnce])
        return;

    [self _cleanupObservers];
    [AsyncTaskState _cancelUnresolvedProducingTasksInTaskStates: _promises];
    [AsyncTaskState _fulfillCompletionSourceOrReject: _completionSource value: value];
}

- (void)_rejectWithException: (OFException *)exception
{
    if (not [self _finishOnce])
        return;

    [self _cleanupObservers];
    [AsyncTaskState _cancelUnresolvedProducingTasksInTaskStates: _promises];
    [AsyncTaskState _rejectCompletionSourceIfPending: _completionSource exception: exception];
}

- (void)start
{
    for (AsyncTaskState *promise in _promises) {
        if ([self _isFinished])
            break;

        auto observer = [[AsyncTaskStateBlockObserver alloc]
            initWithTaskState: promise
                  onResolve: ^(AsyncTaskState *, id value) {
                      [self _resolveWithValue: value];
                  }
                   onReject: ^(AsyncTaskState *, OFException *exception) {
                      [self _rejectWithException: exception];
                  }];

        [_observers addObject: observer];
        [observer attach];
    }
}

@end

#pragma clang assume_nonnull end
