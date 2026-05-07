#import "AUIPrimitives.h"

#pragma clang assume_nonnull begin

@namespace_implementation(AUI)

+ (AUISize)sizeWithWidth: (float)width height: (float)height
{
    return (AUISize){
        .width = width,
        .height = height
    };
}

+ (AUIRawColor)rawColorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha
{
    return (AUIRawColor){
        .red = red,
        .green = green,
        .blue = blue,
        .alpha = alpha
    };
}

+ (AUIRawInsets)rawInsetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom
{
    return (AUIRawInsets){
        .left = left,
        .right = right,
        .top = top,
        .bottom = bottom
    };
}

+ (AUIRawInsets)rawInsetsAll: (uint16_t)inset
{
    return [self rawInsetsWithLeft: inset right: inset top: inset bottom: inset];
}

+ (AUIRawAxisSize)rawAxisGrow: (float)minimumSize
{
    return (AUIRawAxisSize){ .kind = AUIRawAxisSizeKindGrow, .value = minimumSize };
}

+ (AUIRawAxisSize)rawAxisFit: (float)minimumSize
{
    return (AUIRawAxisSize){ .kind = AUIRawAxisSizeKindFit, .value = minimumSize };
}

+ (AUIRawAxisSize)rawAxisFixed: (float)size
{
    return (AUIRawAxisSize){ .kind = AUIRawAxisSizeKindFixed, .value = size };
}

+ (AUIRawAxisSize)rawAxisPercent: (float)percent
{
    return (AUIRawAxisSize){ .kind = AUIRawAxisSizeKindPercent, .value = percent };
}

+ (AUIRawChildAlignment)rawChildAlignmentX: (AUIRawAlignment)x y: (AUIRawAlignment)y
{
    return (AUIRawChildAlignment){
        .x = x,
        .y = y
    };
}

+ (AUIRawLayout)defaultRawLayout
{
    return (AUIRawLayout){
        .width = [self rawAxisGrow: 0],
        .height = [self rawAxisFit: 0],
        .padding = [self rawInsetsAll: 0],
        .childGap = 0,
        .childAlignment = [self rawChildAlignmentX: AUIRawAlignmentStart y: AUIRawAlignmentStart],
        .direction = AUIRawLayoutDirectionColumn
    };
}

+ (AUIRawBorder)rawBorderNone
{
    return (AUIRawBorder){
        .color = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0,
        .betweenChildren = 0
    };
}

+ (AUIRawBorder)rawBorderAll: (uint16_t)width color: (AUIRawColor)color
{
    return (AUIRawBorder){
        .color = color,
        .left = width,
        .right = width,
        .top = width,
        .bottom = width,
        .betweenChildren = 0
    };
}

+ (AUIRawBoxProps)defaultRawBoxProps
{
    return (AUIRawBoxProps){
        .layout = [self defaultRawLayout],
        .backgroundColor = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .cornerRadius = 0,
        .border = [self rawBorderNone],
        .scrollAxis = AUIRawScrollAxisNone
    };
}

+ (AUIRawTextStyle)defaultRawTextStyle
{
    return (AUIRawTextStyle){
        .fontID = 0,
        .fontSize = 16,
        .letterSpacing = 0,
        .lineHeight = 20,
        .color = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 255],
        .wrapMode = AUIRawTextWrapModeWords,
        .alignment = AUIRawTextAlignmentLeft
    };
}

+ (AUIRawTextProps)defaultRawTextProps
{
    return (AUIRawTextProps){
        .style = [self defaultRawTextStyle]
    };
}

+ (AUIRawControlColors)rawControlColorsWithNormal: (AUIRawColor)normal
                                             hover: (AUIRawColor)hover
                                           pressed: (AUIRawColor)pressed
                                          disabled: (AUIRawColor)disabled
{
    return (AUIRawControlColors){
        .normal = normal,
        .hover = hover,
        .pressed = pressed,
        .disabled = disabled
    };
}

+ (AUIRawTextInputColors)defaultRawTextInputColors
{
    return (AUIRawTextInputColors){
        .background = [self rawColorWithRed: 255 green: 255 blue: 255 alpha: 255],
        .border = [self rawColorWithRed: 198 green: 204 blue: 210 alpha: 255],
        .focusedBorder = [self rawColorWithRed: 54 green: 101 blue: 185 alpha: 255],
        .text = [self rawColorWithRed: 28 green: 33 blue: 38 alpha: 255],
        .placeholder = [self rawColorWithRed: 150 green: 155 blue: 160 alpha: 255],
        .disabledBackground = [self rawColorWithRed: 241 green: 243 blue: 245 alpha: 255],
        .disabledBorder = [self rawColorWithRed: 220 green: 224 blue: 228 alpha: 255],
        .disabledText = [self rawColorWithRed: 150 green: 155 blue: 160 alpha: 255],
        .caret = [self rawColorWithRed: 54 green: 101 blue: 185 alpha: 255]
    };
}

@end

#pragma clang assume_nonnull end
