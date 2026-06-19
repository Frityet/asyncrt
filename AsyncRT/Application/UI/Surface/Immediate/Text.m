#import <AsyncRT/Application/UI/Surface/Immediate/Text.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIText

+ (instancetype)withString: (OFString *)string
                  styledBy: (AsyncUITextStyle *)style
{
    return [[self alloc] initWithString: string style: style];
}

- (instancetype)initWithString: (OFString *)string
                         style: (AsyncUITextStyle *)style
{
    self = [super init];
    _string = [string copy];
    _style = style;
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindText;
}

@end

#pragma clang assume_nonnull end
