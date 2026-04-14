#import "Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@namespace_implementation(AUIComponents)

+ (AUIColor)componentColorWithRed: (uint8_t)red
                            green: (uint8_t)green
                             blue: (uint8_t)blue
                            alpha: (uint8_t)alpha
{
    return [AUI colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (OFArray<id<AUIRenderable>> *)childrenOrEmpty: (OFArray<id<AUIRenderable>> *nillable)children
{
    return children ?: @[];
}

+ (AUIInsets)controlInsetsForSize: (AUIControlSize)size
{
    switch (size) {
        case AUIControlSizeSmall:
            return [AUI insetsWithLeft: 10 right: 10 top: 6 bottom: 6];
        case AUIControlSizeLarge:
            return [AUI insetsWithLeft: 18 right: 18 top: 12 bottom: 12];
        case AUIControlSizeMedium:
        default:
            return [AUI insetsWithLeft: 14 right: 14 top: 9 bottom: 9];
    }
}

+ (AUILayoutAxis)controlHeightForSize: (AUIControlSize)size
{
    switch (size) {
        case AUIControlSizeSmall:
            return [AUI axisFixed: 28];
        case AUIControlSizeLarge:
            return [AUI axisFixed: 44];
        case AUIControlSizeMedium:
        default:
            return [AUI axisFixed: 36];
    }
}

+ (uint16_t)controlPointSizeForSize: (AUIControlSize)size
{
    switch (size) {
        case AUIControlSizeSmall:
            return 28;
        case AUIControlSizeLarge:
            return 44;
        case AUIControlSizeMedium:
        default:
            return 36;
    }
}

+ (float)controlCornerRadiusForSize: (AUIControlSize)size
{
    switch (size) {
        case AUIControlSizeSmall:
            return 8;
        case AUIControlSizeLarge:
            return 14;
        case AUIControlSizeMedium:
        default:
            return 10;
    }
}

+ (AUITextStyle)labelTextStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 16;
    style.lineHeight = 20;
    style.color = [self componentColorWithRed: 31 green: 36 blue: 40 alpha: 255];
    return style;
}

+ (AUITextStyle)badgeTextStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 12;
    style.lineHeight = 14;
    style.color = [self componentColorWithRed: 31 green: 36 blue: 40 alpha: 255];
    return style;
}

+ (AUITextStyle)controlTextStyleForSize: (AUIControlSize)size variant: (AUIControlVariant)variant enabled: (bool)enabled
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = (uint16_t)(size == AUIControlSizeSmall ? 13 : (size == AUIControlSizeLarge ? 17 : 15));
    style.lineHeight = (uint16_t)(style.fontSize + 4);
    style.alignment = AUITextAlignmentCenter;
    style.color = enabled ? (variant == AUIControlVariantSecondary || variant == AUIControlVariantNeutral
        ? [self componentColorWithRed: 28 green: 33 blue: 38 alpha: 255]
        : [self componentColorWithRed: 255 green: 255 blue: 255 alpha: 255])
        : [self componentColorWithRed: 150 green: 155 blue: 160 alpha: 255];
    return style;
}

+ (AUITextStyle)inputTextStyleForSize: (AUIControlSize)size
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = (uint16_t)(size == AUIControlSizeSmall ? 13 : (size == AUIControlSizeLarge ? 17 : 15));
    style.lineHeight = (uint16_t)(style.fontSize + 6);
    style.color = [self componentColorWithRed: 28 green: 33 blue: 38 alpha: 255];
    style.alignment = AUITextAlignmentLeft;
    return style;
}

+ (AUIControlColors)controlColorsForVariant: (AUIControlVariant)variant enabled: (bool)enabled
{
    if (enabled == false) {
        return [AUI controlColorsWithNormal: [self componentColorWithRed: 241 green: 243 blue: 245 alpha: 255]
                                      hover: [self componentColorWithRed: 241 green: 243 blue: 245 alpha: 255]
                                     pressed: [self componentColorWithRed: 241 green: 243 blue: 245 alpha: 255]
                                    disabled: [self componentColorWithRed: 241 green: 243 blue: 245 alpha: 255]];
    }

    switch (variant) {
        case AUIControlVariantPrimary:
            return [AUI controlColorsWithNormal: [self componentColorWithRed: 54 green: 101 blue: 185 alpha: 255]
                                          hover: [self componentColorWithRed: 43 green: 89 blue: 170 alpha: 255]
                                         pressed: [self componentColorWithRed: 32 green: 74 blue: 150 alpha: 255]
                                        disabled: [self componentColorWithRed: 184 green: 194 blue: 208 alpha: 255]];
        case AUIControlVariantSecondary:
            return [AUI controlColorsWithNormal: [self componentColorWithRed: 226 green: 229 blue: 234 alpha: 255]
                                          hover: [self componentColorWithRed: 216 green: 220 blue: 226 alpha: 255]
                                         pressed: [self componentColorWithRed: 206 green: 212 blue: 219 alpha: 255]
                                        disabled: [self componentColorWithRed: 236 green: 238 blue: 241 alpha: 255]];
        case AUIControlVariantDanger:
            return [AUI controlColorsWithNormal: [self componentColorWithRed: 200 green: 67 blue: 63 alpha: 255]
                                          hover: [self componentColorWithRed: 184 green: 59 blue: 56 alpha: 255]
                                         pressed: [self componentColorWithRed: 163 green: 50 blue: 48 alpha: 255]
                                        disabled: [self componentColorWithRed: 224 green: 186 blue: 184 alpha: 255]];
        case AUIControlVariantNeutral:
        default:
            return [AUI controlColorsWithNormal: [self componentColorWithRed: 227 green: 230 blue: 234 alpha: 255]
                                          hover: [self componentColorWithRed: 218 green: 222 blue: 227 alpha: 255]
                                         pressed: [self componentColorWithRed: 208 green: 213 blue: 219 alpha: 255]
                                        disabled: [self componentColorWithRed: 236 green: 238 blue: 241 alpha: 255]];
    }
}

+ (AUIBorder)controlBorderForVariant: (AUIControlVariant)variant enabled: (bool)enabled
{
    AUIColor color;

    if (enabled == false)
        color = [self componentColorWithRed: 220 green: 224 blue: 228 alpha: 255];
    else if (variant == AUIControlVariantPrimary || variant == AUIControlVariantDanger)
        color = [self componentColorWithRed: 0 green: 0 blue: 0 alpha: 0];
    else
        color = [self componentColorWithRed: 198 green: 204 blue: 210 alpha: 255];

    return [AUI borderAll: 1 color: color];
}

+ (AUITextInputColors)inputColors
{
    return AUI.defaultTextInputColors;
}

+ (AUIBoxProps)cardBoxProps
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.padding = [AUI insetsWithLeft: 18 right: 18 top: 18 bottom: 18];
    props.layout.childGap = 12;
    props.backgroundColor = [self componentColorWithRed: 247 green: 245 blue: 240 alpha: 255];
    props.cornerRadius = 18;
    props.border = [AUI borderAll: 1 color: [self componentColorWithRed: 226 green: 220 blue: 208 alpha: 255]];
    return props;
}

+ (AUIBoxProps)sectionBoxProps
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.padding = [AUI insetsWithLeft: 0 right: 0 top: 0 bottom: 0];
    props.layout.childGap = 10;
    props.backgroundColor = [self componentColorWithRed: 0 green: 0 blue: 0 alpha: 0];
    props.cornerRadius = 0;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIBoxProps)badgeBoxPropsForVariant: (AUIControlVariant)variant
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.padding = [AUI insetsWithLeft: 10 right: 10 top: 5 bottom: 5];
    props.layout.childGap = 0;
    props.backgroundColor = [self controlColorsForVariant: variant enabled: true].normal;
    props.cornerRadius = 999;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIBoxProps)progressTrackProps
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.padding = [AUI insetsWithLeft: 0 right: 0 top: 0 bottom: 0];
    props.layout.childGap = 0;
    props.backgroundColor = [self componentColorWithRed: 226 green: 229 blue: 234 alpha: 255];
    props.cornerRadius = 999;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIColor)progressFillColorForVariant: (AUIControlVariant)variant
{
    switch (variant) {
        case AUIControlVariantSecondary:
            return [self componentColorWithRed: 70 green: 78 blue: 92 alpha: 255];
        case AUIControlVariantDanger:
            return [self componentColorWithRed: 200 green: 67 blue: 63 alpha: 255];
        case AUIControlVariantNeutral:
            return [self componentColorWithRed: 95 green: 104 blue: 118 alpha: 255];
        case AUIControlVariantPrimary:
        default:
            return [self componentColorWithRed: 54 green: 101 blue: 185 alpha: 255];
    }
}

+ (AUIBorder)dividerBorderWithColor: (AUIColor)color thickness: (uint16_t)thickness
{
    return (AUIBorder){
        .color = color,
        .left = thickness,
        .right = thickness,
        .top = thickness,
        .bottom = thickness,
        .betweenChildren = 0
    };
}

@end

#pragma clang assume_nonnull end
