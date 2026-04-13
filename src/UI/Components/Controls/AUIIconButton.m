#import "UI/Components/Controls/AUIIconButton.h"

#pragma clang assume_nonnull begin

@interface AUIIconButton ()

- (instancetype)initWithIcon: (OFString *nillable)icon
                     variant: (AUIControlVariant)variant
                        size: (AUIControlSize)size
                     enabled: (bool)enabled
                     onPress: (void (^nillable)(void))pressHandler [[designated_initailiser]];

@end

@implementation AUIIconButton {
    OFString *_icon;
    AUIControlVariant _variant;
    AUIControlSize _size;
    bool _enabled;
    void (^nillable _pressHandler)(void);
}

@synthesize isEnabled = _enabled;

+ (instancetype)icon: (OFString *nillable)icon
             variant: (AUIControlVariant)variant
                size: (AUIControlSize)size
             enabled: (bool)enabled
             onPress: (void (^nillable)(void))pressHandler
{
    return [[self alloc] initWithIcon: icon
                              variant: variant
                                 size: size
                              enabled: enabled
                              onPress: pressHandler];
}

- (instancetype)initWithIcon: (OFString *nillable)icon
                     variant: (AUIControlVariant)variant
                        size: (AUIControlSize)size
                     enabled: (bool)enabled
                     onPress: (void (^nillable)(void))pressHandler
{
    if (icon == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _icon = [$assert_nonnil(icon) copy];
    _variant = variant;
    _size = size;
    _enabled = enabled;
    _pressHandler = [pressHandler copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];

    layout.width = [AUIComponents controlHeightForSize: _size];
    layout.height = [AUIComponents controlHeightForSize: _size];
    layout.childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter];

    return [AUIInteractiveBox layout: layout
                         backgrounds: [AUIComponents controlColorsForVariant: _variant enabled: _enabled]
                              radius: [AUIComponents controlCornerRadiusForSize: _size]
                              border: [AUIComponents controlBorderForVariant: _variant enabled: _enabled]
                             enabled: _enabled
                           focusable: false
                          onActivate: _pressHandler
                            children: @[
        [AUIText string: _icon
                  style: [AUIComponents controlTextStyleForSize: _size variant: _variant enabled: _enabled]]
    ]];
}

@end

#pragma clang assume_nonnull end
