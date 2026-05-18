#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

@class AsyncTask<T>;

enum [[clang::enum_extensibility(closed)]] AsyncTaskStatus {
    AsyncTaskStatus_PENDING,
    AsyncTaskStatus_FULFILLED,
    AsyncTaskStatus_REJECTED
};

@interface AsyncTaskException : OFException

@property(readonly, nonatomic) AsyncTask *nillable task;

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskAlreadyResolvedException : AsyncTaskException

@property(readonly, nonatomic) enum AsyncTaskStatus currentStatus;
@property(readonly, nonatomic) enum AsyncTaskStatus attemptedStatus;

- (instancetype)initWithTask: (AsyncTask *nillable)task currentStatus: (enum AsyncTaskStatus)currentStatus attemptedStatus: (enum AsyncTaskStatus)attemptedStatus [[designated_initailiser]];
- (instancetype)initWithTask: (AsyncTask *nillable)task OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskNilResolutionValueException : AsyncTaskException

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskNilRejectionException : AsyncTaskException

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskInvalidStateAccessException : AsyncTaskException

@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) enum AsyncTaskStatus status;

- (instancetype)initWithTask: (AsyncTask *nillable)task operation: (OFString *)operation status: (enum AsyncTaskStatus)status [[designated_initailiser]];
- (instancetype)initWithTask: (AsyncTask *nillable)task OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskAwaitOutsideTaskException : AsyncTaskException

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskSelfAwaitException : AsyncTaskException

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskContinuationOutsideTaskException : AsyncTaskException

- (instancetype)initWithTask: (AsyncTask *nillable)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncCompletionSource<covariant T> : OFObject

@property(readonly, nonatomic) AsyncTask<T> *task;

- (instancetype)init [[designated_initailiser]];
- (AsyncTask<T> *)task [[direct]];
- (void)fulfill: (T nillable)value [[direct]];
- (void)reject: (OFException *nillable)exception [[direct]];
- (void)setPendingTaskCancellationHandler: (void (^nillable)(void))cancellationHandler [[direct]];

@end

#pragma clang assume_nonnull end
