#import <AsyncRT/Application/UI/AsyncUIPrimitives.h>

#pragma clang assume_nonnull begin

@namespace_implementation(AsyncUI)

+ (AsyncUISize)sizeWithWidth: (float)width height: (float)height
{
    return (AsyncUISize){
        .width = width,
        .height = height
    };
}

+ (AsyncUIRawColor)rawColorWithRed: (uint8_t)red green: (uint8_t)green blue: (uint8_t)blue alpha: (uint8_t)alpha
{
    return (AsyncUIRawColor){
        .red = red,
        .green = green,
        .blue = blue,
        .alpha = alpha
    };
}

+ (AsyncUIRawInsets)rawInsetsWithLeft: (uint16_t)left right: (uint16_t)right top: (uint16_t)top bottom: (uint16_t)bottom
{
    return (AsyncUIRawInsets){
        .left = left,
        .right = right,
        .top = top,
        .bottom = bottom
    };
}

+ (AsyncUIRawInsets)rawInsetsAll: (uint16_t)inset
{
    return [self rawInsetsWithLeft: inset right: inset top: inset bottom: inset];
}

+ (AsyncUIRawAxisSize)rawAxisGrow: (float)minimumSize
{
    return (AsyncUIRawAxisSize){ .kind = AsyncUIRawAxisSizeKindGrow, .value = minimumSize };
}

+ (AsyncUIRawAxisSize)rawAxisFit: (float)minimumSize
{
    return (AsyncUIRawAxisSize){ .kind = AsyncUIRawAxisSizeKindFit, .value = minimumSize };
}

+ (AsyncUIRawAxisSize)rawAxisFixed: (float)size
{
    return (AsyncUIRawAxisSize){ .kind = AsyncUIRawAxisSizeKindFixed, .value = size };
}

+ (AsyncUIRawAxisSize)rawAxisPercent: (float)percent
{
    return (AsyncUIRawAxisSize){ .kind = AsyncUIRawAxisSizeKindPercent, .value = percent };
}

+ (AsyncUIRawChildAlignment)rawChildAlignmentX: (AsyncUIRawAlignment)x y: (AsyncUIRawAlignment)y
{
    return (AsyncUIRawChildAlignment){
        .x = x,
        .y = y
    };
}

+ (AsyncUIRawLayout)defaultRawLayout
{
    return (AsyncUIRawLayout){
        .width = [self rawAxisGrow: 0],
        .height = [self rawAxisFit: 0],
        .padding = [self rawInsetsAll: 0],
        .childGap = 0,
        .childAlignment = [self rawChildAlignmentX: AsyncUIRawAlignmentStart y: AsyncUIRawAlignmentStart],
        .direction = AsyncUIRawLayoutDirectionColumn
    };
}

+ (AsyncUIRawBorder)rawBorderNone
{
    return (AsyncUIRawBorder){
        .color = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0,
        .betweenChildren = 0
    };
}

+ (AsyncUIRawBorder)rawBorderAll: (uint16_t)width color: (AsyncUIRawColor)color
{
    return (AsyncUIRawBorder){
        .color = color,
        .left = width,
        .right = width,
        .top = width,
        .bottom = width,
        .betweenChildren = 0
    };
}

+ (AsyncUIRawBoxProps)defaultRawBoxProps
{
    return (AsyncUIRawBoxProps){
        .layout = [self defaultRawLayout],
        .backgroundColor = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 0],
        .cornerRadius = 0,
        .border = [self rawBorderNone],
        .scrollAxis = AsyncUIRawScrollAxisNone
    };
}

+ (AsyncUIRawTextStyle)defaultRawTextStyle
{
    return (AsyncUIRawTextStyle){
        .fontID = 0,
        .fontSize = 16,
        .letterSpacing = 0,
        .lineHeight = 20,
        .color = [self rawColorWithRed: 0 green: 0 blue: 0 alpha: 255],
        .wrapMode = AsyncUIRawTextWrapModeWords,
        .alignment = AsyncUIRawTextAlignmentLeft
    };
}

+ (AsyncUIRawTextProps)defaultRawTextProps
{
    return (AsyncUIRawTextProps){
        .style = [self defaultRawTextStyle]
    };
}

+ (AsyncUIRawControlColors)rawControlColorsWithNormal: (AsyncUIRawColor)normal
                                             hover: (AsyncUIRawColor)hover
                                           pressed: (AsyncUIRawColor)pressed
                                          disabled: (AsyncUIRawColor)disabled
{
    return (AsyncUIRawControlColors){
        .normal = normal,
        .hover = hover,
        .pressed = pressed,
        .disabled = disabled
    };
}

+ (AsyncUIRawTextInputColors)defaultRawTextInputColors
{
    return (AsyncUIRawTextInputColors){
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
