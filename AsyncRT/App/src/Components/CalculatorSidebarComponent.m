#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@implementation CalculatorSidebarComponent {
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
    AUIBoxProps panelProps = [CalculatorTheme sidebarPanelProps];
    OFMutableArray<id<AUIRenderable>> *historyChildren = [OFMutableArray array];

    if (_model.history.count == 0) {
        [historyChildren addObject: [CalculatorViews historyTileWithKey: @"empty-history" children: @[
            [CalculatorViews text: @"No committed history yet." style: CalculatorTheme.sectionTitleStyle],
            [CalculatorViews text: @"Press Evaluate to pin an expression and its result here for later reuse."
                            style: CalculatorTheme.historyExpressionStyle]
        ]]];
    } else {
        for (size_t index = 0; index < _model.history.count; index++) {
            CalculatorHistoryEntry *entry = [_model.history objectAtIndex: index];
            OFString *prefix = [OFString stringWithFormat: @"history-%zu", index];

            [historyChildren addObject: [CalculatorViews historyTileWithKey: prefix children: @[
                [CalculatorViews text: entry.expression style: CalculatorTheme.historyExpressionStyle],
                [CalculatorViews text: entry.resultText style: CalculatorTheme.historyResultStyle],
                [CalculatorViews rowWithKey: [prefix stringByAppendingString: @"-actions"] gap: 8 children: @[
                    [CalculatorViews buttonWithKey: [prefix stringByAppendingString: @"-expr"]
                                             title: @"Expr"
                                           variant: AUIControlVariantSecondary
                                              size: AUIControlSizeSmall
                                         isEnabled: true
                                           onPress: ^{
                        [_model loadHistoryExpressionAtIndex: index];
                        [self _refresh];
                    }],
                    [CalculatorViews buttonWithKey: [prefix stringByAppendingString: @"-result"]
                                             title: @"Result"
                                           variant: AUIControlVariantPrimary
                                              size: AUIControlSizeSmall
                                         isEnabled: true
                                           onPress: ^{
                        [_model loadHistoryResultAtIndex: index];
                        [self _refresh];
                    }]
                ]]
            ]]];
        }
    }

    return [AUIViewBox boxWithKey: @"sidebar-panel"
                         boxProps: panelProps
           interactionConfiguration: nilptr
                         children: @[
        [CalculatorViews columnWithKey: @"sidebar-intro" gap: 4 children: @[
            [CalculatorViews text: @"Reference" style: CalculatorTheme.sectionTitleStyle],
            [CalculatorViews text: @"Memory, mode, typed syntax, and history stay visible in the retained sidebar."
                            style: CalculatorTheme.metricLabelStyle]
        ]],
        [CalculatorViews rowWithKey: @"sidebar-metrics" gap: 10 children: @[
            [CalculatorViews metricTileWithKey: @"mode-metric" label: @"Mode" value: _model.angleModeText],
            [CalculatorViews metricTileWithKey: @"memory-metric"
                                         label: @"Memory"
                                         value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [CalculatorViews columnWithKey: @"syntax" gap: 6 children: @[
            [CalculatorViews text: @"Typed syntax" style: CalculatorTheme.sectionTitleStyle],
            [CalculatorViews text: @"Functions: sin, cosh, ln, log, exp, sqrt, abs, floor, ceil, round, cbrt."
                            style: CalculatorTheme.historyExpressionStyle],
            [CalculatorViews text: @"Two-argument helpers: pow(x, y), min(x, y), max(x, y), mod(x, y). Symbols: ans, pi, e, tau, rand()."
                            style: CalculatorTheme.historyExpressionStyle]
        ]],
        [CalculatorViews dividerWithKey: @"sidebar-divider" color: [CalculatorTheme panelBorderColor]],
        [CalculatorViews text: @"History" style: CalculatorTheme.sectionTitleStyle],
        [CalculatorViews scrollColumnWithKey: @"history-scroll" children: historyChildren]
    ]];
}

@end

#pragma clang assume_nonnull end
