#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncSignal<T> : OFObject

@property T _Null_unspecified value;

+ (instancetype)withValue: (T _Null_unspecified)value [[direct]];
- (instancetype)initWithValue: (T _Null_unspecified)value [[designated_initailiser]] [[direct]];
- (void (^)(void))subscribe: (void (^)(T _Null_unspecified))subscriber [[direct]];
- (T _Null_unspecified)next [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncComputed<T> : OFObject

@property(readonly) T _Null_unspecified value;

+ (instancetype)withBlock: (T (^)(void))computeBlock [[direct]];
- (instancetype)initWithBlock: (T (^)(void))computeBlock [[designated_initailiser]] [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
