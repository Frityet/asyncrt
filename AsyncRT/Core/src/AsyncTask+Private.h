#import "AsyncTask.h"

@class AsyncExecutor;

#pragma clang assume_nonnull begin

@interface AsyncTask<TResult> ()

- (instancetype)_initPendingWithExecutor: (AsyncExecutor *)executor [[designated_initailiser]];

- (bool)_tryResolveWithResult: (TResult nillability_unspecified)result;
- (bool)_tryRejectWithError: (OFException *)error;
- (bool)_tryCancel;

- (void(^)(void))_addContinuationOnExecutor: (AsyncExecutor *)executor block: (void (^)(void))block;

- (void)_removeContinuation: (void(^)(void))continuation;

- (void)_resumeCoroutine;

@end

#pragma clang assume_nonnull end
