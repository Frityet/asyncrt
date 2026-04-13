#import "UI/Components/Display/AUIBadge.h"

#pragma clang assume_nonnull begin

@interface AUIBadge ()

- (instancetype)initWithText: (OFString *nillable)text
                     variant: (AUIControlVariant)variant designated_initaliser;

@end

@implementation AUIBadge {
    OFString *_text;
    AUIControlVariant _variant;
}

@synthesize text = _text;
@synthesize variant = _variant;

+ (instancetype)text: (OFString *nillable)text
{
    return [[self alloc] initWithText: text variant: AUIControlVariantNeutral];
}

+ (instancetype)text: (OFString *nillable)text variant: (AUIControlVariant)variant
{
    return [[self alloc] initWithText: text variant: variant];
}

- (instancetype)initWithText: (OFString *nillable)text
                     variant: (AUIControlVariant)variant
{
    if (text == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _text = [$assert_nonnil(text) copy];
    _variant = variant;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUIBoxProps props = [AUIComponents badgeBoxPropsForVariant: _variant];
    AUITextStyle style = [AUIComponents badgeTextStyle];

    if (_variant == AUIControlVariantPrimary || _variant == AUIControlVariantDanger)
        style.color = [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255];

    return [AUIBox layout: props.layout
               background: props.backgroundColor
                   radius: props.cornerRadius
                   border: props.border
                 children: @[
        [AUIText string: _text style: style]
    ]];
}

@end

#pragma clang assume_nonnull end
