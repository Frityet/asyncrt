#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@implementation CalculatorDisplayComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *nonnil)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)_refresh
{
    [self _refreshCalculatorInterfaceAfterSharedModelMutation];
}

- (AUIView *)renderView
{
    AUIBoxProps panelProps = CalculatorTheme.displayPanelProps;
    AUIBoxProps resultBoxProps = CalculatorTheme.metricTileProps;

    resultBoxProps.layout.padding = [AUI insetsAll: 18];
    resultBoxProps.layout.childGap = 8;
    resultBoxProps.backgroundColor = [AUI colorWithRed: 248 green: 241 blue: 226 alpha: 255];
    resultBoxProps.cornerRadius = 20;

    return [AUIViewBox boxWithKey: @"display-panel"
                         boxProps: panelProps
           interactionConfiguration: nilptr
                         children: @[
        [CalculatorViews rowWithKey: @"display-header" gap: 16 children: @[
            [CalculatorViews columnWithKey: @"workspace-text" gap: 4 children: @[
                [CalculatorViews text: @"Workspace" style: [CalculatorTheme sectionTitleStyle]],
                [CalculatorViews text: @"Edit directly, then use keypad actions when they are faster."
                                style: [CalculatorTheme metricLabelStyle]]
            ]],
            [CalculatorViews rowWithKey: @"angle-buttons" gap: 8 children: @[
                [CalculatorViews buttonWithKey: @"deg-button"
                                    title: @"DEG"
                                  variant: (_model.angleMode == CalculatorAngleModeDegrees ? AUIControlVariantPrimary : AUIControlVariantSecondary)
                                     size: AUIControlSizeSmall
                                isEnabled: true
                                  onPress: ^{
                    if (_model.angleMode != CalculatorAngleModeDegrees)
                        [_model toggleAngleMode];
                    [self _refresh];
                }],
                [CalculatorViews buttonWithKey: @"rad-button"
                                    title: @"RAD"
                                  variant: (_model.angleMode == CalculatorAngleModeRadians ? AUIControlVariantPrimary : AUIControlVariantSecondary)
                                     size: AUIControlSizeSmall
                                isEnabled: true
                                  onPress: ^{
                    if (_model.angleMode != CalculatorAngleModeRadians)
                        [_model toggleAngleMode];
                    [self _refresh];
                }]
            ]]
        ]],
        [CalculatorViews columnWithKey: @"expression-editor" gap: 6 children: @[
            [CalculatorViews text: @"Expression" style: [CalculatorTheme metricLabelStyle]],
            [AUIViewEditableText editableTextWithKey: @"expression-input"
                                               text: _model.expression
                                        placeholder: @"Try: sin(45)^2 + cos(45)^2"
                                              style: [AUIComponents inputTextStyleForSize: AUIControlSizeMedium]
                                             colors: [AUIComponents inputColors]
                                             layout: (AUILayout){
                                                 .width = [AUI axisGrow: 0],
                                                 .height = [AUIComponents controlHeightForSize: AUIControlSizeMedium],
                                                 .padding = [AUIComponents controlInsetsForSize: AUIControlSizeMedium],
                                                 .childGap = 0,
                                                 .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentCenter],
                                                 .direction = AUILayoutDirectionColumn
                                             }
                                      cornerRadius: [AUIComponents controlCornerRadiusForSize: AUIControlSizeMedium]
                                           enabled: true
                                            secure: false
                                         multiline: false
                                       contextMenu: nilptr
                                          onChange: ^(OFString *text) {
                _model.expressionFromText = text;
                [self _refresh];
            }
                                          onSubmit: ^(OFString *text) {
                _model.expressionFromText = text;
                [_model evaluate];
                [self _refresh];
            }]
        ]],
        [CalculatorViews rowWithKey: @"metrics-row" gap: 12 children: @[
            [CalculatorViews metricTileWithKey: @"ans-tile" label: @"ANS" value: _model.lastAnswerDisplayText],
            [CalculatorViews metricTileWithKey: @"memory-tile"
                                         label: @"Memory"
                                         value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [CalculatorViews dividerWithKey: @"display-divider" color: [CalculatorTheme displayBorderColor]],
        [CalculatorViews boxWithKey: @"result-panel" props: resultBoxProps children: @[
            [CalculatorViews text: @"Result" style: [CalculatorTheme displayLabelStyle]],
            [CalculatorViews text: _model.resultText style: [CalculatorTheme resultStyle]]
        ]],
        [CalculatorViews text: _model.statusText
                        style: [CalculatorTheme statusStyleForError: _model.hasError]]
    ]];
}

@end

#pragma clang assume_nonnull end
