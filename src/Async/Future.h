#pragma once

#import "Async/Awaitable.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class Future;

enum [[clang::enum_extensibility(closed)]] FutureStatus {
    FutureStatus_PENDING,
    FutureStatus_FULFILLED,
    FutureStatus_REJECTED
};

@interface FutureException : OFException {
@private
    unretained Future *nillable _future;
}

@property(readonly, nonatomic) Future *nillable future;

- (instancetype)initWithFuture: (Future *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureAlreadyResolvedException : FutureException {
@private
    enum FutureStatus _currentStatus;
    enum FutureStatus _attemptedStatus;
}

@property(readonly, nonatomic) enum FutureStatus currentStatus;
@property(readonly, nonatomic) enum FutureStatus attemptedStatus;

- (instancetype)initWithFuture: (Future *)future currentStatus: (enum FutureStatus)currentStatus attemptedStatus: (enum FutureStatus)attemptedStatus OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureNilResolutionValueException : FutureException

- (instancetype)initWithFuture: (Future *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureNilRejectionException : FutureException

- (instancetype)initWithFuture: (Future *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureInvalidStateAccessException : FutureException {
@private
    OFString *_operation;
    enum FutureStatus _status;
}

@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) enum FutureStatus status;

- (instancetype)initWithFuture: (Future *)future operation: (OFString *)operation status: (enum FutureStatus)status OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureAwaitOutsideTaskException : FutureException

- (instancetype)initWithFuture: (Future *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureSelfAwaitException : FutureException

- (instancetype)initWithFuture: (Future *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Future<__covariant T> : OFObject<Awaitable>

@property(readonly, nonatomic) enum FutureStatus status;
@property(readonly, nonatomic) bool isResolved;
@property(readonly, nonatomic) T value;
@property(readonly, nonatomic) OFException *rejectionException;

+ (Future<T> *)resolved: (T)value;
+ (Future<T> *)rejected: (OFException *)exception;
- (T)await;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureResolver<__covariant T> : OFObject {
@private
    Future<T> *_future;
}

@property(readonly, nonatomic) Future<T> *future;

- (instancetype)init OF_DESIGNATED_INITIALIZER;
- (void)resolve: (T)value;
- (void)reject: (OFException *)exception;

@end

#pragma clang assume_nonnull end
