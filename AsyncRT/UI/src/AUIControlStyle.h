#pragma once

#import "AUIBorderStyle.h"
#import "AUIControlColors.h"
#import "AUIEdgeInsets.h"
#import "AUITextStyle.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIControlStyle : OFObject

@property(retain, nonatomic) AUIEdgeInsets *contentInsets;
@property(retain, nonatomic) AUITextStyle *textStyle;
@property(retain, nonatomic) AUIControlColors *backgroundColors;
@property(retain, nonatomic) AUIBorderStyle *borderStyle;
@property(nonatomic) float cornerRadius;
@property(retain, nonatomic) AUIColorValue *textColor;
@property(retain, nonatomic) AUIColorValue *disabledTextColor;
@property(retain, nonatomic) AUIColorValue *inputBackgroundColor;
@property(retain, nonatomic) AUIColorValue *disabledInputBackgroundColor;
@property(retain, nonatomic) AUIColorValue *inputBorderColor;
@property(retain, nonatomic) AUIColorValue *focusedInputBorderColor;
@property(retain, nonatomic) AUIColorValue *disabledInputBorderColor;
@property(retain, nonatomic) AUIColorValue *placeholderColor;
@property(retain, nonatomic) AUIColorValue *caretColor;
@property(class, readonly, nonatomic) AUIControlStyle *button;
@property(class, readonly, nonatomic) AUIControlStyle *textField;

+ (instancetype)button;
+ (instancetype)textField;

@end

#pragma clang assume_nonnull end
