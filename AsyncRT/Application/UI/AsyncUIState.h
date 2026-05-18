#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIState<covariant T> : OFObject

@property(retain, nonatomic) T nillable value;

- (void)setValue: (T nillable)value;
- (void)update: (T _Nullable (^nonnil)(T nillable currentValue))updateBlock;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
