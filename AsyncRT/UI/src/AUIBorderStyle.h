#pragma once

#import "AUIColorValue.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIBorderStyle : OFObject

@property(retain, nonatomic) AUIColorValue *color;
@property(nonatomic) uint16_t leftWidth;
@property(nonatomic) uint16_t rightWidth;
@property(nonatomic) uint16_t topWidth;
@property(nonatomic) uint16_t bottomWidth;
@property(nonatomic) uint16_t betweenChildrenWidth;
@property(class, readonly, nonatomic) AUIBorderStyle *none;

+ (instancetype)none;
+ (instancetype)all: (uint16_t)width color: (AUIColorValue *)color;

@end

#pragma clang assume_nonnull end
