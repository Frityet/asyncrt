#import "CalculatorComponents.h"

#import "CalculatorModel.h"
#import "CalculatorTheme.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface CalculatorHeaderViewComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorDisplayViewComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorKeypadViewComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorSidebarViewComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

typedef struct CalculatorButtonSpec {
    OFString *key;
    OFString *title;
    AUIControlVariant variant;
    AUIControlSize size;
    bool isEnabled;
    void (^onPress)(void);
} CalculatorButtonSpec;

@namespace(CalculatorViewNodes)

+ (AUIViewTextNode *)textNode: (OFString *nillable)text style: (AUITextStyle)style;
+ (AUIViewBoxNode *)boxNodeWithKey: (OFString *nillable)key props: (AUIBoxProps)props children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)rowNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)columnNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)fixedWidthNodeWithKey: (OFString *)key width: (float)width child: (id<AUIRenderable>)child;
+ (AUIViewBoxNode *)scrollColumnNodeWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)buttonNodeFromSpec: (CalculatorButtonSpec)spec;
+ (AUIViewBoxNode *)metricTileWithKey: (OFString *)key label: (OFString *)label value: (OFString *)value;
+ (AUIViewBoxNode *)historyTileWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children;
+ (AUIViewBoxNode *)badgeNodeWithKey: (OFString *)key text: (OFString *)text variant: (AUIControlVariant)variant;
+ (AUIViewBoxNode *)dividerNodeWithKey: (OFString *)key color: (AUIColor)color;

@end

@namespace_implementation(CalculatorViewNodes)

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
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionRow;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)columnNodeWithKey: (OFString *)key gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *)children
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFit: 0];
    props.layout.childGap = gap;
    props.layout.direction = AUILayoutDirectionColumn;
    props.layout.childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart];
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)fixedWidthNodeWithKey: (OFString *)key width: (float)width child: (id<AUIRenderable>)child
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisFixed: width];
    props.layout.height = [AUI axisGrow: 0];
    return [self boxNodeWithKey: key props: props children: @[child]];
}

+ (AUIViewBoxNode *)scrollColumnNodeWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.childGap = 10;
    props.scrollAxis = AUIScrollAxisVertical;
    return [self boxNodeWithKey: key props: props children: children];
}

+ (AUIViewBoxNode *)buttonNodeFromSpec: (CalculatorButtonSpec)spec
{
    AUIBoxProps props = AUI.defaultBoxProps;
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
    AUIBoxProps props = [CalculatorTheme metricTileProps];
    return [self boxNodeWithKey: key props: props children: @[
        [self textNode: label style: [CalculatorTheme metricLabelStyle]],
        [self textNode: value style: [CalculatorTheme metricValueStyle]]
    ]];
}

+ (AUIViewBoxNode *)historyTileWithKey: (OFString *)key children: (OFArray<id<AUIRenderable>> *)children
{
    return [self boxNodeWithKey: key props: [CalculatorTheme historyTileProps] children: children];
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
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisFixed: 1];
    props.backgroundColor = color;
    return [self boxNodeWithKey: key props: props children: @[]];
}

@end

@implementation CalculatorRootComponent {
    CalculatorModel *_model;
    CalculatorHeaderViewComponent *_headerViewComponent;
    CalculatorDisplayViewComponent *_displayViewComponent;
    CalculatorKeypadViewComponent *_keypadViewComponent;
    CalculatorSidebarViewComponent *_sidebarViewComponent;
}

- (instancetype)init
{
    self = [super init];
    _model = [CalculatorModel model];
    _headerViewComponent = [[CalculatorHeaderViewComponent alloc] initWithModel: _model];
    _displayViewComponent = [[CalculatorDisplayViewComponent alloc] initWithModel: _model];
    _keypadViewComponent = [[CalculatorKeypadViewComponent alloc] initWithModel: _model];
    _sidebarViewComponent = [[CalculatorSidebarViewComponent alloc] initWithModel: _model];
    return self;
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.padding = [AUI insetsAll: 28];
    props.layout.childGap = 22;
    props.layout.direction = AUILayoutDirectionColumn;
    props.backgroundColor = [CalculatorTheme canvasColor];

    return [AUIViewBoxNode boxNodeWithKey: @"calculator-root"
                                 boxProps: props
                   interactionConfiguration: nilptr
                                 children: @[
        [self renderChildViewComponent: _headerViewComponent key: @"header"],
        [CalculatorViewNodes rowNodeWithKey: @"content-row" gap: 20 children: @[
            [CalculatorViewNodes boxNodeWithKey: @"main-column"
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
            [CalculatorViewNodes fixedWidthNodeWithKey: @"sidebar-frame"
                                                        width: 340
                                                        child: [self renderChildViewComponent: _sidebarViewComponent key: @"sidebar"]]
        ]]
    ]];
}

@end

@implementation CalculatorHeaderViewComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *)model
{
    self = [super init];
    _model = model;
    return self;
}

- (AUIViewNode *)renderViewNode
{
    return [CalculatorViewNodes rowNodeWithKey: @"header-row" gap: 18 children: @[
        [CalculatorViewNodes boxNodeWithKey: @"header-text"
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
            [CalculatorViewNodes textNode: @"Scientific Calculator" style: [CalculatorTheme titleStyle]],
            [CalculatorViewNodes textNode: @"Queue-driven runtime, retained view components, and hook-based UI state in one native calculator."
                                                 style: [CalculatorTheme subtitleStyle]]
        ]],
        [CalculatorViewNodes rowNodeWithKey: @"header-badges" gap: 8 children: @[
            [CalculatorViewNodes badgeNodeWithKey: @"mode-badge"
                                                    text: [OFString stringWithFormat: @"Mode %@", _model.angleModeText]
                                                 variant: AUIControlVariantPrimary],
            [CalculatorViewNodes badgeNodeWithKey: @"memory-badge"
                                                    text: (_model.hasMemoryValue
                ? [OFString stringWithFormat: @"M %@", _model.memoryDisplayText]
                : @"Memory empty")
                                                 variant: (_model.hasMemoryValue ? AUIControlVariantSecondary : AUIControlVariantNeutral)],
            [CalculatorViewNodes badgeNodeWithKey: @"history-badge"
                                                    text: [OFString stringWithFormat: @"History %zu", _model.history.count]
                                                 variant: AUIControlVariantNeutral]
        ]]
    ]];
}

@end

@implementation CalculatorDisplayViewComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *)model
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
    AUIBoxProps panelProps = [CalculatorTheme displayPanelProps];
    AUIBoxProps resultBoxProps = [CalculatorTheme metricTileProps];

    resultBoxProps.layout.padding = [AUI insetsAll: 18];
    resultBoxProps.layout.childGap = 8;
    resultBoxProps.backgroundColor = [AUI colorWithRed: 248 green: 241 blue: 226 alpha: 255];
    resultBoxProps.cornerRadius = 20;

    return [AUIViewBoxNode boxNodeWithKey: @"display-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: @[
        [CalculatorViewNodes rowNodeWithKey: @"display-header" gap: 16 children: @[
            [CalculatorViewNodes columnNodeWithKey: @"workspace-text" gap: 4 children: @[
                [CalculatorViewNodes textNode: @"Workspace" style: [CalculatorTheme sectionTitleStyle]],
                [CalculatorViewNodes textNode: @"Edit directly, then use keypad actions when they are faster."
                                                     style: [CalculatorTheme metricLabelStyle]]
            ]],
            [CalculatorViewNodes rowNodeWithKey: @"angle-buttons" gap: 8 children: @[
                [CalculatorViewNodes buttonNodeFromSpec: ((CalculatorButtonSpec){
                    .key = @"deg-button",
                    .title = @"DEG",
                    .variant = (_model.angleMode == CalculatorAngleModeDegrees ? AUIControlVariantPrimary : AUIControlVariantSecondary),
                    .size = AUIControlSizeSmall,
                    .isEnabled = true,
                    .onPress = ^{
                    if (_model.angleMode != CalculatorAngleModeDegrees)
                        [_model toggleAngleMode];
                    [self _refresh];
                }
                })],
                [CalculatorViewNodes buttonNodeFromSpec: ((CalculatorButtonSpec){
                    .key = @"rad-button",
                    .title = @"RAD",
                    .variant = (_model.angleMode == CalculatorAngleModeRadians ? AUIControlVariantPrimary : AUIControlVariantSecondary),
                    .size = AUIControlSizeSmall,
                    .isEnabled = true,
                    .onPress = ^{
                    if (_model.angleMode != CalculatorAngleModeRadians)
                        [_model toggleAngleMode];
                    [self _refresh];
                }
                })]
            ]]
        ]],
        [CalculatorViewNodes columnNodeWithKey: @"expression-editor" gap: 6 children: @[
            [CalculatorViewNodes textNode: @"Expression" style: [CalculatorTheme metricLabelStyle]],
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
        [CalculatorViewNodes rowNodeWithKey: @"metrics-row" gap: 12 children: @[
            [CalculatorViewNodes metricTileWithKey: @"ans-tile" label: @"ANS" value: _model.lastAnswerDisplayText],
            [CalculatorViewNodes metricTileWithKey: @"memory-tile"
                                                    label: @"Memory"
                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [CalculatorViewNodes dividerNodeWithKey: @"display-divider" color: [CalculatorTheme displayBorderColor]],
        [CalculatorViewNodes boxNodeWithKey: @"result-panel" props: resultBoxProps children: @[
            [CalculatorViewNodes textNode: @"Result" style: [CalculatorTheme displayLabelStyle]],
            [CalculatorViewNodes textNode: _model.resultText style: [CalculatorTheme resultStyle]]
        ]],
        [CalculatorViewNodes textNode: _model.statusText
                                       style: [CalculatorTheme statusStyleForError: _model.hasError]]
    ]];
}

@end

@implementation CalculatorKeypadViewComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *)model
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
    AUIBoxProps panelProps = [CalculatorTheme keypadPanelProps];
    OFMutableArray<id<AUIRenderable>> *rows = [OFMutableArray array];

    [rows addObject: [CalculatorViewNodes columnNodeWithKey: @"keypad-title" gap: 4 children: @[
        [CalculatorViewNodes textNode: @"Keypad" style: [CalculatorTheme sectionTitleStyle]],
        [CalculatorViewNodes textNode: @"Scientific rows stay visible while Evaluate commits the current expression."
                                             style: [CalculatorTheme metricLabelStyle]]
    ]]];

#define BUTTON_ROW(key, ...) [rows addObject: [CalculatorViewNodes rowNodeWithKey: key gap: 10 children: @[__VA_ARGS__]]]
#define BUTTON_VALUE(spec) [CalculatorViewNodes buttonNodeFromSpec: spec]

    BUTTON_ROW(@"memory-row",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"memory-clear", .title = @"MC", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = _model.hasMemoryValue, .onPress = ^{ [_model memoryClear]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"memory-recall", .title = @"MR", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = _model.hasMemoryValue, .onPress = ^{ [_model memoryRecall]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"memory-store", .title = @"MS", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model memoryStore]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"memory-add", .title = @"M+", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model memoryAdd]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"memory-subtract", .title = @"M-", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model memorySubtract]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"insert-ans", .title = @"ANS", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = _model.hasLastAnswer, .onPress = ^{ [_model appendAnswerReference]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"edit-row",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"clear", .title = @"C", .variant = AUIControlVariantDanger, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model clearExpression]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"clear-all", .title = @"AC", .variant = AUIControlVariantDanger, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model clearAll]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"backspace", .title = @"Back", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = (_model.expression.length > 0 or _model.hasLastAnswer), .onPress = ^{ [_model backspace]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"toggle-sign", .title = @"+/-", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model toggleSign]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"percent", .title = @"%", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyPercent]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"factorial", .title = @"!", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFactorial]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"functions-row-a",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"sin", .title = @"sin", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"sin"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"cos", .title = @"cos", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"cos"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"tan", .title = @"tan", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"tan"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"sinh", .title = @"sinh", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"sinh"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"cosh", .title = @"cosh", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"cosh"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"tanh", .title = @"tanh", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"tanh"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"functions-row-b",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"asin", .title = @"asin", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"asin"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"acos", .title = @"acos", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"acos"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"atan", .title = @"atan", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"atan"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"ln", .title = @"ln", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"ln"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"log", .title = @"log", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"log"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"exp", .title = @"exp", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"exp"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"functions-row-c",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"sqrt", .title = @"sqrt", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"sqrt"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"square", .title = @"x^2", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applySquare]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"reciprocal", .title = @"1/x", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyReciprocal]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"abs", .title = @"abs", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"abs"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"rand", .title = @"rand", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendRandomFunction]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"power", .title = @"^", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOperator: @"^"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"digits-row-a",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-7", .title = @"7", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"7"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-8", .title = @"8", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"8"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-9", .title = @"9", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"9"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"open-paren", .title = @"(", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOpenParenthesis]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"close-paren", .title = @")", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendCloseParenthesis]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"divide", .title = @"/", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOperator: @"/"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"digits-row-b",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-4", .title = @"4", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"4"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-5", .title = @"5", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"5"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-6", .title = @"6", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"6"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"constant-pi", .title = @"pi", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendConstantNamed: @"pi"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"constant-e", .title = @"e", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendConstantNamed: @"e"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"multiply", .title = @"*", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOperator: @"*"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"digits-row-c",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-1", .title = @"1", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"1"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-2", .title = @"2", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"2"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-3", .title = @"3", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"3"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"floor", .title = @"floor", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"floor"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"ceil", .title = @"ceil", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"ceil"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"minus", .title = @"-", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOperator: @"-"]; [self _refresh]; } }))
    );

    BUTTON_ROW(@"digits-row-d",
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-0", .title = @"0", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"0"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"digit-00", .title = @"00", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDigits: @"00"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"decimal", .title = @".", .variant = AUIControlVariantNeutral, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendDecimalPoint]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"round", .title = @"round", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model applyFunctionNamed: @"round"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"constant-tau", .title = @"tau", .variant = AUIControlVariantSecondary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendConstantNamed: @"tau"]; [self _refresh]; } })),
        BUTTON_VALUE(((CalculatorButtonSpec){ .key = @"plus", .title = @"+", .variant = AUIControlVariantPrimary, .size = AUIControlSizeLarge, .isEnabled = true, .onPress = ^{ [_model appendOperator: @"+"]; [self _refresh]; } }))
    );

    [rows addObject: [CalculatorViewNodes buttonNodeFromSpec: ((CalculatorButtonSpec){
        .key = @"evaluate",
        .title = @"Evaluate",
        .variant = AUIControlVariantPrimary,
        .size = AUIControlSizeLarge,
        .isEnabled = true,
        .onPress = ^{
        [_model evaluate];
        [self _refresh];
    }
    })]];

#undef BUTTON_ROW
#undef BUTTON_VALUE

    return [AUIViewBoxNode boxNodeWithKey: @"keypad-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: rows];
}

@end

@implementation CalculatorSidebarViewComponent {
    CalculatorModel *_model;
}

- (instancetype)initWithModel: (CalculatorModel *)model
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
    AUIBoxProps panelProps = [CalculatorTheme sidebarPanelProps];
    OFMutableArray<id<AUIRenderable>> *historyChildren = [OFMutableArray array];

    if (_model.history.count == 0) {
        [historyChildren addObject: [CalculatorViewNodes historyTileWithKey: @"empty-history" children: @[
            [CalculatorViewNodes textNode: @"No committed history yet." style: [CalculatorTheme sectionTitleStyle]],
            [CalculatorViewNodes textNode: @"Press Evaluate to pin an expression and its result here for later reuse."
                                         style: [CalculatorTheme historyExpressionStyle]]
        ]]];
    } else {
        for (size_t index = 0; index < _model.history.count; index++) {
            CalculatorHistoryEntry *entry = [_model.history objectAtIndex: index];
            OFString *prefix = [OFString stringWithFormat: @"history-%zu", index];

            [historyChildren addObject: [CalculatorViewNodes historyTileWithKey: prefix children: @[
                [CalculatorViewNodes textNode: entry.expression style: [CalculatorTheme historyExpressionStyle]],
                [CalculatorViewNodes textNode: entry.resultText style: [CalculatorTheme historyResultStyle]],
                [CalculatorViewNodes rowNodeWithKey: [prefix stringByAppendingString: @"-actions"] gap: 8 children: @[
                    [CalculatorViewNodes buttonNodeFromSpec: ((CalculatorButtonSpec){
                        .key = [prefix stringByAppendingString: @"-expr"],
                        .title = @"Expr",
                        .variant = AUIControlVariantSecondary,
                        .size = AUIControlSizeSmall,
                        .isEnabled = true,
                        .onPress = ^{
                        [_model loadHistoryExpressionAtIndex: index];
                        [self _refresh];
                    }
                    })],
                    [CalculatorViewNodes buttonNodeFromSpec: ((CalculatorButtonSpec){
                        .key = [prefix stringByAppendingString: @"-result"],
                        .title = @"Result",
                        .variant = AUIControlVariantPrimary,
                        .size = AUIControlSizeSmall,
                        .isEnabled = true,
                        .onPress = ^{
                        [_model loadHistoryResultAtIndex: index];
                        [self _refresh];
                    }
                    })]
                ]]
            ]]];
        }
    }

    return [AUIViewBoxNode boxNodeWithKey: @"sidebar-panel"
                                 boxProps: panelProps
                   interactionConfiguration: nilptr
                                 children: @[
        [CalculatorViewNodes columnNodeWithKey: @"sidebar-intro" gap: 4 children: @[
            [CalculatorViewNodes textNode: @"Reference" style: [CalculatorTheme sectionTitleStyle]],
            [CalculatorViewNodes textNode: @"Memory, mode, typed syntax, and history stay visible in the retained sidebar."
                                                 style: [CalculatorTheme metricLabelStyle]]
        ]],
        [CalculatorViewNodes rowNodeWithKey: @"sidebar-metrics" gap: 10 children: @[
            [CalculatorViewNodes metricTileWithKey: @"mode-metric" label: @"Mode" value: _model.angleModeText],
            [CalculatorViewNodes metricTileWithKey: @"memory-metric"
                                                    label: @"Memory"
                                                    value: (_model.hasMemoryValue ? _model.memoryDisplayText : @"empty")]
        ]],
        [CalculatorViewNodes columnNodeWithKey: @"syntax" gap: 6 children: @[
            [CalculatorViewNodes textNode: @"Typed syntax" style: [CalculatorTheme sectionTitleStyle]],
            [CalculatorViewNodes textNode: @"Functions: sin, cosh, ln, log, exp, sqrt, abs, floor, ceil, round, cbrt."
                                                 style: [CalculatorTheme historyExpressionStyle]],
            [CalculatorViewNodes textNode: @"Two-argument helpers: pow(x, y), min(x, y), max(x, y), mod(x, y). Symbols: ans, pi, e, tau, rand()."
                                                 style: [CalculatorTheme historyExpressionStyle]]
        ]],
        [CalculatorViewNodes dividerNodeWithKey: @"sidebar-divider" color: [CalculatorTheme panelBorderColor]],
        [CalculatorViewNodes textNode: @"History" style: [CalculatorTheme sectionTitleStyle]],
        [CalculatorViewNodes scrollColumnNodeWithKey: @"history-scroll" children: historyChildren]
    ]];
}

@end

#pragma clang assume_nonnull end
