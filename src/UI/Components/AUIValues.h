#pragma once

#import "UI/AUIRenderable.h"
#import "UI/AUIRenderContext.h"

#pragma clang assume_nonnull begin

typedef struct AUIColor {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} AUIColor;

typedef struct AUIInsets {
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
} AUIInsets;

typedef enum AUILayoutAxisKind {
    AUILayoutAxisKindGrow,
    AUILayoutAxisKindFit,
    AUILayoutAxisKindFixed,
    AUILayoutAxisKindPercent
} AUILayoutAxisKind;

typedef struct AUILayoutAxis {
    AUILayoutAxisKind kind;
    float value;
} AUILayoutAxis;

typedef enum AUILayoutDirection {
    AUILayoutDirectionColumn,
    AUILayoutDirectionRow
} AUILayoutDirection;

typedef enum AUIAlignment {
    AUIAlignmentStart,
    AUIAlignmentCenter,
    AUIAlignmentEnd
} AUIAlignment;

typedef struct AUIChildAlignment {
    AUIAlignment x;
    AUIAlignment y;
} AUIChildAlignment;

typedef struct AUILayout {
    AUILayoutAxis width;
    AUILayoutAxis height;
    AUIInsets padding;
    uint16_t childGap;
    AUIChildAlignment childAlignment;
    AUILayoutDirection direction;
} AUILayout;

typedef enum AUIScrollAxis {
    AUIScrollAxisNone,
    AUIScrollAxisHorizontal,
    AUIScrollAxisVertical,
    AUIScrollAxisBoth
} AUIScrollAxis;

typedef struct AUIBorder {
    AUIColor color;
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
    uint16_t betweenChildren;
} AUIBorder;

typedef struct AUIBoxProps {
    AUILayout layout;
    AUIColor backgroundColor;
    float cornerRadius;
    AUIBorder border;
    AUIScrollAxis scrollAxis;
} AUIBoxProps;

typedef enum AUITextWrapMode {
    AUITextWrapModeWords,
    AUITextWrapModeNewlines,
    AUITextWrapModeNone
} AUITextWrapMode;

typedef enum AUITextAlignment {
    AUITextAlignmentLeft,
    AUITextAlignmentCenter,
    AUITextAlignmentRight
} AUITextAlignment;

typedef struct AUITextStyle {
    uint16_t fontID;
    uint16_t fontSize;
    uint16_t letterSpacing;
    uint16_t lineHeight;
    AUIColor color;
    AUITextWrapMode wrapMode;
    AUITextAlignment alignment;
} AUITextStyle;

typedef struct AUITextProps {
    AUITextStyle style;
} AUITextProps;

typedef struct AUIControlColors {
    AUIColor normal;
    AUIColor hover;
    AUIColor pressed;
    AUIColor disabled;
} AUIControlColors;

typedef struct AUITextInputColors {
    AUIColor background;
    AUIColor border;
    AUIColor focusedBorder;
    AUIColor text;
    AUIColor placeholder;
    AUIColor disabledBackground;
    AUIColor disabledBorder;
    AUIColor disabledText;
    AUIColor caret;
} AUITextInputColors;

@namespace(AUI)

+ (AUISize)sizeWithWidth: (float)width height: (float)height;
+ (AUIColor)colorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha;
+ (AUIInsets)insetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom;
+ (AUIInsets)insetsAll: (uint16_t)inset;
+ (AUILayoutAxis)axisGrow: (float)minimumSize;
+ (AUILayoutAxis)axisFit: (float)minimumSize;
+ (AUILayoutAxis)axisFixed: (float)size;
+ (AUILayoutAxis)axisPercent: (float)percent;
+ (AUIChildAlignment)childAlignmentX: (AUIAlignment)x y: (AUIAlignment)y;
+ (AUILayout)layout;
+ (AUIBorder)borderNone;
+ (AUIBorder)borderAll: (uint16_t)width color: (AUIColor)color;
+ (AUIBoxProps)boxProps;
+ (AUITextStyle)textStyle;
+ (AUITextProps)textProps;
+ (AUIControlColors)controlColorsWithNormal: (AUIColor)normal
                                      hover: (AUIColor)hover
                                     pressed: (AUIColor)pressed
                                    disabled: (AUIColor)disabled;
+ (AUITextInputColors)textInputColors;

@end

#pragma clang assume_nonnull end
