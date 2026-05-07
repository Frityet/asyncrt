#import "Internal/AUIClayRuntime.h"

#import "AUIClaySupport.h"

#pragma clang assume_nonnull begin

@namespace_implementation(AUIClayRuntime)

+ (size_t)minimumMemorySize
{
    return AUIClay.minimumMemorySize;
}

+ (Clay_Context *nillable)currentContext
{
    return AUIClay.currentContext;
}

+ (void)setCurrentContext: (Clay_Context *nillable)context
{
    AUIClay.currentContext = context;
}

+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AUISize)dimensions
{
    return [AUIClay initializeWithMemory: memory size: memorySize dimensions: dimensions];
}

+ (AUISize)layoutDimensions
{
    return AUIClay.layoutDimensions;
}

+ (void)setLayoutDimensions: (AUISize)dimensions
{
    AUIClay.layoutDimensions = dimensions;
}

+ (void)updatePointerPositionX: (float)x y: (float)y down: (bool)pointerDown
{
    [AUIClay updatePointerPositionX: x y: y down: pointerDown];
}

+ (void)updateScrollContainersWithDragScrolling: (bool)enableDragScrolling
                                       deltaX: (float)deltaX
                                       deltaY: (float)deltaY
                                    deltaTime: (float)deltaTime
{
    [AUIClay updateScrollContainersWithDragScrolling: enableDragScrolling
                                              deltaX: deltaX
                                              deltaY: deltaY
                                           deltaTime: deltaTime];
}

+ (void)beginLayout
{
    [AUIClay beginLayout];
}

+ (Clay_RenderCommandArray)endLayoutWithDeltaTime: (float)deltaTime
{
    return [AUIClay endLayoutWithDeltaTime: deltaTime];
}

+ (Clay_String)stringFromString: (OFString *nillable)text
{
    return [AUIClay stringFromString: text];
}

+ (Clay_ElementId)elementIDFromString: (OFString *)identifier
{
    return [AUIClay elementIDFromString: identifier];
}

+ (Clay_ElementData)elementDataForID: (Clay_ElementId)elementID
{
    return [AUIClay elementDataForID: elementID];
}

+ (Clay_ScrollContainerData)scrollContainerDataForID: (Clay_ElementId)elementID
{
    return [AUIClay scrollContainerDataForID: elementID];
}

+ (bool)pointerIsHoveringOverElementWithID: (Clay_ElementId)elementID
{
    return [AUIClay pointerIsHoveringOverElementWithID: elementID];
}

+ (Clay_ElementIdArray)pointerOverIDs
{
    return AUIClay.pointerOverIDs;
}

+ (void)openElementWithID: (Clay_ElementId)elementID declaration: (Clay_ElementDeclaration)declaration
{
    [AUIClay openElementWithID: elementID declaration: declaration];
}

+ (void)closeElement
{
    [AUIClay closeElement];
}

+ (void)clearError
{
    [AUIClay clearError];
}

+ (OFString *nillable)consumeError
{
    return AUIClay.consumeError;
}

@end

#pragma clang assume_nonnull end
