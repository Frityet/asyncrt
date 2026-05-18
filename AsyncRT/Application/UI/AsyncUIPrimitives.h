#pragma once

#import <AsyncRT/Application/UI/AsyncUIRenderContext.h>

#pragma clang assume_nonnull begin

typedef struct AsyncUIRawColor {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} AsyncUIRawColor;

typedef struct AsyncUIRawInsets {
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
} AsyncUIRawInsets;

typedef enum AsyncUIRawAxisSizeKind {
    AsyncUIRawAxisSizeKindGrow,
    AsyncUIRawAxisSizeKindFit,
    AsyncUIRawAxisSizeKindFixed,
    AsyncUIRawAxisSizeKindPercent
} AsyncUIRawAxisSizeKind;

typedef struct AsyncUIRawAxisSize {
    AsyncUIRawAxisSizeKind kind;
    float value;
} AsyncUIRawAxisSize;

typedef enum AsyncUIRawLayoutDirection {
    AsyncUIRawLayoutDirectionColumn,
    AsyncUIRawLayoutDirectionRow
} AsyncUIRawLayoutDirection;

typedef enum AsyncUIRawAlignment {
    AsyncUIRawAlignmentStart,
    AsyncUIRawAlignmentCenter,
    AsyncUIRawAlignmentEnd
} AsyncUIRawAlignment;

typedef struct AsyncUIRawChildAlignment {
    AsyncUIRawAlignment x;
    AsyncUIRawAlignment y;
} AsyncUIRawChildAlignment;

typedef struct AsyncUIRawLayout {
    AsyncUIRawAxisSize width;
    AsyncUIRawAxisSize height;
    AsyncUIRawInsets padding;
    uint16_t childGap;
    AsyncUIRawChildAlignment childAlignment;
    AsyncUIRawLayoutDirection direction;
} AsyncUIRawLayout;

typedef enum AsyncUIRawScrollAxis {
    AsyncUIRawScrollAxisNone,
    AsyncUIRawScrollAxisHorizontal,
    AsyncUIRawScrollAxisVertical,
    AsyncUIRawScrollAxisBoth
} AsyncUIRawScrollAxis;

typedef struct AsyncUIRawBorder {
    AsyncUIRawColor color;
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
    uint16_t betweenChildren;
} AsyncUIRawBorder;

typedef struct AsyncUIRawBoxProps {
    AsyncUIRawLayout layout;
    AsyncUIRawColor backgroundColor;
    float cornerRadius;
    AsyncUIRawBorder border;
    AsyncUIRawScrollAxis scrollAxis;
} AsyncUIRawBoxProps;

typedef enum AsyncUIRawTextWrapMode {
    AsyncUIRawTextWrapModeWords,
    AsyncUIRawTextWrapModeNewlines,
    AsyncUIRawTextWrapModeNone
} AsyncUIRawTextWrapMode;

typedef enum AsyncUIRawTextAlignment {
    AsyncUIRawTextAlignmentLeft,
    AsyncUIRawTextAlignmentCenter,
    AsyncUIRawTextAlignmentRight
} AsyncUIRawTextAlignment;

typedef struct AsyncUIRawTextStyle {
    uint16_t fontID;
    uint16_t fontSize;
    uint16_t letterSpacing;
    uint16_t lineHeight;
    AsyncUIRawColor color;
    AsyncUIRawTextWrapMode wrapMode;
    AsyncUIRawTextAlignment alignment;
} AsyncUIRawTextStyle;

typedef struct AsyncUIRawTextProps {
    AsyncUIRawTextStyle style;
} AsyncUIRawTextProps;

typedef struct AsyncUIRawControlColors {
    AsyncUIRawColor normal;
    AsyncUIRawColor hover;
    AsyncUIRawColor pressed;
    AsyncUIRawColor disabled;
} AsyncUIRawControlColors;

typedef struct AsyncUIRawTextInputColors {
    AsyncUIRawColor background;
    AsyncUIRawColor border;
    AsyncUIRawColor focusedBorder;
    AsyncUIRawColor text;
    AsyncUIRawColor placeholder;
    AsyncUIRawColor disabledBackground;
    AsyncUIRawColor disabledBorder;
    AsyncUIRawColor disabledText;
    AsyncUIRawColor caret;
} AsyncUIRawTextInputColors;

@namespace(AsyncUI)

+ (AsyncUISize)sizeWithWidth: (float)width height: (float)height;
+ (AsyncUIRawColor)rawColorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha;
+ (AsyncUIRawInsets)rawInsetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom;
+ (AsyncUIRawInsets)rawInsetsAll: (uint16_t)inset;
+ (AsyncUIRawAxisSize)rawAxisGrow: (float)minimumSize;
+ (AsyncUIRawAxisSize)rawAxisFit: (float)minimumSize;
+ (AsyncUIRawAxisSize)rawAxisFixed: (float)size;
+ (AsyncUIRawAxisSize)rawAxisPercent: (float)percent;
+ (AsyncUIRawChildAlignment)rawChildAlignmentX: (AsyncUIRawAlignment)x y: (AsyncUIRawAlignment)y;
+ (AsyncUIRawLayout)defaultRawLayout;
+ (AsyncUIRawBorder)rawBorderNone;
+ (AsyncUIRawBorder)rawBorderAll: (uint16_t)width color: (AsyncUIRawColor)color;
+ (AsyncUIRawBoxProps)defaultRawBoxProps;
+ (AsyncUIRawTextStyle)defaultRawTextStyle;
+ (AsyncUIRawTextProps)defaultRawTextProps;
+ (AsyncUIRawControlColors)rawControlColorsWithNormal: (AsyncUIRawColor)normal
                                             hover: (AsyncUIRawColor)hover
                                           pressed: (AsyncUIRawColor)pressed
                                          disabled: (AsyncUIRawColor)disabled;
+ (AsyncUIRawTextInputColors)defaultRawTextInputColors;

@end

#pragma clang assume_nonnull end
