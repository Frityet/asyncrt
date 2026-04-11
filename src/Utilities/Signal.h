#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@interface Signal<T> : OFObject {
    @private T _value;
    @private OFMutableArray<void (^)(T)> *_subscribers;
}


@property(null_unspecified) T value;
+ (instancetype)withValue: (null_unspecified T)value;
- (instancetype)initWithValue: (null_unspecified T)value OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

- (void)subscribe: (void (^)(T _Null_unspecified))subscriber;


@end

@interface Computed<T> : OFObject {
    @private T nillable _cached;
    T (^_computeBlock)(void);
}

@property(null_unspecified, readonly) T value;

+ (instancetype)withBlock: (T (^)(void))computeBlock;
- (instancetype)initWithBlock: (T (^)(void))computeBlock OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
