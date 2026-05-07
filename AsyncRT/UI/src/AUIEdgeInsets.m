#import "AUIEdgeInsets.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIEdgeInsets

+ (instancetype)withLeft: (uint16_t)left
                   right: (uint16_t)right
                     top: (uint16_t)top
                  bottom: (uint16_t)bottom
{
    auto insets = [[self alloc] init];
    insets.left = left;
    insets.right = right;
    insets.top = top;
    insets.bottom = bottom;
    return insets;
}

+ (instancetype)all: (uint16_t)inset
{
    return [self withLeft: inset right: inset top: inset bottom: inset];
}

@end

#pragma clang assume_nonnull end
