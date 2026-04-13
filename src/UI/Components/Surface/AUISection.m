#import "UI/Components/Surface/AUISection.h"

#pragma clang assume_nonnull begin

@interface AUISection ()

- (instancetype)initWithTitle: (OFString *nillable)title
                     children: (OFArray<id<AUIRenderable>> *nillable)children [[designated_initailiser]];

@end

@implementation AUISection {
    OFString *nillable _title;
    OFArray<id<AUIRenderable>> *_children;
}


+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithTitle: nilptr children: children];
}

+ (instancetype)title: (OFString *nillable)title children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithTitle: title children: children];
}

- (instancetype)initWithTitle: (OFString *nillable)title
                     children: (OFArray<id<AUIRenderable>> *nillable)children
{
    self = [super init];
    _title = [title copy];
    _children = [[AUIComponents childrenOrEmpty: children] copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    OFMutableArray<id<AUIRenderable>> *children = [OFMutableArray array];
    AUIBoxProps props = [AUIComponents sectionBoxProps];

    if (_title != nilptr) {
        AUITextStyle style = [AUIComponents labelTextStyle];

        style.fontSize = 13;
        style.color = [AUI colorWithRed: 112 green: 118 blue: 126 alpha: 255];
        [children addObject: [AUIText string: _title style: style]];
    }

    for (id<AUIRenderable> child in _children)
        [children addObject: child];

    return [AUIStack columnWithLayout: props.layout
                           background: props.backgroundColor
                               radius: props.cornerRadius
                               border: props.border
                             children: children];
}

@end

#pragma clang assume_nonnull end
