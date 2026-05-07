#import "AUIStackLayout.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIStackLayout

- (instancetype)init
{
    self = [super init];
    _width = AUIAxisSize.grow;
    _height = AUIAxisSize.fit;
    _padding = [AUIEdgeInsets all: 0];
    _spacing = 0;
    _horizontalAlignment = AUIContentAlignmentStart;
    _verticalAlignment = AUIContentAlignmentStart;
    _direction = AUIStackDirectionVertical;
    _scrollBehavior = AUIScrollBehaviorNone;
    return self;
}

+ (instancetype)vertical
{
    auto layout = [[self alloc] init];
    layout.direction = AUIStackDirectionVertical;
    return layout;
}

+ (instancetype)horizontal
{
    auto layout = [[self alloc] init];
    layout.direction = AUIStackDirectionHorizontal;
    return layout;
}

- (instancetype)sizedWidth: (AUIAxisSize *)width
                    height: (AUIAxisSize *)height
{
    self.width = width;
    self.height = height;
    return self;
}

- (instancetype)padded: (AUIEdgeInsets *)padding
{
    self.padding = padding;
    return self;
}

- (instancetype)spaced: (uint16_t)spacing
{
    self.spacing = spacing;
    return self;
}

- (instancetype)alignedHorizontally: (AUIContentAlignment)horizontalAlignment
                           vertical: (AUIContentAlignment)verticalAlignment
{
    self.horizontalAlignment = horizontalAlignment;
    self.verticalAlignment = verticalAlignment;
    return self;
}

- (instancetype)scrolling: (AUIScrollBehavior)scrollBehavior
{
    self.scrollBehavior = scrollBehavior;
    return self;
}

@end

#pragma clang assume_nonnull end
