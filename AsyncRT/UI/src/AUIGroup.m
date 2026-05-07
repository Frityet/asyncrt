#import "AUIGroup.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIGroup

+ (instancetype)withChildren: (OFArray<id<AUIContent>> *)children
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AUIContent>> *)children
{
    self = [super init];
    _children = [children copy];
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindGroup;
}

@end

#pragma clang assume_nonnull end
