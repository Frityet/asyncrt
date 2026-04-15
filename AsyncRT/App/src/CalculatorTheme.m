#import "CalculatorTheme.h"

#pragma clang assume_nonnull begin

@namespace_implementation(CalculatorTheme)

+ (AUIColor)canvasColor
{
    return [AUI colorWithRed: 13 green: 22 blue: 36 alpha: 255];
}

+ (AUIColor)panelColor
{
    return [AUI colorWithRed: 244 green: 238 blue: 227 alpha: 255];
}

+ (AUIColor)panelBorderColor
{
    return [AUI colorWithRed: 208 green: 196 blue: 177 alpha: 255];
}

+ (AUIColor)displayColor
{
    return [AUI colorWithRed: 255 green: 250 blue: 241 alpha: 255];
}

+ (AUIColor)displayBorderColor
{
    return [AUI colorWithRed: 221 green: 210 blue: 190 alpha: 255];
}

+ (AUIColor)sidebarColor
{
    return [AUI colorWithRed: 238 green: 229 blue: 214 alpha: 255];
}

+ (AUIColor)accentTextColor
{
    return [AUI colorWithRed: 36 green: 56 blue: 87 alpha: 255];
}

+ (AUIColor)primaryTextColor
{
    return [AUI colorWithRed: 33 green: 38 blue: 43 alpha: 255];
}

+ (AUIColor)mutedTextColor
{
    return [AUI colorWithRed: 95 green: 100 blue: 108 alpha: 255];
}

+ (AUIColor)positiveTextColor
{
    return [AUI colorWithRed: 42 green: 93 blue: 67 alpha: 255];
}

+ (AUIColor)errorTextColor
{
    return [AUI colorWithRed: 164 green: 56 blue: 46 alpha: 255];
}

+ (AUITextStyle)titleStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 36;
    style.lineHeight = 40;
    style.color = CalculatorTheme.displayColor;
    return style;
}

+ (AUITextStyle)subtitleStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 15;
    style.lineHeight = 20;
    style.color = [AUI colorWithRed: 185 green: 194 blue: 208 alpha: 255];
    return style;
}

+ (AUITextStyle)eyebrowStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 12;
    style.lineHeight = 14;
    style.color = [AUI colorWithRed: 214 green: 224 blue: 240 alpha: 255];
    return style;
}

+ (AUITextStyle)sectionTitleStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 18;
    style.lineHeight = 22;
    style.color = CalculatorTheme.accentTextColor;
    return style;
}

+ (AUITextStyle)displayLabelStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 13;
    style.lineHeight = 16;
    style.color = CalculatorTheme.mutedTextColor;
    style.alignment = AUITextAlignmentRight;
    return style;
}

+ (AUITextStyle)resultStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 46;
    style.lineHeight = 52;
    style.color = CalculatorTheme.accentTextColor;
    style.wrapMode = AUITextWrapModeNone;
    style.alignment = AUITextAlignmentRight;
    return style;
}

+ (AUITextStyle)statusStyleForError: (bool)isError
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 14;
    style.lineHeight = 18;
    style.color = (isError ? CalculatorTheme.errorTextColor : CalculatorTheme.positiveTextColor);
    return style;
}

+ (AUITextStyle)metricLabelStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 12;
    style.lineHeight = 14;
    style.color = CalculatorTheme.mutedTextColor;
    return style;
}

+ (AUITextStyle)metricValueStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 24;
    style.lineHeight = 28;
    style.color = CalculatorTheme.accentTextColor;
    style.wrapMode = AUITextWrapModeNone;
    return style;
}

+ (AUITextStyle)historyExpressionStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 12;
    style.lineHeight = 16;
    style.color = CalculatorTheme.mutedTextColor;
    return style;
}

+ (AUITextStyle)historyResultStyle
{
    AUITextStyle style = AUI.defaultTextStyle;
    style.fontSize = 22;
    style.lineHeight = 26;
    style.color = CalculatorTheme.accentTextColor;
    style.wrapMode = AUITextWrapModeNone;
    return style;
}

+ (AUIBoxProps)mainPanelProps
{
    AUIBoxProps props = AUI.defaultBoxProps;
    props.layout.padding = [AUI insetsAll: 24];
    props.layout.childGap = 18;
    props.backgroundColor = CalculatorTheme.panelColor;
    props.cornerRadius = 28;
    props.border = [AUI borderAll: 1 color: CalculatorTheme.panelBorderColor];
    return props;
}

+ (AUIBoxProps)displayPanelProps
{
    AUIBoxProps props = CalculatorTheme.mainPanelProps;
    props.layout.padding = [AUI insetsAll: 22];
    props.backgroundColor = CalculatorTheme.displayColor;
    props.cornerRadius = 24;
    props.border = [AUI borderAll: 1 color: CalculatorTheme.displayBorderColor];
    return props;
}

+ (AUIBoxProps)keypadPanelProps
{
    AUIBoxProps props = CalculatorTheme.mainPanelProps;
    props.layout.padding = [AUI insetsAll: 20];
    props.layout.childGap = 12;
    props.backgroundColor = [AUI colorWithRed: 231 green: 222 blue: 208 alpha: 255];
    props.cornerRadius = 24;
    props.border = [AUI borderAll: 1 color: [AUI colorWithRed: 208 green: 196 blue: 177 alpha: 255]];
    return props;
}

+ (AUIBoxProps)sidebarPanelProps
{
    AUIBoxProps props = CalculatorTheme.mainPanelProps;
    props.backgroundColor = CalculatorTheme.sidebarColor;
    return props;
}

+ (AUIBoxProps)metricTileProps
{
    AUIBoxProps props = AUI.defaultBoxProps;
    props.layout.padding = [AUI insetsAll: 14];
    props.layout.childGap = 6;
    props.backgroundColor = [AUI colorWithRed: 250 green: 244 blue: 233 alpha: 255];
    props.cornerRadius = 18;
    props.border = [AUI borderAll: 1 color: [AUI colorWithRed: 223 green: 213 blue: 197 alpha: 255]];
    return props;
}

+ (AUIBoxProps)historyTileProps
{
    AUIBoxProps props = AUI.defaultBoxProps;
    props.layout.padding = [AUI insetsAll: 14];
    props.layout.childGap = 10;
    props.backgroundColor = [AUI colorWithRed: 248 green: 241 blue: 229 alpha: 255];
    props.cornerRadius = 18;
    props.border = [AUI borderAll: 1 color: [AUI colorWithRed: 220 green: 208 blue: 190 alpha: 255]];
    return props;
}

@end

#pragma clang assume_nonnull end
