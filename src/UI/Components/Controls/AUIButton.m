#import "UI/Components/Controls/AUIButton.h"

#pragma clang assume_nonnull begin

@interface AUIButton ()

- (instancetype)initWithTitle: (OFString *nillable)title
                      variant: (AUIControlVariant)variant
                         size: (AUIControlSize)size
                      enabled: (bool)enabled
                      onPress: (void (^nillable)(void))pressHandler [[designated_initailiser]];

@end

@implementation AUIButton {
    OFString *_title;
    AUIControlVariant _variant;
    AUIControlSize _size;
    bool _enabled;
    void (^nillable _pressHandler)(void);
}

@synthesize isEnabled = _enabled;

+ (instancetype)title: (OFString *nillable)title
              variant: (AUIControlVariant)variant
                 size: (AUIControlSize)size
              enabled: (bool)enabled
              onPress: (void (^nillable)(void))pressHandler
{
    return [[self alloc] initWithTitle: title
                               variant: variant
                                  size: size
                               enabled: enabled
                               onPress: pressHandler];
}

- (instancetype)initWithTitle: (OFString *nillable)title
                      variant: (AUIControlVariant)variant
                         size: (AUIControlSize)size
                      enabled: (bool)enabled
                      onPress: (void (^nillable)(void))pressHandler
{
    if (title == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _title = [$assert_nonnil(title) copy];
    _variant = variant;
    _size = size;
    _enabled = enabled;
    _pressHandler = [pressHandler copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];

    layout.height = [AUIComponents controlHeightForSize: _size];
    layout.padding = [AUIComponents controlInsetsForSize: _size];
    layout.childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter];

    return [AUIInteractiveBox layout: layout
                         backgrounds: [AUIComponents controlColorsForVariant: _variant enabled: _enabled]
                              radius: [AUIComponents controlCornerRadiusForSize: _size]
                              border: [AUIComponents controlBorderForVariant: _variant enabled: _enabled]
                             enabled: _enabled
                           focusable: false
                          onActivate: _pressHandler
                            children: @[
        [AUIText string: _title
                  style: [AUIComponents controlTextStyleForSize: _size variant: _variant enabled: _enabled]]
    ]];
}

@end

#pragma clang assume_nonnull end
