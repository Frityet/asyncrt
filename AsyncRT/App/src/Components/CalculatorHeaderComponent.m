#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@implementation CalculatorHeaderComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *nonnil)model
{
    self = [super init];
    _model = model;
    return self;
}

- (AUIView *)renderView
{
    return [CalculatorViews rowWithKey: @"header-row" gap: 18 children: @[
        [CalculatorViews boxWithKey: @"header-text"
                              props: (AUIBoxProps){
                                  .layout = (AUILayout){
                                      .width = [AUI axisGrow: 0],
                                      .height = [AUI axisFit: 0],
                                      .padding = [AUI insetsAll: 0],
                                      .childGap = 6,
                                      .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                                      .direction = AUILayoutDirectionColumn
                                  },
                                  .backgroundColor = [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0],
                                  .cornerRadius = 0,
                                  .border = [AUI borderNone],
                                  .scrollAxis = AUIScrollAxisNone
                              }
                           children: @[
            [CalculatorViews text: @"Scientific Calculator" style: [CalculatorTheme titleStyle]],
        ]],
        [CalculatorViews rowWithKey: @"header-badges" gap: 8 children: @[
            [CalculatorViews badgeWithKey: @"mode-badge"
                                     text: [OFString stringWithFormat: @"Mode %@", _model.angleModeText]
                                  variant: AUIControlVariantPrimary],
            [CalculatorViews badgeWithKey: @"memory-badge"
                                     text: (_model.hasMemoryValue
                ? [OFString stringWithFormat: @"M %@", _model.memoryDisplayText]
                : @"Memory empty")
                                  variant: (_model.hasMemoryValue ? AUIControlVariantSecondary : AUIControlVariantNeutral)],
            [CalculatorViews badgeWithKey: @"history-badge"
                                     text: [OFString stringWithFormat: @"History %zu", _model.history.count]
                                  variant: AUIControlVariantNeutral]
        ]]
    ]];
}

@end

#pragma clang assume_nonnull end
