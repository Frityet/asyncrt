#import "UI/Components/Layout/AUIScrollView.h"

#pragma clang assume_nonnull begin

@interface AUIScrollView ()

- (instancetype)initWithAxis: (AUIScrollAxis)axis child: (id<AUIRenderable>)child designated_initaliser;

@end

@implementation AUIScrollView {
    AUIScrollAxis _axis;
    id<AUIRenderable> _child;
}

@synthesize axis = _axis;
@synthesize child = _child;

+ (instancetype)axis: (AUIScrollAxis)axis child: (id<AUIRenderable>)child
{
    return [[self alloc] initWithAxis: axis child: child];
}

- (instancetype)initWithAxis: (AUIScrollAxis)axis child: (id<AUIRenderable>)child
{
    self = [super init];
    _axis = axis;
    _child = child;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];

    layout.width = [AUI axisGrow: 0];
    layout.height = [AUI axisGrow: 0];

    return [AUIBox layout: layout
               background: [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0]
                   radius: 0
                   border: [AUI borderNone]
                   scroll: _axis
                 children: @[ _child ]];
}

@end

#pragma clang assume_nonnull end
