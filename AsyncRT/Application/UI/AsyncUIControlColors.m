#import <AsyncRT/Application/UI/AsyncUIControlColors.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIControlColors

+ (instancetype)withNormal: (AsyncUIColorValue *)normalColor
                     hover: (AsyncUIColorValue *)hoverColor
                   pressed: (AsyncUIColorValue *)pressedColor
                  disabled: (AsyncUIColorValue *)disabledColor
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
