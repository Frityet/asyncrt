#pragma once

#import <AsyncRT/Application/UI/AsyncUIColorValue.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIBorderStyle : OFObject

@property(retain, nonatomic) AsyncUIColorValue *color;
@property(nonatomic) uint16_t leftWidth;
@property(nonatomic) uint16_t rightWidth;
@property(nonatomic) uint16_t topWidth;
@property(nonatomic) uint16_t bottomWidth;
@property(nonatomic) uint16_t betweenChildrenWidth;
@property(class, readonly, nonatomic) AsyncUIBorderStyle *none;

+ (instancetype)none;
+ (instancetype)all: (uint16_t)width color: (AsyncUIColorValue *)color;

@end

#pragma clang assume_nonnull end
