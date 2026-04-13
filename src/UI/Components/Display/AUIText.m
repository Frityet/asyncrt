#include <stdarg.h>

#import "UI/Components/Display/AUIText.h"

#pragma clang assume_nonnull begin

@namespace(AUITextSupport)

+ (OFString *nillable)formattedStringWithFormat: (OFConstantString *nillable)format
                                     arguments: (va_list)arguments;

@end

@namespace_implementation(AUITextSupport)

+ (OFString *nillable)formattedStringWithFormat: (OFConstantString *nillable)format
                                     arguments: (va_list)arguments
{
    if (format == nilptr)
        @throw [OFInvalidArgumentException exception];

    return [[OFString alloc] initWithFormat: $assert_nonnil(format) arguments: arguments];
}

@end

@interface AUIText ()

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)style [[designated_initailiser]];

@end

@implementation AUIText {
    OFString *nillable _text;
    AUITextStyle _style;
}


+ (instancetype)string: (OFString *nillable)text
{
    return [[self alloc] initWithText: text style: [AUI textStyle]];
}

+ (instancetype)string: (OFString *nillable)text style: (AUITextStyle)style
{
    return [[self alloc] initWithText: text style: style];
}

+ (instancetype)format: (OFConstantString *nillable)format, ...
{
    va_list arguments;
    OFString *nillable text;

    va_start(arguments, format);
    text = [AUITextSupport formattedStringWithFormat: format arguments: arguments];
    va_end(arguments);

    return [[self alloc] initWithText: text style: [AUI textStyle]];
}

+ (instancetype)style: (AUITextStyle)style format: (OFConstantString *nillable)format, ...
{
    va_list arguments;
    OFString *nillable text;

    va_start(arguments, format);
    text = [AUITextSupport formattedStringWithFormat: format arguments: arguments];
    va_end(arguments);

    return [[self alloc] initWithText: text style: style];
}

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)style
{
    self = [super init];
    _text = [text copy];
    _style = style;
    return self;
}

@end

#pragma clang assume_nonnull end
