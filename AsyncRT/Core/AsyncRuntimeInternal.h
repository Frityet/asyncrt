#pragma once

#import <AsyncRT/Core/AsyncRuntime.h>
#import <AsyncRT/Core/AsyncCoroutine.h>

#pragma clang assume_nonnull begin

extern thread_local unretained AsyncTask *nillable async_current_task;
extern thread_local unretained AsyncScheduler *nillable async_current_scheduler;

void AsyncRetainForTSAN(id nillable object);

@namespace(AsyncSchedulerValidation)

+ (void)validateRunLoop: (OFRunLoop *nillable)runLoop
                   mode: (OFRunLoopMode nillable)mode
         maxWorkerCount: (size_t)maxWorkerCount
      maxDrainBatchSize: (size_t)maxDrainBatchSize;

@end

[[direct_members]]
@interface AsyncUnit ()

- (instancetype)_initPrivate;

@end

[[direct_members]]
@interface AsyncCoroutine ()

- (instancetype)_initAsRootCoroutine;

@end

@class AsyncTaskWaitRegistration;
@class AsyncTaskStateWaitRegistration;
@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;
@protocol AsyncTaskStateObserver;

[[subclassing_restricted, direct_members]]
@interface AsyncTaskState<covariant T> : OFObject

@property(readonly, nonatomic) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isCompleted;
@property(readonly, nonatomic) id value;
@property(readonly, nonatomic) OFException *failureException;

+ (AsyncTaskState *)resolved: (id nillable)value;
+ (AsyncTaskState *)rejected: (OFException *nillable)exception;
+ (AsyncTaskState<OFArray<id> *> *)allTasks: (OFArray<AsyncTask *> *)tasks;
+ (AsyncTaskState *)raceTasks: (OFArray<AsyncTask *> *)tasks;
+ (OFString *)describeStatus: (enum AsyncTaskStatus)status;
- (AsyncTaskState<id> *)map: (id (^)(id value))transform;
- (AsyncTaskState<id> *)flatMapTask: (AsyncTask * (^)(id value))transform;
- (AsyncTaskState<id> *)recover: (id (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)flatRecoverTask: (AsyncTask * (^)(OFException *exception))handler;
- (AsyncTaskState<id> *)ensure: (void (^)(void))block;
- (OFString *)describe;
- (id)await;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncTaskWaitRegistration : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncTask *task;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (AsyncTask *)task [[designated_initailiser]];
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
- (AsyncTask *nillable)_producingTask [[direct]];
- (void)_setProducingTask: (AsyncTask *nillable)task [[direct]];
- (AsyncTask *nillable)_associatedTask [[direct]];
- (void)_setAssociatedTask: (AsyncTask *nillable)task [[direct]];

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

- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode maxWorkerCount: (size_t)maxWorkerCount maxDrainBatchSize: (size_t)maxDrainBatchSize [[designated_initailiser]];
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop;
- (void)_enqueueTask: (AsyncTask *)task;
- (void)_enqueueBlock: (void (^)(void))block;
- (bool)_tryEnqueueBlock: (void (^)(void))block;
- (void)_recordTaskResolutionForTask: (AsyncTask *)task;
- (void)_shutdown;

@end

[[direct_members]]
[[direct_members]]
@interface AsyncTask ()

- (instancetype)initWithTaskState: (AsyncTaskState *)promise [[designated_initailiser]] [[direct]];
- (AsyncTaskState *)_internalTaskState [[direct]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler name: (OFString *nillable)name block: (id (^)(void))block [[designated_initailiser]] [[direct]];
- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason [[direct]];
- (bool)_resumeFromWaitRegistration: (AsyncTaskWaitRegistration *)registration [[direct]];
- (bool)_markReadyQueued [[direct]];
- (void)_clearReadyQueued [[direct]];
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason;
- (AsyncCoroutine<id> *)_coroutineObject;
- (void)_resolveFromCompletion: (AsyncTaskExecutionCompletion *)completion;
- (void)_fulfillTaskWithValue: (id)value [[direct]];
- (void)_rejectTaskWithException: (OFException *)exception;
- (bool)_isCancellationRequested [[direct]];
- (void)_requestCancellation [[direct]];

@end

#pragma clang assume_nonnull end
