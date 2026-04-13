#import "UI/Components/Surface/AUICard.h"

#pragma clang assume_nonnull begin

@interface AUICard ()

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children designated_initaliser;

@end

@implementation AUICard {
    OFArray<id<AUIRenderable>> *_children;
}

@synthesize children = _children;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children
{
    self = [super init];
    _children = [[AUIComponents childrenOrEmpty: children] copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUIBoxProps props = [AUIComponents cardBoxProps];

    return [AUIBox layout: props.layout
               background: props.backgroundColor
                   radius: props.cornerRadius
                   border: props.border
                 children: _children];
}

@end

#pragma clang assume_nonnull end
