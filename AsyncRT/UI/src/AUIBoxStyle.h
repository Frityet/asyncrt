#pragma once

#import "AUIBorderStyle.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIBoxStyle : OFObject

@property(retain, nonatomic) AUIColorValue *backgroundColor;
@property(nonatomic) float cornerRadius;
@property(retain, nonatomic) AUIBorderStyle *borderStyle;
@property(class, readonly, nonatomic) AUIBoxStyle *clear;
@property(class, readonly, nonatomic) AUIBoxStyle *filled;

+ (instancetype)clear;
+ (instancetype)filled;
- (instancetype)filledWithColor: (AUIColorValue *)backgroundColor
                   cornerRadius: (float)cornerRadius
                    borderStyle: (AUIBorderStyle *)borderStyle;

@end

#pragma clang assume_nonnull end
