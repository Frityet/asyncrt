#import "AUIControlColors.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIControlColors

+ (instancetype)withNormal: (AUIColorValue *)normalColor
                     hover: (AUIColorValue *)hoverColor
                   pressed: (AUIColorValue *)pressedColor
                  disabled: (AUIColorValue *)disabledColor
{
    auto colors = [[self alloc] init];
    colors.normalColor = normalColor;
    colors.hoverColor = hoverColor;
    colors.pressedColor = pressedColor;
    colors.disabledColor = disabledColor;
    return colors;
}

@end

#pragma clang assume_nonnull end
