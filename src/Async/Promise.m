#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@protocol AsyncPromiseObserver

- (void)promise: (Promise *)promise didResolveWithValue: (id)value;
- (void)promise: (Promise *)promise didRejectWithException: (OFException *)exception;

@end

@interface Promise ()

- (instancetype)_initInternal;
+ (void)_scheduleBlock: (void (^)(void))block
          onScheduler: (AsyncScheduler *)scheduler [[direct]];
+ (void)_rejectResolverIfPending: (PromiseResolver<id> *)resolver
                       exception: (OFException *)exception [[direct]];
+ (void)_resolveResolverOrReject: (PromiseResolver<id> *)resolver
                            value: (id)value [[direct]];
+ (Promise *)_promiseFromPromiseLike: (id<PromiseLike>)promiseLike [[direct]];
+ (AsyncScheduler *)_continuationSchedulerOrThrowForPromise: (Promise *)promise [[direct]];
+ (OFNumber *)_indexKeyForPromiseAtIndex: (size_t)index [[direct]];
+ (void)_cancelUnresolvedTasksInPromises: (OFArray<Promise *> *)promises [[direct]];
+ (void)_pipePromise: (Promise *)promise
          intoResolver: (PromiseResolver<id> *)resolver [[direct]];

@end

[[subclassing_restricted]]
@interface AsyncPromiseWaitRegistration : AsyncTaskWaitRegistration<AsyncPromiseObserver>

@property(readonly, nonatomic) Promise *promise;

- (instancetype)initWithPromise: (Promise *)promise scheduler: (AsyncScheduler *)scheduler task: (Task *)task [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (bool)_finishOnce [[direct]];
- (void)signal [[direct]];

@end

[[subclassing_restricted]]
@interface AsyncPromiseBlockObserver : OFObject<AsyncPromiseObserver>

- (instancetype)initWithPromise: (Promise *)promise
                      onResolve: (void (^)(Promise *promise, id value))onResolve
                       onReject: (void (^)(Promise *promise, OFException *exception))onReject [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attach [[direct]];
- (void)invalidate [[direct]];

@end

[[subclassing_restricted, direct_members]]
@interface AsyncPromiseAllState : OFObject

- (instancetype)initWithPromises: (OFArray<id<PromiseLike>> *)promises
                        resolver: (PromiseResolver<OFArray<id> *> *)resolver [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (bool)_isFinished;
- (void)_cleanupObservers;
- (void)_recordValue: (id)value atIndex: (size_t)index;
- (void)_rejectWithException: (OFException *)exception;
- (void)start;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncPromiseRaceState : OFObject

- (instancetype)initWithPromises: (OFArray<id<PromiseLike>> *)promises
                         resolver: (PromiseResolver<id> *)resolver [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (bool)_isFinished;
- (bool)_finishOnce;
- (void)_cleanupObservers;
- (void)_resolveWithValue: (id)value;
- (void)_rejectWithException: (OFException *)exception;
- (void)start;

@end

@implementation PromiseException


- (instancetype)initWithPromise: (Promise *)promise
{
    self = [super init];
    _promise = promise;
    return self;
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseException: %@", promiseDescription];
}

@end

@implementation PromiseAlreadyResolvedException


- (instancetype)initWithPromise: (Promise *)promise currentStatus: (enum PromiseStatus)currentStatus attemptedStatus: (enum PromiseStatus)attemptedStatus
{
    self = [super initWithPromise: promise];
    _currentStatus = currentStatus;
    _attemptedStatus = attemptedStatus;
    return self;
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseAlreadyResolvedException: %@ is already %@ and cannot transition to %@", promiseDescription, [Promise describeStatus: self.currentStatus], [Promise describeStatus: self.attemptedStatus]];
}

@end

@implementation PromiseNilResolutionValueException

- (instancetype)initWithPromise: (Promise *)promise
{
    return [super initWithPromise: promise];
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseNilResolutionValueException: %@ cannot be fulfilled with nilptr", promiseDescription];
}

@end

@implementation PromiseNilRejectionException

- (instancetype)initWithPromise: (Promise *)promise
{
    return [super initWithPromise: promise];
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseNilRejectionException: %@ cannot be rejected with nilptr", promiseDescription];
}

@end

@implementation PromiseInvalidStateAccessException


- (instancetype)initWithPromise: (Promise *)promise operation: (OFString *)operation status: (enum PromiseStatus)status
{
    self = [super initWithPromise: promise];
    _operation = [operation copy];
    _status = status;
    return self;
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseInvalidStateAccessException: %@ cannot %@ while %@", promiseDescription, self.operation, [Promise describeStatus: self.status]];
}

@end

@implementation PromiseAwaitOutsideTaskException

- (instancetype)initWithPromise: (Promise *)promise
{
    return [super initWithPromise: promise];
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseAwaitOutsideTaskException: %@ cannot be awaited outside a Task", promiseDescription];
}

@end

@implementation PromiseSelfAwaitException

- (instancetype)initWithPromise: (Promise *)promise
{
    return [super initWithPromise: promise];
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseSelfAwaitException: %@ cannot await itself", promiseDescription];
}

@end

@implementation PromiseContinuationOutsideTaskException

- (instancetype)initWithPromise: (Promise *)promise
{
    return [super initWithPromise: promise];
}

- (OFString *)description
{
    OFString *promiseDescription = (self.promise == nilptr ? @"<nil>" : self.promise.describe);
    return [OFString stringWithFormat: @"PromiseContinuationOutsideTaskException: %@ requires an explicit scheduler outside a Task", promiseDescription];
}

@end

@implementation Promise {
    OFMutex *_lock;
    enum PromiseStatus _status;
    id nillable _value;
    OFException *nillable _rejectionException;
    OFMutableArray<id<AsyncPromiseObserver>> *_observers;
    void (^nillable _pendingCancellationCallback)(void);
    bool _didFirePendingCancellationCallback;
}

+ (void)_scheduleBlock: (void (^)(void))block
          onScheduler: (AsyncScheduler *)scheduler
{
    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: 0 repeats: false block: ^(OFTimer *) {
        block();
    }];

    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
}

+ (void)_rejectResolverIfPending: (PromiseResolver<id> *)resolver
                       exception: (OFException *)exception
{
    @try {
        [resolver reject: exception];
    } @catch (PromiseAlreadyResolvedException *) {
    }
}

+ (void)_resolveResolverOrReject: (PromiseResolver<id> *)resolver
                            value: (id)value
{
    @try {
        [resolver resolve: value];
    } @catch (OFException *exception) {
        [self _rejectResolverIfPending: resolver exception: exception];
    }
}

+ (Promise *)_promiseFromPromiseLike: (id<PromiseLike>)promiseLike
{
    if (not [(id)promiseLike isKindOfClass: Promise.class])
        @throw [OFInvalidArgumentException exception];

    return (Promise *)promiseLike;
}

+ (AsyncScheduler *)_continuationSchedulerOrThrowForPromise: (Promise *)promise
{
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [[PromiseContinuationOutsideTaskException alloc] initWithPromise: promise];

    return currentTask.scheduler;
}

+ (OFNumber *)_indexKeyForPromiseAtIndex: (size_t)index
{
    return [OFNumber numberWithUnsignedLongLong: (unsigned long long)index];
}

+ (void)_cancelUnresolvedTasksInPromises: (OFArray<Promise *> *)promises
{
    for (Promise *promise in promises) {
        if ([promise isKindOfClass: Task.class] and not promise.isResolved)
            [(Task *)promise cancel];
    }
}

+ (void)_pipePromise: (Promise *)promise
          intoResolver: (PromiseResolver<id> *)resolver
{
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: promise
              onResolve: ^(Promise *, id value) {
                  [self _resolveResolverOrReject: resolver value: value];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [self _rejectResolverIfPending: resolver exception: exception];
              }];

    [observer attach];
}

+ (OFString *)describeStatus: (enum PromiseStatus)status
{
    switch (status) {
        case PromiseStatus_PENDING: return @"PENDING";
        case PromiseStatus_FULFILLED: return @"FULFILLED";
        case PromiseStatus_REJECTED: return @"REJECTED";
    }
}

- (instancetype)_initInternal
{
    self = [super init];
    _lock = [OFMutex mutex];
    _status = PromiseStatus_PENDING;
    _observers = [OFMutableArray array];
    _didFirePendingCancellationCallback = false;
    return self;
}

+ (Promise *)resolved: (id)value
{
    auto resolver = [[PromiseResolver alloc] init];
    [resolver resolve: value];
    return resolver.promise;
}

+ (Promise *)rejected: (OFException *)exception
{
    auto resolver = [[PromiseResolver alloc] init];
    [resolver reject: exception];
    return resolver.promise;
}

+ (Promise<OFArray<id> *> *)all: (OFArray<id<PromiseLike>> *)promises
{
    auto resolver = [[PromiseResolver<OFArray<id> *> alloc] init];

    if (promises.count == 0) {
        [resolver resolve: [OFArray array]];
        return resolver.promise;
    }

    [[[AsyncPromiseAllState alloc] initWithPromises: promises resolver: resolver] start];
    return resolver.promise;
}

+ (Promise *)race: (OFArray<id<PromiseLike>> *)promises
{
    if (promises.count == 0)
        @throw [OFInvalidArgumentException exception];

    auto resolver = [[PromiseResolver alloc] init];
    [[[AsyncPromiseRaceState alloc] initWithPromises: promises resolver: resolver] start];
    return resolver.promise;
}

- (Promise<id> *)map: (id (^)(id value))transform
{
    return [self mapOnScheduler: [Promise _continuationSchedulerOrThrowForPromise: self] transform: transform];
}

- (Promise<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(id value))transform
{
    auto resolver = [[PromiseResolver alloc] init];
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: self
              onResolve: ^(Promise *, id value) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          [Promise _resolveResolverOrReject: resolver value: transform(value)];
                      } @catch (OFException *exception) {
                          [Promise _rejectResolverIfPending: resolver exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [Promise _scheduleBlock: ^{
                      [Promise _rejectResolverIfPending: resolver exception: exception];
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return resolver.promise;
}

- (Promise<id> *)flatMap: (id<PromiseLike> (^)(id value))transform
{
    return [self flatMapOnScheduler: [Promise _continuationSchedulerOrThrowForPromise: self] transform: transform];
}

- (Promise<id> *)flatMapOnScheduler: (AsyncScheduler *)scheduler transform: (id<PromiseLike> (^)(id value))transform
{
    auto resolver = [[PromiseResolver alloc] init];
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: self
              onResolve: ^(Promise *, id value) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          [Promise _pipePromise: [Promise _promiseFromPromiseLike: transform(value)] intoResolver: resolver];
                      } @catch (OFException *exception) {
                          [Promise _rejectResolverIfPending: resolver exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [Promise _scheduleBlock: ^{
                      [Promise _rejectResolverIfPending: resolver exception: exception];
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return resolver.promise;
}

- (Promise<id> *)recover: (id (^)(OFException *exception))handler
{
    return [self recoverOnScheduler: [Promise _continuationSchedulerOrThrowForPromise: self] handler: handler];
}

- (Promise<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler
{
    auto resolver = [[PromiseResolver alloc] init];
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: self
              onResolve: ^(Promise *, id value) {
                  [Promise _scheduleBlock: ^{
                      [Promise _resolveResolverOrReject: resolver value: value];
                  } onScheduler: scheduler];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          [Promise _resolveResolverOrReject: resolver value: handler(exception)];
                      } @catch (OFException *caughtException) {
                          [Promise _rejectResolverIfPending: resolver exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return resolver.promise;
}

- (Promise<id> *)flatRecover: (id<PromiseLike> (^)(OFException *exception))handler
{
    return [self flatRecoverOnScheduler: [Promise _continuationSchedulerOrThrowForPromise: self] handler: handler];
}

- (Promise<id> *)flatRecoverOnScheduler: (AsyncScheduler *)scheduler handler: (id<PromiseLike> (^)(OFException *exception))handler
{
    auto resolver = [[PromiseResolver alloc] init];
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: self
              onResolve: ^(Promise *, id value) {
                  [Promise _scheduleBlock: ^{
                      [Promise _resolveResolverOrReject: resolver value: value];
                  } onScheduler: scheduler];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          [Promise _pipePromise: [Promise _promiseFromPromiseLike: handler(exception)] intoResolver: resolver];
                      } @catch (OFException *caughtException) {
                          [Promise _rejectResolverIfPending: resolver exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return resolver.promise;
}

- (Promise *)ensure: (void (^)(void))block
{
    return [self ensureOnScheduler: [Promise _continuationSchedulerOrThrowForPromise: self] block: block];
}

- (Promise *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block
{
    auto resolver = [[PromiseResolver alloc] init];
    auto observer = [[AsyncPromiseBlockObserver alloc]
        initWithPromise: self
              onResolve: ^(Promise *, id value) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          block();
                          [Promise _resolveResolverOrReject: resolver value: value];
                      } @catch (OFException *exception) {
                          [Promise _rejectResolverIfPending: resolver exception: exception];
                      }
                  } onScheduler: scheduler];
              }
               onReject: ^(Promise *, OFException *exception) {
                  [Promise _scheduleBlock: ^{
                      @try {
                          block();
                          [Promise _rejectResolverIfPending: resolver exception: exception];
                      } @catch (OFException *caughtException) {
                          [Promise _rejectResolverIfPending: resolver exception: caughtException];
                      }
                  } onScheduler: scheduler];
              }];

    [observer attach];
    return resolver.promise;
}

- (enum PromiseStatus)status
{
    block_reference enum PromiseStatus status;

    [_lock lock];
    @try {
        status = _status;
    } @finally {
        [_lock unlock];
    }

    return status;
}

- (bool)isResolved
{
    return self.status != PromiseStatus_PENDING;
}

- (id)value
{
    block_reference enum PromiseStatus status;
    block_reference id value;

    [_lock lock];
    @try {
        status = _status;
        value = _value;
    } @finally {
        [_lock unlock];
    }

    if (status != PromiseStatus_FULFILLED)
        @throw [[PromiseInvalidStateAccessException alloc] initWithPromise: self operation: @"read value" status: status];

    return $assert_nonnil(value);
}

- (OFException *)rejectionException
{
    block_reference enum PromiseStatus status;
    block_reference OFException *exception;

    [_lock lock];
    @try {
        status = _status;
        exception = _rejectionException;
    } @finally {
        [_lock unlock];
    }

    if (status != PromiseStatus_REJECTED)
        @throw [[PromiseInvalidStateAccessException alloc] initWithPromise: self operation: @"read rejectionException" status: status];

    return $assert_nonnil(exception);
}

- (id)await
{
    block_reference enum PromiseStatus status;
    block_reference id value;
    block_reference OFException *exception;
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [[PromiseAwaitOutsideTaskException alloc] initWithPromise: self];
    if ((Promise *)currentTask == self)
        @throw [[PromiseSelfAwaitException alloc] initWithPromise: self];

    [Task checkCancellation];

    [_lock lock];
    @try {
        status = _status;
        value = _value;
        exception = _rejectionException;
    } @finally {
        [_lock unlock];
    }

    if (status == PromiseStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == PromiseStatus_REJECTED)
        @throw $assert_nonnil(exception);

    auto registration = [[AsyncPromiseWaitRegistration alloc] initWithPromise: self scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"await promise"];
    [Task checkCancellation];

    [_lock lock];
    @try {
        status = _status;
        value = _value;
        exception = _rejectionException;
    } @finally {
        [_lock unlock];
    }

    if (status == PromiseStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == PromiseStatus_REJECTED)
        @throw $assert_nonnil(exception);

    @throw [[PromiseInvalidStateAccessException alloc] initWithPromise: self operation: @"finish await" status: status];
}

- (void)_resolveWithValue: (id nillable)value
{
    block_reference OFArray<id<AsyncPromiseObserver>> *observers;

    if (value == nilptr)
        @throw [[PromiseNilResolutionValueException alloc] initWithPromise: self];

    [_lock lock];
    @try {
        if (_status != PromiseStatus_PENDING)
            @throw [[PromiseAlreadyResolvedException alloc] initWithPromise: self currentStatus: _status attemptedStatus: PromiseStatus_FULFILLED];

        _status = PromiseStatus_FULFILLED;
        _value = value;
        _rejectionException = nilptr;
        _pendingCancellationCallback = nilptr;
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (id<AsyncPromiseObserver> observer in observers)
        [observer promise: self didResolveWithValue: $assert_nonnil(value)];
}

- (void)_rejectWithException: (OFException *nillable)exception
{
    block_reference OFArray<id<AsyncPromiseObserver>> *observers;

    if (exception == nilptr)
        @throw [[PromiseNilRejectionException alloc] initWithPromise: self];

    [_lock lock];
    @try {
        if (_status != PromiseStatus_PENDING)
            @throw [[PromiseAlreadyResolvedException alloc] initWithPromise: self currentStatus: _status attemptedStatus: PromiseStatus_REJECTED];

        _status = PromiseStatus_REJECTED;
        _value = nilptr;
        _rejectionException = exception;
        _pendingCancellationCallback = nilptr;
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (id<AsyncPromiseObserver> observer in observers)
        [observer promise: self didRejectWithException: $assert_nonnil(exception)];
}

- (void)_addObserver: (id<AsyncPromiseObserver>)observer
{
    block_reference enum PromiseStatus status = PromiseStatus_PENDING;
    block_reference id value = nilptr;
    block_reference OFException *exception = nilptr;

    [_lock lock];
    @try {
        if (_status == PromiseStatus_PENDING)
            [_observers addObject: observer];
        else {
            status = _status;
            value = _value;
            exception = _rejectionException;
        }
    } @finally {
        [_lock unlock];
    }

    if (status == PromiseStatus_FULFILLED)
        [observer promise: self didResolveWithValue: $assert_nonnil(value)];
    else if (status == PromiseStatus_REJECTED)
        [observer promise: self didRejectWithException: $assert_nonnil(exception)];
}

- (void)_removeObserver: (id<AsyncPromiseObserver>)observer
{
    block_reference void (^nillable pendingCancellationCallback)(void) = nilptr;

    [_lock lock];
    @try {
        [_observers removeObjectIdenticalTo: observer];
        if (_status == PromiseStatus_PENDING and _observers.count == 0 and _pendingCancellationCallback != nilptr and not _didFirePendingCancellationCallback) {
            _didFirePendingCancellationCallback = true;
            pendingCancellationCallback = _pendingCancellationCallback;
        }
    } @finally {
        [_lock unlock];
    }

    if (pendingCancellationCallback != nilptr)
        pendingCancellationCallback();
}

- (void)_addWaitRegistration: (AsyncPromiseWaitRegistration *)registration
{
    [self _addObserver: registration];
}

- (void)_removeWaitRegistration: (AsyncPromiseWaitRegistration *)registration
{
    [self _removeObserver: registration];
}

- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback
{
    [_lock lock];
    @try {
        if (_status == PromiseStatus_PENDING) {
            _pendingCancellationCallback = [cancellationCallback copy];
            _didFirePendingCancellationCallback = false;
        }
    } @finally {
        [_lock unlock];
    }
}

- (OFString *)description
{
    return self.describe;
}

- (OFString *)describe
{
    return [OFString stringWithFormat: @"%p (%@)", self, [Promise describeStatus: self.status]];
}

@end

@implementation PromiseResolver


- (instancetype)init
{
    self = [super init];
    _promise = [[Promise alloc] _initInternal];
    return self;
}

- (void)resolve: (id)value
{
    [_promise _resolveWithValue: value];
}

- (void)reject: (OFException *)exception
{
    [_promise _rejectWithException: exception];
}

@end

@implementation AsyncPromiseWaitRegistration {
    Promise *_promise;
    OFMutex *_lock;
    bool _completed;
}


- (instancetype)initWithPromise: (Promise *)promise scheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _promise = promise;
    _lock = [OFMutex mutex];
    _completed = false;
    return self;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish;

    [_lock lock];
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

- (void)promise: (Promise *)promise didResolveWithValue: (id)value
{
    (void)promise;
    (void)value;
    [self signal];
}

- (void)promise: (Promise *)promise didRejectWithException: (OFException *)exception
{
    (void)promise;
    (void)exception;
    [self signal];
}

@end

@implementation AsyncPromiseBlockObserver {
    OFMutex *_lock;
    Promise *nillable _promise;
    void (^nillable _resolveBlock)(Promise *promise, id value);
    void (^nillable _rejectBlock)(Promise *promise, OFException *exception);
    bool _completed;
}

- (instancetype)initWithPromise: (Promise *)promise
                      onResolve: (void (^)(Promise *promise, id value))onResolve
                       onReject: (void (^)(Promise *promise, OFException *exception))onReject
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
    block_reference Promise *promise = nilptr;

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

- (void)promise: (Promise *)promise didResolveWithValue: (id)value
{
    block_reference void (^resolveBlock)(Promise *promise, id value) = nilptr;
    block_reference Promise *observedPromise = nilptr;

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
        resolveBlock((observedPromise != nilptr ? observedPromise : promise), value);
}

- (void)promise: (Promise *)promise didRejectWithException: (OFException *)exception
{
    block_reference void (^rejectBlock)(Promise *promise, OFException *exception) = nilptr;
    block_reference Promise *observedPromise = nilptr;

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
        rejectBlock((observedPromise != nilptr ? observedPromise : promise), exception);
}

@end

@implementation AsyncPromiseAllState {
    OFMutex *_lock;
    PromiseResolver<OFArray<id> *> *_resolver;
    OFArray<Promise *> *_promises;
    OFMutableDictionary<OFNumber *, id> *_valuesByIndex;
    OFMutableArray<AsyncPromiseBlockObserver *> *_observers;
    size_t _remainingCount;
    bool _finished;
}

- (instancetype)initWithPromises: (OFArray<id<PromiseLike>> *)promises resolver: (PromiseResolver<OFArray<id> *> *)resolver
{
    self = [super init];

    auto normalizedPromises = [OFMutableArray<Promise *> arrayWithCapacity: promises.count];
    for (id<PromiseLike> promiseLike in promises)
        [normalizedPromises addObject: [Promise _promiseFromPromiseLike: promiseLike]];

    _lock = [OFMutex mutex];
    _resolver = resolver;
    _promises = [normalizedPromises copy];
    _valuesByIndex = [OFMutableDictionary dictionary];
    _observers = [OFMutableArray arrayWithCapacity: promises.count];
    _remainingCount = promises.count;
    _finished = false;
    return self;
}

- (bool)_isFinished
{
    block_reference bool finished;

    [_lock lock];
    @try {
        finished = _finished;
    } @finally {
        [_lock unlock];
    }

    return finished;
}

- (void)_cleanupObservers
{
    block_reference OFArray<AsyncPromiseBlockObserver *> *observers = nilptr;

    [_lock lock];
    @try {
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (AsyncPromiseBlockObserver *observer in observers)
        [observer invalidate];
}

- (void)_recordValue: (id)value atIndex: (size_t)index
{
    block_reference bool shouldResolve = false;
    block_reference OFArray<id> *orderedValues = nilptr;

    [_lock lock];
    @try {
        if (_finished)
            return;

        _valuesByIndex[[Promise _indexKeyForPromiseAtIndex: index]] = value;
        _remainingCount--;
        if (_remainingCount == 0) {
            auto results = [OFMutableArray<id> arrayWithCapacity: _promises.count];

            for (size_t resultIndex = 0; resultIndex < _promises.count; resultIndex++)
                [results addObject: $assert_nonnil(_valuesByIndex[[Promise _indexKeyForPromiseAtIndex: resultIndex]])];

            _finished = true;
            orderedValues = [results copy];
            shouldResolve = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldResolve)
        return;

    [self _cleanupObservers];
    [Promise _resolveResolverOrReject: (PromiseResolver<id> *)_resolver value: orderedValues];
}

- (void)_rejectWithException: (OFException *)exception
{
    block_reference bool shouldReject = false;

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
    [Promise _cancelUnresolvedTasksInPromises: _promises];
    [Promise _rejectResolverIfPending: (PromiseResolver<id> *)_resolver exception: exception];
}

- (void)start
{
    for (size_t index = 0; index < _promises.count; index++) {
        if ([self _isFinished])
            break;

        Promise *promise = _promises[index];
        auto observer = [[AsyncPromiseBlockObserver alloc]
            initWithPromise: promise
                  onResolve: ^(Promise *, id value) {
                      [self _recordValue: value atIndex: index];
                  }
                   onReject: ^(Promise *, OFException *exception) {
                      [self _rejectWithException: exception];
                  }];

        [_observers addObject: observer];
        [observer attach];
    }
}

@end

@implementation AsyncPromiseRaceState {
    OFMutex *_lock;
    PromiseResolver<id> *_resolver;
    OFArray<Promise *> *_promises;
    OFMutableArray<AsyncPromiseBlockObserver *> *_observers;
    bool _finished;
}

- (instancetype)initWithPromises: (OFArray<id<PromiseLike>> *)promises resolver: (PromiseResolver<id> *)resolver
{
    self = [super init];

    auto normalizedPromises = [OFMutableArray<Promise *> arrayWithCapacity: promises.count];
    for (id<PromiseLike> promiseLike in promises)
        [normalizedPromises addObject: [Promise _promiseFromPromiseLike: promiseLike]];

    _lock = [OFMutex mutex];
    _resolver = resolver;
    _promises = [normalizedPromises copy];
    _observers = [OFMutableArray arrayWithCapacity: promises.count];
    _finished = false;
    return self;
}

- (bool)_isFinished
{
    block_reference bool finished;

    [_lock lock];
    @try {
        finished = _finished;
    } @finally {
        [_lock unlock];
    }

    return finished;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish = false;

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
    block_reference OFArray<AsyncPromiseBlockObserver *> *observers = nilptr;

    [_lock lock];
    @try {
        observers = [_observers copy];
        [_observers removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (AsyncPromiseBlockObserver *observer in observers)
        [observer invalidate];
}

- (void)_resolveWithValue: (id)value
{
    if (not [self _finishOnce])
        return;

    [self _cleanupObservers];
    [Promise _cancelUnresolvedTasksInPromises: _promises];
    [Promise _resolveResolverOrReject: _resolver value: value];
}

- (void)_rejectWithException: (OFException *)exception
{
    if (not [self _finishOnce])
        return;

    [self _cleanupObservers];
    [Promise _cancelUnresolvedTasksInPromises: _promises];
    [Promise _rejectResolverIfPending: _resolver exception: exception];
}

- (void)start
{
    for (Promise *promise in _promises) {
        if ([self _isFinished])
            break;

        auto observer = [[AsyncPromiseBlockObserver alloc]
            initWithPromise: promise
                  onResolve: ^(Promise *, id value) {
                      [self _resolveWithValue: value];
                  }
                   onReject: ^(Promise *, OFException *exception) {
                      [self _rejectWithException: exception];
                  }];

        [_observers addObject: observer];
        [observer attach];
    }
}

@end

#pragma clang assume_nonnull end
