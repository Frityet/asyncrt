#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/BorderStyle.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ControlColors.h>
#import <AsyncRT/Application/UI/Surface/Immediate/EdgeInsets.h>
#import <AsyncRT/Application/UI/Surface/Immediate/TextStyle.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIControlStyle : OFObject

@property(retain, nonatomic) AsyncUIEdgeInsets *contentInsets;
@property(retain, nonatomic) AsyncUITextStyle *textStyle;
@property(retain, nonatomic) AsyncUIControlColors *backgroundColors;
@property(retain, nonatomic) AsyncUIBorderStyle *borderStyle;
@property(nonatomic) float cornerRadius;
@property(retain, nonatomic) AsyncUIColorValue *textColor;
@property(retain, nonatomic) AsyncUIColorValue *disabledTextColor;
@property(retain, nonatomic) AsyncUIColorValue *inputBackgroundColor;
@property(retain, nonatomic) AsyncUIColorValue *disabledInputBackgroundColor;
@property(retain, nonatomic) AsyncUIColorValue *inputBorderColor;
@property(retain, nonatomic) AsyncUIColorValue *focusedInputBorderColor;
@property(retain, nonatomic) AsyncUIColorValue *disabledInputBorderColor;
@property(retain, nonatomic) AsyncUIColorValue *placeholderColor;
@property(retain, nonatomic) AsyncUIColorValue *caretColor;
@property(class, readonly, nonatomic) AsyncUIControlStyle *button;
@property(class, readonly, nonatomic) AsyncUIControlStyle *textField;

+ (instancetype)button;
+ (instancetype)textField;

@end

#pragma clang assume_nonnull end
