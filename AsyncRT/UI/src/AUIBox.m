#import "AUIBox.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIBox

+ (instancetype)withLayout: (AUIStackLayout *)layout
                  styledBy: (AUIBoxStyle *)style
               interaction: (AUIInteraction *nillable)interaction
                  children: (OFArray<id<AUIContent>> *)children
{
    return [[self alloc] initWithStyle: style
                                layout: layout
                           interaction: interaction
                              children: children];
}

- (instancetype)initWithStyle: (AUIBoxStyle *)style
                       layout: (AUIStackLayout *)layout
                  interaction: (AUIInteraction *nillable)interaction
                     children: (OFArray<id<AUIContent>> *)children
{
    self = [super init];
    _style = style;
    _layout = layout;
    _interaction = interaction;
    _children = [children copy];
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindBox;
}

@end

#pragma clang assume_nonnull end
