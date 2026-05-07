#import "AUIText.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIText

+ (instancetype)withString: (OFString *)string
                  styledBy: (AUITextStyle *)style
{
    return [[self alloc] initWithString: string style: style];
}

- (instancetype)initWithString: (OFString *)string
                         style: (AUITextStyle *)style
{
    self = [super init];
    _string = [string copy];
    _style = style;
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindText;
}

@end

#pragma clang assume_nonnull end
