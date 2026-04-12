#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

[[clang::objc_subclassing_restricted, clang::objc_direct_members]]
@interface Optional<T> : OFObject

@property (readonly, nonatomic) bool hasValue;
@property (readonly, nonatomic) T nonnil value;

+ (instancetype)none;
+ (instancetype)some: (T nonnil)value;
+ (instancetype)fromNillable: (T nillable)value;
- (T nonnil)valueOr: (T nonnil)fallbackValue;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
