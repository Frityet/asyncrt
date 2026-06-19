#import <AsyncRT/Application/UI/Surface/Immediate/ControlStyle.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIControlStyle

- (instancetype)init
{
    self = [super init];
    _contentInsets = [AsyncUIEdgeInsets all: 0];
    _textStyle = AsyncUITextStyle.body;
    _backgroundColors = [AsyncUIControlColors withNormal: [AsyncUIColorValue withRed: 227 green: 230 blue: 234 alpha: 255]
                                               hover: [AsyncUIColorValue withRed: 218 green: 222 blue: 227 alpha: 255]
                                             pressed: [AsyncUIColorValue withRed: 208 green: 213 blue: 219 alpha: 255]
                                            disabled: [AsyncUIColorValue withRed: 236 green: 238 blue: 241 alpha: 255]];
    _borderStyle = AsyncUIBorderStyle.none;
    _cornerRadius = 10;
    _textColor = [AsyncUIColorValue withRed: 28 green: 33 blue: 38 alpha: 255];
    _disabledTextColor = [AsyncUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255];
    _inputBackgroundColor = AsyncUIColorValue.white;
    _disabledInputBackgroundColor = [AsyncUIColorValue withRed: 241 green: 243 blue: 245 alpha: 255];
    _inputBorderColor = [AsyncUIColorValue withRed: 198 green: 204 blue: 210 alpha: 255];
    _focusedInputBorderColor = [AsyncUIColorValue withRed: 54 green: 101 blue: 185 alpha: 255];
    _disabledInputBorderColor = [AsyncUIColorValue withRed: 220 green: 224 blue: 228 alpha: 255];
    _placeholderColor = [AsyncUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255];
    _caretColor = [AsyncUIColorValue withRed: 54 green: 101 blue: 185 alpha: 255];
    return self;
}

+ (instancetype)button
{
    auto style = [[self alloc] init];
    style.contentInsets = [AsyncUIEdgeInsets withLeft: 14 right: 14 top: 9 bottom: 9];
    style.textStyle = AsyncUITextStyle.body;
    style.textStyle.alignment = AsyncUITextHorizontalAlignmentCenter;
    style.borderStyle = [AsyncUIBorderStyle all: 1 color: [AsyncUIColorValue withRed: 198 green: 204 blue: 210 alpha: 255]];
    return style;
}

+ (instancetype)textField
{
    auto style = [[self alloc] init];
    style.contentInsets = [AsyncUIEdgeInsets withLeft: 12 right: 12 top: 10 bottom: 10];
    style.textStyle = AsyncUITextStyle.body;
    style.cornerRadius = 10;
    return style;
}

@end

#pragma clang assume_nonnull end
