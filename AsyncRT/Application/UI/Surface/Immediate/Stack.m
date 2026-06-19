#import <AsyncRT/Application/UI/Surface/Immediate/Stack.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIStack

+ (instancetype)withLayout: (AsyncUIStackLayout *)layout
                  children: (OFArray<id<AsyncUIContent>> *)children
{
    return [[self alloc] initWithLayout: layout children: children];
}

- (instancetype)initWithLayout: (AsyncUIStackLayout *)layout
                      children: (OFArray<id<AsyncUIContent>> *)children
{
    self = [super init];
    _layout = layout;
    _children = [children copy];
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindStack;
}

@end

#pragma clang assume_nonnull end
