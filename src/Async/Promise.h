#pragma once

#import "Async/Awaitable.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class Promise;

enum [[clang::enum_extensibility(closed)]] PromiseStatus {
    PromiseStatus_PENDING,
    PromiseStatus_FULFILLED,
    PromiseStatus_REJECTED
};

@interface PromiseException : OFException {
@private
    unretained Promise *nillable _future;
}

@property(readonly, nonatomic) Promise *nillable future;

- (instancetype)initWithPromise: (Promise *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseAlreadyResolvedException : PromiseException {
@private
    enum PromiseStatus _currentStatus;
    enum PromiseStatus _attemptedStatus;
}

@property(readonly, nonatomic) enum PromiseStatus currentStatus;
@property(readonly, nonatomic) enum PromiseStatus attemptedStatus;

- (instancetype)initWithPromise: (Promise *)future currentStatus: (enum PromiseStatus)currentStatus attemptedStatus: (enum PromiseStatus)attemptedStatus OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseNilResolutionValueException : PromiseException

- (instancetype)initWithPromise: (Promise *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseNilRejectionException : PromiseException

- (instancetype)initWithPromise: (Promise *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseInvalidStateAccessException : PromiseException {
@private
    OFString *_operation;
    enum PromiseStatus _status;
}

@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) enum PromiseStatus status;

- (instancetype)initWithPromise: (Promise *)future operation: (OFString *)operation status: (enum PromiseStatus)status OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseAwaitOutsideTaskException : PromiseException

- (instancetype)initWithPromise: (Promise *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseSelfAwaitException : PromiseException

- (instancetype)initWithPromise: (Promise *)future OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Promise<__covariant T> : OFObject<Awaitable>

@property(readonly, nonatomic) enum PromiseStatus status;
@property(readonly, nonatomic) bool isResolved;
@property(readonly, nonatomic) T value;
@property(readonly, nonatomic) OFException *rejectionException;

+ (Promise<T> *)resolved: (T)value;
+ (Promise<T> *)rejected: (OFException *)exception;
- (T)await;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseResolver<__covariant T> : OFObject {
@private
    Promise<T> *_future;
}

@property(readonly, nonatomic) Promise<T> *future;

- (instancetype)init OF_DESIGNATED_INITIALIZER;
- (void)resolve: (T)value;
- (void)reject: (OFException *)exception;

@end

#pragma clang assume_nonnull end
