#pragma once

#import "Async/AsyncRuntime.h"
#import "Async/Coroutine.h"

#pragma clang assume_nonnull begin

extern thread_local unretained Task *nillable async_current_task;
extern thread_local unretained AsyncScheduler *nillable async_current_scheduler;
extern thread_local unretained AsyncScope *nillable async_current_scope;

OFString *PromiseStatusToString(enum PromiseStatus status);
OFString *DescribePromise(Promise *nillable future);
OFString *DescribeScheduler(AsyncScheduler *nillable scheduler);
OFString *TaskExecutionStateToString(enum AsyncTaskExecutionState state);
void AsyncRetainForTSAN(id nillable object);

@namespace(AsyncSchedulerValidation)

+ (void)validateRunLoop: (OFRunLoop *nillable)runLoop
                  mode: (OFRunLoopMode nillable)mode
        maxWorkerCount: (size_t)maxWorkerCount
    maxDrainBatchSize: (size_t)maxDrainBatchSize;

@end

@interface AsyncUnit ()

- (instancetype)_initPrivate;

@end

@class AsyncTaskWaitRegistration;
@class AsyncPromiseWaitRegistration;

@interface AsyncTaskWaitRegistration : OFObject {
@protected
    AsyncScheduler *_scheduler;
    Task *_task;
}

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) Task *task;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_DESIGNATED_INITIALIZER;
- (void)arm;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncWaitInstruction : OFObject

@property(readonly, nonatomic) AsyncTaskWaitRegistration *registration;
@property(readonly, nonatomic) OFString *waitReason;

- (instancetype)initWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncPromiseCompletion : OFObject

@property(readonly, nonatomic) id nillable value;
@property(readonly, nonatomic) OFException *nillable exception;

- (instancetype)initWithValue: (id)value OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithException: (OFException *)exception OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Promise ()

- (instancetype)_initInternal;
- (void)_resolveWithValue: (id)value;
- (void)_rejectWithException: (OFException *)exception;
- (void)_addWaitRegistration: (AsyncPromiseWaitRegistration *)registration;
- (void)_removeWaitRegistration: (AsyncPromiseWaitRegistration *)registration;
- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback;

@end

@interface AsyncScheduler ()

- (void)_enqueueTask: (Task *)task;
- (void)_recordTaskResolutionForTask: (Task *)task;

@end

@interface AsyncScope ()

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler ownerTask: (Task *)ownerTask parentScope: (AsyncScope *nillable)parentScope name: (OFString *nillable)name deadline: (OFDate *nillable)deadline OF_DESIGNATED_INITIALIZER;
- (id)_runScopeBody: (id (^)(AsyncScope *scope))block;
- (void)_registerChildTask: (Task *)task;
- (void)_task: (Task *)task didCompleteWithException: (OFException *nillable)exception;
- (void)_cancelFromTimeoutWithDeadline: (OFDate *)deadline;
- (OFString *nillable)_debugName;
- (OFString *nillable)_scopeNameForSnapshots;

@end

@interface Task ()

 - (instancetype)initWithScheduler: (AsyncScheduler *)scheduler scope: (AsyncScope *nillable)scope name: (OFString *nillable)name block: (id (^)(void))block OF_DESIGNATED_INITIALIZER;
- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason;
- (bool)_resumeFromWaitRegistration: (AsyncTaskWaitRegistration *)registration;
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason;
 - (void)_setScope: (AsyncScope *nillable)scope;
- (AsyncScope *nillable)_resumeScopeContext;
- (void)_captureCurrentScopeContext;
- (Coroutine<id> *)_coroutineObject;
- (void)_resolveFromCompletion: (AsyncPromiseCompletion *)completion;
- (void)_fulfillTaskWithValue: (id)value;
- (void)_rejectTaskWithException: (OFException *)exception;
- (bool)_isCancellationRequested;
- (void)_requestCancellation;
- (void)_interruptForScopeCancellation;
- (void)_pushCancellationSuppression;
- (void)_popCancellationSuppression;

@end

#pragma clang assume_nonnull end
