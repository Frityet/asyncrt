#pragma once

#import "Async/Future.h"

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

@interface TaskReturnedNilException : FutureException {
@private
    unretained Task *nillable _task;
}

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface TaskCancelledException : FutureException {
@private
    unretained Task *nillable _task;
}

@property(readonly, nonatomic) Task *nillable task;

- (instancetype)initWithTask: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Task<__covariant T> : Future<T>

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncScope *nillable scope;
@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic, getter=isCancellationRequested) bool cancellationRequested;
@property(class, nonatomic) size_t defaultStackSize;

+ (Task *nillable)currentTask;
+ (void)checkCancellation;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
