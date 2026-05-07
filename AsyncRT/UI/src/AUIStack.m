#import "AUIStack.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIStack

+ (instancetype)withLayout: (AUIStackLayout *)layout
                  children: (OFArray<id<AUIContent>> *)children
{
    return [[self alloc] initWithLayout: layout children: children];
}

- (instancetype)initWithLayout: (AUIStackLayout *)layout
                      children: (OFArray<id<AUIContent>> *)children
{
    self = [super init];
    _layout = layout;
    _children = [children copy];
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindStack;
}

@end

#pragma clang assume_nonnull end
