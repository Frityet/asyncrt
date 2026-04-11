#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@interface AsyncUnit : OFObject

@property(class, readonly, nonatomic) AsyncUnit *unit;

+ (AsyncUnit *)unit;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
