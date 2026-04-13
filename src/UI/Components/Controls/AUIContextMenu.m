#import "UI/Components/Controls/AUIContextMenu.h"

#pragma clang assume_nonnull begin

@interface AUIContextMenu ()

- (instancetype)initWithItems: (OFArray<AUIContextMenuItem *> *nillable)items [[designated_initailiser]];

@end

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
