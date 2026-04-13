#import "CalculatorComponents.h"

#import "CalculatorModel.h"
#import "CalculatorTheme.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRTCalculatorHeaderViewComponent : AUIViewComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorDisplayViewComponent : AUIViewComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorKeypadViewComponent : AUIViewComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRTCalculatorSidebarViewComponent : AUIViewComponent

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

typedef struct AsyncRTCalculatorButtonSpec {
    OFString *key;
    OFString *title;
    AUIControlVariant variant;
    AUIControlSize size;
    bool isEnabled;
    void (^onPress)(void);
} AsyncRTCalculatorButtonSpec;

@namespace(AsyncRTCalculatorViewNodes)

+ (AUIViewTextNode *)textNode: (OFString *nillable)text style: (AUITextStyle)style;
+ (AUIViewBoxNode *)boxNodeWithKey: (OFString *nillable)key props: (AUIBoxProps)props children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)rowNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)columnNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)fixedWidthNodeWithKey: (OFString *)key width: (float)width child: (id<AUIRenderable>)child;
+ (AUIViewBoxNode *)scrollColumnNodeWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)buttonNodeFromSpec: (AsyncRTCalculatorButtonSpec)spec;
+ (AUIViewBoxNode *)metricTileWithKey: (OFString *)key label: (OFString *)label value: (OFString *)value;
+ (AUIViewBoxNode *)historyTileWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)badgeNodeWithKey: (OFString *)key text: (OFString *)text variant: (AUIControlVariant)variant;
+ (AUIViewBoxNode *)dividerNodeWithKey: (OFString *)key color: (AUIColor)color;

@end

@namespace_implementation(AsyncRTCalculatorViewNodes)

+ (AUIViewTextNode *)textNode: (OFString *nillable)text style: (AUITextStyle)style
{
    return [AUIViewTextNode textNodeWithText: ($assert_nonnil(text)) style: style];
}

+ (AUIViewBoxNode *)boxNodeWithKey: (OFString *nillable)key props: (AUIBoxProps)props children: (OFArray<id<AUIRenderable>> *)children
{
    return [AUIViewBoxNode boxNodeWithKey: key boxProps: props interactionConfiguration: nilptr children: children];
}

+ (AUIViewBoxNode *)rowNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionRow;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)columnNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionColumn;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)fixedWidthNodeWithKey: (OFString *)key width: (float)width child: (id<AUIRenderable>)child
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisFixed: width];
    props.layout.height = [AUI axisGrow: 0];
    return [self boxNodeWithKey: key props: props children: @[child]];
}

+ (AUIViewBoxNode *)scrollColumnNodeWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.childGap = 10;
    props.scrollAxis = AUIScrollAxisVertical;
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)buttonNodeFromSpec: (AsyncRTCalculatorButtonSpec)spec
{
    AUIBoxProps props = [AUI boxProps];
    AUIControlColors colors = [AUIComponents controlColorsForVariant: spec.variant enabled: spec.isEnabled];
    AUIViewInteractionConfiguration *configuration;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUIComponents controlHeightForSize: spec.size];
    props.layout.padding = [AUIComponents controlInsetsForSize: spec.size];
    props.layout.childGap = 0;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter];
    props.layout.direction = AUILayoutDirectionColumn;
    props.backgroundColor = colors.normal;
    props.cornerRadius = [AUIComponents controlCornerRadiusForSize: spec.size];
    props.border = [AUIComponents controlBorderForVariant: spec.variant enabled: spec.isEnabled];
    configuration = [AUIViewInteractionConfiguration enabled: spec.isEnabled
                                                   focusable: true
                                                 cursorStyle: AUICursorStylePointer
                                                  background: colors
                                                  onActivate: spec.onPress
                                                 contextMenu: nilptr];
    return [AUIViewBoxNode boxNodeWithKey: spec.key
                                 boxProps: props
                   interactionConfiguration: configuration
                                 children: @[
        [self textNode: spec.title
                  style: [AUIComponents controlTextStyleForSize: spec.size variant: spec.variant enabled: spec.isEnabled]]
    ]];
}

+ (AUIViewBoxNode *)metricTileWithKey: (OFString *)key label: (OFString *)label value: (OFString *)value
{
    AUIBoxProps props = [AsyncRTCalculatorTheme metricTileProps];
    return [self boxNodeWithKey: key props: props children: @[
        [self textNode: label style: [AsyncRTCalculatorTheme metricLabelStyle]],
        [self textNode: value style: [AsyncRTCalculatorTheme metricValueStyle]]
    ]];
}

+ (AUIViewBoxNode *)historyTileWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children
{
    return [self boxNodeWithKey: key props: [AsyncRTCalculatorTheme historyTileProps] children: children];
}

+ (AUIViewBoxNode *)badgeNodeWithKey: (OFString *)key text: (OFString *)text variant: (AUIControlVariant)variant
{
    AUIBoxProps props = [AUIComponents badgeBoxPropsForVariant: variant];
    return [self boxNodeWithKey: key props: props children: @[
        [self textNode: text style: [AUIComponents badgeTextStyle]]
    ]];
}

+ (AUIViewBoxNode *)dividerNodeWithKey: (OFString *)key color: (AUIColor)color
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFixed: 1];
    props.backgroundColor = color;
    return [self boxNodeWithKey: key props: props children: @[]];
}

@end

static AsyncRTCalculatorButtonSpec AsyncRTCalculatorButton(OFString *key,
                                                           OFString *title,
                                                           AUIControlVariant variant,
                                                           AUIControlSize size,
                                                           bool isEnabled,
                                                           void (^onPress)(void))
{
    return (AsyncRTCalculatorButtonSpec){
        .key = key,
        .title = title,
        .variant = variant,
        .size = size,
        .isEnabled = isEnabled,
        .onPress = [onPress copy]
    };
}

@implementation AsyncRTCalculatorRootComponent {
    AsyncRTCalculatorModel *_model;
    AsyncRTCalculatorHeaderViewComponent *_headerViewComponent;
    AsyncRTCalculatorDisplayViewComponent *_displayViewComponent;
    AsyncRTCalculatorKeypadViewComponent *_keypadViewComponent;
    AsyncRTCalculatorSidebarViewComponent *_sidebarViewComponent;
}

- (instancetype)init
{
    self = [super init];
    _model = [AsyncRTCalculatorModel model];
    _headerViewComponent = [[AsyncRTCalculatorHeaderViewComponent alloc] initWithModel: _model];
    _displayViewComponent = [[AsyncRTCalculatorDisplayViewComponent alloc] initWithModel: _model];
    _keypadViewComponent = [[AsyncRTCalculatorKeypadViewComponent alloc] initWithModel: _model];
    _sidebarViewComponent = [[AsyncRTCalculatorSidebarViewComponent alloc] initWithModel: _model];
    return self;
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps props = [AUI boxProps];

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.padding = [AUI insetsAll: 28];
    props.layout.childGap = 22;
    props.layout.direction = AUILayoutDirectionColumn;
    props.backgroundColor = [AsyncRTCalculatorTheme canvasColor];

    return [AUIViewBoxNode boxNodeWithKey: @"calculator-root"
                                 boxProps: props
                   interactionConfiguration: nilptr
                                 children: @[
        [self renderChildViewComponent: _headerViewComponent key: @"header"],
        [AsyncRTCalculatorViewNodes rowNodeWithKey: @"content-row" gap: 20 children: @[
            [AsyncRTCalculatorViewNodes boxNodeWithKey: @"main-column"
                                                  props: (AUIBoxProps){
                .layout = (AUILayout){
                    .width = [AUI axisGrow: 0],
                    .height = [AUI axisGrow: 0],
                    .padding = [AUI insetsAll: 0],
                    .childGap = 18,
                    .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                    .direction = AUILayoutDirectionColumn
                },
                .backgroundColor = [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0],
                .cornerRadius = 0,
                .border = [AUI borderNone],
                .scrollAxis = AUIScrollAxisNone
            }
                                               children: @[
                [self renderChildViewComponent: _displayViewComponent key: @"display"],
                [self renderChildViewComponent: _keypadViewComponent key: @"keypad"]
            ]],
            [AsyncRTCalculatorViewNodes fixedWidthNodeWithKey: @"sidebar-frame"
                                                        width: 340
                                                        child: [self renderChildViewComponent: _sidebarViewComponent key: @"sidebar"]]
        ]]
    ]];
}

@end

@implementation AsyncRTCalculatorHeaderViewComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (AUIViewNode *)renderViewNode
{
    return [AsyncRTCalculatorViewNodes rowNodeWithKey: @"header-row" gap: 18 children: @[
        [AsyncRTCalculatorViewNodes boxNodeWithKey: @"header-text"
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
            [AsyncRTCalculatorViewNodes textNode: @"AsyncRT Scientific Calculator" style: [AsyncRTCalculatorTheme titleStyle]],
            [AsyncRTCalculatorViewNodes textNode: @"Queue-driven runtime, retained view components, and hook-based UI state in one native calculator."
                                                 style: [AsyncRTCalculatorTheme subtitleStyle]]
        ]],
        [AsyncRTCalculatorViewNodes rowNodeWithKey: @"header-badges" gap: 8 children: @[
            [AsyncRTCalculatorViewNodes badgeNodeWithKey: @"mode-badge"
                                                    text: [OFString stringWithFormat: @"Mode %@", _model.angleModeText]
                                                 variant: AUIControlVariantPrimary],
            [AsyncRTCalculatorViewNodes badgeNodeWithKey: @"memory-badge"
                                                    text: (_model.hasMemoryValue
                ? [OFString stringWithFormat: @"M %@", _model.memoryDisplayText]
                : @"Memory empty")
                                                 variant: (_model.hasMemoryValue ? AUIControlVariantSecondary : AUIControlVariantNeutral)],
            [AsyncRTCalculatorViewNodes badgeNodeWithKey: @"history-badge"
                                                    text: [OFString stringWithFormat: @"History %zu", _model.history.count]
                                                 variant: AUIControlVariantNeutral]
        ]]
    ]];
}

@end

@implementation AsyncRTCalculatorDisplayViewComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)_refresh
{
    [self setNeedsViewUpdate];
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme displayPanelProps];
    AUIBoxProps resultBoxProps = [AsyncRTCalculatorTheme metricTileProps];

    resultBoxProps.layout.padding = [AUI insetsAll: 18];
    resultBoxProps.layout.childGap = 8;
    resultBoxProps.backgroundColor = [AUI colorWithRed: 248 green: 241 blue: 226 alpha: 255];
    resultBoxProps.cornerRadius = 20;

    return [AUIViewBoxNode boxNodeWithKey: @"display-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: @[
        [AsyncRTCalculatorViewNodes rowNodeWithKey: @"display-header" gap: 16 children: @[
            [AsyncRTCalculatorViewNodes columnNodeWithKey: @"workspace-text" gap: 4 children: @[
                [AsyncRTCalculatorViewNodes textNode: @"Workspace" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
                [AsyncRTCalculatorViewNodes textNode: @"Edit directly, then use keypad actions when they are faster."
                                                     style: [AsyncRTCalculatorTheme metricLabelStyle]]
            ]],
            [AsyncRTCalculatorViewNodes rowNodeWithKey: @"angle-buttons" gap: 8 children: @[
                [AsyncRTCalculatorViewNodes buttonNodeFromSpec: AsyncRTCalculatorButton(@"deg-button",
                                                                                         @"DEG",
                                                                                         _model.angleMode == AsyncRTCalculatorAngleModeDegrees ? AUIControlVariantPrimary : AUIControlVariantSecondary,
                                                                                         AUIControlSizeSmall,
                                                                                         true,
                                                                                         ^{
                    if (_model.angleMode != AsyncRTCalculatorAngleModeDegrees)
                        [_model toggleAngleMode];
                    [self _refresh];
                })],
                [AsyncRTCalculatorViewNodes buttonNodeFromSpec: AsyncRTCalculatorButton(@"rad-button",
                                                                                         @"RAD",
                                                                                         _model.angleMode == AsyncRTCalculatorAngleModeRadians ? AUIControlVariantPrimary : AUIControlVariantSecondary,
                                                                                         AUIControlSizeSmall,
                                                                                         true,
                                                                                         ^{
                    if (_model.angleMode != AsyncRTCalculatorAngleModeRadians)
                        [_model toggleAngleMode];
                    [self _refresh];
                })]
            ]]
        ]],
        [AsyncRTCalculatorViewNodes columnNodeWithKey: @"expression-editor" gap: 6 children: @[
            [AsyncRTCalculatorViewNodes textNode: @"Expression" style: [AsyncRTCalculatorTheme metricLabelStyle]],
            [AUIViewEditableTextNode editableTextNodeWithKey: @"expression-input"
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
                [_model setExpressionFromText: text];
                [self _refresh];
            }
                                                    onSubmit: ^(OFString *text) {
                [_model setExpressionFromText: text];
                [_model evaluate];
                [self _refresh];
            }]
        ]],
        [AsyncRTCalculatorViewNodes rowNodeWithKey: @"metrics-row" gap: 12 children: @[
            [AsyncRTCalculatorViewNodes metricTileWithKey: @"ans-tile" label: @"ANS" value: _model.lastAnswerDisplayText],
            [AsyncRTCalculatorViewNodes metricTileWithKey: @"memory-tile"
                                                    label: @"Memory"
                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [AsyncRTCalculatorViewNodes dividerNodeWithKey: @"display-divider" color: [AsyncRTCalculatorTheme displayBorderColor]],
        [AsyncRTCalculatorViewNodes boxNodeWithKey: @"result-panel" props: resultBoxProps children: @[
            [AsyncRTCalculatorViewNodes textNode: @"Result" style: [AsyncRTCalculatorTheme displayLabelStyle]],
            [AsyncRTCalculatorViewNodes textNode: _model.resultText style: [AsyncRTCalculatorTheme resultStyle]]
        ]],
        [AsyncRTCalculatorViewNodes textNode: _model.statusText
                                       style: [AsyncRTCalculatorTheme statusStyleForError: _model.hasError]]
    ]];
}

@end

@implementation AsyncRTCalculatorKeypadViewComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)_refresh
{
    [self setNeedsViewUpdate];
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme keypadPanelProps];
    OFMutableArray<id<AUIRenderable>> *rows = [OFMutableArray array];

    [rows addObject: [AsyncRTCalculatorViewNodes columnNodeWithKey: @"keypad-title" gap: 4 children: @[
        [AsyncRTCalculatorViewNodes textNode: @"Keypad" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
        [AsyncRTCalculatorViewNodes textNode: @"Scientific rows stay visible while Evaluate commits the current expression."
                                             style: [AsyncRTCalculatorTheme metricLabelStyle]]
    ]]];

#define BUTTON_ROW(key, ...) [rows addObject: [AsyncRTCalculatorViewNodes rowNodeWithKey: key gap: 10 children: @[__VA_ARGS__]]]
#define BUTTON_VALUE(spec) [AsyncRTCalculatorViewNodes buttonNodeFromSpec: spec]

    BUTTON_ROW(@"memory-row",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"memory-clear", @"MC", AUIControlVariantSecondary, AUIControlSizeLarge, _model.hasMemoryValue, ^{ [_model memoryClear]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"memory-recall", @"MR", AUIControlVariantSecondary, AUIControlSizeLarge, _model.hasMemoryValue, ^{ [_model memoryRecall]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"memory-store", @"MS", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model memoryStore]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"memory-add", @"M+", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model memoryAdd]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"memory-subtract", @"M-", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model memorySubtract]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"insert-ans", @"ANS", AUIControlVariantSecondary, AUIControlSizeLarge, _model.hasLastAnswer, ^{ [_model appendAnswerReference]; [self _refresh]; }))
    );

    BUTTON_ROW(@"edit-row",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"clear", @"C", AUIControlVariantDanger, AUIControlSizeLarge, true, ^{ [_model clearExpression]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"clear-all", @"AC", AUIControlVariantDanger, AUIControlSizeLarge, true, ^{ [_model clearAll]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"backspace", @"Back", AUIControlVariantSecondary, AUIControlSizeLarge, _model.expression.length > 0 or _model.hasLastAnswer, ^{ [_model backspace]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"toggle-sign", @"+/-", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model toggleSign]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"percent", @"%", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyPercent]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"factorial", @"!", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFactorial]; [self _refresh]; }))
    );

    BUTTON_ROW(@"functions-row-a",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"sin", @"sin", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"sin"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"cos", @"cos", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"cos"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"tan", @"tan", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"tan"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"sinh", @"sinh", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"sinh"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"cosh", @"cosh", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"cosh"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"tanh", @"tanh", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"tanh"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"functions-row-b",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"asin", @"asin", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"asin"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"acos", @"acos", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"acos"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"atan", @"atan", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"atan"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"ln", @"ln", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"ln"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"log", @"log", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"log"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"exp", @"exp", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"exp"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"functions-row-c",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"sqrt", @"sqrt", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"sqrt"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"square", @"x^2", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applySquare]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"reciprocal", @"1/x", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyReciprocal]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"abs", @"abs", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"abs"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"rand", @"rand", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendRandomFunction]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"power", @"^", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model appendOperator: @"^"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"digits-row-a",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-7", @"7", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"7"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-8", @"8", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"8"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-9", @"9", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"9"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"open-paren", @"(", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendOpenParenthesis]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"close-paren", @")", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendCloseParenthesis]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"divide", @"/", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model appendOperator: @"/"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"digits-row-b",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-4", @"4", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"4"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-5", @"5", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"5"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-6", @"6", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"6"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"constant-pi", @"pi", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendConstantNamed: @"pi"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"constant-e", @"e", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendConstantNamed: @"e"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"multiply", @"*", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model appendOperator: @"*"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"digits-row-c",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-1", @"1", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"1"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-2", @"2", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"2"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-3", @"3", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"3"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"floor", @"floor", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"floor"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"ceil", @"ceil", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"ceil"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"minus", @"-", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model appendOperator: @"-"]; [self _refresh]; }))
    );

    BUTTON_ROW(@"digits-row-d",
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-0", @"0", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"0"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"digit-00", @"00", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDigits: @"00"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"decimal", @".", AUIControlVariantNeutral, AUIControlSizeLarge, true, ^{ [_model appendDecimalPoint]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"round", @"round", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model applyFunctionNamed: @"round"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"constant-tau", @"tau", AUIControlVariantSecondary, AUIControlSizeLarge, true, ^{ [_model appendConstantNamed: @"tau"]; [self _refresh]; })),
        BUTTON_VALUE(AsyncRTCalculatorButton(@"plus", @"+", AUIControlVariantPrimary, AUIControlSizeLarge, true, ^{ [_model appendOperator: @"+"]; [self _refresh]; }))
    );

    [rows addObject: [AsyncRTCalculatorViewNodes buttonNodeFromSpec: AsyncRTCalculatorButton(@"evaluate",
                                                                                              @"Evaluate",
                                                                                              AUIControlVariantPrimary,
                                                                                              AUIControlSizeLarge,
                                                                                              true,
                                                                                              ^{
        [_model evaluate];
        [self _refresh];
    })]];

#undef BUTTON_ROW
#undef BUTTON_VALUE

    return [AUIViewBoxNode boxNodeWithKey: @"keypad-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: rows];
}

@end

@implementation AsyncRTCalculatorSidebarViewComponent {
    AsyncRTCalculatorModel *_model;
}

- (instancetype)initWithModel: (AsyncRTCalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (void)_refresh
{
    [self setNeedsViewUpdate];
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps panelProps = [AsyncRTCalculatorTheme sidebarPanelProps];
    OFMutableArray<id<AUIRenderable>> *historyChildren = [OFMutableArray array];

    if (_model.history.count == 0) {
        [historyChildren addObject: [AsyncRTCalculatorViewNodes historyTileWithKey: @"empty-history" children: @[
            [AsyncRTCalculatorViewNodes textNode: @"No committed history yet." style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AsyncRTCalculatorViewNodes textNode: @"Press Evaluate to pin an expression and its result here for later reuse."
                                         style: [AsyncRTCalculatorTheme historyExpressionStyle]]
        ]]];
    } else {
        for (size_t index = 0; index < _model.history.count; index++) {
            AsyncRTCalculatorHistoryEntry *entry = [_model.history objectAtIndex: index];
            OFString *prefix = [OFString stringWithFormat: @"history-%zu", index];

            [historyChildren addObject: [AsyncRTCalculatorViewNodes historyTileWithKey: prefix children: @[
                [AsyncRTCalculatorViewNodes textNode: entry.expression style: [AsyncRTCalculatorTheme historyExpressionStyle]],
                [AsyncRTCalculatorViewNodes textNode: entry.resultText style: [AsyncRTCalculatorTheme historyResultStyle]],
                [AsyncRTCalculatorViewNodes rowNodeWithKey: [prefix stringByAppendingString: @"-actions"] gap: 8 children: @[
                    [AsyncRTCalculatorViewNodes buttonNodeFromSpec: AsyncRTCalculatorButton([prefix stringByAppendingString: @"-expr"],
                                                                                             @"Expr",
                                                                                             AUIControlVariantSecondary,
                                                                                             AUIControlSizeSmall,
                                                                                             true,
                                                                                             ^{
                        [_model loadHistoryExpressionAtIndex: index];
                        [self _refresh];
                    })],
                    [AsyncRTCalculatorViewNodes buttonNodeFromSpec: AsyncRTCalculatorButton([prefix stringByAppendingString: @"-result"],
                                                                                             @"Result",
                                                                                             AUIControlVariantPrimary,
                                                                                             AUIControlSizeSmall,
                                                                                             true,
                                                                                             ^{
                        [_model loadHistoryResultAtIndex: index];
                        [self _refresh];
                    })]
                ]]
            ]]];
        }
    }

    return [AUIViewBoxNode boxNodeWithKey: @"sidebar-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: @[
        [AsyncRTCalculatorViewNodes columnNodeWithKey: @"sidebar-intro" gap: 4 children: @[
            [AsyncRTCalculatorViewNodes textNode: @"Reference" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AsyncRTCalculatorViewNodes textNode: @"Memory, mode, typed syntax, and history stay visible in the retained sidebar."
                                                 style: [AsyncRTCalculatorTheme metricLabelStyle]]
        ]],
        [AsyncRTCalculatorViewNodes rowNodeWithKey: @"sidebar-metrics" gap: 10 children: @[
            [AsyncRTCalculatorViewNodes metricTileWithKey: @"mode-metric" label: @"Mode" value: _model.angleModeText],
            [AsyncRTCalculatorViewNodes metricTileWithKey: @"memory-metric"
                                                    label: @"Memory"
                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [AsyncRTCalculatorViewNodes columnNodeWithKey: @"syntax" gap: 6 children: @[
            [AsyncRTCalculatorViewNodes textNode: @"Typed syntax" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
            [AsyncRTCalculatorViewNodes textNode: @"Functions: sin, cosh, ln, log, exp, sqrt, abs, floor, ceil, round, cbrt."
                                                 style: [AsyncRTCalculatorTheme historyExpressionStyle]],
            [AsyncRTCalculatorViewNodes textNode: @"Two-argument helpers: pow(x, y), min(x, y), max(x, y), mod(x, y). Symbols: ans, pi, e, tau, rand()."
                                                 style: [AsyncRTCalculatorTheme historyExpressionStyle]]
        ]],
        [AsyncRTCalculatorViewNodes dividerNodeWithKey: @"sidebar-divider" color: [AsyncRTCalculatorTheme panelBorderColor]],
        [AsyncRTCalculatorViewNodes textNode: @"History" style: [AsyncRTCalculatorTheme sectionTitleStyle]],
        [AsyncRTCalculatorViewNodes scrollColumnNodeWithKey: @"history-scroll" children: historyChildren]
    ]];
}

@end

#pragma clang assume_nonnull end
