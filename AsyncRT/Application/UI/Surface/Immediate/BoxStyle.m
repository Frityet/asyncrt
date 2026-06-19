#import <AsyncRT/Application/UI/Surface/Immediate/BoxStyle.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIBoxStyle

- (instancetype)init
{
    self = [super init];
    _backgroundColor = AsyncUIColorValue.clear;
    _cornerRadius = 0;
    _borderStyle = AsyncUIBorderStyle.none;
    return self;
}

+ (instancetype)clear
{
    return [[self alloc] init];
}

+ (instancetype)filled
{
    auto style = [[self alloc] init];
    style.backgroundColor = [AsyncUIColorValue withRed: 245 green: 245 blue: 245 alpha: 255];
    style.cornerRadius = 12;
    style.borderStyle = [AsyncUIBorderStyle all: 1 color: [AsyncUIColorValue withRed: 220 green: 220 blue: 220 alpha: 255]];
    return style;
}

- (instancetype)filledWithColor: (AsyncUIColorValue *)backgroundColor
                   cornerRadius: (float)cornerRadius
                    borderStyle: (AsyncUIBorderStyle *)borderStyle
{
    self.backgroundColor = backgroundColor;
    self.cornerRadius = cornerRadius;
    self.borderStyle = borderStyle;
    return self;
}

@end

#pragma clang assume_nonnull end
