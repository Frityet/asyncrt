#import "UI/AUIRenderHost.h"
#import "UI/AUIClaySupport.h"

#pragma clang assume_nonnull begin

@namespace(AUIRenderHostSupport)

+ (OFString *)childIdentifierForRenderable: (id nillable)renderable
                          parentIdentifier: (OFString *nillable)parentIdentifier
                                     index: (size_t)index;
+ (OFArray<id<AUIRenderable>> *)childrenOrEmpty: (OFArray<id<AUIRenderable>> *nillable)children;
+ (AUIColor)interactiveBackgroundWithFallback: (AUIColor)fallbackColor
                              configuration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                                  identifier: (OFString *nillable)identifier
                    interactionController: (AUIInteractionController *)interactionController;
+ (void)renderText: (OFString *nillable)text style: (AUITextStyle)textStyle;

@end

@namespace_implementation(AUIRenderHostSupport)

+ (OFString *)childIdentifierForRenderable: (id nillable)renderable
                          parentIdentifier: (OFString *nillable)parentIdentifier
                                     index: (size_t)index
{
    OFString *token = nilptr;

    if (renderable == nilptr or parentIdentifier == nilptr)
        @throw [OFInvalidArgumentException exception];

    if ([renderable isKindOfClass: AUIRetainedChildViewComponentNode.class])
        token = [OFString stringWithFormat: @"component:%@", ((AUIRetainedChildViewComponentNode *)renderable).componentKey];
    else if ([renderable isKindOfClass: AUIViewNode.class] and ((AUIViewNode *)renderable).stableKey != nilptr)
        token = [OFString stringWithFormat: @"node:%@", $assert_nonnil(((AUIViewNode *)renderable).stableKey)];

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

@interface AUIRenderHost ()

- (void)_renderRenderable: (id nillable)renderable
                identifier: (OFString *nillable)identifier
               contextMenu: (AUIContextMenu *nillable)contextMenu
              application: (AUIApplication *nillable)application
     interactionController: (AUIInteractionController *)interactionController
     textEditingController: (AUITextEditingController *)textEditingController;
- (void)_renderChildren: (OFArray<id<AUIRenderable>> *nillable)children
         parentIdentifier: (OFString *nillable)parentIdentifier
              contextMenu: (AUIContextMenu *nillable)contextMenu
              application: (AUIApplication *nillable)application
     interactionController: (AUIInteractionController *)interactionController
     textEditingController: (AUITextEditingController *)textEditingController;
- (void)_renderBoxProps: (AUIBoxProps)boxProps
               children: (OFArray<id<AUIRenderable>> *nillable)children
             identifier: (OFString *nillable)identifier
    backgroundOverride: (AUIColor)backgroundOverride
            contextMenu: (AUIContextMenu *nillable)contextMenu
 interactionRegistration: (AUIInteractionRegistration *nillable)interactionRegistration
            application: (AUIApplication *nillable)application
   interactionController: (AUIInteractionController *)interactionController
   textEditingController: (AUITextEditingController *)textEditingController;
- (void)_renderActiveContextMenuWithInteractionController: (AUIInteractionController *)interactionController;
- (void)_runPostRenderEffects;

@end

@implementation AUIRenderHost {
    AUIApplication *nillable _application;
    AUIViewComponent *nillable _rootViewComponent;
    OFMutableArray<void (^)(void)> *_postRenderEffects;
}

- (instancetype)initWithApplication: (AUIApplication *nillable)application
{
    if (application == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    _postRenderEffects = [OFMutableArray array];
    return self;
}

- (void)attachRootViewComponent: (AUIViewComponent *nillable)rootViewComponent
                      taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    if (rootViewComponent == nilptr or taskGroup == nilptr)
        @throw [OFInvalidArgumentException exception];

    [self detachRootViewComponent];
    _rootViewComponent = $assert_nonnil(rootViewComponent);
    [_rootViewComponent _attachToApplication: _application parentViewComponent: nilptr taskGroup: $assert_nonnil(taskGroup)];
    [_rootViewComponent _ensureMountedInTaskGroup: $assert_nonnil(taskGroup)];
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

- (void)enqueuePostRenderEffect: (void (^nillable)(void))effectBlock
{
    if (effectBlock == nilptr)
        @throw [OFInvalidArgumentException exception];

    [_postRenderEffects addObject: $assert_nonnil([effectBlock copy])];
}

- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *nillable)inputState
                                                        window: (AUIWindow *nillable)window
                                         interactionController: (AUIInteractionController *nillable)interactionController
                                         textEditingController: (AUITextEditingController *nillable)textEditingController
                                                 clipboardText: (OFString *nillable (^nillable)(void))clipboardTextProvider
                                           setClipboardText: (void (^nillable)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nillable)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nillable)(void))renderRequester
{
    AUIRenderContext *context;
    Clay_RenderCommandArray renderCommands;
    OFString *nillable clayError = nilptr;
    OFDate *frameDate = OFDate.date;
    OFTimeInterval elapsedTime = 0;
    AUIViewNode *rootViewNode;
    OFString *rootIdentifier = @"root";
    AUIInputState *safeInputState;
    AUIWindow *safeWindow;
    AUIInteractionController *safeInteractionController;
    AUITextEditingController *safeTextEditingController;
    OFString *nillable (^safeClipboardTextProvider)(void);
    void (^safeClipboardTextSetter)(OFString *nillable text);
    void (^safeCursorSetter)(AUICursorStyle cursorStyle);
    void (^safeRenderRequester)(void);

    if (_rootViewComponent == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render without a root view component"];
    if (inputState == nilptr or window == nilptr or interactionController == nilptr or textEditingController == nilptr or
        clipboardTextProvider == nilptr or clipboardTextSetter == nilptr or cursorSetter == nilptr or renderRequester == nilptr)
        @throw [OFInvalidArgumentException exception];

    safeInputState = $assert_nonnil(inputState);
    safeWindow = $assert_nonnil(window);
    safeInteractionController = $assert_nonnil(interactionController);
    safeTextEditingController = $assert_nonnil(textEditingController);
    safeClipboardTextProvider = clipboardTextProvider;
    safeClipboardTextSetter = clipboardTextSetter;
    safeCursorSetter = cursorSetter;
    safeRenderRequester = renderRequester;

    context = [[AUIRenderContext alloc]
        initWithApplication: _application
                     window: safeWindow
               viewportSize: viewportSize
                  frameDate: frameDate
                elapsedTime: elapsedTime];

    [_postRenderEffects removeAllObjects];
    [AUIClay clearError];
    [AUIClay setLayoutDimensions: viewportSize];
    [AUIClay setPointerPositionX: safeInputState.pointerX
                                y: safeInputState.pointerY
                             down: safeInputState.isPrimaryButtonDown];
    [safeInteractionController beginFrame];
    [AUIRenderContext _pushCurrentContext: context];

    @try {
        [AUIClay beginLayout];
        rootViewNode = [_rootViewComponent _resolvedRenderedViewNode];
        if (rootViewNode.stableKey != nilptr)
            rootIdentifier = [AUIRenderHostSupport childIdentifierForRenderable: rootViewNode parentIdentifier: @"root" index: 0];

        [self _renderRenderable: rootViewNode
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

- (void)_renderRenderable: (id nillable)renderable
                identifier: (OFString *nillable)identifier
               contextMenu: (AUIContextMenu *nillable)contextMenu
              application: (AUIApplication *nillable)application
     interactionController: (AUIInteractionController *)interactionController
     textEditingController: (AUITextEditingController *)textEditingController
{
    id renderableObject;
    OFString *safeIdentifier;

    if (renderable == nilptr or identifier == nilptr)
        @throw [OFInvalidArgumentException exception];

    renderableObject = renderable;
    safeIdentifier = $assert_nonnil(identifier);

    if ([renderableObject isKindOfClass: AUIRetainedChildViewComponentNode.class]) {
        AUIRetainedChildViewComponentNode *childNode = (AUIRetainedChildViewComponentNode *)renderableObject;

        [self _renderRenderable: [childNode.childViewComponent _resolvedRenderedViewNode]
                     identifier: safeIdentifier
                    contextMenu: contextMenu
                    application: application
           interactionController: interactionController
           textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewFragmentNode.class]) {
        [self _renderChildren: ((AUIViewFragmentNode *)renderableObject).children
              parentIdentifier: safeIdentifier
                   contextMenu: contextMenu
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewBoxNode.class]) {
        AUIViewBoxNode *boxNode = (AUIViewBoxNode *)renderableObject;
        AUIViewInteractionConfiguration *configuration = boxNode.interactionConfiguration;
        AUIInteractionRegistration *nillable registration = nilptr;
        AUIColor backgroundColor = [AUIRenderHostSupport interactiveBackgroundWithFallback: boxNode.boxProps.backgroundColor
                                                                              configuration: configuration
                                                                                  identifier: safeIdentifier
                                                                    interactionController: interactionController];

        if (configuration != nilptr or contextMenu != nilptr) {
            registration = [AUIInteractionRegistration identifier: safeIdentifier
                                                         elementID: [AUIClay elementIDFromString: safeIdentifier]];
            registration.isEnabled = (configuration != nilptr ? configuration.isEnabled : true);
            registration.isFocusable = (configuration != nilptr ? configuration.isFocusable : false);
            registration.cursorStyle = (configuration != nilptr ? configuration.cursorStyle : AUICursorStyleDefault);
            registration.contextMenu = (configuration != nilptr and configuration.contextMenu != nilptr ? configuration.contextMenu : contextMenu);
            if (configuration != nilptr)
                registration.activateHandler = configuration.activationHandler;
        }

        [self _renderBoxProps: boxNode.boxProps
                      children: boxNode.children
                    identifier: safeIdentifier
           backgroundOverride: backgroundColor
                   contextMenu: contextMenu
        interactionRegistration: registration
                   application: application
          interactionController: interactionController
          textEditingController: textEditingController];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewTextNode.class]) {
        AUIViewTextNode *textNode = (AUIViewTextNode *)renderableObject;
        [AUIRenderHostSupport renderText: textNode.text style: textNode.textStyle];
        return;
    }

    if ([renderableObject isKindOfClass: AUIViewEditableTextNode.class]) {
        AUIViewEditableTextNode *textNode = (AUIViewEditableTextNode *)renderableObject;
        AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: safeIdentifier
                                                                             elementID: [AUIClay elementIDFromString: safeIdentifier]];
        bool focused = [interactionController isIdentifierFocused: safeIdentifier];
        AUIColor backgroundColor = (textNode.isEnabled ? textNode.colors.background : textNode.colors.disabledBackground);
        AUIColor borderColor = (textNode.isEnabled ? textNode.colors.border : textNode.colors.disabledBorder);
        AUITextStyle textStyle = textNode.textStyle;
        OFString *displayText;

        if (textNode.isEnabled and focused)
            borderColor = textNode.colors.focusedBorder;
        textStyle.color = (textNode.isEnabled ? textNode.colors.text : textNode.colors.disabledText);
        displayText = [textEditingController displayStringForText: textNode.text
                                                       identifier: safeIdentifier
                                                        isSecure: textNode.isSecure
                                                          focused: focused];
        if (displayText.length == 0 and not focused)
            textStyle.color = textNode.colors.placeholder;

        registration.isEnabled = textNode.isEnabled;
        registration.isFocusable = textNode.isEnabled;
        registration.isMultiline = textNode.isMultiline;
        registration.text = (textNode.text ?: @"");
        registration.cursorStyle = AUICursorStyleText;
        registration.contextMenu = (textNode.contextMenu ?: contextMenu);
        registration.textChangeHandler = textNode.textChangeHandler;
        registration.submitHandler = textNode.submitHandler;

        [self _renderBoxProps: (AUIBoxProps){
            .layout = textNode.layout,
            .backgroundColor = backgroundColor,
            .cornerRadius = textNode.cornerRadius,
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
            [AUIViewTextNode textNodeWithText: (displayText.length > 0 ? displayText : textNode.placeholder)
                                         style: textStyle]
        ]
                    identifier: safeIdentifier
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
         parentIdentifier: (OFString *nillable)parentIdentifier
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
             identifier: (OFString *nillable)identifier
    backgroundOverride: (AUIColor)backgroundOverride
            contextMenu: (AUIContextMenu *nillable)contextMenu
 interactionRegistration: (AUIInteractionRegistration *nillable)interactionRegistration
            application: (AUIApplication *nillable)application
   interactionController: (AUIInteractionController *)interactionController
   textEditingController: (AUITextEditingController *)textEditingController
{
    OFString *safeIdentifier = $assert_nonnil(identifier);
    Clay_ElementId elementID = [AUIClay elementIDFromString: safeIdentifier];
    AUIBoxProps effectiveBoxProps = boxProps;

    (void)application;
    effectiveBoxProps.backgroundColor = backgroundOverride;
    [AUIClay openElementWithID: elementID declaration: [AUIClay boxDeclarationFromProps: effectiveBoxProps elementID: elementID]];
    @try {
        if (interactionRegistration != nilptr)
            [interactionController registerInteraction: $assert_nonnil(interactionRegistration)];

        [self _renderChildren: children
              parentIdentifier: safeIdentifier
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
    AUIBoxProps menuProps = [AUI boxProps];
    Clay_ElementDeclaration declaration;

    menuProps.layout.width = [AUI axisFit: 0];
    menuProps.layout.height = [AUI axisFit: 0];
    menuProps.layout.padding = [AUI insetsAll: 6];
    menuProps.layout.childGap = 4;
    menuProps.backgroundColor = [AUI colorWithRed: 248 green: 246 blue: 241 alpha: 255];
    menuProps.cornerRadius = 12;
    menuProps.border = [AUI borderAll: 1 color: [AUI colorWithRed: 212 green: 206 blue: 194 alpha: 255]];
    declaration = [AUIClay boxDeclarationFromProps: menuProps elementID: menuID];
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
            AUIBoxProps itemProps = [AUI boxProps];
            AUITextStyle itemStyle = [AUI textStyle];
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
