#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

[[clang::objc_subclassing_restricted, clang::objc_direct_members]]
@interface AsyncSignal<T> : OFObject

@property T _Null_unspecified value;

+ (instancetype)withValue: (T _Null_unspecified)value;
- (instancetype)initWithValue: (T _Null_unspecified)value designated_initaliser;
- (void (^)(void))subscribe: (void (^)(T _Null_unspecified))subscriber;
- (T _Null_unspecified)next;
- (instancetype)init OF_UNAVAILABLE;

@end

[[clang::objc_subclassing_restricted, clang::objc_direct_members]]
@interface AsyncComputed<T> : OFObject

@property(readonly) T _Null_unspecified value;

+ (instancetype)withBlock: (T (^)(void))computeBlock;
- (instancetype)initWithBlock: (T (^)(void))computeBlock designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
