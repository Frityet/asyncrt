#import "UI/Components/Controls/AUIInteractiveBox.h"

#pragma clang assume_nonnull begin

@interface AUIInteractiveBox ()

- (instancetype)initWithLayout: (AUILayout)layout
                   backgrounds: (AUIControlColors)backgrounds
                        radius: (float)cornerRadius
                        border: (AUIBorder)border
                       enabled: (bool)enabled
                     focusable: (bool)focusable
                    onActivate: (void (^nillable)(void))activateHandler
                      children: (OFArray<id<AUIRenderable>> *nillable)children designated_initaliser;

@end

@implementation AUIInteractiveBox {
    AUILayout _layout;
    AUIControlColors _backgrounds;
    float _cornerRadius;
    AUIBorder _border;
    bool _enabled;
    bool _focusable;
    OFArray<id<AUIRenderable>> *_children;
    void (^nillable _activateHandler)(void);
}

@synthesize layout = _layout;
@synthesize backgrounds = _backgrounds;
@synthesize cornerRadius = _cornerRadius;
@synthesize border = _border;
@synthesize enabled = _enabled;
@synthesize focusable = _focusable;
@synthesize children = _children;
@synthesize activateHandler = _activateHandler;

+ (instancetype)layout: (AUILayout)layout
           backgrounds: (AUIControlColors)backgrounds
                radius: (float)cornerRadius
                border: (AUIBorder)border
               enabled: (bool)enabled
             focusable: (bool)focusable
            onActivate: (void (^nillable)(void))activateHandler
              children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithLayout: layout
                            backgrounds: backgrounds
                                 radius: cornerRadius
                                 border: border
                                enabled: enabled
                              focusable: focusable
                             onActivate: activateHandler
                               children: children];
}

- (instancetype)initWithLayout: (AUILayout)layout
                   backgrounds: (AUIControlColors)backgrounds
                        radius: (float)cornerRadius
                        border: (AUIBorder)border
                       enabled: (bool)enabled
                     focusable: (bool)focusable
                    onActivate: (void (^nillable)(void))activateHandler
                      children: (OFArray<id<AUIRenderable>> *nillable)children
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _layout = layout;
    _backgrounds = backgrounds;
    _cornerRadius = cornerRadius;
    _border = border;
    _enabled = enabled;
    _focusable = focusable;
    _children = [children copy];
    _activateHandler = [activateHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
