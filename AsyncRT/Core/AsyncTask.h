#import <AsyncRT/Common/Common.h>

#pragma clang assume_nonnull begin

@class AsyncTask;
@class AsyncExecutor;
@class Coroutine;

enum [[clang::enum_extensibility(closed)]] AsyncTaskStatus {
    AsyncTaskStatus_PENDING,
    AsyncTaskStatus_RESOLVED,
    AsyncTaskStatus_REJECTED,
    AsyncTaskStatus_CANCELLED
};


[[direct_members, subclassing_restricted]]
@interface AsyncTaskCancelledException : OFException {
    @private AsyncTask *_task;
}

@property(readonly, nonatomic) AsyncTask *task;

- (instancetype)initWithTask: (AsyncTask *)task [[designated_initailiser]];
- (instancetype)init [[unavailable]];

@end

[[direct_members, subclassing_restricted]]
@interface AsyncTask<covariant TResult> : OFObject {
    @private TResult nillability_unspecified _result;
    @private __kindof OFException *nillable _error;
    @private TResult nillability_unspecified (^nillable _block)(void);
    @private enum AsyncTaskStatus _status;
    @private AsyncExecutor *_executor;
    @private OFCondition *_condition;
    @private OFMutableArray<void(^)(void)> *_continuations;
    @private Coroutine *nillable _coroutine;
    @private bool _resumeScheduled;
}

@property(readonly) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isComplete, isPending, isCancelled;
@property(retain, nonatomic) AsyncExecutor *executor;

- (instancetype)init [[unavailable]];
- (instancetype)initResolvedWithResult: (TResult nillability_unspecified)result [[designated_initailiser]];
- (instancetype)initRejectedWithError: (__kindof OFException *)error [[designated_initailiser]];

- (instancetype)initExecutingBlock: (TResult nillability_unspecified (^)())block [[designated_initailiser]];

+ (instancetype)resolvedWithResult: (TResult nillability_unspecified)result [[method_family(new)]];
+ (instancetype)rejectedWithError: (__kindof OFException *)error [[method_family(new)]];

+ (instancetype)spawn: (TResult nillability_unspecified (^)())block [[method_family(new)]];

- (TResult nillability_unspecified)await;
- (TResult nillability_unspecified)runUntilCompletion;

@end

[[direct_members, subclassing_restricted]]
@interface AsyncTaskCompletionSource<covariant TResult> : OFObject {
    @private AsyncTask<TResult> *_task;
}

@property(readonly, nonatomic) AsyncTask<TResult> *task;
@property(retain, nonatomic) AsyncExecutor *executor;

- (instancetype)init [[designated_initailiser]];

- (void)resolveWithResult: (TResult nillability_unspecified)result;
- (void)rejectWithError: (__kindof OFException *)error;

- (void)cancel;


@end

#pragma clang assume_nonnull end
