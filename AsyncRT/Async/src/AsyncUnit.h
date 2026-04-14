#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUnit : OFObject

@property(class, readonly, nonatomic) AsyncUnit *unit;

+ (AsyncUnit *)unit [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
