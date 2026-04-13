#import "CalculatorComponents.h"

#import "CalculatorModel.h"
#import "CalculatorTheme.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRTCalculatorHeaderComponent : AUIComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorDisplayComponent : AUIComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorKeypadComponent : AUIComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorSidebarComponent : AUIComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncRTCalculatorHeaderComponent ()
+ (id<AUIRenderable>)badgeRowForModel: (AsyncRTCalculatorModel *)model;
@end

@interface AsyncRTCalculatorDisplayComponent ()
- (void)refreshAfterMutation;
@end

@interface AsyncRTCalculatorKeypadComponent ()
+ (id<AUIRenderable>)rowWithButtons: (OFArray<id<AUIRenderable>> *)buttons;
- (void)refreshAfterMutation;
@end

@interface AsyncRTCalculatorSidebarComponent ()
- (void)refreshAfterMutation;
@end

@implementation AsyncRTCalculatorRootComponent {
    AsyncRTCalculatorModel *_model;
    AsyncRTCalculatorHeaderComponent *_headerComponent;
    AsyncRTCalculatorDisplayComponent *_displayComponent;
    AsyncRTCalculatorKeypadComponent *_keypadComponent;
    AsyncRTCalculatorSidebarComponent *_sidebarComponent;
}

- (instancetype)init
{
    self = [super init];
    _model = [AsyncRTCalculatorModel model];
    _headerComponent = [[AsyncRTCalculatorHeaderComponent alloc] initWithModel: _model];
    _displayComponent = [[AsyncRTCalculatorDisplayComponent alloc] initWithModel: _model];
    _keypadComponent = [[AsyncRTCalculatorKeypadComponent alloc] initWithModel: _model];
    _sidebarComponent = [[AsyncRTCalculatorSidebarComponent alloc] initWithModel: _model];
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 28],
                        .childGap = 22,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AsyncRTCalculatorTheme canvasColor]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        _headerComponent,
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisGrow: 0]
                  child: [AUIHStack gap: 20 children: @[
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisGrow: 0]
                      child: [AUIVStack gap: 18 children: @[
                _displayComponent,
                _keypadComponent
            ]]],
            [AUIFrame width: [AUI axisFixed: 340]
                     height: [AUI axisGrow: 0]
                      child: _sidebarComponent]
        ]]]
    ]];
}

@end

@implementation AsyncRTCalculatorHeaderComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

+ (id<AUIRenderable>)badgeRowForModel: (AsyncRTCalculatorModel *)model
{
    return [AUIHStack gap: 8 children: @[
        [AUIBadge text: [OFString stringWithFormat: @"Mode %@", model.angleModeText]
                 variant: AUIControlVariantPrimary],
        [AUIBadge text: (model.hasMemoryValue
            ? [OFString stringWithFormat: @"M %@", model.memoryDisplayText]
            : @"Memory empty")
                 variant: (model.hasMemoryValue ? AUIControlVariantSecondary : AUIControlVariantNeutral)],
        [AUIBadge text: [OFString stringWithFormat: @"History %zu", model.history.count]
                 variant: AUIControlVariantNeutral]
    ]];
}

- (id<AUIRenderable>)body
{
    return [AUIHStack gap: 18 children: @[
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisFit: 0]
                  child: [AUIVStack gap: 6 children: @[
            [AUIText string: @"AsyncRT Scientific Calculator" style: [AsyncRTCalculatorTheme titleStyle]],
            [AUIText string: @"History, memory, typed expressions, live previews, and a full scientific keypad in one native window."
                      style: [AsyncRTCalculatorTheme subtitleStyle]]
        ]]],
        [AUIFrame width: [AUI axisFit: 0]
                 height: [AUI axisFit: 0]
              alignment: [AUI childAlignmentX: AUIAlignmentEnd y: AUIAlignmentCenter]
                  child: [self.class badgeRowForModel: _model]]
    ]];
}

@end

@implementation AsyncRTCalculatorDisplayComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)refreshAfterMutation
{
    [self setNeedsRender];
}

- (id<AUIRenderable>)body
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme displayPanelProps];
    AUIBoxProps resultBoxProps = [AsyncRTCalculatorTheme metricTileProps];
    AUITextStyle statusStyle = [AsyncRTCalculatorTheme statusStyleForError: _model.hasError];

    resultBoxProps.layout.padding = [AUI insetsAll: 18];
    resultBoxProps.layout.childGap = 8;
    resultBoxProps.backgroundColor = [AUI colorWithRed: 248 green: 241 blue: 226 alpha: 255];
    resultBoxProps.cornerRadius = 20;

    return [AUIBox layout: panelProps.layout
               background: panelProps.backgroundColor
                   radius: panelProps.cornerRadius
                   border: panelProps.border
                 children: @[
        [AUIHStack gap: 16 children: @[
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisFit: 0]
                      child: [AUIVStack gap: 4 children: @[
                [AUIText string: @"Workspace" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
                [AUIText string: @"Use the text field for direct entry, then mix in keypad shortcuts when it is faster."
                          style: [AsyncRTCalculatorTheme metricLabelStyle]]
            ]]],
            [AUIFrame width: [AUI axisFit: 0]
                     height: [AUI axisFit: 0]
              alignment: [AUI childAlignmentX: AUIAlignmentEnd y: AUIAlignmentStart]
                  child: [AUIHStack gap: 8 children: @[
                [AsyncRTCalculatorTheme compactButtonWithTitle: @"DEG"
                                                       variant: (_model.angleMode == AsyncRTCalculatorAngleModeDegrees
                                                            ? AUIControlVariantPrimary
                                                            : AUIControlVariantSecondary)
                                                        enable: true
                                                       onPress: ^{
                    if (_model.angleMode != AsyncRTCalculatorAngleModeDegrees)
                        [_model toggleAngleMode];
                    [self refreshAfterMutation];
                }],
                [AsyncRTCalculatorTheme compactButtonWithTitle: @"RAD"
                                                       variant: (_model.angleMode == AsyncRTCalculatorAngleModeRadians
                                                            ? AUIControlVariantPrimary
                                                            : AUIControlVariantSecondary)
                                                        enable: true
                                                       onPress: ^{
                    if (_model.angleMode != AsyncRTCalculatorAngleModeRadians)
                        [_model toggleAngleMode];
                    [self refreshAfterMutation];
                }]
            ]]]
        ]],
        [AUIVStack gap: 6 children: @[
            [AUIText string: @"Expression" style: [AsyncRTCalculatorTheme metricLabelStyle]],
            [AUITextField text: _model.expression
                    placeholder: @"Try: sin(45)^2 + cos(45)^2"
                        enabled: true
                       onChange: ^(OFString *value) {
                [_model setExpressionFromText: value];
                [self refreshAfterMutation];
            }
                       onSubmit: ^(OFString *value) {
                [_model setExpressionFromText: value];
                [_model evaluate];
                [self refreshAfterMutation];
            }]
        ]],
        [AUIHStack gap: 12 children: @[
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisFit: 0]
                      child: [AsyncRTCalculatorTheme metricTileWithLabel: @"ANS"
                                                                    value: _model.lastAnswerDisplayText]],
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisFit: 0]
                      child: [AsyncRTCalculatorTheme metricTileWithLabel: @"Memory"
                                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]]
        ]],
        [AUIDivider horizontalWithThickness: 1 color: [AsyncRTCalculatorTheme displayBorderColor]],
        [AUIBox layout: resultBoxProps.layout
               background: resultBoxProps.backgroundColor
                   radius: resultBoxProps.cornerRadius
                   border: resultBoxProps.border
                 children: @[
            [AUIText string: @"Result" style: [AsyncRTCalculatorTheme displayLabelStyle]],
            [AUIText string: _model.resultText style: [AsyncRTCalculatorTheme resultStyle]]
        ]],
        [AUIText string: _model.statusText style: statusStyle]
    ]];
}

@end

@implementation AsyncRTCalculatorKeypadComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)refreshAfterMutation
{
    [self setNeedsRender];
}

+ (id<AUIRenderable>)rowWithButtons: (OFArray<id<AUIRenderable>> *)buttons
{
    return [AUIHStack gap: 10 children: buttons];
}

- (id<AUIRenderable>)body
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme keypadPanelProps];

    return [AUIBox layout: panelProps.layout
               background: panelProps.backgroundColor
                   radius: panelProps.cornerRadius
                   border: panelProps.border
                 children: @[
        [AUIVStack gap: 4 children: @[
            [AUIText string: @"Keypad" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AUIText string: @"Scientific rows stay visible while the big Evaluate button finishes the current expression."
                      style: [AsyncRTCalculatorTheme metricLabelStyle]]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"MC"
                                                  variant: AUIControlVariantSecondary
                                                   enable: _model.hasMemoryValue
                                                  onPress: ^{
                [_model memoryClear];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"MR"
                                                  variant: AUIControlVariantSecondary
                                                   enable: _model.hasMemoryValue
                                                  onPress: ^{
                [_model memoryRecall];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"MS"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model memoryStore];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"M+"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model memoryAdd];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"M-"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model memorySubtract];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"ANS"
                                                  variant: AUIControlVariantSecondary
                                                   enable: _model.hasLastAnswer
                                                  onPress: ^{
                [_model appendAnswerReference];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"C"
                                                  variant: AUIControlVariantDanger
                                                   enable: true
                                                  onPress: ^{
                [_model clearExpression];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"AC"
                                                  variant: AUIControlVariantDanger
                                                   enable: true
                                                  onPress: ^{
                [_model clearAll];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"Back"
                                                  variant: AUIControlVariantSecondary
                                                   enable: _model.expression.length > 0 or _model.hasLastAnswer
                                                  onPress: ^{
                [_model backspace];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"+/-"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model toggleSign];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"%"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyPercent];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"!"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFactorial];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"sin"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"sin"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"cos"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"cos"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"tan"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"tan"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"sinh"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"sinh"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"cosh"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"cosh"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"tanh"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"tanh"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"asin"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"asin"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"acos"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"acos"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"atan"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"atan"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"ln"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"ln"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"log"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"log"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"exp"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"exp"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"sqrt"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"sqrt"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"x^2"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applySquare];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"1/x"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyReciprocal];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"abs"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"abs"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"rand"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendRandomFunction];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"^"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOperator: @"^"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"7"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"7"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"8"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"8"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"9"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"9"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"("
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOpenParenthesis];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @")"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendCloseParenthesis];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"/"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOperator: @"/"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"4"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"4"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"5"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"5"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"6"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"6"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"pi"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendConstantNamed: @"pi"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"e"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendConstantNamed: @"e"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"*"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOperator: @"*"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"1"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"1"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"2"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"2"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"3"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"3"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"floor"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"floor"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"ceil"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"ceil"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"-"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOperator: @"-"];
                [self refreshAfterMutation];
            }]
        ]],
        [self.class rowWithButtons: @[
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"0"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"0"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"00"
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDigits: @"00"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"."
                                                  variant: AUIControlVariantNeutral
                                                   enable: true
                                                  onPress: ^{
                [_model appendDecimalPoint];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"round"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model applyFunctionNamed: @"round"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"tau"
                                                  variant: AUIControlVariantSecondary
                                                   enable: true
                                                  onPress: ^{
                [_model appendConstantNamed: @"tau"];
                [self refreshAfterMutation];
            }],
            [AsyncRTCalculatorTheme keypadButtonWithTitle: @"+"
                                                  variant: AUIControlVariantPrimary
                                                   enable: true
                                                  onPress: ^{
                [_model appendOperator: @"+"];
                [self refreshAfterMutation];
            }]
        ]],
        [AsyncRTCalculatorTheme fullWidthButtonWithTitle: @"Evaluate"
                                                 variant: AUIControlVariantPrimary
                                                  enable: true
                                                 onPress: ^{
            [_model evaluate];
            [self refreshAfterMutation];
        }]
    ]];
}

@end

@implementation AsyncRTCalculatorSidebarComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)refreshAfterMutation
{
    [self setNeedsRender];
}

- (id<AUIRenderable>)body
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme sidebarPanelProps];
    OFMutableArray<id<AUIRenderable>> *historyRows = [OFMutableArray array];

    if (_model.history.count == 0) {
        [historyRows addObject: [AUIBox layout: [AsyncRTCalculatorTheme historyTileProps].layout
                                     background: [AsyncRTCalculatorTheme historyTileProps].backgroundColor
                                         radius: [AsyncRTCalculatorTheme historyTileProps].cornerRadius
                                         border: [AsyncRTCalculatorTheme historyTileProps].border
                                       children: @[
            [AUIText string: @"No committed history yet."
                      style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AUIText string: @"Press Evaluate to pin an expression and its result here for later reuse."
                      style: [AsyncRTCalculatorTheme historyExpressionStyle]]
        ]]];
    } else {
        for (size_t index = 0; index < _model.history.count; index++) {
            AsyncRTCalculatorHistoryEntry *entry = [_model.history objectAtIndex: index];
            AUIBoxProps tileProps = [AsyncRTCalculatorTheme historyTileProps];

            [historyRows addObject: [AUIBox layout: tileProps.layout
                                         background: tileProps.backgroundColor
                                             radius: tileProps.cornerRadius
                                             border: tileProps.border
                                           children: @[
                [AUIText string: entry.expression style: [AsyncRTCalculatorTheme historyExpressionStyle]],
                [AUIText string: entry.resultText style: [AsyncRTCalculatorTheme historyResultStyle]],
                [AUIHStack gap: 8 children: @[
                    [AsyncRTCalculatorTheme compactButtonWithTitle: @"Expr"
                                                           variant: AUIControlVariantSecondary
                                                            enable: true
                                                           onPress: ^{
                        [_model loadHistoryExpressionAtIndex: index];
                        [self refreshAfterMutation];
                    }],
                    [AsyncRTCalculatorTheme compactButtonWithTitle: @"Result"
                                                           variant: AUIControlVariantPrimary
                                                            enable: true
                                                           onPress: ^{
                        [_model loadHistoryResultAtIndex: index];
                        [self refreshAfterMutation];
                    }]
                ]]
            ]]];
        }
    }

    return [AUIBox layout: panelProps.layout
               background: panelProps.backgroundColor
                   radius: panelProps.cornerRadius
                   border: panelProps.border
                 children: @[
        [AUIVStack gap: 4 children: @[
            [AUIText string: @"Reference" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AUIText string: @"Keep an eye on memory, the active mode, and the typed syntax the parser understands."
                      style: [AsyncRTCalculatorTheme metricLabelStyle]]
        ]],
        [AUIHStack gap: 10 children: @[
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisFit: 0]
                      child: [AsyncRTCalculatorTheme metricTileWithLabel: @"Mode" value: _model.angleModeText]],
            [AUIFrame width: [AUI axisGrow: 0]
                     height: [AUI axisFit: 0]
                      child: [AsyncRTCalculatorTheme metricTileWithLabel: @"Memory"
                                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]]
        ]],
        [AUIVStack gap: 6 children: @[
            [AUIText string: @"Typed syntax" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AUIText string: @"Use functions like sin(x), cosh(x), ln(x), log(x), exp(x), sqrt(x), abs(x), floor(x), ceil(x), round(x), cbrt(x)."
                      style: [AsyncRTCalculatorTheme historyExpressionStyle]],
            [AUIText string: @"Two-argument functions: pow(x, y), min(x, y), max(x, y), mod(x, y). Symbols: ans, pi, e, tau, rand()."
                      style: [AsyncRTCalculatorTheme historyExpressionStyle]]
        ]],
        [AUIDivider horizontalWithThickness: 1 color: [AsyncRTCalculatorTheme panelBorderColor]],
        [AUIText string: @"History" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisGrow: 0]
                  child: [AUIScrollView axis: AUIScrollAxisVertical
                                          child: [AUIVStack gap: 10 children: historyRows]]]
    ]];
}

@end

#pragma clang assume_nonnull end
