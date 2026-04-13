#pragma once

#import "UI/AUI.h"

#pragma clang assume_nonnull begin

@namespace(AsyncRTCalculatorTheme)

+ (AUIColor)canvasColor;
+ (AUIColor)panelColor;
+ (AUIColor)panelBorderColor;
+ (AUIColor)displayColor;
+ (AUIColor)displayBorderColor;
+ (AUIColor)sidebarColor;
+ (AUIColor)accentTextColor;
+ (AUIColor)primaryTextColor;
+ (AUIColor)mutedTextColor;
+ (AUIColor)positiveTextColor;
+ (AUIColor)errorTextColor;

+ (AUITextStyle)titleStyle;
+ (AUITextStyle)subtitleStyle;
+ (AUITextStyle)eyebrowStyle;
+ (AUITextStyle)sectionTitleStyle;
+ (AUITextStyle)displayLabelStyle;
+ (AUITextStyle)resultStyle;
+ (AUITextStyle)statusStyleForError: (bool)isError;
+ (AUITextStyle)metricLabelStyle;
+ (AUITextStyle)metricValueStyle;
+ (AUITextStyle)historyExpressionStyle;
+ (AUITextStyle)historyResultStyle;

+ (AUIBoxProps)mainPanelProps;
+ (AUIBoxProps)displayPanelProps;
+ (AUIBoxProps)keypadPanelProps;
+ (AUIBoxProps)sidebarPanelProps;
+ (AUIBoxProps)metricTileProps;
+ (AUIBoxProps)historyTileProps;

+ (id<AUIRenderable>)keypadButtonWithTitle: (OFString *nillable)title
                                   variant: (AUIControlVariant)variant
                                    enable: (bool)enabled
                                   onPress: (void (^nillable)(void))onPress;
+ (id<AUIRenderable>)compactButtonWithTitle: (OFString *nillable)title
                                    variant: (AUIControlVariant)variant
                                     enable: (bool)enabled
                                    onPress: (void (^nillable)(void))onPress;
+ (id<AUIRenderable>)fullWidthButtonWithTitle: (OFString *nillable)title
                                      variant: (AUIControlVariant)variant
                                       enable: (bool)enabled
                                      onPress: (void (^nillable)(void))onPress;
+ (id<AUIRenderable>)metricTileWithLabel: (OFString *nillable)label value: (OFString *nillable)value;

@end

#pragma clang assume_nonnull end
