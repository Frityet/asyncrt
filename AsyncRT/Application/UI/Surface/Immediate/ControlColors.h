#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/ColorValue.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIControlColors : OFObject

@property(retain, nonatomic) AsyncUIColorValue *normalColor;
@property(retain, nonatomic) AsyncUIColorValue *hoverColor;
@property(retain, nonatomic) AsyncUIColorValue *pressedColor;
@property(retain, nonatomic) AsyncUIColorValue *disabledColor;

+ (instancetype)withNormal: (AsyncUIColorValue *)normalColor
                     hover: (AsyncUIColorValue *)hoverColor
                   pressed: (AsyncUIColorValue *)pressedColor
                  disabled: (AsyncUIColorValue *)disabledColor;

@end

#pragma clang assume_nonnull end
