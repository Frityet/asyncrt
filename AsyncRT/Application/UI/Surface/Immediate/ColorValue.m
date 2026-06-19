#import <AsyncRT/Application/UI/Surface/Immediate/ColorValue.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIColorValue

+ (instancetype)withRed: (uint8_t)red
                  green: (uint8_t)green
                   blue: (uint8_t)blue
                  alpha: (uint8_t)alpha
{
    return [[self alloc] initWithRed: red green: green blue: blue alpha: alpha];
}

+ (instancetype)clear
{
    return [self withRed: 0 green: 0 blue: 0 alpha: 0];
}

+ (instancetype)white
{
    return [self withRed: 255 green: 255 blue: 255 alpha: 255];
}

+ (instancetype)black
{
    return [self withRed: 0 green: 0 blue: 0 alpha: 255];
}

- (instancetype)initWithRed: (uint8_t)red
                      green: (uint8_t)green
                       blue: (uint8_t)blue
                      alpha: (uint8_t)alpha
{
    self = [super init];
    _red = red;
    _green = green;
    _blue = blue;
    _alpha = alpha;
    return self;
}

@end

#pragma clang assume_nonnull end
