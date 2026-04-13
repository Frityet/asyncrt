#include <string.h>

#import "UI/AUIClaySupport.h"

#pragma clang assume_nonnull begin

static OFString *nillable async_ui_last_clay_error;

@namespace(AUIClaySupportPrivate)

+ (Clay_LayoutDirection)layoutDirectionFromDirection: (AUILayoutDirection)direction;
+ (Clay_LayoutAlignmentX)alignmentXFromAlignment: (AUIAlignment)alignment;
+ (Clay_LayoutAlignmentY)alignmentYFromAlignment: (AUIAlignment)alignment;
+ (Clay_TextElementConfigWrapMode)wrapModeFromWrapMode: (AUITextWrapMode)wrapMode;
+ (Clay_TextAlignment)textAlignmentFromAlignment: (AUITextAlignment)alignment;
+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AUIScrollAxis)scrollAxis;
+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AUIScrollAxis)scrollAxis
                                         elementID: (Clay_ElementId)elementID;
+ (void)handleErrorData: (Clay_ErrorData)errorData;

@end

static void AUIClayErrorHandlerBridge(Clay_ErrorData errorData)
{
    [AUIClaySupportPrivate handleErrorData: errorData];
}

@namespace_implementation(AUIClaySupportPrivate)

+ (Clay_LayoutDirection)layoutDirectionFromDirection: (AUILayoutDirection)direction
{
    return (direction == AUILayoutDirectionRow ? CLAY_LEFT_TO_RIGHT : CLAY_TOP_TO_BOTTOM);
}

+ (Clay_LayoutAlignmentX)alignmentXFromAlignment: (AUIAlignment)alignment
{
    switch (alignment) {
        case AUIAlignmentCenter:
            return CLAY_ALIGN_X_CENTER;
        case AUIAlignmentEnd:
            return CLAY_ALIGN_X_RIGHT;
        case AUIAlignmentStart:
        default:
            return CLAY_ALIGN_X_LEFT;
    }
}

+ (Clay_LayoutAlignmentY)alignmentYFromAlignment: (AUIAlignment)alignment
{
    switch (alignment) {
        case AUIAlignmentCenter:
            return CLAY_ALIGN_Y_CENTER;
        case AUIAlignmentEnd:
            return CLAY_ALIGN_Y_BOTTOM;
        case AUIAlignmentStart:
        default:
            return CLAY_ALIGN_Y_TOP;
    }
}

+ (Clay_TextElementConfigWrapMode)wrapModeFromWrapMode: (AUITextWrapMode)wrapMode
{
    switch (wrapMode) {
        case AUITextWrapModeNewlines:
            return CLAY_TEXT_WRAP_NEWLINES;
        case AUITextWrapModeNone:
            return CLAY_TEXT_WRAP_NONE;
        case AUITextWrapModeWords:
        default:
            return CLAY_TEXT_WRAP_WORDS;
    }
}

+ (Clay_TextAlignment)textAlignmentFromAlignment: (AUITextAlignment)alignment
{
    switch (alignment) {
        case AUITextAlignmentCenter:
            return CLAY_TEXT_ALIGN_CENTER;
        case AUITextAlignmentRight:
            return CLAY_TEXT_ALIGN_RIGHT;
        case AUITextAlignmentLeft:
        default:
            return CLAY_TEXT_ALIGN_LEFT;
    }
}

+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AUIScrollAxis)scrollAxis
{
    return [self clipConfigFromScrollAxis: scrollAxis elementID: (Clay_ElementId){0}];
}

+ (Clay_ClipElementConfig)clipConfigFromScrollAxis: (AUIScrollAxis)scrollAxis
                                         elementID: (Clay_ElementId)elementID
{
    Clay_ClipElementConfig config = {0};

    switch (scrollAxis) {
        case AUIScrollAxisHorizontal:
            config.horizontal = true;
            break;
        case AUIScrollAxisVertical:
            config.vertical = true;
            break;
        case AUIScrollAxisBoth:
            config.horizontal = true;
            config.vertical = true;
            break;
        case AUIScrollAxisNone:
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

@namespace_implementation(AUIClay)

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
                            dimensions: (AUISize)dimensions
{
    Clay_Arena arena = Clay_CreateArenaWithCapacityAndMemory(memorySize, memory);

    return Clay_Initialize(arena,
                           (Clay_Dimensions){ .width = dimensions.width, .height = dimensions.height },
                           [self errorHandler]);
}

+ (void)setLayoutDimensions: (AUISize)dimensions
{
    Clay_SetLayoutDimensions((Clay_Dimensions){
        .width = dimensions.width,
        .height = dimensions.height
    });
}

+ (void)setPointerPositionX: (float)x y: (float)y down: (bool)pointerDown
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

+ (bool)pointerOverElementWithID: (Clay_ElementId)elementID
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

+ (Clay_Color)colorFromColor: (AUIColor)color
{
    return (Clay_Color){
        .r = color.red,
        .g = color.green,
        .b = color.blue,
        .a = color.alpha
    };
}

+ (Clay_Padding)paddingFromInsets: (AUIInsets)insets
{
    return (Clay_Padding){
        .left = insets.left,
        .right = insets.right,
        .top = insets.top,
        .bottom = insets.bottom
    };
}

+ (Clay_SizingAxis)sizingAxisFromAxis: (AUILayoutAxis)axis
{
    switch (axis.kind) {
        case AUILayoutAxisKindFixed:
            return CLAY_SIZING_FIXED(axis.value);
        case AUILayoutAxisKindPercent:
            return CLAY_SIZING_PERCENT(axis.value);
        case AUILayoutAxisKindFit:
            return (Clay_SizingAxis){
                .size = {
                    .minMax = {
                        .min = axis.value,
                        .max = 0
                    }
                },
                .type = CLAY__SIZING_TYPE_FIT
            };
        case AUILayoutAxisKindGrow:
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

+ (Clay_ChildAlignment)childAlignmentFromAlignment: (AUIChildAlignment)alignment
{
    return (Clay_ChildAlignment){
        .x = [AUIClaySupportPrivate alignmentXFromAlignment: alignment.x],
        .y = [AUIClaySupportPrivate alignmentYFromAlignment: alignment.y]
    };
}

+ (Clay_LayoutConfig)layoutConfigFromLayout: (AUILayout)layout
{
    return (Clay_LayoutConfig){
        .sizing = {
            .width = [self sizingAxisFromAxis: layout.width],
            .height = [self sizingAxisFromAxis: layout.height]
        },
        .padding = [self paddingFromInsets: layout.padding],
        .childGap = layout.childGap,
        .childAlignment = [self childAlignmentFromAlignment: layout.childAlignment],
        .layoutDirection = [AUIClaySupportPrivate layoutDirectionFromDirection: layout.direction]
    };
}

+ (Clay_CornerRadius)cornerRadiusWithRadius: (float)radius
{
    return CLAY_CORNER_RADIUS(radius);
}

+ (Clay_BorderElementConfig)borderFromBorder: (AUIBorder)border
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

+ (Clay_TextElementConfig)textConfigFromProps: (AUITextProps)props
{
    return (Clay_TextElementConfig){
        .textColor = [self colorFromColor: props.style.color],
        .fontId = props.style.fontID,
        .fontSize = props.style.fontSize,
        .letterSpacing = props.style.letterSpacing,
        .lineHeight = props.style.lineHeight,
        .wrapMode = [AUIClaySupportPrivate wrapModeFromWrapMode: props.style.wrapMode],
        .textAlignment = [AUIClaySupportPrivate textAlignmentFromAlignment: props.style.alignment]
    };
}

+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIBoxProps)props
{
    return [self boxDeclarationFromProps: props elementID: (Clay_ElementId){0}];
}

+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIBoxProps)props
                                     elementID: (Clay_ElementId)elementID
{
    Clay_ElementDeclaration declaration = {0};

    declaration.layout = [self layoutConfigFromLayout: props.layout];
    declaration.backgroundColor = [self colorFromColor: props.backgroundColor];
    declaration.cornerRadius = [self cornerRadiusWithRadius: props.cornerRadius];
    declaration.border = [self borderFromBorder: props.border];
    declaration.clip = [AUIClaySupportPrivate clipConfigFromScrollAxis: props.scrollAxis elementID: elementID];
    return declaration;
}

+ (Clay_ErrorHandler)errorHandler
{
    return (Clay_ErrorHandler){ .errorHandlerFunction = AUIClayErrorHandlerBridge };
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
