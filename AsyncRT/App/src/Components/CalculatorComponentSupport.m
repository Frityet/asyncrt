#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@namespace_implementation(CalculatorViews)

+ (AUIViewText *)text: (OFString *nonnil)text style: (AUITextStyle)style
{
    return [AUIViewText textWithText: text style: style];
}

+ (AUIViewBox *)boxWithKey: (OFString *nonnil)key
                       props: (AUIBoxProps)props
                    children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    return [AUIViewBox boxWithKey: key
                         boxProps: props
           interactionConfiguration: nilptr
                         children: children];
}

+ (AUIViewBox *)rowWithKey: (OFString *nonnil)key
                      gap: (uint16_t)gap
                 children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionRow;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxWithKey: key props: props children: children];
}

+ (AUIViewBox *)columnWithKey: (OFString *nonnil)key
                         gap: (uint16_t)gap
                    children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionColumn;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxWithKey: key props: props children: children];
}

+ (AUIViewBox *)fixedWidthWithKey: (OFString *nonnil)key
                            width: (float)width
                            child: (id<AUIRenderable>)child
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisFixed: width];
    props.layout.height = [AUI axisGrow: 0];
    return [self boxWithKey: key props: props children: @[child]];
}

+ (AUIViewBox *)scrollColumnWithKey: (OFString *nonnil)key
                                children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.childGap = 10;
    props.scrollAxis = AUIScrollAxisVertical;
    return [self boxWithKey: key props: props children: children];
}

+ (AUIViewBox *)metricTileWithKey: (OFString *nonnil)key
                               label: (OFString *nonnil)label
                               value: (OFString *nonnil)value
{
    return [self boxWithKey: key
                      props: [CalculatorTheme metricTileProps]
                   children: @[
        [self text: label style: [CalculatorTheme metricLabelStyle]],
        [self text: value style: [CalculatorTheme metricValueStyle]]
    ]];
}

+ (AUIViewBox *)historyTileWithKey: (OFString *nonnil)key
                                children: (OFArray<id<AUIRenderable>> *nonnil)children
{
    return [self boxWithKey: key props: [CalculatorTheme historyTileProps] children: children];
}

+ (AUIViewBox *)badgeWithKey: (OFString *nonnil)key
                             text: (OFString *nonnil)text
                          variant: (AUIControlVariant)variant
{
    return [self boxWithKey: key
                      props: [AUIComponents badgeBoxPropsForVariant: variant]
                   children: @[
        [self text: text style: [AUIComponents badgeTextStyle]]
    ]];
}

+ (AUIViewBox *)dividerWithKey: (OFString *nonnil)key color: (AUIColor)color
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFixed: 1];
    props.backgroundColor = color;
    return [self boxWithKey: key props: props children: @[]];
}

+ (AUIViewBox *)buttonWithKey: (OFString *nonnil)key
                     title: (OFString *nonnil)title
                   variant: (AUIControlVariant)variant
                      size: (AUIControlSize)size
                 isEnabled: (bool)isEnabled
                   onPress: (void (^nonnil)(void))onPress
{
    AUIBoxProps props = AUI.defaultBoxProps;
    AUIControlColors colors = [AUIComponents controlColorsForVariant: variant enabled: isEnabled];
    AUIViewInteractionConfiguration *configuration;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUIComponents controlHeightForSize: size];
    props.layout.padding = [AUIComponents controlInsetsForSize: size];
    props.layout.childGap = 0;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter];
    props.layout.direction = AUILayoutDirectionColumn;
    props.backgroundColor = colors.normal;
    props.cornerRadius = [AUIComponents controlCornerRadiusForSize: size];
    props.border = [AUIComponents controlBorderForVariant: variant enabled: isEnabled];
    configuration = [AUIViewInteractionConfiguration enabled: isEnabled
                                                   focusable: true
                                                 cursorStyle: AUICursorStylePointer
                                                  background: colors
                                                  onActivate: onPress
                                                 contextMenu: nilptr];
    return [AUIViewBox boxWithKey: key
                         boxProps: props
           interactionConfiguration: configuration
                         children: @[
        [CalculatorViews text: title
                        style: [AUIComponents controlTextStyleForSize: size
                                                               variant: variant
                                                               enabled: isEnabled]]
    ]];
}

@end

#pragma clang assume_nonnull end
