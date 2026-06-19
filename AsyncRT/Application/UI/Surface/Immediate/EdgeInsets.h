#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIEdgeInsets : OFObject

@property(nonatomic) uint16_t left;
@property(nonatomic) uint16_t right;
@property(nonatomic) uint16_t top;
@property(nonatomic) uint16_t bottom;

+ (instancetype)withLeft: (uint16_t)left
                   right: (uint16_t)right
                     top: (uint16_t)top
                  bottom: (uint16_t)bottom;
+ (instancetype)all: (uint16_t)inset;

@end

#pragma clang assume_nonnull end
