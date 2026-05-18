#pragma once

#import <AsyncRT/Application/UI/AsyncUIBorderStyle.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIBoxStyle : OFObject

@property(retain, nonatomic) AsyncUIColorValue *backgroundColor;
@property(nonatomic) float cornerRadius;
@property(retain, nonatomic) AsyncUIBorderStyle *borderStyle;
@property(class, readonly, nonatomic) AsyncUIBoxStyle *clear;
@property(class, readonly, nonatomic) AsyncUIBoxStyle *filled;

+ (instancetype)clear;
+ (instancetype)filled;
- (instancetype)filledWithColor: (AsyncUIColorValue *)backgroundColor
                   cornerRadius: (float)cornerRadius
                    borderStyle: (AsyncUIBorderStyle *)borderStyle;

@end

#pragma clang assume_nonnull end
