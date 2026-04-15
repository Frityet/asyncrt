#import "AUIView.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIViewInteractionConfiguration {
    bool _isEnabled;
    bool _isFocusable;
    AUICursorStyle _cursorStyle;
    bool _usesInteractiveBackgroundColors;
    AUIControlColors _interactiveBackgroundColors;
    AUIContextMenu *nillable _contextMenu;
    void (^nillable _activationHandler)(void);
}

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
    _isEnabled = isEnabled;
    _isFocusable = isFocusable;
    _cursorStyle = cursorStyle;
    _usesInteractiveBackgroundColors = usesInteractiveBackgroundColors;
    _interactiveBackgroundColors = interactiveBackgroundColors;
    _contextMenu = contextMenu;
    _activationHandler = [activationHandler copy];
    return self;
}

@end

@implementation AUIView {
    AUIViewFamily _viewFamily;
    OFString *nillable _stableKey;
}

- (instancetype)initWithViewFamily: (AUIViewFamily)viewFamily
                         stableKey: (OFString *nillable)stableKey
{
    self = [super init];
    _viewFamily = viewFamily;
    _stableKey = [stableKey copy];
    return self;
}

@end

[[direct_members]]
@implementation AUIViewFragment {
    OFArray<id<AUIRenderable>> *_children;
}

+ (instancetype)fragmentWithChildren: (OFArray<id<AUIRenderable>> *nonnil)children [[direct]]
{
    return [[self alloc] initWithChildren: children];
}

- (instancetype)initWithChildren: (OFArray<id<AUIRenderable>> *nonnil)children
{
    self = [super initWithViewFamily: AUIViewFamilyFragment stableKey: nilptr];
    _children = [children copy];
    return self;
}

@end

[[direct_members]]
@implementation AUIViewBox {
    AUIBoxProps _boxProps;
    AUIViewInteractionConfiguration *nillable _interactionConfiguration;
    OFArray<id<AUIRenderable>> *_children;
}

+ (instancetype)boxWithKey: (OFString *nillable)stableKey
                      boxProps: (AUIBoxProps)boxProps
      interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                      children: (OFArray<id<AUIRenderable>> *nonnil)children
                      [[direct]]
{
    return [[self alloc] initWithStableKey: stableKey
                                  boxProps: boxProps
                  interactionConfiguration: interactionConfiguration
                                  children: children];
}

- (instancetype)initWithStableKey: (OFString *nillable)stableKey
                         boxProps: (AUIBoxProps)boxProps
         interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                         children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    self = [super initWithViewFamily: AUIViewFamilyBox stableKey: stableKey];
    _boxProps = boxProps;
    _interactionConfiguration = interactionConfiguration;
    _children = [children copy];
    return self;
}

@end

[[direct_members]]
@implementation AUIViewText {
    OFString *_text;
    AUITextStyle _textStyle;
}

+ (instancetype)textWithText: (OFString *nonnil)text style: (AUITextStyle)textStyle
{
    return [[self alloc] initWithText: text style: textStyle];
}

- (instancetype)initWithText: (OFString *nonnil)text style: (AUITextStyle)textStyle
{
    self = [super initWithViewFamily: AUIViewFamilyText stableKey: nilptr];
    _text = [text copy];
    _textStyle = textStyle;
    return self;
}

@end

[[direct_members]]
@implementation AUIViewEditableText {
    OFString *nillable _text;
    OFString *_placeholder;
    AUITextStyle _textStyle;
    AUITextInputColors _colors;
    AUILayout _layout;
    float _cornerRadius;
    bool _isEnabled;
    bool _isSecure;
    bool _isMultiline;
    AUIContextMenu *nillable _contextMenu;
    void (^nillable _textChangeHandler)(OFString *text);
    void (^nillable _submitHandler)(OFString *text);
}

+ (instancetype)editableTextWithKey: (OFString *nillable)stableKey
                                   text: (OFString *nillable)text
                            placeholder: (OFString *nonnil)placeholder
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
                        placeholder: (OFString *nonnil)placeholder
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
    self = [super initWithViewFamily: AUIViewFamilyEditableText stableKey: stableKey];
    _text = [text copy];
    _placeholder = [placeholder copy];
    _textStyle = textStyle;
    _colors = colors;
    _layout = layout;
    _cornerRadius = cornerRadius;
    _isEnabled = isEnabled;
    _isSecure = isSecure;
    _isMultiline = isMultiline;
    _contextMenu = contextMenu;
    _textChangeHandler = [textChangeHandler copy];
    _submitHandler = [submitHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
