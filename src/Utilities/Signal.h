#include "Utilities/common.h"

#pragma clang assume_nonnull begin

typedef void (^SignalCleanupBlock)(void);

[[subclassing_restricted, direct_members]]
@interface Signal<T> : OFObject

@property T _Null_unspecified value;
+ (instancetype)withValue: (T _Null_unspecified)value [[direct]];
- (instancetype)initWithValue: (T _Null_unspecified)value [[designated_initailiser]] [[direct]];
- (instancetype)init OF_UNAVAILABLE;

- (SignalCleanupBlock)subscribe: (void (^)(T _Null_unspecified))subscriber [[direct]];

@end

[[subclassing_restricted]]
@interface Computed<T> : OFObject

@property(readonly) T _Null_unspecified value;

+ (instancetype)withBlock: (T (^)(void))computeBlock [[direct]];
- (instancetype)initWithBlock: (T (^)(void))computeBlock [[designated_initailiser]] [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface Effect : OFObject

+ (instancetype)withBlock: (void (^)(void))effectBlock [[direct]];
- (instancetype)initWithBlock: (void (^)(void))effectBlock [[designated_initailiser]] [[direct]];
- (void)invalidate [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
