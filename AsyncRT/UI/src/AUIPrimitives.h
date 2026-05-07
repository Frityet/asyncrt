#pragma once

#import "AUIRenderContext.h"

#pragma clang assume_nonnull begin

typedef struct AUIRawColor {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} AUIRawColor;

typedef struct AUIRawInsets {
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
} AUIRawInsets;

typedef enum AUIRawAxisSizeKind {
    AUIRawAxisSizeKindGrow,
    AUIRawAxisSizeKindFit,
    AUIRawAxisSizeKindFixed,
    AUIRawAxisSizeKindPercent
} AUIRawAxisSizeKind;

typedef struct AUIRawAxisSize {
    AUIRawAxisSizeKind kind;
    float value;
} AUIRawAxisSize;

typedef enum AUIRawLayoutDirection {
    AUIRawLayoutDirectionColumn,
    AUIRawLayoutDirectionRow
} AUIRawLayoutDirection;

typedef enum AUIRawAlignment {
    AUIRawAlignmentStart,
    AUIRawAlignmentCenter,
    AUIRawAlignmentEnd
} AUIRawAlignment;

typedef struct AUIRawChildAlignment {
    AUIRawAlignment x;
    AUIRawAlignment y;
} AUIRawChildAlignment;

typedef struct AUIRawLayout {
    AUIRawAxisSize width;
    AUIRawAxisSize height;
    AUIRawInsets padding;
    uint16_t childGap;
    AUIRawChildAlignment childAlignment;
    AUIRawLayoutDirection direction;
} AUIRawLayout;

typedef enum AUIRawScrollAxis {
    AUIRawScrollAxisNone,
    AUIRawScrollAxisHorizontal,
    AUIRawScrollAxisVertical,
    AUIRawScrollAxisBoth
} AUIRawScrollAxis;

typedef struct AUIRawBorder {
    AUIRawColor color;
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
    uint16_t betweenChildren;
} AUIRawBorder;

typedef struct AUIRawBoxProps {
    AUIRawLayout layout;
    AUIRawColor backgroundColor;
    float cornerRadius;
    AUIRawBorder border;
    AUIRawScrollAxis scrollAxis;
} AUIRawBoxProps;

typedef enum AUIRawTextWrapMode {
    AUIRawTextWrapModeWords,
    AUIRawTextWrapModeNewlines,
    AUIRawTextWrapModeNone
} AUIRawTextWrapMode;

typedef enum AUIRawTextAlignment {
    AUIRawTextAlignmentLeft,
    AUIRawTextAlignmentCenter,
    AUIRawTextAlignmentRight
} AUIRawTextAlignment;

typedef struct AUIRawTextStyle {
    uint16_t fontID;
    uint16_t fontSize;
    uint16_t letterSpacing;
    uint16_t lineHeight;
    AUIRawColor color;
    AUIRawTextWrapMode wrapMode;
    AUIRawTextAlignment alignment;
} AUIRawTextStyle;

typedef struct AUIRawTextProps {
    AUIRawTextStyle style;
} AUIRawTextProps;

typedef struct AUIRawControlColors {
    AUIRawColor normal;
    AUIRawColor hover;
    AUIRawColor pressed;
    AUIRawColor disabled;
} AUIRawControlColors;

typedef struct AUIRawTextInputColors {
    AUIRawColor background;
    AUIRawColor border;
    AUIRawColor focusedBorder;
    AUIRawColor text;
    AUIRawColor placeholder;
    AUIRawColor disabledBackground;
    AUIRawColor disabledBorder;
    AUIRawColor disabledText;
    AUIRawColor caret;
} AUIRawTextInputColors;

@namespace(AUI)

+ (AUISize)sizeWithWidth: (float)width height: (float)height;
+ (AUIRawColor)rawColorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha;
+ (AUIRawInsets)rawInsetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom;
+ (AUIRawInsets)rawInsetsAll: (uint16_t)inset;
+ (AUIRawAxisSize)rawAxisGrow: (float)minimumSize;
+ (AUIRawAxisSize)rawAxisFit: (float)minimumSize;
+ (AUIRawAxisSize)rawAxisFixed: (float)size;
+ (AUIRawAxisSize)rawAxisPercent: (float)percent;
+ (AUIRawChildAlignment)rawChildAlignmentX: (AUIRawAlignment)x y: (AUIRawAlignment)y;
+ (AUIRawLayout)defaultRawLayout;
+ (AUIRawBorder)rawBorderNone;
+ (AUIRawBorder)rawBorderAll: (uint16_t)width color: (AUIRawColor)color;
+ (AUIRawBoxProps)defaultRawBoxProps;
+ (AUIRawTextStyle)defaultRawTextStyle;
+ (AUIRawTextProps)defaultRawTextProps;
+ (AUIRawControlColors)rawControlColorsWithNormal: (AUIRawColor)normal
                                             hover: (AUIRawColor)hover
                                           pressed: (AUIRawColor)pressed
                                          disabled: (AUIRawColor)disabled;
+ (AUIRawTextInputColors)defaultRawTextInputColors;

@end

#pragma clang assume_nonnull end
