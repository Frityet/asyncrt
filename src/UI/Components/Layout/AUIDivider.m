#import "UI/Components/Layout/AUIDivider.h"

#pragma clang assume_nonnull begin

@interface AUIDivider ()

- (instancetype)initWithHorizontal: (bool)horizontal thickness: (uint16_t)thickness color: (AUIColor)color designated_initaliser;

@end

@implementation AUIDivider {
    bool _horizontal;
    uint16_t _thickness;
    AUIColor _color;
}

@synthesize horizontal = _horizontal;
@synthesize thickness = _thickness;
@synthesize color = _color;

+ (instancetype)horizontalWithThickness: (uint16_t)thickness color: (AUIColor)color
{
    return [[self alloc] initWithHorizontal: true thickness: thickness color: color];
}

+ (instancetype)verticalWithThickness: (uint16_t)thickness color: (AUIColor)color
{
    return [[self alloc] initWithHorizontal: false thickness: thickness color: color];
}

- (instancetype)initWithHorizontal: (bool)horizontal thickness: (uint16_t)thickness color: (AUIColor)color
{
    if (thickness == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _horizontal = horizontal;
    _thickness = thickness;
    _color = color;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];
    layout.width = _horizontal ? [AUI axisGrow: 0] : [AUI axisFixed: _thickness];
    layout.height = _horizontal ? [AUI axisFixed: _thickness] : [AUI axisGrow: 0];

    return [AUIBox layout: layout
               background: _color
                   radius: 0
                   border: [AUI borderNone]
                 children: @[]];
}

@end

#pragma clang assume_nonnull end
