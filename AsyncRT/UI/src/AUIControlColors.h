#pragma once

#import "AUIColorValue.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIControlColors : OFObject

@property(retain, nonatomic) AUIColorValue *normalColor;
@property(retain, nonatomic) AUIColorValue *hoverColor;
@property(retain, nonatomic) AUIColorValue *pressedColor;
@property(retain, nonatomic) AUIColorValue *disabledColor;

+ (instancetype)withNormal: (AUIColorValue *)normalColor
                     hover: (AUIColorValue *)hoverColor
                   pressed: (AUIColorValue *)pressedColor
                  disabled: (AUIColorValue *)disabledColor;

@end

#pragma clang assume_nonnull end
