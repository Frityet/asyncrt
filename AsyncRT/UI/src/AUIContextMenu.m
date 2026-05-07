#import "AUIContextMenu.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIContextMenu {
    OFArray<AUIContextMenuItem *> *_items;
}

+ (instancetype)withItems: (OFArray<AUIContextMenuItem *> *nonnil)items
{
    return [[self alloc] initWithItems: items];
}

- (instancetype)initWithItems: (OFArray<AUIContextMenuItem *> *nonnil)items
{
    self = [super init];
    _items = [items copy];
    return self;
}

@end

#pragma clang assume_nonnull end
