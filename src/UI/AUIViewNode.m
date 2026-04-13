#import "UI/AUIViewNode.h"

#pragma clang assume_nonnull begin

@interface AUIViewInteractionConfiguration ()

- (instancetype)initWithEnabled: (bool)isEnabled
                      focusable: (bool)isFocusable
                    cursorStyle: (AUICursorStyle)cursorStyle
         interactiveBackgrounds: (AUIControlColors)interactiveBackgroundColors
                 usesBackground: (bool)usesInteractiveBackgroundColors
                     onActivate: (void (^nillable)(void))activationHandler
                    contextMenu: (AUIContextMenu *nillable)contextMenu [[designated_initailiser]];

@end

@interface AUIViewNode ()

- (instancetype)initWithNodeFamily: (AUIViewNodeFamily)nodeFamily
                          stableKey: (OFString *nillable)stableKey;

@end

@interface AUIViewFragmentNode ()

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children [[designated_initailiser]];

@end

@interface AUIViewBoxNode ()

- (instancetype)initWithStableKey: (OFString *nillable)stableKey
                          boxProps: (AUIBoxProps)boxProps
            interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                          children: (OFArray<id<AUIRenderable>> *nillable)children [[designated_initailiser]];

@end

@interface AUIViewTextNode ()

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)textStyle [[designated_initailiser]];

@end

@interface AUIViewEditableTextNode ()

- (instancetype)initWithStableKey: (OFString *nillable)stableKey
                               text: (OFString *nillable)text
                        placeholder: (OFString *nillable)placeholder
                              style: (AUITextStyle)textStyle
                             colors: (AUITextInputColors)colors
                             layout: (AUILayout)layout
                       cornerRadius: (float)cornerRadius
                            enabled: (bool)isEnabled
                             secure: (bool)isSecure
                          multiline: (bool)isMultiline
                        contextMenu: (AUIContextMenu *nillable)contextMenu
                           onChange: (void (^nillable)(OFString *text))textChangeHandler
                           onSubmit: (void (^nillable)(OFString *text))submitHandler [[designated_initailiser]];

@end

@implementation AUIViewInteractionConfiguration {
    bool _enabled;
    bool _focusable;
    AUICursorStyle _cursorStyle;
    bool _usesInteractiveBackgroundColors;
    AUIControlColors _interactiveBackgroundColors;
    AUIContextMenu *nillable _contextMenu;
    void (^nillable _activationHandler)(void);
}

@synthesize isEnabled = _enabled;
@synthesize isFocusable = _focusable;
@synthesize cursorStyle = _cursorStyle;
@synthesize usesInteractiveBackgroundColors = _usesInteractiveBackgroundColors;
@synthesize interactiveBackgroundColors = _interactiveBackgroundColors;

+ (instancetype)enabled: (bool)isEnabled
              focusable: (bool)isFocusable
            cursorStyle: (AUICursorStyle)cursorStyle
             background: (AUIControlColors)interactiveBackgroundColors
             onActivate: (void (^nillable)(void))activationHandler
            contextMenu: (AUIContextMenu *nillable)contextMenu
{
    return [[self alloc] initWithEnabled: isEnabled
                               focusable: isFocusable
                             cursorStyle: cursorStyle
                  interactiveBackgrounds: interactiveBackgroundColors
                          usesBackground: true
                              onActivate: activationHandler
                             contextMenu: contextMenu];
}

+ (instancetype)enabled: (bool)isEnabled
              focusable: (bool)isFocusable
            cursorStyle: (AUICursorStyle)cursorStyle
             onActivate: (void (^nillable)(void))activationHandler
            contextMenu: (AUIContextMenu *nillable)contextMenu
{
    return [[self alloc] initWithEnabled: isEnabled
                               focusable: isFocusable
                             cursorStyle: cursorStyle
                  interactiveBackgrounds: (AUIControlColors){0}
                          usesBackground: false
                              onActivate: activationHandler
                             contextMenu: contextMenu];
}

- (instancetype)initWithEnabled: (bool)isEnabled
                      focusable: (bool)isFocusable
                    cursorStyle: (AUICursorStyle)cursorStyle
         interactiveBackgrounds: (AUIControlColors)interactiveBackgroundColors
                 usesBackground: (bool)usesInteractiveBackgroundColors
                     onActivate: (void (^nillable)(void))activationHandler
                    contextMenu: (AUIContextMenu *nillable)contextMenu
{
    self = [super init];
    _enabled = isEnabled;
    _focusable = isFocusable;
    _cursorStyle = cursorStyle;
    _usesInteractiveBackgroundColors = usesInteractiveBackgroundColors;
    _interactiveBackgroundColors = interactiveBackgroundColors;
    _contextMenu = contextMenu;
    _activationHandler = [activationHandler copy];
    return self;
}

@end

@implementation AUIViewNode {
    AUIViewNodeFamily _nodeFamily;
    OFString *nillable _stableKey;
}

@synthesize nodeFamily = _nodeFamily;

- (instancetype)initWithNodeFamily: (AUIViewNodeFamily)nodeFamily
                          stableKey: (OFString *nillable)stableKey
{
    self = [super init];
    _nodeFamily = nodeFamily;
    _stableKey = [stableKey copy];
    return self;
}

@end

@implementation AUIViewFragmentNode {
    OFArray<id<AUIRenderable>> *_children;
}

+ (instancetype)fragmentNodeWithChildren: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nillable)children
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super initWithNodeFamily: AUIViewNodeFamilyFragment stableKey: nilptr];
    _children = [$assert_nonnil(children) copy];
    return self;
}

@end

@implementation AUIViewBoxNode {
    AUIBoxProps _boxProps;
    AUIViewInteractionConfiguration *nillable _interactionConfiguration;
    OFArray<id<AUIRenderable>> *_children;
}

+ (instancetype)boxNodeWithKey: (OFString *nillable)stableKey
                      boxProps: (AUIBoxProps)boxProps
        interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                      children: (OFArray<id<AUIRenderable>> *nillable)children
{
    return [[self alloc] initWithStableKey: stableKey
                                   boxProps: boxProps
                     interactionConfiguration: interactionConfiguration
                                   children: children];
}

- (instancetype)initWithStableKey: (OFString *nillable)stableKey
                          boxProps: (AUIBoxProps)boxProps
            interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                          children: (OFArray<id<AUIRenderable>> *nillable)children
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super initWithNodeFamily: AUIViewNodeFamilyBox stableKey: stableKey];
    _boxProps = boxProps;
    _interactionConfiguration = interactionConfiguration;
    _children = [$assert_nonnil(children) copy];
    return self;
}

@end

@implementation AUIViewTextNode {
    OFString *_text;
    AUITextStyle _textStyle;
}

+ (instancetype)textNodeWithText: (OFString *nillable)text style: (AUITextStyle)textStyle
{
    return [[self alloc] initWithText: text style: textStyle];
}

- (instancetype)initWithText: (OFString *nillable)text style: (AUITextStyle)textStyle
{
    if (text == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super initWithNodeFamily: AUIViewNodeFamilyText stableKey: nilptr];
    _text = [$assert_nonnil(text) copy];
    _textStyle = textStyle;
    return self;
}

@end

@implementation AUIViewEditableTextNode {
    OFString *nillable _text;
    OFString *_placeholder;
    AUITextStyle _textStyle;
    AUITextInputColors _colors;
    AUILayout _layout;
    float _cornerRadius;
    bool _enabled;
    bool _secure;
    bool _multiline;
    AUIContextMenu *nillable _contextMenu;
    void (^nillable _textChangeHandler)(OFString *text);
    void (^nillable _submitHandler)(OFString *text);
}

@synthesize isEnabled = _enabled;
@synthesize isSecure = _secure;
@synthesize isMultiline = _multiline;

+ (instancetype)editableTextNodeWithKey: (OFString *nillable)stableKey
                                   text: (OFString *nillable)text
                            placeholder: (OFString *nillable)placeholder
                                  style: (AUITextStyle)textStyle
                                 colors: (AUITextInputColors)colors
                                 layout: (AUILayout)layout
                           cornerRadius: (float)cornerRadius
                                enabled: (bool)isEnabled
                                 secure: (bool)isSecure
                              multiline: (bool)isMultiline
                            contextMenu: (AUIContextMenu *nillable)contextMenu
                               onChange: (void (^nillable)(OFString *text))textChangeHandler
                               onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    return [[self alloc] initWithStableKey: stableKey
                                      text: text
                               placeholder: placeholder
                                     style: textStyle
                                    colors: colors
                                    layout: layout
                              cornerRadius: cornerRadius
                                   enabled: isEnabled
                                    secure: isSecure
                                 multiline: isMultiline
                               contextMenu: contextMenu
                                  onChange: textChangeHandler
                                  onSubmit: submitHandler];
}

- (instancetype)initWithStableKey: (OFString *nillable)stableKey
                               text: (OFString *nillable)text
                        placeholder: (OFString *nillable)placeholder
                              style: (AUITextStyle)textStyle
                             colors: (AUITextInputColors)colors
                             layout: (AUILayout)layout
                       cornerRadius: (float)cornerRadius
                            enabled: (bool)isEnabled
                             secure: (bool)isSecure
                          multiline: (bool)isMultiline
                        contextMenu: (AUIContextMenu *nillable)contextMenu
                           onChange: (void (^nillable)(OFString *text))textChangeHandler
                           onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    if (placeholder == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super initWithNodeFamily: AUIViewNodeFamilyEditableText stableKey: stableKey];
    _text = [text copy];
    _placeholder = [$assert_nonnil(placeholder) copy];
    _textStyle = textStyle;
    _colors = colors;
    _layout = layout;
    _cornerRadius = cornerRadius;
    _enabled = isEnabled;
    _secure = isSecure;
    _multiline = isMultiline;
    _contextMenu = contextMenu;
    _textChangeHandler = [textChangeHandler copy];
    _submitHandler = [submitHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
