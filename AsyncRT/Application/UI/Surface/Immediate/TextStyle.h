#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/ColorValue.h>

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AsyncUITextWrapStyle {
    AsyncUITextWrapStyleWords,
    AsyncUITextWrapStyleNewlines,
    AsyncUITextWrapStyleNone
} AsyncUITextWrapStyle;

typedef enum [[clang::enum_extensibility(closed)]] AsyncUITextHorizontalAlignment {
    AsyncUITextHorizontalAlignmentLeading,
    AsyncUITextHorizontalAlignmentCenter,
    AsyncUITextHorizontalAlignmentTrailing
} AsyncUITextHorizontalAlignment;

[[subclassing_restricted, direct_members]]
@interface AsyncUITextStyle : OFObject

@property(nonatomic) uint16_t fontID;
@property(nonatomic) uint16_t fontSize;
@property(nonatomic) uint16_t letterSpacing;
@property(nonatomic) uint16_t lineHeight;
@property(retain, nonatomic) AsyncUIColorValue *color;
@property(nonatomic) AsyncUITextWrapStyle wrapStyle;
@property(nonatomic) AsyncUITextHorizontalAlignment alignment;
@property(class, readonly, nonatomic) AsyncUITextStyle *body;
@property(class, readonly, nonatomic) AsyncUITextStyle *label;

+ (instancetype)body;
+ (instancetype)label;
- (instancetype)alignedTo: (AsyncUITextHorizontalAlignment)alignment;
- (instancetype)fontSize: (uint16_t)fontSize
              lineHeight: (uint16_t)lineHeight;
- (instancetype)colored: (AsyncUIColorValue *)color;
- (instancetype)wrapped: (AsyncUITextWrapStyle)wrapStyle;
- (instancetype)alignedTo: (AsyncUITextHorizontalAlignment)alignment
                 fontSize: (uint16_t)fontSize
               lineHeight: (uint16_t)lineHeight
                    color: (AsyncUIColorValue *)color;

@end

#pragma clang assume_nonnull end
