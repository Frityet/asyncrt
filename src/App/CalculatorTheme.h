#pragma once

#import "UI/AUI.h"

#pragma clang assume_nonnull begin

@namespace(CalculatorTheme)

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

@end

#pragma clang assume_nonnull end
