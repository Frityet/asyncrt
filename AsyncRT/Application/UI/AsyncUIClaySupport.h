#pragma once

#import <AsyncRT/Application/UI/AsyncUIPrimitives.h>
#import <AsyncRT/Application/UI/AsyncUIRenderContext.h>
#import <AsyncRT/Vendor/clay.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUIClay)

@property(class, nonatomic) Clay_Context *nillable currentContext;
@property(class, nonatomic) AsyncUISize layoutDimensions;

+ (size_t)minimumMemorySize;
+ (Clay_Context *nillable)currentContext;
+ (void)setCurrentContext: (Clay_Context *nillable)context;
+ (Clay_Context *)initializeWithMemory: (void *)memory
                                  size: (size_t)memorySize
                            dimensions: (AsyncUISize)dimensions;
+ (AsyncUISize)layoutDimensions;
+ (void)setLayoutDimensions: (AsyncUISize)dimensions;
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
+ (Clay_Color)colorFromColor: (AsyncUIRawColor)color;
+ (Clay_Padding)paddingFromInsets: (AsyncUIRawInsets)insets;
+ (Clay_SizingAxis)sizingAxisFromAxis: (AsyncUIRawAxisSize)axis;
+ (Clay_ChildAlignment)childAlignmentFromAlignment: (AsyncUIRawChildAlignment)alignment;
+ (Clay_LayoutConfig)layoutConfigFromLayout: (AsyncUIRawLayout)layout;
+ (Clay_CornerRadius)cornerRadiusWithRadius: (float)radius;
+ (Clay_BorderElementConfig)borderFromBorder: (AsyncUIRawBorder)border;
+ (Clay_TextElementConfig)textConfigFromProps: (AsyncUIRawTextProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AsyncUIRawBoxProps)props;
+ (Clay_ElementDeclaration)boxDeclarationFromProps: (AsyncUIRawBoxProps)props
                                     elementID: (Clay_ElementId)elementID;
+ (Clay_ErrorHandler)errorHandler;
+ (void)clearError;
+ (OFString *nillable)consumeError;

@end

#pragma clang assume_nonnull end
