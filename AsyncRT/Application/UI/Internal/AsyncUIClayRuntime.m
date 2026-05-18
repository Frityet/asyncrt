#import <AsyncRT/Application/UI/Internal/AsyncUIClayRuntime.h>

#import <AsyncRT/Application/UI/AsyncUIClaySupport.h>

#pragma clang assume_nonnull begin

@namespace_implementation(AsyncUIClayRuntime)

+ (size_t)minimumMemorySize
{
    return AsyncUIClay.minimumMemorySize;
}

+ (Clay_Context *nillable)currentContext
{
    return AsyncUIClay.currentContext;
}

+ (void)setCurrentContext: (Clay_Context *nillable)context
{
    AsyncUIClay.currentContext = context;
}

+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AsyncUISize)dimensions
{
    return [AsyncUIClay initializeWithMemory: memory size: memorySize dimensions: dimensions];
}

+ (AsyncUISize)layoutDimensions
{
    return AsyncUIClay.layoutDimensions;
}

+ (void)setLayoutDimensions: (AsyncUISize)dimensions
{
    AsyncUIClay.layoutDimensions = dimensions;
}

+ (void)updatePointerPositionX: (float)x y: (float)y down: (bool)pointerDown
{
    [AsyncUIClay updatePointerPositionX: x y: y down: pointerDown];
}

+ (void)updateScrollContainersWithDragScrolling: (bool)enableDragScrolling
                                       deltaX: (float)deltaX
                                       deltaY: (float)deltaY
                                    deltaTime: (float)deltaTime
{
    [AsyncUIClay updateScrollContainersWithDragScrolling: enableDragScrolling
                                              deltaX: deltaX
                                              deltaY: deltaY
                                           deltaTime: deltaTime];
}

+ (void)beginLayout
{
    [AsyncUIClay beginLayout];
}

+ (Clay_RenderCommandArray)endLayoutWithDeltaTime: (float)deltaTime
{
    return [AsyncUIClay endLayoutWithDeltaTime: deltaTime];
}

+ (Clay_String)stringFromString: (OFString *nillable)text
{
    return [AsyncUIClay stringFromString: text];
}

+ (Clay_ElementId)elementIDFromString: (OFString *)identifier
{
    return [AsyncUIClay elementIDFromString: identifier];
}

+ (Clay_ElementData)elementDataForID: (Clay_ElementId)elementID
{
    return [AsyncUIClay elementDataForID: elementID];
}

+ (Clay_ScrollContainerData)scrollContainerDataForID: (Clay_ElementId)elementID
{
    return [AsyncUIClay scrollContainerDataForID: elementID];
}

+ (bool)pointerIsHoveringOverElementWithID: (Clay_ElementId)elementID
{
    return [AsyncUIClay pointerIsHoveringOverElementWithID: elementID];
}

+ (Clay_ElementIdArray)pointerOverIDs
{
    return AsyncUIClay.pointerOverIDs;
}

+ (void)openElementWithID: (Clay_ElementId)elementID declaration: (Clay_ElementDeclaration)declaration
{
    [AsyncUIClay openElementWithID: elementID declaration: declaration];
}

+ (void)closeElement
{
    [AsyncUIClay closeElement];
}

+ (void)clearError
{
    [AsyncUIClay clearError];
}

+ (OFString *nillable)consumeError
{
    return AsyncUIClay.consumeError;
}

@end

#pragma clang assume_nonnull end
