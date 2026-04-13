#import "UI/Components/Layout/AUIHStack.h"

#pragma clang assume_nonnull begin

@interface AUIHStack ()

- (instancetype)initWithGap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *nillable)children designated_initaliser;

@end

@implementation AUIHStack {
    OFArray<id<AUIRenderable>> *_children;
    uint16_t _gap;
}

@synthesize children = _children;
@synthesize gap = _gap;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [self gap: 0 children: children];
}

+ (instancetype)gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithGap: gap children: children];
}

- (instancetype)initWithGap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *nillable)children
{
    self = [super init];
    _gap = gap;
    _children = [[AUIComponents childrenOrEmpty: children] copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];
    layout.direction = AUILayoutDirectionRow;
    layout.childGap = _gap;

    return [AUIStack rowWithLayout: layout
                        background: [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0]
                            radius: 0
                            border: [AUI borderNone]
                          children: _children];
}

@end

#pragma clang assume_nonnull end
