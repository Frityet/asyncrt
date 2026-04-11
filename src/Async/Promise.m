#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@interface AsyncPromiseWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) Promise *future;

- (instancetype)initWithPromise: (Promise *)future scheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (void)signal;

@end

@interface Promise ()

- (instancetype)_initInternal;
- (void)_resolveWithValue: (id nillable)value;
- (void)_rejectWithException: (OFException *nillable)exception;
- (void)_addWaitRegistration: (AsyncPromiseWaitRegistration *)registration;
- (void)_removeWaitRegistration: (AsyncPromiseWaitRegistration *)registration;
- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback;

@end

@implementation PromiseException

- (instancetype)initWithPromise: (Promise *)future
{
    self = [super init];
    _future = future;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseException: %@", DescribePromise(self.future)];
}

@end

@implementation PromiseAlreadyResolvedException

- (instancetype)initWithPromise: (Promise *)future currentStatus: (enum PromiseStatus)currentStatus attemptedStatus: (enum PromiseStatus)attemptedStatus
{
    self = [super initWithPromise: future];
    _currentStatus = currentStatus;
    _attemptedStatus = attemptedStatus;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseAlreadyResolvedException: %@ is already %@ and cannot transition to %@", DescribePromise(self.future), PromiseStatusToString(self.currentStatus), PromiseStatusToString(self.attemptedStatus)];
}

@end

@implementation PromiseNilResolutionValueException

- (instancetype)initWithPromise: (Promise *)future
{
    return [super initWithPromise: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseNilResolutionValueException: %@ cannot be fulfilled with nilptr", DescribePromise(self.future)];
}

@end

@implementation PromiseNilRejectionException

- (instancetype)initWithPromise: (Promise *)future
{
    return [super initWithPromise: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseNilRejectionException: %@ cannot be rejected with nilptr", DescribePromise(self.future)];
}

@end

@implementation PromiseInvalidStateAccessException

- (instancetype)initWithPromise: (Promise *)future operation: (OFString *)operation status: (enum PromiseStatus)status
{
    self = [super initWithPromise: future];
    _operation = [operation copy];
    _status = status;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseInvalidStateAccessException: %@ cannot %@ while %@", DescribePromise(self.future), self.operation, PromiseStatusToString(self.status)];
}

@end

@implementation PromiseAwaitOutsideTaskException

- (instancetype)initWithPromise: (Promise *)future
{
    return [super initWithPromise: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseAwaitOutsideTaskException: %@ cannot be awaited outside a Task", DescribePromise(self.future)];
}

@end

@implementation PromiseSelfAwaitException

- (instancetype)initWithPromise: (Promise *)future
{
    return [super initWithPromise: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseSelfAwaitException: %@ cannot await itself", DescribePromise(self.future)];
}

@end

@implementation Promise {
    OFMutex *_lock;
    enum PromiseStatus _status;
    id nillable _value;
    OFException *nillable _rejectionException;
    OFMutableArray<AsyncPromiseWaitRegistration *> *_waitRegistrations;
    void (^nillable _pendingCancellationCallback)(void);
    bool _didFirePendingCancellationCallback;
}

- (instancetype)_initInternal
{
    self = [super init];
    _lock = [OFMutex mutex];
    _status = PromiseStatus_PENDING;
    _waitRegistrations = [OFMutableArray array];
    _didFirePendingCancellationCallback = false;
    return self;
}

+ (Promise *)resolved: (id)value
{
    auto resolver = [[PromiseResolver alloc] init];
    [resolver resolve: value];
    return resolver.future;
}

+ (Promise *)rejected: (OFException *)exception
{
    auto resolver = [[PromiseResolver alloc] init];
    [resolver reject: exception];
    return resolver.future;
}

- (enum PromiseStatus)status
{
    block_reference enum PromiseStatus status;

    [_lock scopedLock: ^{
        status = _status;
    }];

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

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
    }];

    if (status != PromiseStatus_FULFILLED)
        @throw [[PromiseInvalidStateAccessException alloc] initWithPromise: self operation: @"read value" status: status];

    return $assert_nonnil(value);
}

- (OFException *)rejectionException
{
    block_reference enum PromiseStatus status;
    block_reference OFException *exception;

    [_lock scopedLock: ^{
        status = _status;
        exception = _rejectionException;
    }];

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

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
        exception = _rejectionException;
    }];

    if (status == PromiseStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == PromiseStatus_REJECTED)
        @throw $assert_nonnil(exception);

    auto registration = [[AsyncPromiseWaitRegistration alloc] initWithPromise: self scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"await future"];
    [Task checkCancellation];

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
        exception = _rejectionException;
    }];

    if (status == PromiseStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == PromiseStatus_REJECTED)
        @throw $assert_nonnil(exception);

    @throw [[PromiseInvalidStateAccessException alloc] initWithPromise: self operation: @"finish await" status: status];
}

- (void)_resolveWithValue: (id nillable)value
{
    block_reference OFArray<AsyncPromiseWaitRegistration *> *waitRegistrations;

    if (value == nil)
        @throw [[PromiseNilResolutionValueException alloc] initWithPromise: self];

    [_lock scopedLock: ^{
        if (_status != PromiseStatus_PENDING)
            @throw [[PromiseAlreadyResolvedException alloc] initWithPromise: self currentStatus: _status attemptedStatus: PromiseStatus_FULFILLED];

        _status = PromiseStatus_FULFILLED;
        _value = value;
        _rejectionException = nilptr;
        _pendingCancellationCallback = nilptr;
        waitRegistrations = [_waitRegistrations copy];
        [_waitRegistrations removeAllObjects];
    }];

    for (AsyncPromiseWaitRegistration *registration in waitRegistrations)
        [registration signal];
}

- (void)_rejectWithException: (OFException *nillable)exception
{
    block_reference OFArray<AsyncPromiseWaitRegistration *> *waitRegistrations;

    if (exception == nil)
        @throw [[PromiseNilRejectionException alloc] initWithPromise: self];

    [_lock scopedLock: ^{
        if (_status != PromiseStatus_PENDING)
            @throw [[PromiseAlreadyResolvedException alloc] initWithPromise: self currentStatus: _status attemptedStatus: PromiseStatus_REJECTED];

        _status = PromiseStatus_REJECTED;
        _value = nilptr;
        _rejectionException = exception;
        _pendingCancellationCallback = nilptr;
        waitRegistrations = [_waitRegistrations copy];
        [_waitRegistrations removeAllObjects];
    }];

    for (AsyncPromiseWaitRegistration *registration in waitRegistrations)
        [registration signal];
}

- (void)_addWaitRegistration: (AsyncPromiseWaitRegistration *)registration
{
    block_reference bool shouldSignalImmediately = false;

    [_lock scopedLock: ^{
        if (_status == PromiseStatus_PENDING)
            [_waitRegistrations addObject: registration];
        else
            shouldSignalImmediately = true;
    }];

    if (shouldSignalImmediately)
        [registration signal];
}

- (void)_removeWaitRegistration: (AsyncPromiseWaitRegistration *)registration
{
    block_reference void (^nillable pendingCancellationCallback)(void) = nilptr;

    [_lock scopedLock: ^{
        [_waitRegistrations removeObjectIdenticalTo: registration];
        if (_status == PromiseStatus_PENDING and _waitRegistrations.count == 0 and _pendingCancellationCallback != nilptr and not _didFirePendingCancellationCallback) {
            _didFirePendingCancellationCallback = true;
            pendingCancellationCallback = _pendingCancellationCallback;
        }
    }];

    if (pendingCancellationCallback != nilptr)
        pendingCancellationCallback();
}

- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback
{
    [_lock scopedLock: ^{
        if (_status == PromiseStatus_PENDING) {
            _pendingCancellationCallback = [cancellationCallback copy];
            _didFirePendingCancellationCallback = false;
        }
    }];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<Promise %p %@>", self, PromiseStatusToString(self.status)];
}

@end

@implementation PromiseResolver

@synthesize future = _future;

- (instancetype)init
{
    self = [super init];
    _future = [[Promise alloc] _initInternal];
    return self;
}

- (void)resolve: (id)value
{
    [_future _resolveWithValue: value];
}

- (void)reject: (OFException *)exception
{
    [_future _rejectWithException: exception];
}

@end

@implementation AsyncPromiseWaitRegistration {
    Promise *_future;
    OFMutex *_lock;
    bool _completed;
}

@synthesize future = _future;

- (instancetype)initWithPromise: (Promise *)future scheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _future = future;
    _lock = [OFMutex mutex];
    _completed = false;
    return self;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish;

    [_lock scopedLock: ^{
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    }];

    return shouldFinish;
}

- (void)arm
{
    [self.future _addWaitRegistration: self];
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    [self.future _removeWaitRegistration: self];
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

@end

#pragma clang assume_nonnull end
