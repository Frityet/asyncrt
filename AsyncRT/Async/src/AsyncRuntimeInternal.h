#pragma once

#import "AsyncRuntime.h"
#import "Coroutine.h"

#pragma clang assume_nonnull begin

extern thread_local unretained Task *nillable async_current_task;
extern thread_local unretained AsyncScheduler *nillable async_current_scheduler;
extern thread_local unretained AsyncTaskGroup *nillable async_current_task_group;

void AsyncRetainForTSAN(id nillable object);

@namespace(AsyncSchedulerValidation)

+ (void)validateRunLoop: (OFRunLoop *nonnil)runLoop
                   mode: (OFRunLoopMode nonnil)mode
         maxWorkerCount: (size_t)maxWorkerCount
      maxDrainBatchSize: (size_t)maxDrainBatchSize;

@end

[[direct_members]]
@interface AsyncUnit ()

- (instancetype)_initPrivate;

@end

[[direct_members]]
@interface Coroutine ()

- (instancetype)_initAsRootCoroutine;

@end

@class AsyncTaskWaitRegistration;
@class AsyncTaskStateWaitRegistration;
@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;
@protocol AsyncTaskStateObserver;

[[subclassing_restricted, direct_members]]
@interface AsyncTaskState<__covariant T> : OFObject

@property(readonly, nonatomic) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isCompleted;
@property(readonly, nonatomic) id value;
@property(readonly, nonatomic) OFException *failureException;

+ (AsyncTaskState *)resolved: (id)value;
+ (AsyncTaskState *)rejected: (OFException *)exception;
+ (AsyncTaskState<OFArray<id> *> *)allTasks: (OFArray<Task *> *)tasks;
+ (AsyncTaskState *)raceTasks: (OFArray<Task *> *)tasks;
+ (OFString *)describeStatus: (enum AsyncTaskStatus)status;
- (AsyncTaskState<id> *)map: (id (^)(id value))transform;
- (AsyncTaskState<id> *)mapOnScheduler: (AsyncScheduler *)scheduler transform: (id (^)(id value))transform;
- (AsyncTaskState<id> *)flatMapTask: (Task * (^)(id value))transform;
- (AsyncTaskState<id> *)flatMapTaskOnScheduler: (AsyncScheduler *)scheduler transform: (Task * (^)(id value))transform;
- (AsyncTaskState<id> *)recover: (id (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)recoverOnScheduler: (AsyncScheduler *)scheduler handler: (id (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)flatRecoverTask: (Task * (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)flatRecoverTaskOnScheduler: (AsyncScheduler *)scheduler handler: (Task * (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)ensure: (void (^)(void))block;
- (AsyncTaskState<id> *)ensureOnScheduler: (AsyncScheduler *)scheduler block: (void (^)(void))block;
- (OFString *)describe;
- (id)await;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncTaskWaitRegistration : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) Task *task;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task [[designated_initailiser]];
- (void)arm;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWaitInstruction : OFObject

@property(readonly, nonatomic) AsyncTaskWaitRegistration *registration;
@property(readonly, nonatomic) OFString *waitReason;

- (instancetype)initWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskExecutionCompletion : OFObject

@property(readonly, nonatomic) id nillable value;
@property(readonly, nonatomic) OFException *nillable exception;

- (instancetype)initWithValue: (id)value [[designated_initailiser]];
- (instancetype)initWithException: (OFException *)exception [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[direct_members]]
@interface AsyncTaskState ()

- (instancetype)_initInternal;
- (void)_resolveWithValue: (id nonnil)value [[direct]];
- (void)_rejectWithException: (OFException *nonnil)exception [[direct]];
- (void)_addWaitRegistration: (AsyncTaskStateWaitRegistration *)registration [[direct]];
- (void)_removeWaitRegistration: (AsyncTaskStateWaitRegistration *)registration [[direct]];
- (void)_setPendingCancellationCallback: (void (^nillable)(void))cancellationCallback [[direct]];
- (void)_addObserver: (id<AsyncTaskStateObserver>)observer [[direct]];
- (void)_removeObserver: (id<AsyncTaskStateObserver>)observer [[direct]];
- (Task *nillable)_producingTask [[direct]];
- (void)_setProducingTask: (Task *nillable)task [[direct]];
- (Task *nillable)_associatedTask [[direct]];
- (void)_setAssociatedTask: (Task *nillable)task [[direct]];

@end

[[direct_members]]
@interface AsyncCompletionSource ()

- (AsyncTaskState *)_internalTaskState [[direct]];

@end

[[direct_members]]
@interface AsyncChannel ()

- (void)_armSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_cancelSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;
- (void)_cancelReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;

@end

[[direct_members]]
@interface AsyncScheduler ()

- (void)_enqueueTask: (Task *)task;
- (void)_enqueueBlock: (void (^)(void))block;
- (void)_recordTaskResolutionForTask: (Task *)task;

@end

[[direct_members]]
@interface AsyncTaskGroup ()

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler ownerTask: (Task *)ownerTask parentTaskGroup: (AsyncTaskGroup *nillable)parentTaskGroup name: (OFString *nillable)name deadline: (OFDate *nillable)deadline [[designated_initailiser]];
- (id)_runTaskGroupBody: (id (^)(AsyncTaskGroup *taskGroup))block;
- (void)_registerChildTask: (Task *)task;
- (void)_task: (Task *)task didCompleteWithException: (OFException *nillable)exception;
- (void)_cancelFromTimeoutWithDeadline: (OFDate *)deadline;
- (OFString *nillable)_taskGroupNameForSnapshots;

@end

[[direct_members]]
@interface Task ()

- (instancetype)initWithTaskState: (AsyncTaskState *)promise [[designated_initailiser]] [[direct]];
- (AsyncTaskState *)_internalTaskState [[direct]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler taskGroup: (AsyncTaskGroup *nillable)taskGroup name: (OFString *nillable)name block: (id (^)(void))block [[designated_initailiser]] [[direct]];
- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason [[direct]];
- (bool)_resumeFromWaitRegistration: (AsyncTaskWaitRegistration *)registration [[direct]];
- (bool)_markReadyQueued [[direct]];
- (void)_clearReadyQueued [[direct]];
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason;
- (void)_setTaskGroup: (AsyncTaskGroup *nillable)taskGroup [[direct]];
- (AsyncTaskGroup *nillable)_resumeTaskGroupContext;
- (void)_captureCurrentScopeContext;
- (Coroutine<id> *)_coroutineObject;
- (void)_resolveFromCompletion: (AsyncTaskExecutionCompletion *)completion;
- (void)_fulfillTaskWithValue: (id)value [[direct]];
- (void)_rejectTaskWithException: (OFException *)exception;
- (bool)_isCancellationRequested [[direct]];
- (void)_requestCancellation [[direct]];
- (void)_interruptForScopeCancellation;
- (void)_pushCancellationSuppression;
- (void)_popCancellationSuppression;

@end

#pragma clang assume_nonnull end
