#import <AsyncRT/Application/UI/AsyncUIStackLayout.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIStackLayout

- (instancetype)init
{
    self = [super init];
    _width = AsyncUIAxisSize.grow;
    _height = AsyncUIAxisSize.fit;
    _padding = [AsyncUIEdgeInsets all: 0];
    _spacing = 0;
    _horizontalAlignment = AsyncUIContentAlignmentStart;
    _verticalAlignment = AsyncUIContentAlignmentStart;
    _direction = AsyncUIStackDirectionVertical;
    _scrollBehavior = AsyncUIScrollBehaviorNone;
    return self;
}

+ (instancetype)vertical
{
    auto layout = [[self alloc] init];
    layout.direction = AsyncUIStackDirectionVertical;
    return layout;
}

+ (instancetype)horizontal
{
    auto layout = [[self alloc] init];
    layout.direction = AsyncUIStackDirectionHorizontal;
    return layout;
}

- (instancetype)sizedWidth: (AsyncUIAxisSize *)width
                    height: (AsyncUIAxisSize *)height
{
    self.width = width;
    self.height = height;
    return self;
}

- (instancetype)padded: (AsyncUIEdgeInsets *)padding
{
    self.padding = padding;
    return self;
}

- (instancetype)spaced: (uint16_t)spacing
{
    self.spacing = spacing;
    return self;
}

- (instancetype)alignedHorizontally: (AsyncUIContentAlignment)horizontalAlignment
                           vertical: (AsyncUIContentAlignment)verticalAlignment
{
    self.horizontalAlignment = horizontalAlignment;
    self.verticalAlignment = verticalAlignment;
    return self;
}

- (instancetype)scrolling: (AsyncUIScrollBehavior)scrollBehavior
{
    self.scrollBehavior = scrollBehavior;
    return self;
}

@end

#pragma clang assume_nonnull end
