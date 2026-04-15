#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@implementation CalculatorKeypadComponent {
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
    AUIBoxProps panelProps = [CalculatorTheme keypadPanelProps];

    return [AUIViewBox boxWithKey: @"keypad-panel"
                         boxProps: panelProps
           interactionConfiguration: nilptr
                         children: @[
        [CalculatorViews columnWithKey: @"keypad-title" gap: 4 children: @[
            [CalculatorViews text: @"Keypad" style: [CalculatorTheme sectionTitleStyle]]
        ]],
        [CalculatorViews rowWithKey: @"memory-row" gap: 10 children: @[
            [CalculatorViews withKey: @"memory-clear"
                                title: @"MC"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: _model.hasMemoryValue
                              onPress: ^{ [_model memoryClear]; [self _refresh]; }],
            [CalculatorViews withKey: @"memory-recall"
                                title: @"MR"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: _model.hasMemoryValue
                              onPress: ^{ [_model memoryRecall]; [self _refresh]; }],
            [CalculatorViews withKey: @"memory-store"
                                title: @"MS"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model memoryStore]; [self _refresh]; }],
            [CalculatorViews withKey: @"memory-add"
                                title: @"M+"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model memoryAdd]; [self _refresh]; }],
            [CalculatorViews withKey: @"memory-subtract"
                                title: @"M-"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model memorySubtract]; [self _refresh]; }],
            [CalculatorViews withKey: @"insert-ans"
                                title: @"ANS"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: _model.hasLastAnswer
                              onPress: ^{ [_model appendAnswerReference]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"edit-row" gap: 10 children: @[
            [CalculatorViews withKey: @"clear"
                                title: @"C"
                              variant: AUIControlVariantDanger
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model clearExpression]; [self _refresh]; }],
            [CalculatorViews withKey: @"clear-all"
                                title: @"AC"
                              variant: AUIControlVariantDanger
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model clearAll]; [self _refresh]; }],
            [CalculatorViews withKey: @"backspace"
                                title: @"Back"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: (_model.expression.length > 0 or _model.hasLastAnswer)
                              onPress: ^{ [_model backspace]; [self _refresh]; }],
            [CalculatorViews withKey: @"toggle-sign"
                                title: @"+/-"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model toggleSign]; [self _refresh]; }],
            [CalculatorViews withKey: @"percent"
                                title: @"%"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyPercent]; [self _refresh]; }],
            [CalculatorViews withKey: @"factorial"
                                title: @"!"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFactorial]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"functions-row-a" gap: 10 children: @[
            [CalculatorViews withKey: @"sin"
                                title: @"sin"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"sin"]; [self _refresh]; }],
            [CalculatorViews withKey: @"cos"
                                title: @"cos"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"cos"]; [self _refresh]; }],
            [CalculatorViews withKey: @"tan"
                                title: @"tan"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"tan"]; [self _refresh]; }],
            [CalculatorViews withKey: @"sinh"
                                title: @"sinh"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"sinh"]; [self _refresh]; }],
            [CalculatorViews withKey: @"cosh"
                                title: @"cosh"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"cosh"]; [self _refresh]; }],
            [CalculatorViews withKey: @"tanh"
                                title: @"tanh"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"tanh"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"functions-row-b" gap: 10 children: @[
            [CalculatorViews withKey: @"asin"
                                title: @"asin"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"asin"]; [self _refresh]; }],
            [CalculatorViews withKey: @"acos"
                                title: @"acos"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"acos"]; [self _refresh]; }],
            [CalculatorViews withKey: @"atan"
                                title: @"atan"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"atan"]; [self _refresh]; }],
            [CalculatorViews withKey: @"ln"
                                title: @"ln"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"ln"]; [self _refresh]; }],
            [CalculatorViews withKey: @"log"
                                title: @"log"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"log"]; [self _refresh]; }],
            [CalculatorViews withKey: @"exp"
                                title: @"exp"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"exp"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"functions-row-c" gap: 10 children: @[
            [CalculatorViews withKey: @"sqrt"
                                title: @"sqrt"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"sqrt"]; [self _refresh]; }],
            [CalculatorViews withKey: @"square"
                                title: @"x^2"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applySquare]; [self _refresh]; }],
            [CalculatorViews withKey: @"reciprocal"
                                title: @"1/x"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyReciprocal]; [self _refresh]; }],
            [CalculatorViews withKey: @"abs"
                                title: @"abs"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"abs"]; [self _refresh]; }],
            [CalculatorViews withKey: @"rand"
                                title: @"rand"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendRandomFunction]; [self _refresh]; }],
            [CalculatorViews withKey: @"power"
                                title: @"^"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOperator: @"^"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"digits-row-a" gap: 10 children: @[
            [CalculatorViews withKey: @"digit-7"
                                title: @"7"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"7"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-8"
                                title: @"8"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"8"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-9"
                                title: @"9"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"9"]; [self _refresh]; }],
            [CalculatorViews withKey: @"open-paren"
                                title: @"("
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOpenParenthesis]; [self _refresh]; }],
            [CalculatorViews withKey: @"close-paren"
                                title: @")"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendCloseParenthesis]; [self _refresh]; }],
            [CalculatorViews withKey: @"divide"
                                title: @"/"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOperator: @"/"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"digits-row-b" gap: 10 children: @[
            [CalculatorViews withKey: @"digit-4"
                                title: @"4"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"4"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-5"
                                title: @"5"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"5"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-6"
                                title: @"6"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"6"]; [self _refresh]; }],
            [CalculatorViews withKey: @"constant-pi"
                                title: @"pi"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendConstantNamed: @"pi"]; [self _refresh]; }],
            [CalculatorViews withKey: @"constant-e"
                                title: @"e"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendConstantNamed: @"e"]; [self _refresh]; }],
            [CalculatorViews withKey: @"multiply"
                                title: @"*"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOperator: @"*"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"digits-row-c" gap: 10 children: @[
            [CalculatorViews withKey: @"digit-1"
                                title: @"1"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"1"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-2"
                                title: @"2"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"2"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-3"
                                title: @"3"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"3"]; [self _refresh]; }],
            [CalculatorViews withKey: @"floor"
                                title: @"floor"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"floor"]; [self _refresh]; }],
            [CalculatorViews withKey: @"ceil"
                                title: @"ceil"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"ceil"]; [self _refresh]; }],
            [CalculatorViews withKey: @"minus"
                                title: @"-"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOperator: @"-"]; [self _refresh]; }]
        ]],
        [CalculatorViews rowWithKey: @"digits-row-d" gap: 10 children: @[
            [CalculatorViews withKey: @"digit-0"
                                title: @"0"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"0"]; [self _refresh]; }],
            [CalculatorViews withKey: @"digit-00"
                                title: @"00"
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDigits: @"00"]; [self _refresh]; }],
            [CalculatorViews withKey: @"decimal"
                                title: @"."
                              variant: AUIControlVariantNeutral
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendDecimalPoint]; [self _refresh]; }],
            [CalculatorViews withKey: @"round"
                                title: @"round"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model applyFunctionNamed: @"round"]; [self _refresh]; }],
            [CalculatorViews withKey: @"constant-tau"
                                title: @"tau"
                              variant: AUIControlVariantSecondary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendConstantNamed: @"tau"]; [self _refresh]; }],
            [CalculatorViews withKey: @"plus"
                                title: @"+"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeLarge
                            isEnabled: true
                              onPress: ^{ [_model appendOperator: @"+"]; [self _refresh]; }]
        ]],
        [CalculatorViews withKey: @"evaluate"
                            title: @"Evaluate"
                          variant: AUIControlVariantPrimary
                             size: AUIControlSizeLarge
                        isEnabled: true
                          onPress: ^{
            [_model evaluate];
            [self _refresh];
        }]
    ]];
}

@end

#pragma clang assume_nonnull end
