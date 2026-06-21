#pragma once

#import <AsyncRT/Core/AsyncCompletionSource.h>

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncTask;

enum [[clang::enum_extensibility(closed)]] AsyncTaskExecutionState {
    AsyncTaskExecutionState_READY,
    AsyncTaskExecutionState_RUNNING,
    AsyncTaskExecutionState_WAITING,
    AsyncTaskExecutionState_RESOLVED
};

[[subclassing_restricted, direct_members]]
@interface AsyncTaskReturnedNilException : OFException

@property(readonly, nonatomic) AsyncTask *nillable task;

- (instancetype)initWithTask: (AsyncTask *)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskCancelledException : OFException

@property(readonly, nonatomic) AsyncTask *nillable task;

- (instancetype)initWithTask: (AsyncTask *)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTask<covariant T> : OFObject

@property(readonly, nonatomic) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isCompleted;
@property(readonly, nonatomic) OFException *failureException;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) bool isCancellationRequested;
@property(class, nonatomic) size_t defaultStackSize;

+ (AsyncTask *nillable)currentTask;
+ (AsyncTask<T> *)resolved: (T)value;
+ (AsyncTask<T> *)rejected: (OFException *)exception;
+ (AsyncTask<OFArray<T> *> *)all: (OFArray<AsyncTask *> *)tasks;
+ (AsyncTask<T> *)race: (OFArray<AsyncTask *> *)tasks;
+ (void)checkCancellation;
+ (OFString *)describeStatus: (enum AsyncTaskStatus)status;
+ (OFString *)describeExecutionState: (enum AsyncTaskExecutionState)state;
- (AsyncTask<id> *)map: (id (^)(T value))transform;
- (AsyncTask<id> *)flatMap: (AsyncTask * (^)(T value))transform;
- (AsyncTask<id> *)recover: (id (^)(OFException *exception))handler;
- (AsyncTask<id> *)flatRecover: (AsyncTask * (^)(OFException *exception))handler;
- (AsyncTask<T> *)ensure: (void (^)(void))block;
- (T)await;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
