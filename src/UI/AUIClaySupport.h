#pragma once

#import "UI/AUIPrimitives.h"
#import "UI/AUIRenderContext.h"
#import "extern/clay.h"

#pragma clang assume_nonnull begin

@namespace(AUIClay)

+ (size_t)minimumMemorySize;
+ (Clay_Context *nillable)currentContext;
+ (void)setCurrentContext: (Clay_Context *nillable)context;
+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AUISize)dimensions;
+ (void)setLayoutDimensions: (AUISize)dimensions;
+ (void)setPointerPositionX: (float)x y: (float)y down: (bool)pointerDown;
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
+ (bool)pointerOverElementWithID: (Clay_ElementId)elementID;
+ (Clay_ElementIdArray)pointerOverIDs;
+ (void)openElementWithID: (Clay_ElementId)elementID declaration: (Clay_ElementDeclaration)declaration;
+ (void)closeElement;
+ (Clay_Color)colorFromColor: (AUIColor)color;
+ (Clay_Padding)paddingFromInsets: (AUIInsets)insets;
+ (Clay_SizingAxis)sizingAxisFromAxis: (AUILayoutAxis)axis;
+ (Clay_ChildAlignment)childAlignmentFromAlignment: (AUIChildAlignment)alignment;
+ (Clay_LayoutConfig)layoutConfigFromLayout: (AUILayout)layout;
+ (Clay_CornerRadius)cornerRadiusWithRadius: (float)radius;
+ (Clay_BorderElementConfig)borderFromBorder: (AUIBorder)border;
+ (Clay_TextElementConfig)textConfigFromProps: (AUITextProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIBoxProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AUIBoxProps)props
                                     elementID: (Clay_ElementId)elementID;
+ (Clay_ErrorHandler)errorHandler;
+ (void)clearError;
+ (OFString *nillable)consumeError;

@end

#pragma clang assume_nonnull end
