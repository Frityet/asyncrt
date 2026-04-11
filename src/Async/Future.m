#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@interface AsyncFutureWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) Future *future;

- (instancetype)initWithFuture: (Future *)future scheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (void)signal;

@end

@interface Future ()

- (instancetype)_initInternal;
- (void)_resolveWithValue: (id nillable)value;
- (void)_rejectWithException: (OFException *nillable)exception;
- (void)_addWaitRegistration: (AsyncFutureWaitRegistration *)registration;
- (void)_removeWaitRegistration: (AsyncFutureWaitRegistration *)registration;
- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback;

@end

@implementation FutureException

- (instancetype)initWithFuture: (Future *)future
{
    self = [super init];
    _future = future;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureException: %@", DescribeFuture(self.future)];
}

@end

@implementation FutureAlreadyResolvedException

- (instancetype)initWithFuture: (Future *)future currentStatus: (enum FutureStatus)currentStatus attemptedStatus: (enum FutureStatus)attemptedStatus
{
    self = [super initWithFuture: future];
    _currentStatus = currentStatus;
    _attemptedStatus = attemptedStatus;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureAlreadyResolvedException: %@ is already %@ and cannot transition to %@", DescribeFuture(self.future), FutureStatusToString(self.currentStatus), FutureStatusToString(self.attemptedStatus)];
}

@end

@implementation FutureNilResolutionValueException

- (instancetype)initWithFuture: (Future *)future
{
    return [super initWithFuture: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureNilResolutionValueException: %@ cannot be fulfilled with nilptr", DescribeFuture(self.future)];
}

@end

@implementation FutureNilRejectionException

- (instancetype)initWithFuture: (Future *)future
{
    return [super initWithFuture: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureNilRejectionException: %@ cannot be rejected with nilptr", DescribeFuture(self.future)];
}

@end

@implementation FutureInvalidStateAccessException

- (instancetype)initWithFuture: (Future *)future operation: (OFString *)operation status: (enum FutureStatus)status
{
    self = [super initWithFuture: future];
    _operation = [operation copy];
    _status = status;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureInvalidStateAccessException: %@ cannot %@ while %@", DescribeFuture(self.future), self.operation, FutureStatusToString(self.status)];
}

@end

@implementation FutureAwaitOutsideTaskException

- (instancetype)initWithFuture: (Future *)future
{
    return [super initWithFuture: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureAwaitOutsideTaskException: %@ cannot be awaited outside a Task", DescribeFuture(self.future)];
}

@end

@implementation FutureSelfAwaitException

- (instancetype)initWithFuture: (Future *)future
{
    return [super initWithFuture: future];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureSelfAwaitException: %@ cannot await itself", DescribeFuture(self.future)];
}

@end

@implementation Future {
    OFMutex *_lock;
    enum FutureStatus _status;
    id nillable _value;
    OFException *nillable _rejectionException;
    OFMutableArray<AsyncFutureWaitRegistration *> *_waitRegistrations;
    void (^nillable _pendingCancellationCallback)(void);
    bool _didFirePendingCancellationCallback;
}

- (instancetype)_initInternal
{
    self = [super init];
    _lock = [OFMutex mutex];
    _status = FutureStatus_PENDING;
    _waitRegistrations = [OFMutableArray array];
    _didFirePendingCancellationCallback = false;
    return self;
}

+ (Future *)resolved: (id)value
{
    auto resolver = [[FutureResolver alloc] init];
    [resolver resolve: value];
    return resolver.future;
}

+ (Future *)rejected: (OFException *)exception
{
    auto resolver = [[FutureResolver alloc] init];
    [resolver reject: exception];
    return resolver.future;
}

- (enum FutureStatus)status
{
    block_reference enum FutureStatus status;

    [_lock scopedLock: ^{
        status = _status;
    }];

    return status;
}

- (bool)isResolved
{
    return self.status != FutureStatus_PENDING;
}

- (id)value
{
    block_reference enum FutureStatus status;
    block_reference id value;

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
    }];

    if (status != FutureStatus_FULFILLED)
        @throw [[FutureInvalidStateAccessException alloc] initWithFuture: self operation: @"read value" status: status];

    return $assert_nonnil(value);
}

- (OFException *)rejectionException
{
    block_reference enum FutureStatus status;
    block_reference OFException *exception;

    [_lock scopedLock: ^{
        status = _status;
        exception = _rejectionException;
    }];

    if (status != FutureStatus_REJECTED)
        @throw [[FutureInvalidStateAccessException alloc] initWithFuture: self operation: @"read rejectionException" status: status];

    return $assert_nonnil(exception);
}

- (id)await
{
    block_reference enum FutureStatus status;
    block_reference id value;
    block_reference OFException *exception;
    Task *currentTask = Task.currentTask;

    if (currentTask == nilptr)
        @throw [[FutureAwaitOutsideTaskException alloc] initWithFuture: self];
    if ((Future *)currentTask == self)
        @throw [[FutureSelfAwaitException alloc] initWithFuture: self];

    [Task checkCancellation];

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
        exception = _rejectionException;
    }];

    if (status == FutureStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == FutureStatus_REJECTED)
        @throw $assert_nonnil(exception);

    AsyncFutureWaitRegistration *registration = [[AsyncFutureWaitRegistration alloc] initWithFuture: self scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"await future"];
    [Task checkCancellation];

    [_lock scopedLock: ^{
        status = _status;
        value = _value;
        exception = _rejectionException;
    }];

    if (status == FutureStatus_FULFILLED)
        return $assert_nonnil(value);
    if (status == FutureStatus_REJECTED)
        @throw $assert_nonnil(exception);

    @throw [[FutureInvalidStateAccessException alloc] initWithFuture: self operation: @"finish await" status: status];
}

- (void)_resolveWithValue: (id nillable)value
{
    block_reference OFArray<AsyncFutureWaitRegistration *> *waitRegistrations;

    if (value == nil)
        @throw [[FutureNilResolutionValueException alloc] initWithFuture: self];

    [_lock scopedLock: ^{
        if (_status != FutureStatus_PENDING)
            @throw [[FutureAlreadyResolvedException alloc] initWithFuture: self currentStatus: _status attemptedStatus: FutureStatus_FULFILLED];

        _status = FutureStatus_FULFILLED;
        _value = value;
        _rejectionException = nilptr;
        _pendingCancellationCallback = nilptr;
        waitRegistrations = [_waitRegistrations copy];
        [_waitRegistrations removeAllObjects];
    }];

    for (AsyncFutureWaitRegistration *registration in waitRegistrations)
        [registration signal];
}

- (void)_rejectWithException: (OFException *nillable)exception
{
    block_reference OFArray<AsyncFutureWaitRegistration *> *waitRegistrations;

    if (exception == nil)
        @throw [[FutureNilRejectionException alloc] initWithFuture: self];

    [_lock scopedLock: ^{
        if (_status != FutureStatus_PENDING)
            @throw [[FutureAlreadyResolvedException alloc] initWithFuture: self currentStatus: _status attemptedStatus: FutureStatus_REJECTED];

        _status = FutureStatus_REJECTED;
        _value = nilptr;
        _rejectionException = exception;
        _pendingCancellationCallback = nilptr;
        waitRegistrations = [_waitRegistrations copy];
        [_waitRegistrations removeAllObjects];
    }];

    for (AsyncFutureWaitRegistration *registration in waitRegistrations)
        [registration signal];
}

- (void)_addWaitRegistration: (AsyncFutureWaitRegistration *)registration
{
    block_reference bool shouldSignalImmediately = false;

    [_lock scopedLock: ^{
        if (_status == FutureStatus_PENDING)
            [_waitRegistrations addObject: registration];
        else
            shouldSignalImmediately = true;
    }];

    if (shouldSignalImmediately)
        [registration signal];
}

- (void)_removeWaitRegistration: (AsyncFutureWaitRegistration *)registration
{
    block_reference void (^nillable pendingCancellationCallback)(void) = nilptr;

    [_lock scopedLock: ^{
        [_waitRegistrations removeObjectIdenticalTo: registration];
        if (_status == FutureStatus_PENDING and _waitRegistrations.count == 0 and _pendingCancellationCallback != nilptr and not _didFirePendingCancellationCallback) {
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
        if (_status == FutureStatus_PENDING) {
            _pendingCancellationCallback = [cancellationCallback copy];
            _didFirePendingCancellationCallback = false;
        }
    }];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<Future %p %@>", self, FutureStatusToString(self.status)];
}

@end

@implementation FutureResolver

@synthesize future = _future;

- (instancetype)init
{
    self = [super init];
    _future = [[Future alloc] _initInternal];
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

@implementation AsyncFutureWaitRegistration {
    Future *_future;
    OFMutex *_lock;
    bool _completed;
}

@synthesize future = _future;

- (instancetype)initWithFuture: (Future *)future scheduler: (AsyncScheduler *)scheduler task: (Task *)task
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
