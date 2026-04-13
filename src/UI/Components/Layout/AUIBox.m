#import "UI/Components/Layout/AUIBox.h"

#pragma clang assume_nonnull begin

@interface AUIBox ()

- (instancetype)initWithLayout: (AUILayout)layout
                    background: (AUIColor)backgroundColor
                        radius: (float)cornerRadius
                        border: (AUIBorder)border
                        scroll: (AUIScrollAxis)scrollAxis
                      children: (OFArray<id<AUIRenderable>> *nillable)children [[designated_initailiser]];

@end

@implementation AUIBox {
    AUILayout _layout;
    AUIColor _backgroundColor;
    float _cornerRadius;
    AUIBorder _border;
    AUIScrollAxis _scrollAxis;
    OFArray<id<AUIRenderable>> *_children;
}


+ (instancetype)layout: (AUILayout)layout
            background: (AUIColor)backgroundColor
                radius: (float)cornerRadius
                border: (AUIBorder)border
              children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithLayout: layout
                             background: backgroundColor
                                 radius: cornerRadius
                                 border: border
                                 scroll: AUIScrollAxisNone
                               children: children];
}

+ (instancetype)layout: (AUILayout)layout
            background: (AUIColor)backgroundColor
                radius: (float)cornerRadius
                border: (AUIBorder)border
                scroll: (AUIScrollAxis)scrollAxis
              children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithLayout: layout
                             background: backgroundColor
                                 radius: cornerRadius
                                 border: border
                                 scroll: scrollAxis
                               children: children];
}

- (instancetype)initWithLayout: (AUILayout)layout
                    background: (AUIColor)backgroundColor
                        radius: (float)cornerRadius
                        border: (AUIBorder)border
                        scroll: (AUIScrollAxis)scrollAxis
                      children: (OFArray<id<AUIRenderable>> *nillable)children
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _layout = layout;
    _backgroundColor = backgroundColor;
    _cornerRadius = cornerRadius;
    _border = border;
    _scrollAxis = scrollAxis;
    _children = [children copy];
    return self;
}

@end

#pragma clang assume_nonnull end
