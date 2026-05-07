#pragma once

#import "AUIColorValue.h"

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AUITextWrapStyle {
    AUITextWrapStyleWords,
    AUITextWrapStyleNewlines,
    AUITextWrapStyleNone
} AUITextWrapStyle;

typedef enum [[clang::enum_extensibility(closed)]] AUITextHorizontalAlignment {
    AUITextHorizontalAlignmentLeading,
    AUITextHorizontalAlignmentCenter,
    AUITextHorizontalAlignmentTrailing
} AUITextHorizontalAlignment;

[[subclassing_restricted, direct_members]]
@interface AUITextStyle : OFObject

@property(nonatomic) uint16_t fontID;
@property(nonatomic) uint16_t fontSize;
@property(nonatomic) uint16_t letterSpacing;
@property(nonatomic) uint16_t lineHeight;
@property(retain, nonatomic) AUIColorValue *color;
@property(nonatomic) AUITextWrapStyle wrapStyle;
@property(nonatomic) AUITextHorizontalAlignment alignment;
@property(class, readonly, nonatomic) AUITextStyle *body;
@property(class, readonly, nonatomic) AUITextStyle *label;

+ (instancetype)body;
+ (instancetype)label;
- (instancetype)alignedTo: (AUITextHorizontalAlignment)alignment;
- (instancetype)fontSize: (uint16_t)fontSize
              lineHeight: (uint16_t)lineHeight;
- (instancetype)colored: (AUIColorValue *)color;
- (instancetype)wrapped: (AUITextWrapStyle)wrapStyle;
- (instancetype)alignedTo: (AUITextHorizontalAlignment)alignment
                 fontSize: (uint16_t)fontSize
               lineHeight: (uint16_t)lineHeight
                    color: (AUIColorValue *)color;

@end

#pragma clang assume_nonnull end
