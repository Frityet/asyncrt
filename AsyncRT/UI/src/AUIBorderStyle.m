#import "AUIBorderStyle.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIBorderStyle

+ (instancetype)none
{
    auto border = [[self alloc] init];
    border.color = AUIColorValue.clear;
    return border;
}

+ (instancetype)all: (uint16_t)width color: (AUIColorValue *)color
{
    auto border = [[self alloc] init];
    border.color = color;
    border.leftWidth = width;
    border.rightWidth = width;
    border.topWidth = width;
    border.bottomWidth = width;
    return border;
}

@end

#pragma clang assume_nonnull end
