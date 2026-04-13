#pragma once

#import "Async/AsyncCompletionSource.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncTaskGroup;
@class Task;

enum [[clang::enum_extensibility(closed)]] AsyncTaskExecutionState {
    AsyncTaskExecutionState_READY,
    AsyncTaskExecutionState_RUNNING,
    AsyncTaskExecutionState_WAITING,
    AsyncTaskExecutionState_RESOLVED
};

[[subclassing_restricted]]
@interface TaskReturnedNilException : OFException

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface TaskCancelledException : OFException

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface Task<__covariant T> : OFObject<Awaitable>

@property(readonly, nonatomic) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isCompleted;
@property(readonly, nonatomic) T value;
@property(readonly, nonatomic) OFException *failureException;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncTaskGroup *nillable taskGroup;
@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) bool isCancellationRequested;
@property(class, nonatomic) size_t defaultStackSize;

+ (Task *nillable)currentTask;
+ (Task<T> *)resolved: (T)value;
+ (Task<T> *)rejected: (OFException *)exception;
+ (Task<OFArray<T> *> *)all: (OFArray<Task *> *)tasks;
+ (Task<T> *)race: (OFArray<Task *> *)tasks;
+ (void)checkCancellation;
+ (OFString *)describeStatus: (enum AsyncTaskStatus)status;
+ (OFString *)describeExecutionState: (enum AsyncTaskExecutionState)state;
- (Task<id> *)map: (id (^)(T value))transform;
- (Task<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(T value))transform;
- (Task<id> *)flatMap: (Task * (^)(T value))transform;
- (Task<id> *)flatMapOnScheduler: (AsyncScheduler *)scheduler transform: (Task * (^)(T value))transform;
- (Task<id> *)recover: (id (^)(OFException *exception))handler;
- (Task<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler;
- (Task<id> *)flatRecover: (Task * (^)(OFException *exception))handler;
- (Task<id> *)flatRecoverOnScheduler: (AsyncScheduler *)scheduler handler: (Task * (^)(OFException *exception))handler;
- (Task<T> *)ensure: (void (^)(void))block;
- (Task<T> *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block;
- (T)await;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
