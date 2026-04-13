#import "UI/Components/Layout/AUIPadding.h"

#pragma clang assume_nonnull begin

@interface AUIPadding ()

- (instancetype)initWithInsets: (AUIInsets)insets child: (id<AUIRenderable>)child designated_initaliser;

@end

@implementation AUIPadding {
    AUIInsets _insets;
    id<AUIRenderable> _child;
}

@synthesize insets = _insets;
@synthesize child = _child;

+ (instancetype)insets: (AUIInsets)insets child: (id<AUIRenderable>)child
{
    return [[self alloc] initWithInsets: insets child: child];
}

- (instancetype)initWithInsets: (AUIInsets)insets child: (id<AUIRenderable>)child
{
    self = [super init];
    _insets = insets;
    _child = child;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];
    layout.padding = _insets;

    return [AUIBox layout: layout
               background: [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[ _child ]];
}

@end

#pragma clang assume_nonnull end
