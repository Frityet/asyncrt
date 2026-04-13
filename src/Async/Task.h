#pragma once

#import "Async/Promise.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncScope;
@class Task;

enum [[clang::enum_extensibility(closed)]] AsyncTaskExecutionState {
    AsyncTaskExecutionState_READY,
    AsyncTaskExecutionState_RUNNING,
    AsyncTaskExecutionState_WAITING,
    AsyncTaskExecutionState_RESOLVED
};

[[subclassing_restricted]]
@interface TaskReturnedNilException : PromiseException

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task [[designated_initailiser]];
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface TaskCancelledException : PromiseException

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task [[designated_initailiser]];
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface Task<__covariant T> : Promise<T>

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncScope *nillable scope;
@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) bool isCancellationRequested;
@property(class, nonatomic) size_t defaultStackSize;

+ (Task *nillable)currentTask;
+ (void)checkCancellation;
+ (OFString *)describeExecutionState: (enum AsyncTaskExecutionState)state;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
