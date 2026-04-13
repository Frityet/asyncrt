#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

static AUIColor AUIComponentColor(uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
{
    return [AUI colorWithRed: red green: green blue: blue alpha: alpha];
}

@namespace_implementation(AUIComponents)

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
    AUITextStyle style = [AUI textStyle];
    style.fontSize = 16;
    style.lineHeight = 20;
    style.color = AUIComponentColor(31, 36, 40, 255);
    return style;
}

+ (AUITextStyle)badgeTextStyle
{
    AUITextStyle style = [AUI textStyle];
    style.fontSize = 12;
    style.lineHeight = 14;
    style.color = AUIComponentColor(31, 36, 40, 255);
    return style;
}

+ (AUITextStyle)controlTextStyleForSize: (AUIControlSize)size variant: (AUIControlVariant)variant enabled: (bool)enabled
{
    AUITextStyle style = [AUI textStyle];
    style.fontSize = (uint16_t)(size == AUIControlSizeSmall ? 13 : (size == AUIControlSizeLarge ? 17 : 15));
    style.lineHeight = (uint16_t)(style.fontSize + 4);
    style.alignment = AUITextAlignmentCenter;
    style.color = enabled ? (variant == AUIControlVariantSecondary || variant == AUIControlVariantNeutral
        ? AUIComponentColor(28, 33, 38, 255)
        : AUIComponentColor(255, 255, 255, 255))
        : AUIComponentColor(150, 155, 160, 255);
    return style;
}

+ (AUITextStyle)inputTextStyleForSize: (AUIControlSize)size
{
    AUITextStyle style = [AUI textStyle];
    style.fontSize = (uint16_t)(size == AUIControlSizeSmall ? 13 : (size == AUIControlSizeLarge ? 17 : 15));
    style.lineHeight = (uint16_t)(style.fontSize + 6);
    style.color = AUIComponentColor(28, 33, 38, 255);
    style.alignment = AUITextAlignmentLeft;
    return style;
}

+ (AUIControlColors)controlColorsForVariant: (AUIControlVariant)variant enabled: (bool)enabled
{
    if (enabled == false) {
        return [AUI controlColorsWithNormal: AUIComponentColor(241, 243, 245, 255)
                                      hover: AUIComponentColor(241, 243, 245, 255)
                                     pressed: AUIComponentColor(241, 243, 245, 255)
                                    disabled: AUIComponentColor(241, 243, 245, 255)];
    }

    switch (variant) {
        case AUIControlVariantPrimary:
            return [AUI controlColorsWithNormal: AUIComponentColor(54, 101, 185, 255)
                                          hover: AUIComponentColor(43, 89, 170, 255)
                                         pressed: AUIComponentColor(32, 74, 150, 255)
                                        disabled: AUIComponentColor(184, 194, 208, 255)];
        case AUIControlVariantSecondary:
            return [AUI controlColorsWithNormal: AUIComponentColor(226, 229, 234, 255)
                                          hover: AUIComponentColor(216, 220, 226, 255)
                                         pressed: AUIComponentColor(206, 212, 219, 255)
                                        disabled: AUIComponentColor(236, 238, 241, 255)];
        case AUIControlVariantDanger:
            return [AUI controlColorsWithNormal: AUIComponentColor(200, 67, 63, 255)
                                          hover: AUIComponentColor(184, 59, 56, 255)
                                         pressed: AUIComponentColor(163, 50, 48, 255)
                                        disabled: AUIComponentColor(224, 186, 184, 255)];
        case AUIControlVariantNeutral:
        default:
            return [AUI controlColorsWithNormal: AUIComponentColor(227, 230, 234, 255)
                                          hover: AUIComponentColor(218, 222, 227, 255)
                                         pressed: AUIComponentColor(208, 213, 219, 255)
                                        disabled: AUIComponentColor(236, 238, 241, 255)];
    }
}

+ (AUIBorder)controlBorderForVariant: (AUIControlVariant)variant enabled: (bool)enabled
{
    AUIColor color;

    if (enabled == false)
        color = AUIComponentColor(220, 224, 228, 255);
    else if (variant == AUIControlVariantPrimary || variant == AUIControlVariantDanger)
        color = AUIComponentColor(0, 0, 0, 0);
    else
        color = AUIComponentColor(198, 204, 210, 255);

    return [AUI borderAll: 1 color: color];
}

+ (AUITextInputColors)inputColors
{
    return [AUI textInputColors];
}

+ (AUIBoxProps)cardBoxProps
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.padding = [AUI insetsWithLeft: 18 right: 18 top: 18 bottom: 18];
    props.layout.childGap = 12;
    props.backgroundColor = AUIComponentColor(247, 245, 240, 255);
    props.cornerRadius = 18;
    props.border = [AUI borderAll: 1 color: AUIComponentColor(226, 220, 208, 255)];
    return props;
}

+ (AUIBoxProps)sectionBoxProps
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.padding = [AUI insetsWithLeft: 0 right: 0 top: 0 bottom: 0];
    props.layout.childGap = 10;
    props.backgroundColor = AUIComponentColor(0, 0, 0, 0);
    props.cornerRadius = 0;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIBoxProps)badgeBoxPropsForVariant: (AUIControlVariant)variant
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.padding = [AUI insetsWithLeft: 10 right: 10 top: 5 bottom: 5];
    props.layout.childGap = 0;
    props.backgroundColor = [self controlColorsForVariant: variant enabled: true].normal;
    props.cornerRadius = 999;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIBoxProps)progressTrackProps
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.padding = [AUI insetsWithLeft: 0 right: 0 top: 0 bottom: 0];
    props.layout.childGap = 0;
    props.backgroundColor = AUIComponentColor(226, 229, 234, 255);
    props.cornerRadius = 999;
    props.border = [AUI borderNone];
    return props;
}

+ (AUIColor)progressFillColorForVariant: (AUIControlVariant)variant
{
    switch (variant) {
        case AUIControlVariantSecondary:
            return AUIComponentColor(70, 78, 92, 255);
        case AUIControlVariantDanger:
            return AUIComponentColor(200, 67, 63, 255);
        case AUIControlVariantNeutral:
            return AUIComponentColor(95, 104, 118, 255);
        case AUIControlVariantPrimary:
        default:
            return AUIComponentColor(54, 101, 185, 255);
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
