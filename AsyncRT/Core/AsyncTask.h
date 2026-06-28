#import <AsyncRT/Common/Common.h>

#pragma clang assume_nonnull begin

enum [[clang::enum_extensibility(closed)]] AsyncTaskStatus {
    AsyncTaskStatus_PENDING,
    AsyncTaskStatus_RESOLVED,
    AsyncTaskStatus_REJECTED,
    AsyncTaskStatus_CANCELLED
};


@interface AsyncTask<covariant TResult> : OFObject {
    TResult nillability_unspecified _result;
    __kindof OFException *_error;
    TResult nillability_unspecified (^_block)();
}

@property(readonly) enum AsyncTaskStatus status;
@property(readonly, nonatomic) bool isComplete, isPending, isCancelled;

- (instancetype)init [[unavailable]];
- (instancetype)initResolvedWithResult: (TResult nillability_unspecified)result [[designated_initailiser]];
- (instancetype)initRejectedWithError: (__kindof OFException *)error [[designated_initailiser]];

- (instancetype)initExecutingBlock: (TResult nillability_unspecified (^)())block [[designated_initailiser]];

+ (instancetype)resolvedWithResult: (TResult nillability_unspecified)result;
+ (instancetype)rejectedWithError: (__kindof OFException *)error;

+ (instancetype)spawn: (TResult nillability_unspecified (^)())block;
+ (instancetype)spawnOffloaded: (TResult nillability_unspecified (^)())block;

- (TResult nillability_unspecified)await;
- (TResult nillability_unspecified)runUntilCompletion;

@end

@interface AsyncTaskCompletionSource<covariant TResult> : OFObject


@end

#pragma clang assume_nonnull end
