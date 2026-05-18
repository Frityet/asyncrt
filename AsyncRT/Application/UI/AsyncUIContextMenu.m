#import <AsyncRT/Application/UI/AsyncUIContextMenu.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIContextMenu {
    OFArray<AsyncUIContextMenuItem *> *_items;
}

+ (instancetype)withItems: (OFArray<AsyncUIContextMenuItem *> *nonnil)items
{
    return [[self alloc] initWithItems: items];
}

- (instancetype)initWithItems: (OFArray<AsyncUIContextMenuItem *> *nonnil)items
{
    self = [super init];
    _items = [items copy];
    return self;
}

@end

#pragma clang assume_nonnull end
