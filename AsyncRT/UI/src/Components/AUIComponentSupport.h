#pragma once

#import "AUIPrimitives.h"

#pragma clang assume_nonnull begin

typedef enum AUIControlSize {
    AUIControlSizeSmall,
    AUIControlSizeMedium,
    AUIControlSizeLarge
} AUIControlSize;

typedef enum AUIControlVariant {
    AUIControlVariantNeutral,
    AUIControlVariantPrimary,
    AUIControlVariantSecondary,
    AUIControlVariantDanger
} AUIControlVariant;

@namespace(AUIComponents)

+ (OFArray<id<AUIRenderable>> *)childrenOrEmpty: (OFArray<id<AUIRenderable>> *nillable)children;
+ (AUIInsets)controlInsetsForSize: (AUIControlSize)size;
+ (AUILayoutAxis)controlHeightForSize: (AUIControlSize)size;
+ (uint16_t)controlPointSizeForSize: (AUIControlSize)size;
+ (float)controlCornerRadiusForSize: (AUIControlSize)size;
+ (AUITextStyle)labelTextStyle;
+ (AUITextStyle)badgeTextStyle;
+ (AUITextStyle)controlTextStyleForSize: (AUIControlSize)size variant: (AUIControlVariant)variant enabled: (bool)enabled;
+ (AUITextStyle)inputTextStyleForSize: (AUIControlSize)size;
+ (AUIControlColors)controlColorsForVariant: (AUIControlVariant)variant enabled: (bool)enabled;
+ (AUIBorder)controlBorderForVariant: (AUIControlVariant)variant enabled: (bool)enabled;
+ (AUITextInputColors)inputColors;
+ (AUIBoxProps)cardBoxProps;
+ (AUIBoxProps)sectionBoxProps;
+ (AUIBoxProps)badgeBoxPropsForVariant: (AUIControlVariant)variant;
+ (AUIBoxProps)progressTrackProps;
+ (AUIColor)progressFillColorForVariant: (AUIControlVariant)variant;
+ (AUIBorder)dividerBorderWithColor: (AUIColor)color thickness: (uint16_t)thickness;

@end

#pragma clang assume_nonnull end
