#import "AUIControlStyle.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIControlStyle

- (instancetype)init
{
    self = [super init];
    _contentInsets = [AUIEdgeInsets all: 0];
    _textStyle = AUITextStyle.body;
    _backgroundColors = [AUIControlColors withNormal: [AUIColorValue withRed: 227 green: 230 blue: 234 alpha: 255]
                                               hover: [AUIColorValue withRed: 218 green: 222 blue: 227 alpha: 255]
                                             pressed: [AUIColorValue withRed: 208 green: 213 blue: 219 alpha: 255]
                                            disabled: [AUIColorValue withRed: 236 green: 238 blue: 241 alpha: 255]];
    _borderStyle = AUIBorderStyle.none;
    _cornerRadius = 10;
    _textColor = [AUIColorValue withRed: 28 green: 33 blue: 38 alpha: 255];
    _disabledTextColor = [AUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255];
    _inputBackgroundColor = AUIColorValue.white;
    _disabledInputBackgroundColor = [AUIColorValue withRed: 241 green: 243 blue: 245 alpha: 255];
    _inputBorderColor = [AUIColorValue withRed: 198 green: 204 blue: 210 alpha: 255];
    _focusedInputBorderColor = [AUIColorValue withRed: 54 green: 101 blue: 185 alpha: 255];
    _disabledInputBorderColor = [AUIColorValue withRed: 220 green: 224 blue: 228 alpha: 255];
    _placeholderColor = [AUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255];
    _caretColor = [AUIColorValue withRed: 54 green: 101 blue: 185 alpha: 255];
    return self;
}

+ (instancetype)button
{
    auto style = [[self alloc] init];
    style.contentInsets = [AUIEdgeInsets withLeft: 14 right: 14 top: 9 bottom: 9];
    style.textStyle = AUITextStyle.body;
    style.textStyle.alignment = AUITextHorizontalAlignmentCenter;
    style.borderStyle = [AUIBorderStyle all: 1 color: [AUIColorValue withRed: 198 green: 204 blue: 210 alpha: 255]];
    return style;
}

+ (instancetype)textField
{
    auto style = [[self alloc] init];
    style.contentInsets = [AUIEdgeInsets withLeft: 12 right: 12 top: 10 bottom: 10];
    style.textStyle = AUITextStyle.body;
    style.cornerRadius = 10;
    return style;
}

@end

#pragma clang assume_nonnull end
