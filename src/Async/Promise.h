#pragma once

#import "Async/Awaitable.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class Promise;
@class AsyncScheduler;

enum [[clang::enum_extensibility(closed)]] PromiseStatus {
    PromiseStatus_PENDING,
    PromiseStatus_FULFILLED,
    PromiseStatus_REJECTED
};

@protocol PromiseLike <Awaitable>
@end

@interface PromiseException : OFException

@property(readonly, nonatomic) Promise *nillable promise;

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseAlreadyResolvedException : PromiseException

@property(readonly, nonatomic) enum PromiseStatus currentStatus;
@property(readonly, nonatomic) enum PromiseStatus attemptedStatus;

- (instancetype)initWithPromise: (Promise *)promise currentStatus: (enum PromiseStatus)currentStatus attemptedStatus: (enum PromiseStatus)attemptedStatus designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseNilResolutionValueException : PromiseException

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseNilRejectionException : PromiseException

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseInvalidStateAccessException : PromiseException

@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) enum PromiseStatus status;

- (instancetype)initWithPromise: (Promise *)promise operation: (OFString *)operation status: (enum PromiseStatus)status designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseAwaitOutsideTaskException : PromiseException

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseSelfAwaitException : PromiseException

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseContinuationOutsideTaskException : PromiseException

- (instancetype)initWithPromise: (Promise *)promise designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Promise<__covariant T> : OFObject<PromiseLike>

@property(readonly, nonatomic) enum PromiseStatus status;
@property(readonly, nonatomic) bool isResolved;
@property(readonly, nonatomic) T value;
@property(readonly, nonatomic) OFException *rejectionException;

+ (Promise<T> *)resolved: (T)value;
+ (Promise<T> *)rejected: (OFException *)exception;
+ (Promise<OFArray<T> *> *)all: (OFArray<id<PromiseLike>> *)promises;
+ (Promise<T> *)race: (OFArray<id<PromiseLike>> *)promises;
+ (OFString *)describeStatus: (enum PromiseStatus)status;
- (Promise<id> *)map: (id (^)(T value))transform;
- (Promise<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(T value))transform;
- (Promise<id> *)flatMap: (id<PromiseLike> (^)(T value))transform;
- (Promise<id> *)flatMapOnScheduler: (AsyncScheduler *)scheduler transform: (id<PromiseLike> (^)(T value))transform;
- (Promise<id> *)recover: (id (^)(OFException *exception))handler;
- (Promise<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler;
- (Promise<id> *)flatRecover: (id<PromiseLike> (^)(OFException *exception))handler;
- (Promise<id> *)flatRecoverOnScheduler: (AsyncScheduler *)scheduler handler: (id<PromiseLike> (^)(OFException *exception))handler;
- (Promise<T> *)ensure: (void (^)(void))block;
- (Promise<T> *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block;
- (OFString *)describe;
- (T)await;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseResolver<__covariant T> : OFObject

@property(readonly, nonatomic) Promise<T> *promise;

- (instancetype)init designated_initaliser;
- (void)resolve: (T)value;
- (void)reject: (OFException *)exception;

@end

#pragma clang assume_nonnull end
