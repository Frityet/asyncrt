#pragma once

#import "Async/AsyncRuntime.h"
#import "Async/Coroutine.h"

#pragma clang assume_nonnull begin

extern thread_local unretained Task *nillable async_current_task;
extern thread_local unretained AsyncScheduler *nillable async_current_scheduler;
extern thread_local unretained AsyncScope *nillable async_current_scope;

void AsyncRetainForTSAN(id nillable object);

@namespace(AsyncSchedulerValidation)

+ (void)validateRunLoop: (OFRunLoop *nillable)runLoop
                   mode: (OFRunLoopMode nillable)mode
         maxWorkerCount: (size_t)maxWorkerCount
      maxDrainBatchSize: (size_t)maxDrainBatchSize;

@end

[[clang::objc_direct_members]]
@interface AsyncUnit ()

- (instancetype)_initPrivate;

@end

[[clang::objc_direct_members]]
@interface Coroutine ()

- (instancetype)_initAsRootCoroutine;

@end

@class AsyncTaskWaitRegistration;
@class AsyncPromiseWaitRegistration;
@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;
@protocol AsyncPromiseObserver;

@interface AsyncTaskWaitRegistration : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) Task *task;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task designated_initaliser;
- (void)arm;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncWaitInstruction : OFObject

@property(readonly, nonatomic) AsyncTaskWaitRegistration *registration;
@property(readonly, nonatomic) OFString *waitReason;

- (instancetype)initWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncPromiseCompletion : OFObject

@property(readonly, nonatomic) id nillable value;
@property(readonly, nonatomic) OFException *nillable exception;

- (instancetype)initWithValue: (id)value designated_initaliser;
- (instancetype)initWithException: (OFException *)exception designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface Promise ()

- (instancetype)_initInternal;
- (void)_resolveWithValue: (id nillable)value [[clang::objc_direct]];
- (void)_rejectWithException: (OFException *nillable)exception [[clang::objc_direct]];
- (void)_addWaitRegistration: (AsyncPromiseWaitRegistration *)registration [[clang::objc_direct]];
- (void)_removeWaitRegistration: (AsyncPromiseWaitRegistration *)registration [[clang::objc_direct]];
- (void)_setPendingCancellationCallback: (void (^)(void))cancellationCallback [[clang::objc_direct]];
- (void)_addObserver: (id<AsyncPromiseObserver>)observer [[clang::objc_direct]];
- (void)_removeObserver: (id<AsyncPromiseObserver>)observer [[clang::objc_direct]];

@end

[[clang::objc_direct_members]]
@interface AsyncChannel ()

- (void)_armSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_cancelSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;
- (void)_cancelReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;

@end

[[clang::objc_direct_members]]
@interface AsyncScheduler ()

- (void)_enqueueTask: (Task *)task;
- (void)_recordTaskResolutionForTask: (Task *)task;

@end

[[clang::objc_direct_members]]
@interface AsyncScope ()

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler ownerTask: (Task *)ownerTask parentScope: (AsyncScope *nillable)parentScope name: (OFString *nillable)name deadline: (OFDate *nillable)deadline designated_initaliser;
- (id)_runScopeBody: (id (^)(AsyncScope *scope))block;
- (void)_registerChildTask: (Task *)task;
- (void)_task: (Task *)task didCompleteWithException: (OFException *nillable)exception;
- (void)_cancelFromTimeoutWithDeadline: (OFDate *)deadline;
- (OFString *nillable)_debugName;
- (OFString *nillable)_scopeNameForSnapshots;

@end

@interface Task ()

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler scope: (AsyncScope *nillable)scope name: (OFString *nillable)name block: (id (^)(void))block designated_initaliser [[clang::objc_direct]];
- (void)_yieldWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason [[clang::objc_direct]];
- (bool)_resumeFromWaitRegistration: (AsyncTaskWaitRegistration *)registration [[clang::objc_direct]];
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason;
- (void)_setScope: (AsyncScope *nillable)scope [[clang::objc_direct]];
- (AsyncScope *nillable)_resumeScopeContext;
- (void)_captureCurrentScopeContext;
- (Coroutine<id> *)_coroutineObject;
- (void)_resolveFromCompletion: (AsyncPromiseCompletion *)completion;
- (void)_fulfillTaskWithValue: (id)value [[clang::objc_direct]];
- (void)_rejectTaskWithException: (OFException *)exception;
- (bool)_isCancellationRequested [[clang::objc_direct]];
- (void)_requestCancellation [[clang::objc_direct]];
- (void)_interruptForScopeCancellation;
- (void)_pushCancellationSuppression;
- (void)_popCancellationSuppression;

@end

#pragma clang assume_nonnull end
