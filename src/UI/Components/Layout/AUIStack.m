#import "UI/Components/Layout/AUIStack.h"

#pragma clang assume_nonnull begin

@interface AUIBox ()

- (instancetype)initWithLayout: (AUILayout)layout
                    background: (AUIColor)backgroundColor
                        radius: (float)cornerRadius
                        border: (AUIBorder)border
                        scroll: (AUIScrollAxis)scrollAxis
                      children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

@implementation AUIStack

+ (instancetype)rowWithLayout: (AUILayout)layout
                   background: (AUIColor)backgroundColor
                       radius: (float)cornerRadius
                       border: (AUIBorder)border
                     children: (OFArray<id<AUIRenderable>> *nillable)children
{
    layout.direction = AUILayoutDirectionRow;
    return [[self alloc] initWithLayout: layout
                             background: backgroundColor
                                 radius: cornerRadius
                                 border: border
                                 scroll: AUIScrollAxisNone
                               children: children];
}

+ (instancetype)columnWithLayout: (AUILayout)layout
                      background: (AUIColor)backgroundColor
                          radius: (float)cornerRadius
                          border: (AUIBorder)border
                        children: (OFArray<id<AUIRenderable>> *nillable)children
{
    layout.direction = AUILayoutDirectionColumn;
    return [[self alloc] initWithLayout: layout
                             background: backgroundColor
                                 radius: cornerRadius
                                 border: border
                                 scroll: AUIScrollAxisNone
                               children: children];
}

@end

#pragma clang assume_nonnull end
