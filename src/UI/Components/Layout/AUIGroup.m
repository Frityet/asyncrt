#import "UI/Components/Layout/AUIGroup.h"

#pragma clang assume_nonnull begin

@interface AUIGroup ()

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children designated_initaliser;

@end

@implementation AUIGroup {
    OFArray<id<AUIRenderable>> *_children;
}

@synthesize children = _children;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _children = [children copy];
    return self;
}

@end

#pragma clang assume_nonnull end
