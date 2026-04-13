#pragma once

#import "Async/Awaitable.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class Task<T>;

enum [[clang::enum_extensibility(closed)]] AsyncTaskStatus {
    AsyncTaskStatus_PENDING,
    AsyncTaskStatus_FULFILLED,
    AsyncTaskStatus_REJECTED
};

@interface AsyncTaskException : OFException

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskAlreadyResolvedException : AsyncTaskException

@property(readonly, nonatomic) enum AsyncTaskStatus currentStatus;
@property(readonly, nonatomic) enum AsyncTaskStatus attemptedStatus;

- (instancetype)initWithTask: (Task *nillable)task currentStatus: (enum AsyncTaskStatus)currentStatus attemptedStatus: (enum AsyncTaskStatus)attemptedStatus [[designated_initailiser]];
- (instancetype)initWithTask: (Task *nillable)task OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskNilResolutionValueException : AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskNilRejectionException : AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskInvalidStateAccessException : AsyncTaskException

@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) enum AsyncTaskStatus status;

- (instancetype)initWithTask: (Task *nillable)task operation: (OFString *)operation status: (enum AsyncTaskStatus)status [[designated_initailiser]];
- (instancetype)initWithTask: (Task *nillable)task OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskAwaitOutsideTaskException : AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskSelfAwaitException : AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskContinuationOutsideTaskException : AsyncTaskException

- (instancetype)initWithTask: (Task *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncCompletionSource<__covariant T> : OFObject

@property(readonly, nonatomic) Task<T> *task;

- (instancetype)init [[designated_initailiser]];
- (void)fulfill: (T)value;
- (void)reject: (OFException *)exception;
- (void)setPendingTaskCancellationHandler: (void (^nillable)(void))cancellationHandler;

@end

#pragma clang assume_nonnull end
