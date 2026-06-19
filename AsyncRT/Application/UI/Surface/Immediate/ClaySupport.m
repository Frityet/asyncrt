#include <string.h>

#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>

#pragma clang assume_nonnull begin

static OFString *nillable async_ui_last_clay_error;
static AsyncUISize async_ui_layout_dimensions;

@namespace(AsyncUIClaySupportPrivate)

+ (Clay_LayoutDirection)layoutDirectionFromDirection: (AsyncUIRawLayoutDirection)direction;
+ (Clay_LayoutAlignmentX)alignmentXFromAlignment: (AsyncUIRawAlignment)alignment;
+ (Clay_LayoutAlignmentY)alignmentYFromAlignment: (AsyncUIRawAlignment)alignment;
+ (Clay_TextElementConfigWrapMode)wrapModeFromWrapMode: (AsyncUIRawTextWrapMode)wrapMode;
+ (Clay_TextAlignment)textAlignmentFromAlignment: (AsyncUIRawTextAlignment)alignment;
+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AsyncUIRawScrollAxis)scrollAxis;
+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AsyncUIRawScrollAxis)scrollAxis
                                         elementID: (Clay_ElementId)elementID;
+ (void)handleErrorData: (Clay_ErrorData)errorData;

@end

static void AsyncUIClayErrorHandlerBridge(Clay_ErrorData errorData)
{
    [AsyncUIClaySupportPrivate handleErrorData: errorData];
}

@namespace_implementation(AsyncUIClaySupportPrivate)

+ (Clay_LayoutDirection)layoutDirectionFromDirection: (AsyncUIRawLayoutDirection)direction
{
    return (direction == AsyncUIRawLayoutDirectionRow ? CLAY_LEFT_TO_RIGHT : CLAY_TOP_TO_BOTTOM);
}

+ (Clay_LayoutAlignmentX)alignmentXFromAlignment: (AsyncUIRawAlignment)alignment
{
    switch (alignment) {
        case AsyncUIRawAlignmentCenter:
            return CLAY_ALIGN_X_CENTER;
        case AsyncUIRawAlignmentEnd:
            return CLAY_ALIGN_X_RIGHT;
        case AsyncUIRawAlignmentStart:
        default:
            return CLAY_ALIGN_X_LEFT;
    }
}

+ (Clay_LayoutAlignmentY)alignmentYFromAlignment: (AsyncUIRawAlignment)alignment
{
    switch (alignment) {
        case AsyncUIRawAlignmentCenter:
            return CLAY_ALIGN_Y_CENTER;
        case AsyncUIRawAlignmentEnd:
            return CLAY_ALIGN_Y_BOTTOM;
        case AsyncUIRawAlignmentStart:
        default:
            return CLAY_ALIGN_Y_TOP;
    }
}

+ (Clay_TextElementConfigWrapMode)wrapModeFromWrapMode: (AsyncUIRawTextWrapMode)wrapMode
{
    switch (wrapMode) {
        case AsyncUIRawTextWrapModeNewlines:
            return CLAY_TEXT_WRAP_NEWLINES;
        case AsyncUIRawTextWrapModeNone:
            return CLAY_TEXT_WRAP_NONE;
        case AsyncUIRawTextWrapModeWords:
        default:
            return CLAY_TEXT_WRAP_WORDS;
    }
}

+ (Clay_TextAlignment)textAlignmentFromAlignment: (AsyncUIRawTextAlignment)alignment
{
    switch (alignment) {
        case AsyncUIRawTextAlignmentCenter:
            return CLAY_TEXT_ALIGN_CENTER;
        case AsyncUIRawTextAlignmentRight:
            return CLAY_TEXT_ALIGN_RIGHT;
        case AsyncUIRawTextAlignmentLeft:
        default:
            return CLAY_TEXT_ALIGN_LEFT;
    }
}

+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AsyncUIRawScrollAxis)scrollAxis
{
    return [self clipConfigFromScrollAxis: scrollAxis elementID: (Clay_ElementId){0}];
}

+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AsyncUIRawScrollAxis)scrollAxis
                                         elementID: (Clay_ElementId)elementID
{
    Clay_ClipElementConfig config = {0};

    switch (scrollAxis) {
        case AsyncUIRawScrollAxisHorizontal:
            config.horizontal = true;
            break;
        case AsyncUIRawScrollAxisVertical:
            config.vertical = true;
            break;
        case AsyncUIRawScrollAxisBoth:
            config.horizontal = true;
            config.vertical = true;
            break;
        case AsyncUIRawScrollAxisNone:
        default:
            break;
    }

    if ((config.horizontal or config.vertical) and elementID.id != 0) {
        Clay_ScrollContainerData scrollData = Clay_GetScrollContainerData(elementID);

        if (scrollData.found and scrollData.scrollPosition != nullptr)
            config.childOffset = *scrollData.scrollPosition;
    }

    return config;
}

+ (void)handleErrorData: (Clay_ErrorData)errorData
{
    size_t length = (errorData.errorText.length > 0 ? (size_t)errorData.errorText.length : 0);
    char *buffer = calloc(length + 1, sizeof(char));

    if (buffer == nullptr) {
        async_ui_last_clay_error = [[OFString alloc] initWithUTF8String: "Clay reported an error"];
        return;
    }

    if (length > 0)
        memcpy(buffer, errorData.errorText.chars, length);

    async_ui_last_clay_error = [[OFString alloc] initWithUTF8String: buffer];
    free(buffer);
}

@end

@namespace_implementation(AsyncUIClay)

+ (size_t)minimumMemorySize
{
    return (size_t)Clay_MinMemorySize();
}

+ (Clay_Context *nillable)currentContext
{
    return Clay_GetCurrentContext();
}

+ (void)setCurrentContext: (Clay_Context *nillable)context
{
    Clay_SetCurrentContext(context);
}

+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AsyncUISize)dimensions
{
    Clay_Arena arena = Clay_CreateArenaWithCapacityAndMemory(memorySize, memory);
    async_ui_layout_dimensions = dimensions;

    return Clay_Initialize(arena,
                           (Clay_Dimensions){ .width = dimensions.width, .height = dimensions.height },
                           [self errorHandler]);
}

+ (AsyncUISize)layoutDimensions
{
    return async_ui_layout_dimensions;
}

+ (void)setLayoutDimensions: (AsyncUISize)dimensions
{
    async_ui_layout_dimensions = dimensions;
    Clay_SetLayoutDimensions((Clay_Dimensions){
        .width = dimensions.width,
        .height = dimensions.height
    });
}

+ (void)updatePointerPositionX: (float)x y: (float)y down: (bool)pointerDown
{
    Clay_SetPointerState((Clay_Vector2){ .x = x, .y = y }, pointerDown);
}

+ (void)updateScrollContainersWithDragScrolling: (bool)enableDragScrolling
                                       deltaX: (float)deltaX
                                       deltaY: (float)deltaY
                                    deltaTime: (float)deltaTime
{
    Clay_UpdateScrollContainers(enableDragScrolling,
                                (Clay_Vector2){ .x = deltaX, .y = deltaY },
                                deltaTime);
}

+ (void)beginLayout
{
    Clay_BeginLayout();
}

+ (Clay_RenderCommandArray)endLayoutWithDeltaTime: (float)deltaTime
{
    return Clay_EndLayout(deltaTime);
}

+ (Clay_String)stringFromString: (OFString *nillable)text
{
    const char *utf8String;

    if (text == nilptr)
        return CLAY_STRING("");

    utf8String = text.UTF8String;
    if (utf8String == nullptr)
        return CLAY_STRING("");

    return (Clay_String){
        .chars = utf8String,
        .length = (int32_t)strlen(utf8String),
        .isStaticallyAllocated = false
    };
}

+ (Clay_ElementId)elementIDFromString: (OFString *)identifier
{
    return Clay_GetElementId([self stringFromString: identifier]);
}

+ (Clay_ElementData)elementDataForID: (Clay_ElementId)elementID
{
    return Clay_GetElementData(elementID);
}

+ (Clay_ScrollContainerData)scrollContainerDataForID: (Clay_ElementId)elementID
{
    return Clay_GetScrollContainerData(elementID);
}

+ (bool)pointerIsHoveringOverElementWithID: (Clay_ElementId)elementID
{
    return Clay_PointerOver(elementID);
}

+ (Clay_ElementIdArray)pointerOverIDs
{
    return Clay_GetPointerOverIds();
}

+ (void)openElementWithID: (Clay_ElementId)elementID declaration: (Clay_ElementDeclaration)declaration
{
    Clay__OpenElementWithId(elementID);
    Clay__ConfigureOpenElementPtr(&declaration);
}

+ (void)closeElement
{
    Clay__CloseElement();
}

+ (Clay_Color)colorFromColor: (AsyncUIRawColor)color
{
    return (Clay_Color){
        .r = color.red,
        .g = color.green,
        .b = color.blue,
        .a = color.alpha
    };
}

+ (Clay_Padding)paddingFromInsets: (AsyncUIRawInsets)insets
{
    return (Clay_Padding){
        .left = insets.left,
        .right = insets.right,
        .top = insets.top,
        .bottom = insets.bottom
    };
}

+ (Clay_SizingAxis)sizingAxisFromAxis: (AsyncUIRawAxisSize)axis
{
    switch (axis.kind) {
        case AsyncUIRawAxisSizeKindFixed:
            return CLAY_SIZING_FIXED(axis.value);
        case AsyncUIRawAxisSizeKindPercent:
            return CLAY_SIZING_PERCENT(axis.value);
        case AsyncUIRawAxisSizeKindFit:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = axis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_FIT
            };
        case AsyncUIRawAxisSizeKindGrow:
        default:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = axis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_GROW
            };
    }
}

+ (Clay_ChildAlignment)childAlignmentFromAlignment: (AsyncUIRawChildAlignment)alignment
{
    return (Clay_ChildAlignment){
        .x = [AsyncUIClaySupportPrivate alignmentXFromAlignment: alignment.x],
        .y = [AsyncUIClaySupportPrivate alignmentYFromAlignment: alignment.y]
    };
}

+ (Clay_LayoutConfig)layoutConfigFromLayout: (AsyncUIRawLayout)layout
{
    return (Clay_LayoutConfig){
        .sizing = {
            .width = [self sizingAxisFromAxis: layout.width],
            .height = [self sizingAxisFromAxis: layout.height]
        },
        .padding = [self paddingFromInsets: layout.padding],
        .childGap = layout.childGap,
        .childAlignment = [self childAlignmentFromAlignment: layout.childAlignment],
        .layoutDirection = [AsyncUIClaySupportPrivate layoutDirectionFromDirection: layout.direction]
    };
}

+ (Clay_CornerRadius)cornerRadiusWithRadius: (float)radius
{
    return CLAY_CORNER_RADIUS(radius);
}

+ (Clay_BorderElementConfig)borderFromBorder: (AsyncUIRawBorder)border
{
    return (Clay_BorderElementConfig){
        .color = [self colorFromColor: border.color],
        .width = {
            .left = border.left,
            .right = border.right,
            .top = border.top,
            .bottom = border.bottom,
            .betweenChildren = border.betweenChildren
        }
    };
}

+ (Clay_TextElementConfig)textConfigFromProps: (AsyncUIRawTextProps)props
{
    return (Clay_TextElementConfig){
        .textColor = [self colorFromColor: props.style.color],
        .fontId = props.style.fontID,
        .fontSize = props.style.fontSize,
        .letterSpacing = props.style.letterSpacing,
        .lineHeight = props.style.lineHeight,
        .wrapMode = [AsyncUIClaySupportPrivate wrapModeFromWrapMode: props.style.wrapMode],
        .textAlignment = [AsyncUIClaySupportPrivate textAlignmentFromAlignment: props.style.alignment]
    };
}

+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AsyncUIRawBoxProps)props
{
    return [self boxDeclarationFromProps: props elementID: (Clay_ElementId){0}];
}

+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AsyncUIRawBoxProps)props
                                     elementID: (Clay_ElementId)elementID
{
    Clay_ElementDeclaration declaration = {0};

    declaration.layout = [self layoutConfigFromLayout: props.layout];
    declaration.backgroundColor = [self colorFromColor: props.backgroundColor];
    declaration.cornerRadius = [self cornerRadiusWithRadius: props.cornerRadius];
    declaration.border = [self borderFromBorder: props.border];
    declaration.clip = [AsyncUIClaySupportPrivate clipConfigFromScrollAxis: props.scrollAxis elementID: elementID];
    return declaration;
}

+ (Clay_ErrorHandler)errorHandler
{
    return (Clay_ErrorHandler){ .errorHandlerFunction = AsyncUIClayErrorHandlerBridge };
}

+ (void)clearError
{
    async_ui_last_clay_error = nilptr;
}

+ (OFString *nillable)consumeError
{
    OFString *nillable error = async_ui_last_clay_error;

    async_ui_last_clay_error = nilptr;
    return error;
}

@end

#pragma clang assume_nonnull end
