#import "Components/AUIValues.h"

#pragma clang assume_nonnull begin

@namespace_implementation(AUI)

+ (AUISize)sizeWithWidth: (float)width height: (float)height
{
    return (AUISize){ width, height };
}

+ (AUIColor)colorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha
{
    return (AUIColor){ red, green, blue, alpha };
}

+ (AUIInsets)insetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom
{
    return (AUIInsets){ left, right, top, bottom };
}

+ (AUIInsets)insetsAll: (uint16_t)inset
{
    return [self insetsWithLeft: inset right: inset top: inset bottom: inset];
}

+ (AUILayoutAxis)axisGrow: (float)minimumSize
{
    return (AUILayoutAxis){ .kind = AUILayoutAxisKindGrow, .value = minimumSize };
}

+ (AUILayoutAxis)axisFit: (float)minimumSize
{
    return (AUILayoutAxis){ .kind = AUILayoutAxisKindFit, .value = minimumSize };
}

+ (AUILayoutAxis)axisFixed: (float)size
{
    return (AUILayoutAxis){ .kind = AUILayoutAxisKindFixed, .value = size };
}

+ (AUILayoutAxis)axisPercent: (float)percent
{
    return (AUILayoutAxis){ .kind = AUILayoutAxisKindPercent, .value = percent };
}

+ (AUIChildAlignment)childAlignmentX: (AUIAlignment)x y: (AUIAlignment)y
{
    return (AUIChildAlignment){ x, y };
}

+ (AUILayout)defaultLayout
{
    return (AUILayout){
        .width = [self axisGrow: 0],
        .height = [self axisFit: 0],
        .padding = [self insetsWithLeft: 0 right: 0 top: 0 bottom: 0],
        .childGap = 0,
        .childAlignment = [self childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
        .direction = AUILayoutDirectionColumn
    };
}

+ (AUIBorder)borderNone
{
    return (AUIBorder){
        .color = [self colorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0,
        .betweenChildren = 0
    };
}

+ (AUIBorder)borderAll: (uint16_t)width color: (AUIColor)color
{
    return (AUIBorder){
        .color = color,
        .left = width,
        .right = width,
        .top = width,
        .bottom = width,
        .betweenChildren = 0
    };
}

+ (AUIBoxProps)defaultBoxProps
{
    return (AUIBoxProps){
        .layout = [self defaultLayout],
        .backgroundColor = [self colorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .cornerRadius = 0,
        .border = [self borderNone],
        .scrollAxis = AUIScrollAxisNone
    };
}

+ (AUITextStyle)defaultTextStyle
{
    return (AUITextStyle){
        .fontID = 0,
        .fontSize = 16,
        .letterSpacing = 0,
        .lineHeight = 0,
        .color = [self colorWithRed: 24 green: 24 blue: 24 alpha: 255],
        .wrapMode = AUITextWrapModeWords,
        .alignment = AUITextAlignmentLeft
    };
}

+ (AUITextProps)defaultTextProps
{
    return (AUITextProps){ .style = [self defaultTextStyle] };
}

+ (AUIControlColors)controlColorsWithNormal: (AUIColor)normal
                                      hover: (AUIColor)hover
                                     pressed: (AUIColor)pressed
                                    disabled: (AUIColor)disabled
{
    return (AUIControlColors){
        .normal = normal,
        .hover = hover,
        .pressed = pressed,
        .disabled = disabled
    };
}

+ (AUITextInputColors)defaultTextInputColors
{
    return (AUITextInputColors){
        .background = [self colorWithRed: 255 green: 255 blue: 255 alpha: 255],
        .border = [self colorWithRed: 198 green: 204 blue: 210 alpha: 255],
        .focusedBorder = [self colorWithRed: 72 green: 118 blue: 177 alpha: 255],
        .text = [self colorWithRed: 28 green: 33 blue: 38 alpha: 255],
        .placeholder = [self colorWithRed: 126 green: 133 blue: 140 alpha: 255],
        .disabledBackground = [self colorWithRed: 241 green: 243 blue: 245 alpha: 255],
        .disabledBorder = [self colorWithRed: 220 green: 224 blue: 228 alpha: 255],
        .disabledText = [self colorWithRed: 150 green: 155 blue: 160 alpha: 255],
        .caret = [self colorWithRed: 28 green: 33 blue: 38 alpha: 255]
    };
}

@end

#pragma clang assume_nonnull end
