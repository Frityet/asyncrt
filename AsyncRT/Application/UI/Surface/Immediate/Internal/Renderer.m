#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Renderer.h>

#import <AsyncRT/Application/UI/Application.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Box.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Button.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ContextMenu.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ContextMenuItem.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Group.h>
#import <AsyncRT/Application/UI/Surface/Immediate/KeyedContent.h>
#import <AsyncRT/Application/UI/Surface/Immediate/RenderContext.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Stack.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Text.h>
#import <AsyncRT/Application/UI/Surface/Immediate/TextField.h>
#import <AsyncRT/Application/UI/Window/Window.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/RenderContext+Private.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUIRendererSupport)

+ (AsyncUIColorValue *)fallbackColor: (AsyncUIColorValue *nillable)color;
+ (AsyncUIEdgeInsets *)fallbackInsets: (AsyncUIEdgeInsets *nillable)insets;
+ (Clay_Color)clayColorFromColor: (AsyncUIColorValue *nillable)color;
+ (Clay_Padding)clayPaddingFromInsets: (AsyncUIEdgeInsets *nillable)insets;
+ (Clay_SizingAxis)claySizingFromAxis: (AsyncUIAxisSize *nillable)axis;
+ (Clay_LayoutDirection)clayDirectionFromDirection: (AsyncUIStackDirection)direction;
+ (Clay_LayoutAlignmentX)clayAlignmentXFromAlignment: (AsyncUIContentAlignment)alignment;
+ (Clay_LayoutAlignmentY)clayAlignmentYFromAlignment: (AsyncUIContentAlignment)alignment;
+ (Clay_TextElementConfigWrapMode)clayWrapModeFromWrapStyle: (AsyncUITextWrapStyle)wrapStyle;
+ (Clay_TextAlignment)clayTextAlignmentFromAlignment: (AsyncUITextHorizontalAlignment)alignment;
+ (Clay_ClipElementConfig)clipConfigForScrollBehavior: (AsyncUIScrollBehavior)scrollBehavior
                                             elementID: (Clay_ElementId)elementID;
+ (Clay_LayoutConfig)layoutConfigFromLayout: (AsyncUIStackLayout *nillable)layout;
+ (Clay_BorderElementConfig)borderFromBorderStyle: (AsyncUIBorderStyle *nillable)borderStyle;
+ (Clay_TextElementConfig)textConfigFromTextStyle: (AsyncUITextStyle *)textStyle
                                      textColor: (AsyncUIColorValue *nillable)textColorOverride;
+ (Clay_ElementDeclaration)declarationWithLayout: (AsyncUIStackLayout *)layout
                                 backgroundColor: (AsyncUIColorValue *nillable)backgroundColor
                                    cornerRadius: (float)cornerRadius
                                     borderStyle: (AsyncUIBorderStyle *nillable)borderStyle
                                  scrollBehavior: (AsyncUIScrollBehavior)scrollBehavior
                                       elementID: (Clay_ElementId)elementID;
+ (OFArray<id<AsyncUIContent>> *)childrenOrEmpty: (OFArray<id<AsyncUIContent>> *nillable)children;
+ (OFString *)identifierForToken: (OFString *)token parentIdentifier: (OFString *)parentIdentifier;
+ (AsyncUIColorValue *)interactiveColorWithFallback: (AsyncUIColorValue *)fallbackColor
                                    interaction: (AsyncUIInteraction *nillable)interaction
                                     identifier: (OFString *)identifier
                              interactionEngine: (AsyncUIInteractionEngine *)interactionEngine;

@end

@namespace_implementation(AsyncUIRendererSupport)

+ (AsyncUIColorValue *)fallbackColor: (AsyncUIColorValue *nillable)color
{
    return (color ?: AsyncUIColorValue.clear);
}

+ (AsyncUIEdgeInsets *)fallbackInsets: (AsyncUIEdgeInsets *nillable)insets
{
    return (insets ?: [AsyncUIEdgeInsets all: 0]);
}

+ (Clay_Color)clayColorFromColor: (AsyncUIColorValue *nillable)color
{
    AsyncUIColorValue *safeColor = [self fallbackColor: color];

    return (Clay_Color){
        .r = safeColor.red,
        .g = safeColor.green,
        .b = safeColor.blue,
        .a = safeColor.alpha
    };
}

+ (Clay_Padding)clayPaddingFromInsets: (AsyncUIEdgeInsets *nillable)insets
{
    AsyncUIEdgeInsets *safeInsets = [self fallbackInsets: insets];

    return (Clay_Padding){
        .left = safeInsets.left,
        .right = safeInsets.right,
        .top = safeInsets.top,
        .bottom = safeInsets.bottom
    };
}

+ (Clay_SizingAxis)claySizingFromAxis: (AsyncUIAxisSize *nillable)axis
{
    AsyncUIAxisSize *safeAxis = (axis ?: AsyncUIAxisSize.grow);

    switch (safeAxis.mode) {
        case AsyncUIAxisSizeModeFixed:
            return CLAY_SIZING_FIXED(safeAxis.value);
        case AsyncUIAxisSizeModePercent:
            return CLAY_SIZING_PERCENT(safeAxis.value);
        case AsyncUIAxisSizeModeFit:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = safeAxis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_FIT
            };
        case AsyncUIAxisSizeModeGrow:
        default:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = safeAxis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_GROW
            };
    }
}

+ (Clay_LayoutDirection)clayDirectionFromDirection: (AsyncUIStackDirection)direction
{
    return (direction == AsyncUIStackDirectionHorizontal ? CLAY_LEFT_TO_RIGHT : CLAY_TOP_TO_BOTTOM);
}

+ (Clay_LayoutAlignmentX)clayAlignmentXFromAlignment: (AsyncUIContentAlignment)alignment
{
    switch (alignment) {
        case AsyncUIContentAlignmentCenter:
            return CLAY_ALIGN_X_CENTER;
        case AsyncUIContentAlignmentEnd:
            return CLAY_ALIGN_X_RIGHT;
        case AsyncUIContentAlignmentStart:
        default:
            return CLAY_ALIGN_X_LEFT;
    }
}

+ (Clay_LayoutAlignmentY)clayAlignmentYFromAlignment: (AsyncUIContentAlignment)alignment
{
    switch (alignment) {
        case AsyncUIContentAlignmentCenter:
            return CLAY_ALIGN_Y_CENTER;
        case AsyncUIContentAlignmentEnd:
            return CLAY_ALIGN_Y_BOTTOM;
        case AsyncUIContentAlignmentStart:
        default:
            return CLAY_ALIGN_Y_TOP;
    }
}

+ (Clay_TextElementConfigWrapMode)clayWrapModeFromWrapStyle: (AsyncUITextWrapStyle)wrapStyle
{
    switch (wrapStyle) {
        case AsyncUITextWrapStyleNewlines:
            return CLAY_TEXT_WRAP_NEWLINES;
        case AsyncUITextWrapStyleNone:
            return CLAY_TEXT_WRAP_NONE;
        case AsyncUITextWrapStyleWords:
        default:
            return CLAY_TEXT_WRAP_WORDS;
    }
}

+ (Clay_TextAlignment)clayTextAlignmentFromAlignment: (AsyncUITextHorizontalAlignment)alignment
{
    switch (alignment) {
        case AsyncUITextHorizontalAlignmentCenter:
            return CLAY_TEXT_ALIGN_CENTER;
        case AsyncUITextHorizontalAlignmentTrailing:
            return CLAY_TEXT_ALIGN_RIGHT;
        case AsyncUITextHorizontalAlignmentLeading:
        default:
            return CLAY_TEXT_ALIGN_LEFT;
    }
}

+ (Clay_ClipElementConfig)clipConfigForScrollBehavior: (AsyncUIScrollBehavior)scrollBehavior
                                             elementID: (Clay_ElementId)elementID
{
    Clay_ClipElementConfig config = {0};

    switch (scrollBehavior) {
        case AsyncUIScrollBehaviorHorizontal:
            config.horizontal = true;
            break;
        case AsyncUIScrollBehaviorVertical:
            config.vertical = true;
            break;
        case AsyncUIScrollBehaviorBoth:
            config.horizontal = true;
            config.vertical = true;
            break;
        case AsyncUIScrollBehaviorNone:
        default:
            break;
    }

    if ((config.horizontal or config.vertical) and elementID.id != 0) {
        Clay_ScrollContainerData scrollData = [AsyncUIClayRuntime scrollContainerDataForID: elementID];

        if (scrollData.found and scrollData.scrollPosition != nullptr)
            config.childOffset = *scrollData.scrollPosition;
    }

    return config;
}

+ (Clay_LayoutConfig)layoutConfigFromLayout: (AsyncUIStackLayout *nillable)layout
{
    AsyncUIStackLayout *safeLayout = (layout ?: AsyncUIStackLayout.vertical);

    return (Clay_LayoutConfig){
        .sizing = {
            .width = [self claySizingFromAxis: safeLayout.width],
            .height = [self claySizingFromAxis: safeLayout.height]
        },
        .padding = [self clayPaddingFromInsets: safeLayout.padding],
        .childGap = safeLayout.spacing,
        .childAlignment = {
            .x = [self clayAlignmentXFromAlignment: safeLayout.horizontalAlignment],
            .y = [self clayAlignmentYFromAlignment: safeLayout.verticalAlignment]
        },
        .layoutDirection = [self clayDirectionFromDirection: safeLayout.direction]
    };
}

+ (Clay_BorderElementConfig)borderFromBorderStyle: (AsyncUIBorderStyle *nillable)borderStyle
{
    AsyncUIBorderStyle *safeBorder = (borderStyle ?: AsyncUIBorderStyle.none);

    return (Clay_BorderElementConfig){
        .color = [self clayColorFromColor: safeBorder.color],
        .width = {
            .left = safeBorder.leftWidth,
            .right = safeBorder.rightWidth,
            .top = safeBorder.topWidth,
            .bottom = safeBorder.bottomWidth,
            .betweenChildren = safeBorder.betweenChildrenWidth
        }
    };
}

+ (Clay_TextElementConfig)textConfigFromTextStyle: (AsyncUITextStyle *)textStyle
                                      textColor: (AsyncUIColorValue *nillable)textColorOverride
{
    AsyncUITextStyle *safeStyle = (textStyle ?: AsyncUITextStyle.body);
    AsyncUIColorValue *color = (textColorOverride ?: safeStyle.color);

    return (Clay_TextElementConfig){
        .textColor = [self clayColorFromColor: color],
        .fontId = safeStyle.fontID,
        .fontSize = safeStyle.fontSize,
        .letterSpacing = safeStyle.letterSpacing,
        .lineHeight = safeStyle.lineHeight,
        .wrapMode = [self clayWrapModeFromWrapStyle: safeStyle.wrapStyle],
        .textAlignment = [self clayTextAlignmentFromAlignment: safeStyle.alignment]
    };
}

+ (Clay_ElementDeclaration)declarationWithLayout: (AsyncUIStackLayout *)layout
                                 backgroundColor: (AsyncUIColorValue *nillable)backgroundColor
                                    cornerRadius: (float)cornerRadius
                                     borderStyle: (AsyncUIBorderStyle *nillable)borderStyle
                                  scrollBehavior: (AsyncUIScrollBehavior)scrollBehavior
                                       elementID: (Clay_ElementId)elementID
{
    Clay_ElementDeclaration declaration = {0};

    declaration.layout = [self layoutConfigFromLayout: layout];
    declaration.backgroundColor = [self clayColorFromColor: backgroundColor];
    declaration.cornerRadius = CLAY_CORNER_RADIUS(cornerRadius);
    declaration.border = [self borderFromBorderStyle: borderStyle];
    declaration.clip = [self clipConfigForScrollBehavior: scrollBehavior elementID: elementID];
    return declaration;
}

+ (OFArray<id<AsyncUIContent>> *)childrenOrEmpty: (OFArray<id<AsyncUIContent>> *nillable)children
{
    return (children ?: [OFArray array]);
}

+ (OFString *)identifierForToken: (OFString *)token parentIdentifier: (OFString *)parentIdentifier
{
    return [OFString stringWithFormat: @"%@/%@", parentIdentifier, token];
}

+ (AsyncUIColorValue *)interactiveColorWithFallback: (AsyncUIColorValue *)fallbackColor
                                    interaction: (AsyncUIInteraction *nillable)interaction
                                     identifier: (OFString *)identifier
                              interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
{
    if (interaction == nilptr or interaction.feedbackColors == nilptr)
        return fallbackColor;
    if (not interaction.isEnabled)
        return (interaction.feedbackColors.disabledColor ?: fallbackColor);
    if ([interactionEngine isIdentifierPressed: identifier])
        return (interaction.feedbackColors.pressedColor ?: fallbackColor);
    if ([interactionEngine isIdentifierHovered: identifier])
        return (interaction.feedbackColors.hoverColor ?: fallbackColor);
    return (interaction.feedbackColors.normalColor ?: fallbackColor);
}

@end

[[direct_members]]
@implementation AsyncUIRenderer {
    AsyncUIApplication *_application;
    id<AsyncUIContent> nillable _rootContent;
    AsyncUIComponentHost *nillable _rootHost;
    OFMutableArray<void (^)(void)> *_postRenderEffects;
}

- (instancetype)initWithApplication: (AsyncUIApplication *)application
{
    self = [super init];
    _application = application;
    _postRenderEffects = [OFMutableArray array];
    return self;
}

- (id<AsyncUIContent> nillable)rootContent
{
    return _rootContent;
}

- (void)attachRootContent: (id<AsyncUIContent>)rootContent
                taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    [self detachRootContent];
    _rootContent = rootContent;
    _rootHost = [[AsyncUIComponentHost alloc] initWithOwner: nilptr];
    [_rootHost attachToApplication: _application parentHost: nilptr taskGroup: taskGroup];
    if (taskGroup != nilptr)
        [_rootHost ensureMountedInTaskGroup: $assert_nonnil(taskGroup)];
}

- (void)detachRootContent
{
    if (_rootHost == nilptr)
        return;

    [_rootHost unmountRecursively];
    [_rootHost detachFromApplication];
    _rootHost = nilptr;
    _rootContent = nilptr;
}

- (void)enqueuePostRenderEffect: (void (^nonnil)(void))effectBlock
{
    [_postRenderEffects addObject: [effectBlock copy]];
}

- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AsyncUIInputState *)inputState
                                                        window: (AsyncUIWindow *)window
                                             interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
                                                 textInput: (AsyncUITextInputEngine *)textInput
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester
{
    OFString *nillable clayError = nilptr;

    if (_rootContent == nilptr or _rootHost == nilptr)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Cannot render without root content"];

    auto frameDate = OFDate.date;
    auto context = [[AsyncUIRenderContext alloc] initWithApplication: _application
                                                          window: window
                                                    viewportSize: viewportSize
                                                       frameDate: frameDate
                                                     elapsedTime: 0];
    Clay_RenderCommandArray renderCommands = (Clay_RenderCommandArray){0};

    [_postRenderEffects removeAllObjects];
    [AsyncUIClayRuntime clearError];
    AsyncUIClayRuntime.layoutDimensions = viewportSize;
    [AsyncUIClayRuntime updatePointerPositionX: inputState.pointerX
                                      y: inputState.pointerY
                                   down: inputState.isPrimaryButtonDown];
    [interactionEngine beginFrame];
    [AsyncUIRenderContext _pushCurrentContext: context];

    @try {
        [AsyncUIClayRuntime beginLayout];
        [_rootHost beginContentTraversal];
        @try {
            [self _renderResolvedContent: $assert_nonnil(_rootContent)
                               identifier: @"root"
                        parentContextMenu: nilptr
                             currentHost: $assert_nonnil(_rootHost)
                           interactionEngine: interactionEngine
                               textInput: textInput];
        } @finally {
            [_rootHost endContentTraversalWithRenderer: self];
        }
        [self _renderActiveContextMenuWithInteractionEngine: interactionEngine];

        renderCommands = [AsyncUIClayRuntime endLayoutWithDeltaTime: deltaTime];
        [AsyncUIClayRuntime updateScrollContainersWithDragScrolling: true
                                                         deltaX: inputState.scrollDeltaX
                                                         deltaY: inputState.scrollDeltaY
                                                      deltaTime: deltaTime];
        [interactionEngine completeFrameWithInputState: inputState
                                             textInput: textInput
                                          clipboardText: clipboardTextProvider
                                    setClipboardText: clipboardTextSetter
                                         cursorSetter: cursorSetter
                                      renderRequester: renderRequester];
        [self _runPostRenderEffects];

        clayError = [AsyncUIClayRuntime consumeError];
        if (clayError != nilptr)
            @throw [[AsyncUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];
    } @catch (AsyncUIException *exception) {
        @throw exception;
    } @catch (OFException *exception) {
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Root content rendering failed"
                                       underlyingException: exception];
    } @finally {
        [AsyncUIRenderContext _popCurrentContext];
    }

    return renderCommands;
}

- (void)_renderResolvedContent: (id<AsyncUIContent>)content
                    identifier: (OFString *)identifier
             parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
                  currentHost: (AsyncUIComponentHost *)currentHost
            interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
                textInput: (AsyncUITextInputEngine *)textInput
{
    id<AsyncUIContent> actualContent = content;

    if ([(OFObject *)actualContent isKindOfClass: AsyncUIKeyedContent.class])
        actualContent = ((AsyncUIKeyedContent *)actualContent).content;

    if ([(OFObject *)actualContent isKindOfClass: AsyncUIComponent.class]) {
        AsyncUIComponentHost *childHost = [currentHost resolveChildHostForComponent: (AsyncUIComponent *)actualContent key: @"root"];

        [childHost beginContentTraversal];
        @try {
            [self _renderResolvedContent: [childHost resolvedRenderedContent]
                               identifier: identifier
                        parentContextMenu: parentContextMenu
                             currentHost: childHost
                       interactionEngine: interactionEngine
                           textInput: textInput];
        } @finally {
            [childHost endContentTraversalWithRenderer: self];
        }
        return;
    }

    switch (actualContent.contentKind) {
        case AsyncUIContentKindGroup:
            [self _renderChildren: ((AsyncUIGroup *)actualContent).children
                  parentIdentifier: identifier
                parentContextMenu: parentContextMenu
                     currentHost: currentHost
               interactionEngine: interactionEngine
                   textInput: textInput];
            return;
        case AsyncUIContentKindStack:
            [self _renderStack: (AsyncUIStack *)actualContent
                     identifier: identifier
              parentContextMenu: parentContextMenu
                   currentHost: currentHost
             interactionEngine: interactionEngine
                 textInput: textInput];
            return;
        case AsyncUIContentKindBox:
            [self _renderBox: (AsyncUIBox *)actualContent
                   identifier: identifier
            parentContextMenu: parentContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
            return;
        case AsyncUIContentKindText:
            [self _renderTextContent: (AsyncUIText *)actualContent];
            return;
        case AsyncUIContentKindButton:
            [self _renderButton: (AsyncUIButton *)actualContent
                      identifier: identifier
               parentContextMenu: parentContextMenu
                    currentHost: currentHost
              interactionEngine: interactionEngine];
            return;
        case AsyncUIContentKindTextField:
            [self _renderTextField: (AsyncUITextField *)actualContent
                         identifier: identifier
                  parentContextMenu: parentContextMenu
                       currentHost: currentHost
                 interactionEngine: interactionEngine
                     textInput: textInput];
            return;
        case AsyncUIContentKindComponent:
        case AsyncUIContentKindKeyed:
        default:
            return;
    }
}

- (void)_renderChildren: (OFArray<id<AsyncUIContent>> *)children
          parentIdentifier: (OFString *)parentIdentifier
        parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
             currentHost: (AsyncUIComponentHost *)currentHost
       interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
           textInput: (AsyncUITextInputEngine *)textInput
{
    OFArray<id<AsyncUIContent>> *safeChildren = [AsyncUIRendererSupport childrenOrEmpty: children];

    for (size_t index = 0; index < safeChildren.count; index++) {
        id<AsyncUIContent> child = [safeChildren objectAtIndex: index];
        OFString *token = [OFString stringWithFormat: @"%zu", index];
        id<AsyncUIContent> actualChild = child;

        if ([(OFObject *)child isKindOfClass: AsyncUIKeyedContent.class]) {
            token = ((AsyncUIKeyedContent *)child).key;
            actualChild = ((AsyncUIKeyedContent *)child).content;
        }

        OFString *childIdentifier = [AsyncUIRendererSupport identifierForToken: token parentIdentifier: parentIdentifier];

        if ([(OFObject *)actualChild isKindOfClass: AsyncUIComponent.class]) {
            AsyncUIComponentHost *childHost = [currentHost resolveChildHostForComponent: (AsyncUIComponent *)actualChild key: token];

            [childHost beginContentTraversal];
            @try {
                [self _renderResolvedContent: [childHost resolvedRenderedContent]
                                   identifier: childIdentifier
                            parentContextMenu: parentContextMenu
                                 currentHost: childHost
                           interactionEngine: interactionEngine
                               textInput: textInput];
            } @finally {
                [childHost endContentTraversalWithRenderer: self];
            }
            continue;
        }

        [self _renderResolvedContent: actualChild
                           identifier: childIdentifier
                    parentContextMenu: parentContextMenu
                         currentHost: currentHost
                   interactionEngine: interactionEngine
                       textInput: textInput];
    }
}

- (void)_renderStack: (AsyncUIStack *)stack
           identifier: (OFString *)identifier
    parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
         currentHost: (AsyncUIComponentHost *)currentHost
   interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
       textInput: (AsyncUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AsyncUIClayRuntime elementIDFromString: identifier];
    Clay_ElementDeclaration declaration = [AsyncUIRendererSupport declarationWithLayout: stack.layout
                                                                    backgroundColor: AsyncUIColorValue.clear
                                                                       cornerRadius: 0
                                                                        borderStyle: AsyncUIBorderStyle.none
                                                                     scrollBehavior: stack.layout.scrollBehavior
                                                                          elementID: elementID];

    [AsyncUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        [self _renderChildren: stack.children
              parentIdentifier: identifier
            parentContextMenu: parentContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
    } @finally {
        [AsyncUIClayRuntime closeElement];
    }
}

- (void)_renderBox: (AsyncUIBox *)box
         identifier: (OFString *)identifier
  parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
       currentHost: (AsyncUIComponentHost *)currentHost
 interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
     textInput: (AsyncUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AsyncUIClayRuntime elementIDFromString: identifier];
    AsyncUIColorValue *backgroundColor = [AsyncUIRendererSupport interactiveColorWithFallback: box.style.backgroundColor
                                                                           interaction: box.interaction
                                                                            identifier: identifier
                                                                     interactionEngine: interactionEngine];
    Clay_ElementDeclaration declaration = [AsyncUIRendererSupport declarationWithLayout: box.layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: box.style.cornerRadius
                                                                        borderStyle: box.style.borderStyle
                                                                     scrollBehavior: box.layout.scrollBehavior
                                                                          elementID: elementID];
    AsyncUIInteractionRegistration *nillable registration = nilptr;
    AsyncUIContextMenu *childContextMenu = parentContextMenu;

    if (box.interaction != nilptr or parentContextMenu != nilptr) {
        registration = [AsyncUIInteractionRegistration identifier: identifier elementID: elementID];
        registration.isEnabled = (box.interaction != nilptr ? box.interaction.isEnabled : true);
        registration.isFocusable = (box.interaction != nilptr ? box.interaction.isFocusable : false);
        registration.cursorStyle = (box.interaction != nilptr ? box.interaction.cursorStyle : AsyncUICursorStyleDefault);
        registration.contextMenu = (box.interaction != nilptr and box.interaction.contextMenu != nilptr
            ? box.interaction.contextMenu
            : parentContextMenu);
        registration.activationAction = box.interaction.activationAction;
        registration.taskGroup = currentHost.mountedTaskGroup;
        childContextMenu = registration.contextMenu;
        [interactionEngine registerInteraction: $assert_nonnil(registration)];
    }

    [AsyncUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        [self _renderChildren: box.children
              parentIdentifier: identifier
            parentContextMenu: childContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
    } @finally {
        [AsyncUIClayRuntime closeElement];
    }
}

- (void)_renderTextContent: (AsyncUIText *)text
{
    Clay_TextElementConfig textConfig = [AsyncUIRendererSupport textConfigFromTextStyle: text.style textColor: nilptr];
    CLAY_TEXT([AsyncUIClayRuntime stringFromString: text.string], CLAY_TEXT_CONFIG(textConfig));
}

- (void)_renderButton: (AsyncUIButton *)button
            identifier: (OFString *)identifier
     parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
          currentHost: (AsyncUIComponentHost *)currentHost
    interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
{
    Clay_ElementId elementID = [AsyncUIClayRuntime elementIDFromString: identifier];
    auto buttonInteraction = [[AsyncUIInteraction alloc] init];
    buttonInteraction.activationAction = button.action;
    buttonInteraction.cursorStyle = AsyncUICursorStylePointer;
    AsyncUIColorValue *backgroundColor = (button.isEnabled
        ? [AsyncUIRendererSupport interactiveColorWithFallback: button.style.backgroundColors.normalColor
                                               interaction: buttonInteraction
                                                identifier: identifier
                                         interactionEngine: interactionEngine]
        : button.style.backgroundColors.disabledColor);
    auto layout = AsyncUIStackLayout.vertical;
    layout.width = AsyncUIAxisSize.fit;
    layout.height = AsyncUIAxisSize.fit;
    layout.padding = button.style.contentInsets;
    Clay_ElementDeclaration declaration = [AsyncUIRendererSupport declarationWithLayout: layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: button.style.cornerRadius
                                                                        borderStyle: button.style.borderStyle
                                                                     scrollBehavior: AsyncUIScrollBehaviorNone
                                                                          elementID: elementID];
    auto registration = [AsyncUIInteractionRegistration identifier: identifier elementID: elementID];
    registration.isEnabled = button.isEnabled;
    registration.isFocusable = true;
    registration.cursorStyle = AsyncUICursorStylePointer;
    registration.contextMenu = parentContextMenu;
    registration.activationAction = button.action;
    registration.taskGroup = currentHost.mountedTaskGroup;
    [interactionEngine registerInteraction: registration];

    [AsyncUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        Clay_TextElementConfig textConfig = [AsyncUIRendererSupport textConfigFromTextStyle: button.style.textStyle
                                                                              textColor: (button.isEnabled
            ? button.style.textColor
            : button.style.disabledTextColor)];
        CLAY_TEXT([AsyncUIClayRuntime stringFromString: button.title], CLAY_TEXT_CONFIG(textConfig));
    } @finally {
        [AsyncUIClayRuntime closeElement];
    }
}

- (void)_renderTextField: (AsyncUITextField *)field
               identifier: (OFString *)identifier
        parentContextMenu: (AsyncUIContextMenu *nillable)parentContextMenu
             currentHost: (AsyncUIComponentHost *)currentHost
       interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
           textInput: (AsyncUITextInputEngine *)textInput
{
    [self _renderTextInputWithText: field.text
                       placeholder: field.placeholder
                             style: field.style
                          identifier: identifier
                          isEnabled: field.isEnabled
                           isSecure: field.isSecure
                        contextMenu: (field.contextMenu ?: parentContextMenu)
                      changeHandler: field.changeHandler
                      submitHandler: field.submitHandler
                       currentHost: currentHost
                 interactionEngine: interactionEngine
                       textInput: textInput];
}

- (void)_renderTextInputWithText: (OFString *nillable)text
                     placeholder: (OFString *)placeholder
                           style: (AsyncUIControlStyle *)style
                       identifier: (OFString *)identifier
                        isEnabled: (bool)isEnabled
                         isSecure: (bool)isSecure
                      contextMenu: (AsyncUIContextMenu *nillable)contextMenu
                    changeHandler: (AsyncUITextChangeHandler nillable)changeHandler
                    submitHandler: (AsyncUITextSubmitHandler nillable)submitHandler
                     currentHost: (AsyncUIComponentHost *)currentHost
               interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
                   textInput: (AsyncUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AsyncUIClayRuntime elementIDFromString: identifier];
    bool focused = [interactionEngine isIdentifierFocused: identifier];
    AsyncUIColorValue *backgroundColor = (isEnabled ? style.inputBackgroundColor : style.disabledInputBackgroundColor);
    AsyncUIColorValue *borderColor = (isEnabled ? style.inputBorderColor : style.disabledInputBorderColor);
    OFString *displayText = [textInput displayStringForText: text
                                                 identifier: identifier
                                                   isSecure: isSecure
                                                    focused: focused];
    AsyncUIColorValue *textColor = (isEnabled ? style.textColor : style.disabledTextColor);
    auto layout = AsyncUIStackLayout.vertical;
    layout.width = AsyncUIAxisSize.grow;
    layout.height = AsyncUIAxisSize.fit;
    layout.padding = style.contentInsets;
    if (isEnabled and focused)
        borderColor = style.focusedInputBorderColor;
    if (displayText.length == 0 and not focused)
        textColor = style.placeholderColor;

    auto inputBorder = [AsyncUIBorderStyle all: 1 color: borderColor];
    Clay_ElementDeclaration declaration = [AsyncUIRendererSupport declarationWithLayout: layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: style.cornerRadius
                                                                        borderStyle: inputBorder
                                                                     scrollBehavior: AsyncUIScrollBehaviorNone
                                                                          elementID: elementID];
    auto registration = [AsyncUIInteractionRegistration identifier: identifier elementID: elementID];
    registration.isEnabled = isEnabled;
    registration.isFocusable = isEnabled;
    registration.text = (text ?: @"");
    registration.cursorStyle = AsyncUICursorStyleText;
    registration.contextMenu = contextMenu;
    registration.taskGroup = currentHost.mountedTaskGroup;
    registration.textChangeHandler = changeHandler;
    registration.submitHandler = submitHandler;
    [interactionEngine registerInteraction: registration];

    [AsyncUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        Clay_TextElementConfig textConfig = [AsyncUIRendererSupport textConfigFromTextStyle: style.textStyle textColor: textColor];
        CLAY_TEXT([AsyncUIClayRuntime stringFromString: (displayText.length > 0 ? displayText : placeholder)],
                  CLAY_TEXT_CONFIG(textConfig));
    } @finally {
        [AsyncUIClayRuntime closeElement];
    }
}

- (void)_renderActiveContextMenuWithInteractionEngine: (AsyncUIInteractionEngine *)interactionEngine
{
    if (interactionEngine.activeContextMenu == nilptr)
        return;

    auto menuLayout = AsyncUIStackLayout.vertical;
    menuLayout.width = AsyncUIAxisSize.fit;
    menuLayout.height = AsyncUIAxisSize.fit;
    menuLayout.padding = [AsyncUIEdgeInsets all: 4];
    menuLayout.spacing = 2;

    auto menuStyle = AsyncUIBoxStyle.filled;
    menuStyle.backgroundColor = [AsyncUIColorValue withRed: 250 green: 250 blue: 250 alpha: 255];
    menuStyle.cornerRadius = 10;

    Clay_ElementId menuID = [AsyncUIClayRuntime elementIDFromString: @"context-menu"];
    Clay_ElementDeclaration menuDeclaration = [AsyncUIRendererSupport declarationWithLayout: menuLayout
                                                                        backgroundColor: menuStyle.backgroundColor
                                                                           cornerRadius: menuStyle.cornerRadius
                                                                            borderStyle: menuStyle.borderStyle
                                                                         scrollBehavior: AsyncUIScrollBehaviorNone
                                                                              elementID: menuID];
    menuDeclaration.floating = (Clay_FloatingElementConfig){
        .attachTo = CLAY_ATTACH_TO_ROOT,
        .offset = {
            .x = interactionEngine.activeContextMenuX,
            .y = interactionEngine.activeContextMenuY
        },
        .pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH
    };

    [AsyncUIClayRuntime openElementWithID: menuID declaration: menuDeclaration];
    @try {
        size_t index = 0;

        for (AsyncUIContextMenuItem *item in interactionEngine.activeContextMenu.items) {
            OFString *identifier = [OFString stringWithFormat: @"context-menu/%zu", index];
            Clay_ElementId itemID = [AsyncUIClayRuntime elementIDFromString: identifier];
            auto itemLayout = AsyncUIStackLayout.vertical;
            itemLayout.width = AsyncUIAxisSize.fit;
            itemLayout.height = AsyncUIAxisSize.fit;
            itemLayout.padding = [AsyncUIEdgeInsets withLeft: 10 right: 10 top: 8 bottom: 8];
            Clay_ElementDeclaration itemDeclaration = [AsyncUIRendererSupport declarationWithLayout: itemLayout
                                                                                backgroundColor: AsyncUIColorValue.clear
                                                                                   cornerRadius: 8
                                                                                    borderStyle: AsyncUIBorderStyle.none
                                                                                 scrollBehavior: AsyncUIScrollBehaviorNone
                                                                                      elementID: itemID];
            auto registration = [AsyncUIInteractionRegistration identifier: identifier elementID: itemID];
            registration.isEnabled = item.isEnabled;
            registration.cursorStyle = AsyncUICursorStylePointer;
            registration.activationAction = item.action;
            registration.taskGroup = interactionEngine.activeContextMenuTaskGroup;
            [interactionEngine registerInteraction: registration];

            [AsyncUIClayRuntime openElementWithID: itemID declaration: itemDeclaration];
            @try {
                auto textStyle = AsyncUITextStyle.body;
                textStyle.color = (item.isEnabled
                    ? [AsyncUIColorValue withRed: 28 green: 33 blue: 38 alpha: 255]
                    : [AsyncUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255]);
                Clay_TextElementConfig textConfig = [AsyncUIRendererSupport textConfigFromTextStyle: textStyle textColor: nilptr];
                CLAY_TEXT([AsyncUIClayRuntime stringFromString: item.title], CLAY_TEXT_CONFIG(textConfig));
            } @finally {
                [AsyncUIClayRuntime closeElement];
            }

            index++;
        }
    } @finally {
        [AsyncUIClayRuntime closeElement];
    }
}

- (void)_runPostRenderEffects
{
    OFArray<void (^)(void)> *effects = [_postRenderEffects copy];

    [_postRenderEffects removeAllObjects];
    for (void (^effect)(void) in effects)
        effect();
}

@end

#pragma clang assume_nonnull end
