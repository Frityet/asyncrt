#import "UI/Components/Controls/AUIContextMenuRegion.h"

#pragma clang assume_nonnull begin

@interface AUIContextMenuRegion ()

- (instancetype)initWithChild: (id<AUIRenderable> nillable)child
                         menu: (AUIContextMenu *nillable)menu designated_initaliser;

@end

@implementation AUIContextMenuRegion {
    id<AUIRenderable> _child;
    AUIContextMenu *_menu;
}

@synthesize child = _child;
@synthesize menu = _menu;

+ (instancetype)child: (id<AUIRenderable> nillable)child
                 menu: (AUIContextMenu *nillable)menu
{
    return [[self alloc] initWithChild: child menu: menu];
}

- (instancetype)initWithChild: (id<AUIRenderable> nillable)child
                         menu: (AUIContextMenu *nillable)menu
{
    if (child == nilptr or menu == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _child = $assert_nonnil(child);
    _menu = $assert_nonnil(menu);
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    return _child;
}

@end

#pragma clang assume_nonnull end
