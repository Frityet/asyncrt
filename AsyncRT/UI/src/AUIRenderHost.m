#import "AUIRenderHost.h"
#import "AUIClaySupport.h"

#pragma clang assume_nonnull begin

@namespace(AUIRenderHostSupport)

+ (OFString *)childIdentifierForRenderable: (id nonnil)renderable
                          parentIdentifier: (OFString *nonnil)parentIdentifier
                                     index: (size_t)index;
+ (OFArray<id<AUIRenderable>> *)childrenOrEmpty: (OFArray<id<AUIRenderable>> *nillable)children;
+ (AUIColor)interactiveBackgroundWithFallback: (AUIColor)fallbackColor
                              configuration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                                  identifier: (OFString *nillable)identifier
                    interactionController: (AUIInteractionController *)interactionController;
+ (void)renderText: (OFString *nillable)text style: (AUITextStyle)textStyle;

@end

@namespace_implementation(AUIRenderHostSupport)

+ (OFString *)childIdentifierForRenderable: (id nonnil)renderable
                          parentIdentifier: (OFString *nonnil)parentIdentifier
                                     index: (size_t)index
{
    OFString *token = nilptr;

    if ([renderable isKindOfClass: AUIRetainedChildViewComponent.class])
        token = [OFString stringWithFormat: @"component:%@", ((AUIRetainedChildViewComponent *)renderable).componentKey];
    else if ([renderable isKindOfClass: AUIView.class] and ((AUIView *)renderable).stableKey != nilptr)
        token = [OFString stringWithFormat: @"view:%@", $assert_nonnil(((AUIView *)renderable).stableKey)];

    if (token == nilptr)
        token = [OFString stringWithFormat: @"index:%zu", index];

    return [OFString stringWithFormat: @"%@/%@", parentIdentifier, token];
}

+ (OFArray<id<AUIRenderable>> *)childrenOrEmpty: (OFArray<id<AUIRenderable>> *nillable)children
{
    return (children ?: @[]);
}

+ (AUIColor)interactiveBackgroundWithFallback: (AUIColor)fallbackColor
                              configuration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                                  identifier: (OFString *nillable)identifier
                    interactionController: (AUIInteractionController *)interactionController
{
    if (interactionConfiguration == nilptr or not $assert_nonnil(interactionConfiguration).usesInteractiveBackgroundColors)
        return fallbackColor;
    if (not interactionConfiguration.isEnabled)
        return interactionConfiguration.interactiveBackgroundColors.disabled;
    if ([interactionController isIdentifierPressed: identifier])
        return interactionConfiguration.interactiveBackgroundColors.pressed;
    if ([interactionController isIdentifierHovered: identifier])
        return interactionConfiguration.interactiveBackgroundColors.hover;
    return interactionConfiguration.interactiveBackgroundColors.normal;
}

+ (void)renderText: (OFString *nillable)text style: (AUITextStyle)textStyle
{
    Clay_TextElementConfig textConfig = [AUIClay textConfigFromProps: (AUITextProps){ .style = textStyle }];
    CLAY_TEXT([AUIClay stringFromString: text], CLAY_TEXT_CONFIG(textConfig));
}

@end

[[direct_members]]
@implementation AUIRenderHost {
    AUIApplication *_application;
    AUIViewComponent *nillable _rootViewComponent;
    OFMutableArray<void (^)(void)> *_postRenderEffects;
}

- (instancetype)initWithApplication: (AUIApplication *nonnil)application
{
    self = [super init];
    _application = application;
    _postRenderEffects = [OFMutableArray array];
    return self;
}

- (void)attachRootViewComponent: (AUIViewComponent *nonnil)rootViewComponent
                      taskGroup: (AsyncTaskGroup *nonnil)taskGroup
{
    [self detachRootViewComponent];
    _rootViewComponent = rootViewComponent;
    [_rootViewComponent _attachToApplication: _application parentViewComponent: nilptr taskGroup: taskGroup];
    [_rootViewComponent _ensureMountedInTaskGroup: taskGroup];
}

- (void)detachRootViewComponent
{
    if (_rootViewComponent == nilptr)
        return;

    [_rootViewComponent _unmountRecursively];
    [_rootViewComponent _detachFromApplication];
    _rootViewComponent = nilptr;
}

- (void)setRootViewComponentForTesting: (AUIViewComponent *nillable)rootViewComponent
{
    if (_rootViewComponent == rootViewComponent)
        return;

    [self detachRootViewComponent];
    _rootViewComponent = rootViewComponent;
    if (_rootViewComponent != nilptr)
        [_rootViewComponent _attachToApplication: _application parentViewComponent: nilptr taskGroup: nilptr];
}

- (void)enqueuePostRenderEffect: (void (^nonnil)(void))effectBlock
{
    [_postRenderEffects addObject: [effectBlock copy]];
}

- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *nonnil)inputState
                                                        window: (AUIWindow *nonnil)window
                                         interactionController: (AUIInteractionController *nonnil)interactionController
                                         textEditingController: (AUITextEditingController *nonnil)textEditingController
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester
{
    OFString *nillable clayError = nilptr;
    OFString *rootIdentifier = @"root";

    if (_rootViewComponent == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render without a root view component"];
    AUIInputState *safeInputState = inputState;
    AUIWindow *safeWindow = window;
    AUIInteractionController *safeInteractionController = interactionController;
    AUITextEditingController *safeTextEditingController = textEditingController;
    OFString *nillable (^safeClipboardTextProvider)(void) = clipboardTextProvider;
    void (^safeClipboardTextSetter)(OFString *nillable text) = clipboardTextSetter;
    void (^safeCursorSetter)(AUICursorStyle cursorStyle) = cursorSetter;
    void (^safeRenderRequester)(void) = renderRequester;
    OFDate *frameDate = OFDate.date;
    AUIRenderContext *context = [[AUIRenderContext alloc]
        initWithApplication: _application
                     window: safeWindow
               viewportSize: viewportSize
                  frameDate: frameDate
                elapsedTime: 0];
    Clay_RenderCommandArray renderCommands = (Clay_RenderCommandArray){0};

    [_postRenderEffects removeAllObjects];
    [AUIClay clearError];
    AUIClay.layoutDimensions = viewportSize;
    [AUIClay setPointerPositionX: safeInputState.pointerX
                                y: safeInputState.pointerY
                             down: safeInputState.isPrimaryButtonDown];
    [safeInteractionController beginFrame];
    [AUIRenderContext _pushCurrentContext: context];

    @try {
        [AUIClay beginLayout];
        AUIView *rootView = [_rootViewComponent _resolvedRenderedView];
        if (rootView.stableKey != nilptr)
            rootIdentifier = [AUIRenderHostSupport childIdentifierForRenderable: rootView parentIdentifier: @"root" index: 0];

        [self _renderRenderable: rootView
                     identifier: rootIdentifier
                    contextMenu: nilptr
                    application: _application
           interactionController: safeInteractionController
           textEditingController: safeTextEditingController];
        [self _renderActiveContextMenuWithInteractionController: safeInteractionController];

        renderCommands = [AUIClay endLayoutWithDeltaTime: deltaTime];
        [AUIClay updateScrollContainersWithDragScrolling: true
                                                  deltaX: safeInputState.scrollDeltaX
                                                  deltaY: safeInputState.scrollDeltaY
                                               deltaTime: deltaTime];
        [safeInteractionController completeFrameWithInputState: safeInputState
                                         textEditingController: safeTextEditingController
                                                clipboardText: safeClipboardTextProvider
                                          setClipboardText: safeClipboardTextSetter
                                               cursorSetter: safeCursorSetter
                                          renderRequester: safeRenderRequester];
        [self _runPostRenderEffects];

        clayError = [AUIClay consumeError];
        if (clayError != nilptr)
            @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];
    } @catch (AUIException *exception) {
        @throw exception;
    } @catch (OFException *exception) {
        @throw [[AUIRenderException alloc] initWithReason: @"Root view component rendering failed"
                                           underlyingException: exception];
    } @finally {
        [AUIRenderContext _popCurrentContext];
    }

    return renderCommands;
}

- (void)_renderRenderable: (id nonnil)renderable
                identifier: (OFString *nonnil)identifier
               contextMenu: (AUIContextMenu *nillable)contextMenu
              application: (AUIApplication *nillable)application
     interactionController: (AUIInteractionController *)interactionController
     textEditingController: (AUITextEditingController *)textEditingController
{
    id renderableObject = renderable;

    if ([renderableObject isKindOfClass: AUIRetainedChildViewComponent.class]) {
        AUIRetainedChildViewComponent *retainedChildViewComponent = (AUIRetainedChildViewComponent *)renderableObject;

        [self _renderRenderable: [retainedChildViewComponent.childViewComponent _resolvedRenderedView]
                     identifier: identifier
                    contextMenu: contextMenu
                    application: application
           interactionController: interactionController
           textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewFragment.class]) {
        [self _renderChildren: ((AUIViewFragment *)renderableObject).children
              parentIdentifier: identifier
                   contextMenu: contextMenu
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewBox.class]) {
        AUIViewBox *boxView = (AUIViewBox *)renderableObject;
        AUIViewInteractionConfiguration *configuration = boxView.interactionConfiguration;
        AUIInteractionRegistration *nillable registration = nilptr;
        AUIColor backgroundColor = [AUIRenderHostSupport interactiveBackgroundWithFallback: boxView.boxProps.backgroundColor
                                                                              configuration: configuration
                                                                                  identifier: identifier
                                                                    interactionController: interactionController];

        if (configuration != nilptr or contextMenu != nilptr) {
            registration = [AUIInteractionRegistration identifier: identifier
                                                         elementID: [AUIClay elementIDFromString: identifier]];
            registration.isEnabled = (configuration != nilptr ? configuration.isEnabled : true);
            registration.isFocusable = (configuration != nilptr ? configuration.isFocusable : false);
            registration.cursorStyle = (configuration != nilptr ? configuration.cursorStyle : AUICursorStyleDefault);
            registration.contextMenu = (configuration != nilptr and configuration.contextMenu != nilptr ? configuration.contextMenu : contextMenu);
            if (configuration != nilptr)
                registration.activateHandler = configuration.activationHandler;
        }

        [self _renderBoxProps: boxView.boxProps
                      children: boxView.children
                    identifier: identifier
           backgroundOverride: backgroundColor
                   contextMenu: contextMenu
        interactionRegistration: registration
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewText.class]) {
        AUIViewText *textView = (AUIViewText *)renderableObject;
        [AUIRenderHostSupport renderText: textView.text style: textView.textStyle];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewEditableText.class]) {
        AUIViewEditableText *editableTextView = (AUIViewEditableText *)renderableObject;
        AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: identifier
                                                                             elementID: [AUIClay elementIDFromString: identifier]];
        bool focused = [interactionController isIdentifierFocused: identifier];
        AUIColor backgroundColor = (editableTextView.isEnabled ? editableTextView.colors.background : editableTextView.colors.disabledBackground);
        AUIColor borderColor = (editableTextView.isEnabled ? editableTextView.colors.border : editableTextView.colors.disabledBorder);
        AUITextStyle textStyle = editableTextView.textStyle;
        OFString *displayText;

        if (editableTextView.isEnabled and focused)
            borderColor = editableTextView.colors.focusedBorder;
        textStyle.color = (editableTextView.isEnabled ? editableTextView.colors.text : editableTextView.colors.disabledText);
        displayText = [textEditingController displayStringForText: editableTextView.text
                                                       identifier: identifier
                                                        isSecure: editableTextView.isSecure
                                                          focused: focused];
        if (displayText.length == 0 and not focused)
            textStyle.color = editableTextView.colors.placeholder;

        registration.isEnabled = editableTextView.isEnabled;
        registration.isFocusable = editableTextView.isEnabled;
        registration.isMultiline = editableTextView.isMultiline;
        registration.text = (editableTextView.text ?: @"");
        registration.cursorStyle = AUICursorStyleText;
        registration.contextMenu = (editableTextView.contextMenu ?: contextMenu);
        registration.textChangeHandler = editableTextView.textChangeHandler;
        registration.submitHandler = editableTextView.submitHandler;

        [self _renderBoxProps: (AUIBoxProps){
            .layout = editableTextView.layout,
            .backgroundColor = backgroundColor,
            .cornerRadius = editableTextView.cornerRadius,
            .border = (AUIBorder){
                .color = borderColor,
                .left = 1,
                .right = 1,
                .top = 1,
                .bottom = 1,
                .betweenChildren = 0
            },
            .scrollAxis = AUIScrollAxisNone
        }
                      children: @[
            [AUIViewText textWithText: (displayText.length > 0 ? displayText : editableTextView.placeholder)
                                         style: textStyle]
        ]
                    identifier: identifier
           backgroundOverride: backgroundColor
                   contextMenu: contextMenu
        interactionRegistration: registration
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
        return;
    }

    @throw [[AUIRenderException alloc] initWithReason: [OFString stringWithFormat: @"Unsupported renderable: %@", [renderableObject className]]];
}

- (void)_renderChildren: (OFArray<id<AUIRenderable>> *nillable)children
         parentIdentifier: (OFString *nonnil)parentIdentifier
              contextMenu: (AUIContextMenu *nillable)contextMenu
              application: (AUIApplication *nillable)application
     interactionController: (AUIInteractionController *)interactionController
     textEditingController: (AUITextEditingController *)textEditingController
{
    OFArray<id<AUIRenderable>> *effectiveChildren = [AUIRenderHostSupport childrenOrEmpty: children];

    for (size_t index = 0; index < effectiveChildren.count; index++) {
        id<AUIRenderable> child = [effectiveChildren objectAtIndex: index];

        if (child == nilptr)
            @throw [[AUIRenderException alloc] initWithReason: @"Children arrays cannot contain nil renderables"];

        [self _renderRenderable: child
                     identifier: [AUIRenderHostSupport childIdentifierForRenderable: child
                                                                      parentIdentifier: parentIdentifier
                                                                                 index: index]
                    contextMenu: contextMenu
                    application: application
           interactionController: interactionController
           textEditingController: textEditingController];
    }
}

- (void)_renderBoxProps: (AUIBoxProps)boxProps
               children: (OFArray<id<AUIRenderable>> *nillable)children
             identifier: (OFString *nonnil)identifier
    backgroundOverride: (AUIColor)backgroundOverride
            contextMenu: (AUIContextMenu *nillable)contextMenu
 interactionRegistration: (AUIInteractionRegistration *nillable)interactionRegistration
            application: (AUIApplication *nillable)application
   interactionController: (AUIInteractionController *)interactionController
   textEditingController: (AUITextEditingController *)textEditingController
{
    Clay_ElementId elementID = [AUIClay elementIDFromString: identifier];
    AUIBoxProps effectiveBoxProps = boxProps;

    (void)application;
    effectiveBoxProps.backgroundColor = backgroundOverride;
    [AUIClay openElementWithID: elementID declaration: [AUIClay boxDeclarationFromProps: effectiveBoxProps elementID: elementID]];
    @try {
        if (interactionRegistration != nilptr)
            [interactionController registerInteraction: $assert_nonnil(interactionRegistration)];

        [self _renderChildren: children
              parentIdentifier: identifier
                   contextMenu: contextMenu
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
    } @finally {
        [AUIClay closeElement];
    }
}

- (void)_renderActiveContextMenuWithInteractionController: (AUIInteractionController *)interactionController
{
    if (interactionController.activeContextMenu == nilptr or interactionController.activeContextMenu.items.count == 0)
        return;

    Clay_ElementId menuID = [AUIClay elementIDFromString: @"__context_menu__"];
    AUIBoxProps menuProps = AUI.defaultBoxProps;

    menuProps.layout.width = [AUI axisFit: 0];
    menuProps.layout.height = [AUI axisFit: 0];
    menuProps.layout.padding = [AUI insetsAll: 6];
    menuProps.layout.childGap = 4;
    menuProps.backgroundColor = [AUI colorWithRed: 248 green: 246 blue: 241 alpha: 255];
    menuProps.cornerRadius = 12;
    menuProps.border = [AUI borderAll: 1 color: [AUI colorWithRed: 212 green: 206 blue: 194 alpha: 255]];
    Clay_ElementDeclaration declaration = [AUIClay boxDeclarationFromProps: menuProps elementID: menuID];
    declaration.floating = (Clay_FloatingElementConfig){
        .offset = { .x = interactionController.activeContextMenuX, .y = interactionController.activeContextMenuY },
        .zIndex = 32767,
        .pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_CAPTURE,
        .attachTo = CLAY_ATTACH_TO_ROOT
    };

    [AUIClay openElementWithID: menuID declaration: declaration];
    @try {
        for (size_t index = 0; index < interactionController.activeContextMenu.items.count; index++) {
            AUIContextMenuItem *item = [interactionController.activeContextMenu.items objectAtIndex: index];
            OFString *identifier = [OFString stringWithFormat: @"__context_menu__/%zu", index];
            Clay_ElementId itemID = [AUIClay elementIDFromString: identifier];
            AUIBoxProps itemProps = AUI.defaultBoxProps;
            AUITextStyle itemStyle = AUI.defaultTextStyle;
            AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: identifier elementID: itemID];

            itemProps.layout.width = [AUI axisFit: 160];
            itemProps.layout.height = [AUI axisFit: 0];
            itemProps.layout.padding = [AUI insetsWithLeft: 12 right: 12 top: 8 bottom: 8];
            itemProps.backgroundColor = (item.isEnabled
                ? ([interactionController isIdentifierPressed: identifier]
                    ? [AUI colorWithRed: 221 green: 228 blue: 239 alpha: 255]
                    : ([interactionController isIdentifierHovered: identifier]
                        ? [AUI colorWithRed: 232 green: 237 blue: 245 alpha: 255]
                        : [AUI colorWithRed: 248 green: 246 blue: 241 alpha: 255]))
                : [AUI colorWithRed: 244 green: 242 blue: 238 alpha: 255]);
            itemProps.cornerRadius = 8;
            itemProps.border = [AUI borderNone];
            itemStyle.fontSize = 14;
            itemStyle.lineHeight = 18;
            itemStyle.color = (item.isEnabled
                ? [AUI colorWithRed: 32 green: 36 blue: 42 alpha: 255]
                : [AUI colorWithRed: 142 green: 146 blue: 150 alpha: 255]);

            registration.isEnabled = item.isEnabled;
            registration.cursorStyle = AUICursorStylePointer;
            registration.activateHandler = ^{
                if (item.selectHandler != nilptr)
                    item.selectHandler();
            };
            [interactionController registerInteraction: registration];

            [AUIClay openElementWithID: itemID declaration: [AUIClay boxDeclarationFromProps: itemProps elementID: itemID]];
            @try {
                [AUIRenderHostSupport renderText: item.title style: itemStyle];
            } @finally {
                [AUIClay closeElement];
            }
        }
    } @finally {
        [AUIClay closeElement];
    }
}

- (void)_runPostRenderEffects
{
    OFArray<void (^)(void)> *effects = [_postRenderEffects copy];

    [_postRenderEffects removeAllObjects];

    for (void (^effect)(void) in effects) {
        if (effect != nilptr)
            effect();
    }
}

@end

#pragma clang assume_nonnull end
