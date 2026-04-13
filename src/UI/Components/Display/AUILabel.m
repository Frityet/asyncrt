#import "UI/Components/Display/AUILabel.h"

#pragma clang assume_nonnull begin

@interface AUILabel ()

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)style designated_initaliser;

@end

@implementation AUILabel {
    OFString *nillable _text;
    AUITextStyle _style;
}

@synthesize text = _text;
@synthesize style = _style;

+ (instancetype)text: (OFString *nillable)text
{
    return [[self alloc] initWithText: text style: [AUIComponents labelTextStyle]];
}

+ (instancetype)text: (OFString *nillable)text style: (AUITextStyle)style
{
    return [[self alloc] initWithText: text style: style];
}

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)style
{
    self = [super init];
    _text = [text copy];
    _style = style;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    return [AUIText string: _text style: _style];
}

@end

#pragma clang assume_nonnull end
