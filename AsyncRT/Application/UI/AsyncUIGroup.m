#import <AsyncRT/Application/UI/AsyncUIGroup.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIGroup

+ (instancetype)withChildren: (OFArray<id<AsyncUIContent>> *)children
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AsyncUIContent>> *)children
{
    self = [super init];
    _children = [children copy];
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindGroup;
}

@end

#pragma clang assume_nonnull end
