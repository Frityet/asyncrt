#import <AsyncRT/Application/UI/AsyncUIBox.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIBox

+ (instancetype)withLayout: (AsyncUIStackLayout *)layout
                  styledBy: (AsyncUIBoxStyle *)style
               interaction: (AsyncUIInteraction *nillable)interaction
                  children: (OFArray<id<AsyncUIContent>> *)children
{
    return [[self alloc] initWithStyle: style
                                layout: layout
                           interaction: interaction
                              children: children];
}

- (instancetype)initWithStyle: (AsyncUIBoxStyle *)style
                       layout: (AsyncUIStackLayout *)layout
                  interaction: (AsyncUIInteraction *nillable)interaction
                     children: (OFArray<id<AsyncUIContent>> *)children
{
    self = [super init];
    _style = style;
    _layout = layout;
    _interaction = interaction;
    _children = [children copy];
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindBox;
}

@end

#pragma clang assume_nonnull end
