#import "Internal/AUIRenderer.h"

#import "AUIApplication.h"
#import "AUIBox.h"
#import "AUIButton.h"
#import "AUIContextMenu.h"
#import "AUIContextMenuItem.h"
#import "AUIExceptions.h"
#import "AUIGroup.h"
#import "AUIKeyedContent.h"
#import "AUIRenderContext.h"
#import "AUIStack.h"
#import "AUIText.h"
#import "AUITextField.h"
#import "Backend/AUIWindow.h"
#import "Internal/AUIRenderContext+Private.h"

#pragma clang assume_nonnull begin

@namespace(AUIRendererSupport)

+ (AUIColorValue *)fallbackColor: (AUIColorValue *nillable)color;
+ (AUIEdgeInsets *)fallbackInsets: (AUIEdgeInsets *nillable)insets;
+ (Clay_Color)clayColorFromColor: (AUIColorValue *nillable)color;
+ (Clay_Padding)clayPaddingFromInsets: (AUIEdgeInsets *nillable)insets;
+ (Clay_SizingAxis)claySizingFromAxis: (AUIAxisSize *nillable)axis;
+ (Clay_LayoutDirection)clayDirectionFromDirection: (AUIStackDirection)direction;
+ (Clay_LayoutAlignmentX)clayAlignmentXFromAlignment: (AUIContentAlignment)alignment;
+ (Clay_LayoutAlignmentY)clayAlignmentYFromAlignment: (AUIContentAlignment)alignment;
+ (Clay_TextElementConfigWrapMode)clayWrapModeFromWrapStyle: (AUITextWrapStyle)wrapStyle;
+ (Clay_TextAlignment)clayTextAlignmentFromAlignment: (AUITextHorizontalAlignment)alignment;
+ (Clay_ClipElementConfig)clipConfigForScrollBehavior: (AUIScrollBehavior)scrollBehavior
                                             elementID: (Clay_ElementId)elementID;
+ (Clay_LayoutConfig)layoutConfigFromLayout: (AUIStackLayout *nillable)layout;
+ (Clay_BorderElementConfig)borderFromBorderStyle: (AUIBorderStyle *nillable)borderStyle;
+ (Clay_TextElementConfig)textConfigFromTextStyle: (AUITextStyle *)textStyle
                                      textColor: (AUIColorValue *nillable)textColorOverride;
+ (Clay_ElementDeclaration)declarationWithLayout: (AUIStackLayout *)layout
                                 backgroundColor: (AUIColorValue *nillable)backgroundColor
                                    cornerRadius: (float)cornerRadius
                                     borderStyle: (AUIBorderStyle *nillable)borderStyle
                                  scrollBehavior: (AUIScrollBehavior)scrollBehavior
                                       elementID: (Clay_ElementId)elementID;
+ (OFArray<id<AUIContent>> *)childrenOrEmpty: (OFArray<id<AUIContent>> *nillable)children;
+ (OFString *)identifierForToken: (OFString *)token parentIdentifier: (OFString *)parentIdentifier;
+ (AUIColorValue *)interactiveColorWithFallback: (AUIColorValue *)fallbackColor
                                    interaction: (AUIInteraction *nillable)interaction
                                     identifier: (OFString *)identifier
                              interactionEngine: (AUIInteractionEngine *)interactionEngine;

@end

@namespace_implementation(AUIRendererSupport)

+ (AUIColorValue *)fallbackColor: (AUIColorValue *nillable)color
{
    return (color ?: AUIColorValue.clear);
}

+ (AUIEdgeInsets *)fallbackInsets: (AUIEdgeInsets *nillable)insets
{
    return (insets ?: [AUIEdgeInsets all: 0]);
}

+ (Clay_Color)clayColorFromColor: (AUIColorValue *nillable)color
{
    AUIColorValue *safeColor = [self fallbackColor: color];

    return (Clay_Color){
        .r = safeColor.red,
        .g = safeColor.green,
        .b = safeColor.blue,
        .a = safeColor.alpha
    };
}

+ (Clay_Padding)clayPaddingFromInsets: (AUIEdgeInsets *nillable)insets
{
    AUIEdgeInsets *safeInsets = [self fallbackInsets: insets];

    return (Clay_Padding){
        .left = safeInsets.left,
        .right = safeInsets.right,
        .top = safeInsets.top,
        .bottom = safeInsets.bottom
    };
}

+ (Clay_SizingAxis)claySizingFromAxis: (AUIAxisSize *nillable)axis
{
    AUIAxisSize *safeAxis = (axis ?: AUIAxisSize.grow);

    switch (safeAxis.mode) {
        case AUIAxisSizeModeFixed:
            return CLAY_SIZING_FIXED(safeAxis.value);
        case AUIAxisSizeModePercent:
            return CLAY_SIZING_PERCENT(safeAxis.value);
        case AUIAxisSizeModeFit:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = safeAxis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_FIT
            };
        case AUIAxisSizeModeGrow:
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

+ (Clay_LayoutDirection)clayDirectionFromDirection: (AUIStackDirection)direction
{
    return (direction == AUIStackDirectionHorizontal ? CLAY_LEFT_TO_RIGHT : CLAY_TOP_TO_BOTTOM);
}

+ (Clay_LayoutAlignmentX)clayAlignmentXFromAlignment: (AUIContentAlignment)alignment
{
    switch (alignment) {
        case AUIContentAlignmentCenter:
            return CLAY_ALIGN_X_CENTER;
        case AUIContentAlignmentEnd:
            return CLAY_ALIGN_X_RIGHT;
        case AUIContentAlignmentStart:
        default:
            return CLAY_ALIGN_X_LEFT;
    }
}

+ (Clay_LayoutAlignmentY)clayAlignmentYFromAlignment: (AUIContentAlignment)alignment
{
    switch (alignment) {
        case AUIContentAlignmentCenter:
            return CLAY_ALIGN_Y_CENTER;
        case AUIContentAlignmentEnd:
            return CLAY_ALIGN_Y_BOTTOM;
        case AUIContentAlignmentStart:
        default:
            return CLAY_ALIGN_Y_TOP;
    }
}

+ (Clay_TextElementConfigWrapMode)clayWrapModeFromWrapStyle: (AUITextWrapStyle)wrapStyle
{
    switch (wrapStyle) {
        case AUITextWrapStyleNewlines:
            return CLAY_TEXT_WRAP_NEWLINES;
        case AUITextWrapStyleNone:
            return CLAY_TEXT_WRAP_NONE;
        case AUITextWrapStyleWords:
        default:
            return CLAY_TEXT_WRAP_WORDS;
    }
}

+ (Clay_TextAlignment)clayTextAlignmentFromAlignment: (AUITextHorizontalAlignment)alignment
{
    switch (alignment) {
        case AUITextHorizontalAlignmentCenter:
            return CLAY_TEXT_ALIGN_CENTER;
        case AUITextHorizontalAlignmentTrailing:
            return CLAY_TEXT_ALIGN_RIGHT;
        case AUITextHorizontalAlignmentLeading:
        default:
            return CLAY_TEXT_ALIGN_LEFT;
    }
}

+ (Clay_ClipElementConfig)clipConfigForScrollBehavior: (AUIScrollBehavior)scrollBehavior
                                             elementID: (Clay_ElementId)elementID
{
    Clay_ClipElementConfig config = {0};

    switch (scrollBehavior) {
        case AUIScrollBehaviorHorizontal:
            config.horizontal = true;
            break;
        case AUIScrollBehaviorVertical:
            config.vertical = true;
            break;
        case AUIScrollBehaviorBoth:
            config.horizontal = true;
            config.vertical = true;
            break;
        case AUIScrollBehaviorNone:
        default:
            break;
    }

    if ((config.horizontal or config.vertical) and elementID.id != 0) {
        Clay_ScrollContainerData scrollData = [AUIClayRuntime scrollContainerDataForID: elementID];

        if (scrollData.found and scrollData.scrollPosition != nullptr)
            config.childOffset = *scrollData.scrollPosition;
    }

    return config;
}

+ (Clay_LayoutConfig)layoutConfigFromLayout: (AUIStackLayout *nillable)layout
{
    AUIStackLayout *safeLayout = (layout ?: AUIStackLayout.vertical);

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

+ (Clay_BorderElementConfig)borderFromBorderStyle: (AUIBorderStyle *nillable)borderStyle
{
    AUIBorderStyle *safeBorder = (borderStyle ?: AUIBorderStyle.none);

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

+ (Clay_TextElementConfig)textConfigFromTextStyle: (AUITextStyle *)textStyle
                                      textColor: (AUIColorValue *nillable)textColorOverride
{
    AUITextStyle *safeStyle = (textStyle ?: AUITextStyle.body);
    AUIColorValue *color = (textColorOverride ?: safeStyle.color);

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

+ (Clay_ElementDeclaration)declarationWithLayout: (AUIStackLayout *)layout
                                 backgroundColor: (AUIColorValue *nillable)backgroundColor
                                    cornerRadius: (float)cornerRadius
                                     borderStyle: (AUIBorderStyle *nillable)borderStyle
                                  scrollBehavior: (AUIScrollBehavior)scrollBehavior
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

+ (OFArray<id<AUIContent>> *)childrenOrEmpty: (OFArray<id<AUIContent>> *nillable)children
{
    return (children ?: @[]);
}

+ (OFString *)identifierForToken: (OFString *)token parentIdentifier: (OFString *)parentIdentifier
{
    return [OFString stringWithFormat: @"%@/%@", parentIdentifier, token];
}

+ (AUIColorValue *)interactiveColorWithFallback: (AUIColorValue *)fallbackColor
                                    interaction: (AUIInteraction *nillable)interaction
                                     identifier: (OFString *)identifier
                              interactionEngine: (AUIInteractionEngine *)interactionEngine
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
@implementation AUIRenderer {
    AUIApplication *_application;
    id<AUIContent> nillable _rootContent;
    AUIComponentHost *nillable _rootHost;
    OFMutableArray<void (^)(void)> *_postRenderEffects;
}

- (instancetype)initWithApplication: (AUIApplication *)application
{
    self = [super init];
    _application = application;
    _postRenderEffects = [OFMutableArray array];
    return self;
}

- (id<AUIContent> nillable)rootContent
{
    return _rootContent;
}

- (void)attachRootContent: (id<AUIContent>)rootContent
                taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    [self detachRootContent];
    _rootContent = rootContent;
    _rootHost = [[AUIComponentHost alloc] initWithOwner: nilptr];
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

- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *)inputState
                                                        window: (AUIWindow *)window
                                             interactionEngine: (AUIInteractionEngine *)interactionEngine
                                                 textInput: (AUITextInputEngine *)textInput
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester
{
    OFString *nillable clayError = nilptr;

    if (_rootContent == nilptr or _rootHost == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render without root content"];

    auto frameDate = OFDate.date;
    auto context = [[AUIRenderContext alloc] initWithApplication: _application
                                                          window: window
                                                    viewportSize: viewportSize
                                                       frameDate: frameDate
                                                     elapsedTime: 0];
    Clay_RenderCommandArray renderCommands = (Clay_RenderCommandArray){0};

    [_postRenderEffects removeAllObjects];
    [AUIClayRuntime clearError];
    AUIClayRuntime.layoutDimensions = viewportSize;
    [AUIClayRuntime updatePointerPositionX: inputState.pointerX
                                      y: inputState.pointerY
                                   down: inputState.isPrimaryButtonDown];
    [interactionEngine beginFrame];
    [AUIRenderContext _pushCurrentContext: context];

    @try {
        [AUIClayRuntime beginLayout];
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

        renderCommands = [AUIClayRuntime endLayoutWithDeltaTime: deltaTime];
        [AUIClayRuntime updateScrollContainersWithDragScrolling: true
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

        clayError = [AUIClayRuntime consumeError];
        if (clayError != nilptr)
            @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];
    } @catch (AUIException *exception) {
        @throw exception;
    } @catch (OFException *exception) {
        @throw [[AUIRenderException alloc] initWithReason: @"Root content rendering failed"
                                       underlyingException: exception];
    } @finally {
        [AUIRenderContext _popCurrentContext];
    }

    return renderCommands;
}

- (void)_renderResolvedContent: (id<AUIContent>)content
                    identifier: (OFString *)identifier
             parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
                  currentHost: (AUIComponentHost *)currentHost
            interactionEngine: (AUIInteractionEngine *)interactionEngine
                textInput: (AUITextInputEngine *)textInput
{
    id<AUIContent> actualContent = content;

    if ([(OFObject *)actualContent isKindOfClass: AUIKeyedContent.class])
        actualContent = ((AUIKeyedContent *)actualContent).content;

    if ([(OFObject *)actualContent isKindOfClass: AUIComponent.class]) {
        AUIComponentHost *childHost = [currentHost resolveChildHostForComponent: (AUIComponent *)actualContent key: @"root"];

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
        case AUIContentKindGroup:
            [self _renderChildren: ((AUIGroup *)actualContent).children
                  parentIdentifier: identifier
                parentContextMenu: parentContextMenu
                     currentHost: currentHost
               interactionEngine: interactionEngine
                   textInput: textInput];
            return;
        case AUIContentKindStack:
            [self _renderStack: (AUIStack *)actualContent
                     identifier: identifier
              parentContextMenu: parentContextMenu
                   currentHost: currentHost
             interactionEngine: interactionEngine
                 textInput: textInput];
            return;
        case AUIContentKindBox:
            [self _renderBox: (AUIBox *)actualContent
                   identifier: identifier
            parentContextMenu: parentContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
            return;
        case AUIContentKindText:
            [self _renderTextContent: (AUIText *)actualContent];
            return;
        case AUIContentKindButton:
            [self _renderButton: (AUIButton *)actualContent
                      identifier: identifier
               parentContextMenu: parentContextMenu
                    currentHost: currentHost
              interactionEngine: interactionEngine];
            return;
        case AUIContentKindTextField:
            [self _renderTextField: (AUITextField *)actualContent
                         identifier: identifier
                  parentContextMenu: parentContextMenu
                       currentHost: currentHost
                 interactionEngine: interactionEngine
                     textInput: textInput];
            return;
        case AUIContentKindComponent:
        case AUIContentKindKeyed:
        default:
            return;
    }
}

- (void)_renderChildren: (OFArray<id<AUIContent>> *)children
          parentIdentifier: (OFString *)parentIdentifier
        parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
             currentHost: (AUIComponentHost *)currentHost
       interactionEngine: (AUIInteractionEngine *)interactionEngine
           textInput: (AUITextInputEngine *)textInput
{
    OFArray<id<AUIContent>> *safeChildren = [AUIRendererSupport childrenOrEmpty: children];

    for (size_t index = 0; index < safeChildren.count; index++) {
        id<AUIContent> child = [safeChildren objectAtIndex: index];
        OFString *token = [OFString stringWithFormat: @"%zu", index];
        id<AUIContent> actualChild = child;

        if ([(OFObject *)child isKindOfClass: AUIKeyedContent.class]) {
            token = ((AUIKeyedContent *)child).key;
            actualChild = ((AUIKeyedContent *)child).content;
        }

        OFString *childIdentifier = [AUIRendererSupport identifierForToken: token parentIdentifier: parentIdentifier];

        if ([(OFObject *)actualChild isKindOfClass: AUIComponent.class]) {
            AUIComponentHost *childHost = [currentHost resolveChildHostForComponent: (AUIComponent *)actualChild key: token];

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

- (void)_renderStack: (AUIStack *)stack
           identifier: (OFString *)identifier
    parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
         currentHost: (AUIComponentHost *)currentHost
   interactionEngine: (AUIInteractionEngine *)interactionEngine
       textInput: (AUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AUIClayRuntime elementIDFromString: identifier];
    Clay_ElementDeclaration declaration = [AUIRendererSupport declarationWithLayout: stack.layout
                                                                    backgroundColor: AUIColorValue.clear
                                                                       cornerRadius: 0
                                                                        borderStyle: AUIBorderStyle.none
                                                                     scrollBehavior: stack.layout.scrollBehavior
                                                                          elementID: elementID];

    [AUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        [self _renderChildren: stack.children
              parentIdentifier: identifier
            parentContextMenu: parentContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
    } @finally {
        [AUIClayRuntime closeElement];
    }
}

- (void)_renderBox: (AUIBox *)box
         identifier: (OFString *)identifier
  parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
       currentHost: (AUIComponentHost *)currentHost
 interactionEngine: (AUIInteractionEngine *)interactionEngine
     textInput: (AUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AUIClayRuntime elementIDFromString: identifier];
    AUIColorValue *backgroundColor = [AUIRendererSupport interactiveColorWithFallback: box.style.backgroundColor
                                                                           interaction: box.interaction
                                                                            identifier: identifier
                                                                     interactionEngine: interactionEngine];
    Clay_ElementDeclaration declaration = [AUIRendererSupport declarationWithLayout: box.layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: box.style.cornerRadius
                                                                        borderStyle: box.style.borderStyle
                                                                     scrollBehavior: box.layout.scrollBehavior
                                                                          elementID: elementID];
    AUIInteractionRegistration *nillable registration = nilptr;
    AUIContextMenu *childContextMenu = parentContextMenu;

    if (box.interaction != nilptr or parentContextMenu != nilptr) {
        registration = [AUIInteractionRegistration identifier: identifier elementID: elementID];
        registration.isEnabled = (box.interaction != nilptr ? box.interaction.isEnabled : true);
        registration.isFocusable = (box.interaction != nilptr ? box.interaction.isFocusable : false);
        registration.cursorStyle = (box.interaction != nilptr ? box.interaction.cursorStyle : AUICursorStyleDefault);
        registration.contextMenu = (box.interaction != nilptr and box.interaction.contextMenu != nilptr
            ? box.interaction.contextMenu
            : parentContextMenu);
        registration.activationAction = box.interaction.activationAction;
        registration.taskGroup = currentHost.mountedTaskGroup;
        childContextMenu = registration.contextMenu;
        [interactionEngine registerInteraction: $assert_nonnil(registration)];
    }

    [AUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        [self _renderChildren: box.children
              parentIdentifier: identifier
            parentContextMenu: childContextMenu
                 currentHost: currentHost
           interactionEngine: interactionEngine
               textInput: textInput];
    } @finally {
        [AUIClayRuntime closeElement];
    }
}

- (void)_renderTextContent: (AUIText *)text
{
    Clay_TextElementConfig textConfig = [AUIRendererSupport textConfigFromTextStyle: text.style textColor: nilptr];
    CLAY_TEXT([AUIClayRuntime stringFromString: text.string], CLAY_TEXT_CONFIG(textConfig));
}

- (void)_renderButton: (AUIButton *)button
            identifier: (OFString *)identifier
     parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
          currentHost: (AUIComponentHost *)currentHost
    interactionEngine: (AUIInteractionEngine *)interactionEngine
{
    Clay_ElementId elementID = [AUIClayRuntime elementIDFromString: identifier];
    auto buttonInteraction = [[AUIInteraction alloc] init];
    buttonInteraction.activationAction = button.action;
    buttonInteraction.cursorStyle = AUICursorStylePointer;
    AUIColorValue *backgroundColor = (button.isEnabled
        ? [AUIRendererSupport interactiveColorWithFallback: button.style.backgroundColors.normalColor
                                               interaction: buttonInteraction
                                                identifier: identifier
                                         interactionEngine: interactionEngine]
        : button.style.backgroundColors.disabledColor);
    auto layout = AUIStackLayout.vertical;
    layout.width = AUIAxisSize.fit;
    layout.height = AUIAxisSize.fit;
    layout.padding = button.style.contentInsets;
    Clay_ElementDeclaration declaration = [AUIRendererSupport declarationWithLayout: layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: button.style.cornerRadius
                                                                        borderStyle: button.style.borderStyle
                                                                     scrollBehavior: AUIScrollBehaviorNone
                                                                          elementID: elementID];
    auto registration = [AUIInteractionRegistration identifier: identifier elementID: elementID];
    registration.isEnabled = button.isEnabled;
    registration.isFocusable = true;
    registration.cursorStyle = AUICursorStylePointer;
    registration.contextMenu = parentContextMenu;
    registration.activationAction = button.action;
    registration.taskGroup = currentHost.mountedTaskGroup;
    [interactionEngine registerInteraction: registration];

    [AUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        Clay_TextElementConfig textConfig = [AUIRendererSupport textConfigFromTextStyle: button.style.textStyle
                                                                              textColor: (button.isEnabled
            ? button.style.textColor
            : button.style.disabledTextColor)];
        CLAY_TEXT([AUIClayRuntime stringFromString: button.title], CLAY_TEXT_CONFIG(textConfig));
    } @finally {
        [AUIClayRuntime closeElement];
    }
}

- (void)_renderTextField: (AUITextField *)field
               identifier: (OFString *)identifier
        parentContextMenu: (AUIContextMenu *nillable)parentContextMenu
             currentHost: (AUIComponentHost *)currentHost
       interactionEngine: (AUIInteractionEngine *)interactionEngine
           textInput: (AUITextInputEngine *)textInput
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
                           style: (AUIControlStyle *)style
                       identifier: (OFString *)identifier
                        isEnabled: (bool)isEnabled
                         isSecure: (bool)isSecure
                      contextMenu: (AUIContextMenu *nillable)contextMenu
                    changeHandler: (AUITextChangeHandler nillable)changeHandler
                    submitHandler: (AUITextSubmitHandler nillable)submitHandler
                     currentHost: (AUIComponentHost *)currentHost
               interactionEngine: (AUIInteractionEngine *)interactionEngine
                   textInput: (AUITextInputEngine *)textInput
{
    Clay_ElementId elementID = [AUIClayRuntime elementIDFromString: identifier];
    bool focused = [interactionEngine isIdentifierFocused: identifier];
    AUIColorValue *backgroundColor = (isEnabled ? style.inputBackgroundColor : style.disabledInputBackgroundColor);
    AUIColorValue *borderColor = (isEnabled ? style.inputBorderColor : style.disabledInputBorderColor);
    OFString *displayText = [textInput displayStringForText: text
                                                 identifier: identifier
                                                   isSecure: isSecure
                                                    focused: focused];
    AUIColorValue *textColor = (isEnabled ? style.textColor : style.disabledTextColor);
    auto layout = AUIStackLayout.vertical;
    layout.width = AUIAxisSize.grow;
    layout.height = AUIAxisSize.fit;
    layout.padding = style.contentInsets;
    if (isEnabled and focused)
        borderColor = style.focusedInputBorderColor;
    if (displayText.length == 0 and not focused)
        textColor = style.placeholderColor;

    auto inputBorder = [AUIBorderStyle all: 1 color: borderColor];
    Clay_ElementDeclaration declaration = [AUIRendererSupport declarationWithLayout: layout
                                                                    backgroundColor: backgroundColor
                                                                       cornerRadius: style.cornerRadius
                                                                        borderStyle: inputBorder
                                                                     scrollBehavior: AUIScrollBehaviorNone
                                                                          elementID: elementID];
    auto registration = [AUIInteractionRegistration identifier: identifier elementID: elementID];
    registration.isEnabled = isEnabled;
    registration.isFocusable = isEnabled;
    registration.text = (text ?: @"");
    registration.cursorStyle = AUICursorStyleText;
    registration.contextMenu = contextMenu;
    registration.taskGroup = currentHost.mountedTaskGroup;
    registration.textChangeHandler = changeHandler;
    registration.submitHandler = submitHandler;
    [interactionEngine registerInteraction: registration];

    [AUIClayRuntime openElementWithID: elementID declaration: declaration];
    @try {
        Clay_TextElementConfig textConfig = [AUIRendererSupport textConfigFromTextStyle: style.textStyle textColor: textColor];
        CLAY_TEXT([AUIClayRuntime stringFromString: (displayText.length > 0 ? displayText : placeholder)],
                  CLAY_TEXT_CONFIG(textConfig));
    } @finally {
        [AUIClayRuntime closeElement];
    }
}

- (void)_renderActiveContextMenuWithInteractionEngine: (AUIInteractionEngine *)interactionEngine
{
    if (interactionEngine.activeContextMenu == nilptr)
        return;

    auto menuLayout = AUIStackLayout.vertical;
    menuLayout.width = AUIAxisSize.fit;
    menuLayout.height = AUIAxisSize.fit;
    menuLayout.padding = [AUIEdgeInsets all: 4];
    menuLayout.spacing = 2;

    auto menuStyle = AUIBoxStyle.filled;
    menuStyle.backgroundColor = [AUIColorValue withRed: 250 green: 250 blue: 250 alpha: 255];
    menuStyle.cornerRadius = 10;

    Clay_ElementId menuID = [AUIClayRuntime elementIDFromString: @"context-menu"];
    Clay_ElementDeclaration menuDeclaration = [AUIRendererSupport declarationWithLayout: menuLayout
                                                                        backgroundColor: menuStyle.backgroundColor
                                                                           cornerRadius: menuStyle.cornerRadius
                                                                            borderStyle: menuStyle.borderStyle
                                                                         scrollBehavior: AUIScrollBehaviorNone
                                                                              elementID: menuID];
    menuDeclaration.floating = (Clay_FloatingElementConfig){
        .attachTo = CLAY_ATTACH_TO_ROOT,
        .offset = {
            .x = interactionEngine.activeContextMenuX,
            .y = interactionEngine.activeContextMenuY
        },
        .pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH
    };

    [AUIClayRuntime openElementWithID: menuID declaration: menuDeclaration];
    @try {
        size_t index = 0;

        for (AUIContextMenuItem *item in interactionEngine.activeContextMenu.items) {
            OFString *identifier = [OFString stringWithFormat: @"context-menu/%zu", index];
            Clay_ElementId itemID = [AUIClayRuntime elementIDFromString: identifier];
            auto itemLayout = AUIStackLayout.vertical;
            itemLayout.width = AUIAxisSize.fit;
            itemLayout.height = AUIAxisSize.fit;
            itemLayout.padding = [AUIEdgeInsets withLeft: 10 right: 10 top: 8 bottom: 8];
            Clay_ElementDeclaration itemDeclaration = [AUIRendererSupport declarationWithLayout: itemLayout
                                                                                backgroundColor: AUIColorValue.clear
                                                                                   cornerRadius: 8
                                                                                    borderStyle: AUIBorderStyle.none
                                                                                 scrollBehavior: AUIScrollBehaviorNone
                                                                                      elementID: itemID];
            auto registration = [AUIInteractionRegistration identifier: identifier elementID: itemID];
            registration.isEnabled = item.isEnabled;
            registration.cursorStyle = AUICursorStylePointer;
            registration.activationAction = item.action;
            registration.taskGroup = interactionEngine.activeContextMenuTaskGroup;
            [interactionEngine registerInteraction: registration];

            [AUIClayRuntime openElementWithID: itemID declaration: itemDeclaration];
            @try {
                auto textStyle = AUITextStyle.body;
                textStyle.color = (item.isEnabled
                    ? [AUIColorValue withRed: 28 green: 33 blue: 38 alpha: 255]
                    : [AUIColorValue withRed: 150 green: 155 blue: 160 alpha: 255]);
                Clay_TextElementConfig textConfig = [AUIRendererSupport textConfigFromTextStyle: textStyle textColor: nilptr];
                CLAY_TEXT([AUIClayRuntime stringFromString: item.title], CLAY_TEXT_CONFIG(textConfig));
            } @finally {
                [AUIClayRuntime closeElement];
            }

            index++;
        }
    } @finally {
        [AUIClayRuntime closeElement];
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
