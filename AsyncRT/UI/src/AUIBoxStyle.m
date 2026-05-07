#import "AUIBoxStyle.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIBoxStyle

- (instancetype)init
{
    self = [super init];
    _backgroundColor = AUIColorValue.clear;
    _cornerRadius = 0;
    _borderStyle = AUIBorderStyle.none;
    return self;
}

+ (instancetype)clear
{
    return [[self alloc] init];
}

+ (instancetype)filled
{
    auto style = [[self alloc] init];
    style.backgroundColor = [AUIColorValue withRed: 245 green: 245 blue: 245 alpha: 255];
    style.cornerRadius = 12;
    style.borderStyle = [AUIBorderStyle all: 1 color: [AUIColorValue withRed: 220 green: 220 blue: 220 alpha: 255]];
    return style;
}

- (instancetype)filledWithColor: (AUIColorValue *)backgroundColor
                   cornerRadius: (float)cornerRadius
                    borderStyle: (AUIBorderStyle *)borderStyle
{
    self.backgroundColor = backgroundColor;
    self.cornerRadius = cornerRadius;
    self.borderStyle = borderStyle;
    return self;
}

@end

#pragma clang assume_nonnull end
