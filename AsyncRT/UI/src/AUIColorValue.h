#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIColorValue : OFObject

@property(readonly, nonatomic) uint8_t red;
@property(readonly, nonatomic) uint8_t green;
@property(readonly, nonatomic) uint8_t blue;
@property(readonly, nonatomic) uint8_t alpha;
@property(class, readonly, nonatomic) AUIColorValue *clear;
@property(class, readonly, nonatomic) AUIColorValue *white;
@property(class, readonly, nonatomic) AUIColorValue *black;

+ (instancetype)withRed: (uint8_t)red
                  green: (uint8_t)green
                   blue: (uint8_t)blue
                  alpha: (uint8_t)alpha;
+ (instancetype)clear;
+ (instancetype)white;
+ (instancetype)black;
- (instancetype)initWithRed: (uint8_t)red
                      green: (uint8_t)green
                       blue: (uint8_t)blue
                      alpha: (uint8_t)alpha [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
