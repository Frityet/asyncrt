#import "Components/Controls/AUIContextMenu.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@interface AUIContextMenu ()

- (instancetype)initWithItems: (OFArray<AUIContextMenuItem *> *nillable)items [[designated_initailiser]];

@end

[[direct_members]]
@implementation AUIContextMenu {
    OFArray<AUIContextMenuItem *> *_items;
}


+ (instancetype)items: (OFArray<AUIContextMenuItem *> *nillable)items
{
    return [[self alloc] initWithItems: items];
}

- (instancetype)initWithItems: (OFArray<AUIContextMenuItem *> *nillable)items
{
    if (items == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _items = [$assert_nonnil(items) copy];
    return self;
}

@end

#pragma clang assume_nonnull end
