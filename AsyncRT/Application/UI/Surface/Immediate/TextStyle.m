#import <AsyncRT/Application/UI/Surface/Immediate/TextStyle.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUITextStyle

- (instancetype)init
{
    self = [super init];
    _fontID = 0;
    _fontSize = 16;
    _letterSpacing = 0;
    _lineHeight = 20;
    _color = AsyncUIColorValue.black;
    _wrapStyle = AsyncUITextWrapStyleWords;
    _alignment = AsyncUITextHorizontalAlignmentLeading;
    return self;
}

+ (instancetype)body
{
    return [[self alloc] init];
}

+ (instancetype)label
{
    auto style = [[self alloc] init];
    style.fontSize = 14;
    style.lineHeight = 18;
    style.color = [AsyncUIColorValue withRed: 82 green: 82 blue: 82 alpha: 255];
    return style;
}

- (instancetype)alignedTo: (AsyncUITextHorizontalAlignment)alignment
{
    self.alignment = alignment;
    return self;
}

- (instancetype)fontSize: (uint16_t)fontSize
              lineHeight: (uint16_t)lineHeight
{
    self.fontSize = fontSize;
    self.lineHeight = lineHeight;
    return self;
}

- (instancetype)colored: (AsyncUIColorValue *)color
{
    self.color = color;
    return self;
}

- (instancetype)wrapped: (AsyncUITextWrapStyle)wrapStyle
{
    self.wrapStyle = wrapStyle;
    return self;
}

- (instancetype)alignedTo: (AsyncUITextHorizontalAlignment)alignment
                 fontSize: (uint16_t)fontSize
               lineHeight: (uint16_t)lineHeight
                    color: (AsyncUIColorValue *)color
{
    return [[[self alignedTo: alignment] fontSize: fontSize lineHeight: lineHeight] colored: color];
}

@end

#pragma clang assume_nonnull end
