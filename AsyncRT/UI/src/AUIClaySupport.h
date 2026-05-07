#pragma once

#import "AUIPrimitives.h"
#import "AUIRenderContext.h"
#import "clay.h"

#pragma clang assume_nonnull begin

@namespace(AUIClay)

@property(class, nonatomic) Clay_Context *nillable currentContext;
@property(class, nonatomic) AUISize layoutDimensions;

+ (size_t)minimumMemorySize;
+ (Clay_Context *nillable)currentContext;
+ (void)setCurrentContext: (Clay_Context *nillable)context;
+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AUISize)dimensions;
+ (AUISize)layoutDimensions;
+ (void)setLayoutDimensions: (AUISize)dimensions;
+ (void)updatePointerPositionX: (float)x y: (float)y down: (bool)pointerDown;
+ (void)updateScrollContainersWithDragScrolling: (bool)enableDragScrolling
                                       deltaX: (float)deltaX
                                       deltaY: (float)deltaY
                                    deltaTime: (float)deltaTime;
+ (void)beginLayout;
+ (Clay_RenderCommandArray)endLayoutWithDeltaTime: (float)deltaTime;
+ (Clay_String)stringFromString: (OFString *nillable)text;
+ (Clay_ElementId)elementIDFromString: (OFString *)identifier;
+ (Clay_ElementData)elementDataForID: (Clay_ElementId)elementID;
+ (Clay_ScrollContainerData)scrollContainerDataForID: (Clay_ElementId)elementID;
+ (bool)pointerIsHoveringOverElementWithID: (Clay_ElementId)elementID;
+ (Clay_ElementIdArray)pointerOverIDs;
+ (void)openElementWithID: (Clay_ElementId)elementID declaration: (Clay_ElementDeclaration)declaration;
+ (void)closeElement;
+ (Clay_Color)colorFromColor: (AUIRawColor)color;
+ (Clay_Padding)paddingFromInsets: (AUIRawInsets)insets;
+ (Clay_SizingAxis)sizingAxisFromAxis: (AUIRawAxisSize)axis;
+ (Clay_ChildAlignment)childAlignmentFromAlignment: (AUIRawChildAlignment)alignment;
+ (Clay_LayoutConfig)layoutConfigFromLayout: (AUIRawLayout)layout;
+ (Clay_CornerRadius)cornerRadiusWithRadius: (float)radius;
+ (Clay_BorderElementConfig)borderFromBorder: (AUIRawBorder)border;
+ (Clay_TextElementConfig)textConfigFromProps: (AUIRawTextProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIRawBoxProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIRawBoxProps)props
                                     elementID: (Clay_ElementId)elementID;
+ (Clay_ErrorHandler)errorHandler;
+ (void)clearError;
+ (OFString *nillable)consumeError;

@end

#pragma clang assume_nonnull end
