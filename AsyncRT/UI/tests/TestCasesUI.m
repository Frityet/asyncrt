#include <stdlib.h>
#include <string.h>

#define AsyncScope AsyncTaskGroup
#import "TestSupport.h"
#undef AsyncScope

#import "CalculatorComponents.h"
#import "UI.h"
#import "AUIClaySupport.h"
#import "AUIInternal.h"
#import "AUIRenderHost.h"
#import "Backend/Window/AUIHeadlessWindow.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUITestApplication : AUIApplication @end

@implementation AUITestApplication

- (AUIViewComponent *)makeRootViewComponent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

@end

typedef struct AUITestRenderHarness {
    AUITestApplication *application;
    AUIHeadlessWindow *window;
    Clay_Context *nillable context;
    void *nillable memory;
    size_t memorySize;
} AUITestRenderHarness;

static Clay_Dimensions AUITestMeasureText(Clay_StringSlice text,
                                          Clay_TextElementConfig *config,
                                          void *userData)
{
    (void)config;
    (void)userData;
    return (Clay_Dimensions){
        .width = (float)text.length * 8.0f,
        .height = 16.0f
    };
}

static AUITestRenderHarness AUITestRenderHarnessMake(AUITestApplication *application)
{
    AUITestRenderHarness harness = {0};
    AUIWindowOptions *options = [AUIWindowOptions title: @"UI Test"
                                                   size: [AUI sizeWithWidth: 360 height: 240]
                                              resizable: false
                              autoResizeToRootComponent: false
                                    scaleWithWindowSize: false
                                           contentScale: 1];

    harness.application = application;
    harness.window = [[AUIHeadlessWindow alloc] initWithApplication: application options: options];
    [harness.window openWindow];
    [application _setWindowForTesting: harness.window];

    harness.memorySize = [AUIClay minimumMemorySize];
    harness.memory = malloc(harness.memorySize);
    harness.context = [AUIClay initializeWithMemory: $assert_nonnil(harness.memory)
                                               size: harness.memorySize
                                         dimensions: harness.window.viewportSize];
    AUIClay.currentContext = harness.context;
    Clay_SetMeasureTextFunction(AUITestMeasureText, nilptr);
    return harness;
}

static void AUITestRenderHarnessDestroy(AUITestRenderHarness *harness)
{
    [harness->application _setWindowForTesting: nilptr];
    [harness->window closeWindow];
    AUIClay.currentContext = nullptr;
    free(harness->memory);
    harness->memory = nullptr;
    harness->context = nullptr;
}

static void AUITestMountComponent(AUITestRenderHarness *harness,
                                  AUIViewComponent *rootViewComponent,
                                  AsyncTaskGroup *taskGroup)
{
    [[harness->application _renderHost] attachRootViewComponent: rootViewComponent taskGroup: taskGroup];
}

static void AUITestUnmountComponent(AUITestRenderHarness *harness)
{
    [[harness->application _renderHost] detachRootViewComponent];
}

static Clay_RenderCommandArray AUITestRenderMountedComponent(AUITestRenderHarness *harness)
{
    Clay_RenderCommandArray commands = {0};

    for (size_t iteration = 0; iteration < 4; iteration++) {
        (void)[harness->application _consumePendingRenderRequest];
        AUIClay.currentContext = harness->context;
        AUIClay.layoutDimensions = harness->window.viewportSize;
        commands = [harness->application _buildRenderCommandsWithViewportSize: harness->window.viewportSize deltaTime: (1.0f / 60.0f)];

        if (not [harness->application _hasPendingRenderRequest])
            break;
    }

    return commands;
}

static OFString *AUITestStringFromSlice(Clay_StringSlice slice)
{
    char *buffer = calloc((size_t)slice.length + 1, sizeof(char));
    OFString *string;

    memcpy(buffer, slice.chars, (size_t)slice.length);
    string = [[OFString alloc] initWithUTF8String: buffer];
    free(buffer);
    return string;
}

static bool AUITestCommandsContainText(Clay_RenderCommandArray commands, OFString *expectedText)
{
    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

        if (command == nullptr or command->commandType != CLAY_RENDER_COMMAND_TYPE_TEXT)
            continue;
        if ([AUITestStringFromSlice(command->renderData.text.stringContents) containsString: expectedText])
            return true;
    }

    return false;
}

static bool AUITestSizeEquals(AUISize left, AUISize right)
{
    return (left.width == right.width and left.height == right.height);
}

static Clay_BoundingBox AUITestBoundingBoxForIdentifier(OFString *identifier)
{
    Clay_ElementData data = [AUIClay elementDataForID: [AUIClay elementIDFromString: identifier]];

    if (not data.found)
        @throw [[TestFailureException alloc] initWithMessage: [OFString stringWithFormat: @"Missing element %@", identifier]];

    return data.boundingBox;
}

static void AUITestClickPrimary(AUITestRenderHarness *harness, float x, float y)
{
    [harness->window sendPointerMoveToX: x y: y];
    [harness->window sendMouseDown: AUIMouseButtonPrimary];
    [harness->window sendMouseUp: AUIMouseButtonPrimary];
}

static void AUITestClickSecondary(AUITestRenderHarness *harness, float x, float y)
{
    [harness->window sendPointerMoveToX: x y: y];
    [harness->window sendMouseDown: AUIMouseButtonSecondary];
    [harness->window sendMouseUp: AUIMouseButtonSecondary];
}

static void window_options_expose_content_scaling_configuration(void)
{
    AUIWindowOptions *options = [AUIWindowOptions title: @"Scaled"
                                                   size: [AUI sizeWithWidth: 360 height: 240]
                                              resizable: true
                                autoResizeToRootComponent: false
                                     scaleWithWindowSize: true
                                            contentScale: 2.5];

    [AsyncRuntimeTestSupport assertCondition: options.scalesWithWindowSize
                                     message: @"AUIWindowOptions should retain whether content scales with window size"];
    [AsyncRuntimeTestSupport assertCondition: (options.contentScale == 2.5)
                                     message: @"AUIWindowOptions should retain the requested content scale"];
}

static void headless_window_content_scale_changes_viewport_and_pointer_space(void)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUIWindowOptions *options = [AUIWindowOptions title: @"Scaled"
                                                   size: [AUI sizeWithWidth: 360 height: 240]
                                              resizable: false
                                autoResizeToRootComponent: false
                                     scaleWithWindowSize: false
                                            contentScale: 2.0];
    AUIHeadlessWindow *window = [[AUIHeadlessWindow alloc] initWithApplication: application options: options];

    [window openWindow];
    [application _setWindowForTesting: window];

    [AsyncRuntimeTestSupport assertCondition: AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120])
                                     message: @"contentScale should shrink the logical viewport while keeping the native window size"];

    [window sendPointerMoveToX: 180 y: 120];
    [AsyncRuntimeTestSupport assertCondition: (application._inputState.pointerX == 90.0f and application._inputState.pointerY == 60.0f)
                                     message: @"headless pointer events should be mapped back into logical viewport coordinates"];

    [window setNativeSize: [AUI sizeWithWidth: 720 height: 480]];
    [AsyncRuntimeTestSupport assertCondition: AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 360 height: 240])
                                     message: @"logical viewport should continue to track native size when scaleWithWindowSize is disabled"];

    [window sendPointerMoveToX: 360 y: 240];
    [AsyncRuntimeTestSupport assertCondition: (application._inputState.pointerX == 180.0f and application._inputState.pointerY == 120.0f)
                                     message: @"pointer mapping should keep respecting contentScale after native resizes"];

    [application _setWindowForTesting: nilptr];
    [window closeWindow];
}

static void headless_window_scale_with_window_size_keeps_reference_viewport(void)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUIWindowOptions *options = [AUIWindowOptions title: @"Scaled"
                                                   size: [AUI sizeWithWidth: 360 height: 240]
                                              resizable: false
                                autoResizeToRootComponent: false
                                     scaleWithWindowSize: true
                                            contentScale: 2.0];
    AUIHeadlessWindow *window = [[AUIHeadlessWindow alloc] initWithApplication: application options: options];

    [window openWindow];
    [application _setWindowForTesting: window];

    [AsyncRuntimeTestSupport assertCondition: AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120])
                                     message: @"scaleWithWindowSize should establish a reference logical viewport at open time"];

    [window setNativeSize: [AUI sizeWithWidth: 720 height: 480]];
    [AsyncRuntimeTestSupport assertCondition: AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120])
                                     message: @"scaleWithWindowSize should keep the logical viewport fixed across native resizes"];

    [window sendPointerMoveToX: 360 y: 240];
    [AsyncRuntimeTestSupport assertCondition: (application._inputState.pointerX == 90.0f and application._inputState.pointerY == 60.0f)
                                     message: @"pointer mapping should use the fixed reference viewport when scaling with window size"];

    [window setViewportSize: [AUI sizeWithWidth: 200 height: 100]];
    [AsyncRuntimeTestSupport assertCondition: AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 200 height: 100])
                                     message: @"setting the viewport explicitly should replace the reference viewport"];

    [window sendPointerMoveToX: 200 y: 100];
    [AsyncRuntimeTestSupport assertCondition: (application._inputState.pointerX == 100.0f and application._inputState.pointerY == 50.0f)
                                     message: @"pointer mapping should follow the updated reference viewport after explicit viewport changes"];

    [application _setWindowForTesting: nilptr];
    [window closeWindow];
}

[[subclassing_restricted]]
@interface AUITestStateComponent : AUIViewComponent

@property(readonly, nonatomic) AUIStateBinding<OFString *> *nillable stateBinding;

@end

@implementation AUITestStateComponent {
    AUIStateBinding<OFString *> *nillable _stateBinding;
}

- (AUIViewNode *)renderViewNode
{
    _stateBinding = [self useStateWithInitialValue: @"alpha"];
    return [AUIViewTextNode textNodeWithText: _stateBinding.value style: AUI.defaultTextStyle];
}

@end

[[subclassing_restricted]]
@interface AUITestLeafComponent : AUIViewComponent

@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) size_t mountCount;
@property(readonly, nonatomic) AUIStateBinding<OFString *> *nillable stateBinding;

- (instancetype)initWithName: (OFString *)name [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AUITestLeafComponent {
    OFString *_name;
    size_t _mountCount;
    AUIStateBinding<OFString *> *nillable _stateBinding;
}

- (instancetype)initWithName: (OFString *)name
{
    self = [super init];
    _name = [name copy];
    return self;
}

- (void)viewComponentDidMount
{
    _mountCount++;
}

- (AUIViewNode *)renderViewNode
{
    _stateBinding = [self useStateWithInitialValue: _name];
    return [AUIViewTextNode textNodeWithText: _stateBinding.value style: AUI.defaultTextStyle];
}

@end

[[subclassing_restricted]]
@interface AUITestReorderComponent : AUIViewComponent

@property(nonatomic) bool isReversed;

- (instancetype)initWithLeft: (AUITestLeafComponent *)left right: (AUITestLeafComponent *)right [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AUITestReorderComponent {
    AUITestLeafComponent *_left;
    AUITestLeafComponent *_right;
    bool _isReversed;
}

- (instancetype)initWithLeft: (AUITestLeafComponent *)left right: (AUITestLeafComponent *)right
{
    self = [super init];
    _left = left;
    _right = right;
    return self;
}

- (AUIViewNode *)renderViewNode
{
    if (_isReversed) {
        return [AUIViewFragmentNode fragmentNodeWithChildren: @[
            [self renderChildViewComponent: _right key: @"right"],
            [self renderChildViewComponent: _left key: @"left"]
        ]];
    }

    return [AUIViewFragmentNode fragmentNodeWithChildren: @[
        [self renderChildViewComponent: _left key: @"left"],
        [self renderChildViewComponent: _right key: @"right"]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestEditableFieldComponent : AUIViewComponent

@property(copy, nonatomic) OFString *latestText;
@property(copy, nonatomic) OFString *submittedText;
@property(nonatomic) bool showsBanner;

@end

@implementation AUITestEditableFieldComponent {
    OFString *_latestText;
    OFString *_submittedText;
    bool _showsBanner;
}

- (instancetype)init
{
    self = [super init];
    _latestText = @"";
    _submittedText = @"";
    return self;
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps fieldProps = AUI.defaultBoxProps;
    OFMutableArray<id<AUIRenderable>> *children = [OFMutableArray array];

    fieldProps.layout.width = [AUI axisFixed: 220];
    fieldProps.layout.height = [AUI axisFit: 0];
    fieldProps.layout.childGap = 8;
    fieldProps.layout.direction = AUILayoutDirectionColumn;

    if (_showsBanner)
        [children addObject: [AUIViewTextNode textNodeWithText: @"Banner" style: AUI.defaultTextStyle]];

    [children addObject: [AUIViewEditableTextNode editableTextNodeWithKey: @"field"
                                                                     text: _latestText
                                                              placeholder: @"Type"
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
        _latestText = [text copy];
        [self setNeedsViewUpdate];
    }
                                                                 onSubmit: ^(OFString *text) {
        _submittedText = [text copy];
    }]];

    return [AUIViewBoxNode boxNodeWithKey: @"field-root" boxProps: fieldProps interactionConfiguration: nilptr children: children];
}

@end

[[subclassing_restricted]]
@interface AUITestEffectComponent : AUIViewComponent

@property(nonatomic) uint32_t phase;
@property(nonatomic) uint32_t runCount;
@property(nonatomic) uint32_t cleanupCount;

@end

@implementation AUITestEffectComponent {
    uint32_t _phase;
    uint32_t _runCount;
    uint32_t _cleanupCount;
}

- (AUIViewNode *)renderViewNode
{
    OFNumber *phaseValue = @(_phase);

    [self useEffectWithDependencies: @[phaseValue] effect: ^AUIViewEffectCleanupHandler{
        _runCount++;
        return ^{
            _cleanupCount++;
        };
    }];

    return [AUIViewTextNode textNodeWithText: @"effect" style: AUI.defaultTextStyle];
}

@end

[[subclassing_restricted]]
@interface AUITestContextMenuComponent : AUIViewComponent

@property(nonatomic) bool didSelect;

@end

@implementation AUITestContextMenuComponent {
    bool _didSelect;
}

- (AUIViewNode *)renderViewNode
{
    AUIBoxProps props = AUI.defaultBoxProps;
    AUIContextMenu *menu = [AUIContextMenu items: @[
        [AUIContextMenuItem title: @"Inspect" enabled: true onSelect: ^{
            _didSelect = true;
        }]
    ]];

    props.layout.width = [AUI axisFixed: 180];
    props.layout.height = [AUI axisFixed: 40];
    props.layout.padding = [AUI insetsAll: 12];
    props.backgroundColor = [AUI colorWithRed: 240 green: 240 blue: 240 alpha: 255];
    props.cornerRadius = 8;
    return [AUIViewBoxNode boxNodeWithKey: @"menu-box"
                                 boxProps: props
                   interactionConfiguration: [AUIViewInteractionConfiguration enabled: true
                                                                           focusable: false
                                                                         cursorStyle: AUICursorStylePointer
                                                                          onActivate: nilptr
                                                                         contextMenu: menu]
                                 children: @[
        [AUIViewTextNode textNodeWithText: @"Context target" style: AUI.defaultTextStyle]
    ]];
}

@end

static void hook_state_updates_request_render_only_on_change(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestStateComponent *component = [[AUITestStateComponent alloc] init];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
    Clay_RenderCommandArray commands;

    AUITestMountComponent(&harness, component, taskGroup);
    commands = AUITestRenderMountedComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: AUITestCommandsContainText(commands, @"alpha")
                                     message: @"initial state should render"];

    [[component stateBinding] setValue: @"alpha"];
    [AsyncRuntimeTestSupport assertCondition: (not [application _hasPendingRenderRequest])
                                     message: @"writing the same state value should not request a render"];

    [[component stateBinding] setValue: @"beta"];
    [AsyncRuntimeTestSupport assertCondition: [application _hasPendingRenderRequest]
                                     message: @"writing a different state value should request a render"];

    commands = AUITestRenderMountedComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: AUITestCommandsContainText(commands, @"beta")
                                     message: @"updated state should render"];
    AUITestUnmountComponent(&harness);
    AUITestRenderHarnessDestroy(&harness);
}

static void keyed_child_components_retain_state_across_reorder(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestLeafComponent *left = [[AUITestLeafComponent alloc] initWithName: @"left"];
    AUITestLeafComponent *right = [[AUITestLeafComponent alloc] initWithName: @"right"];
    AUITestReorderComponent *root = [[AUITestReorderComponent alloc] initWithLeft: left right: right];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
    Clay_RenderCommandArray commands;

    AUITestMountComponent(&harness, root, taskGroup);
    (void)AUITestRenderMountedComponent(&harness);
    [[left stateBinding] setValue: @"preserved"];
    root.isReversed = true;
    [root setNeedsViewUpdate];

    commands = AUITestRenderMountedComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: AUITestCommandsContainText(commands, @"preserved")
                                     message: @"stable child keys should preserve child hook state through reorder"];
    [AsyncRuntimeTestSupport assertCondition: (left.mountCount == 1 and right.mountCount == 1)
                                     message: @"stable child keys should retain mounted child instances"];
    AUITestUnmountComponent(&harness);
    AUITestRenderHarnessDestroy(&harness);
}

static void editable_text_focus_persists_across_conditional_insertion(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestEditableFieldComponent *component = [[AUITestEditableFieldComponent alloc] init];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
    Clay_BoundingBox boundingBox;

    AUITestMountComponent(&harness, component, taskGroup);
    (void)AUITestRenderMountedComponent(&harness);
    boundingBox = AUITestBoundingBoxForIdentifier(@"root/node:field-root/node:field");
    AUITestClickPrimary(&harness,
                        boundingBox.x + boundingBox.width / 2.0f,
                        boundingBox.y + boundingBox.height / 2.0f);
    (void)AUITestRenderMountedComponent(&harness);

    component.showsBanner = true;
    [component setNeedsViewUpdate];
    (void)AUITestRenderMountedComponent(&harness);

    [harness.window sendText: @"x"];
    (void)AUITestRenderMountedComponent(&harness);
    [harness.window sendKey: AUIKeyEnter modifiers: AUIModifierFlagNone repeat: false];
    (void)AUITestRenderMountedComponent(&harness);

    [AsyncRuntimeTestSupport assertCondition: [component.latestText isEqual: @"x"]
                                     message: @"focused editable nodes should keep focus when sibling structure changes but key stays stable"];
    [AsyncRuntimeTestSupport assertCondition: [component.submittedText isEqual: @"x"]
                                     message: @"focused editable nodes should continue to submit after keyed reconciliation"];
    AUITestUnmountComponent(&harness);
    AUITestRenderHarnessDestroy(&harness);
}

static void effect_cleanup_runs_on_dependency_change_and_unmount(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestEffectComponent *component = [[AUITestEffectComponent alloc] init];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);

    AUITestMountComponent(&harness, component, taskGroup);
    (void)AUITestRenderMountedComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: (component.runCount == 1 and component.cleanupCount == 0)
                                     message: @"effect hooks should run after first commit"];

    component.phase = 1;
    [component setNeedsViewUpdate];
    (void)AUITestRenderMountedComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: (component.runCount == 2 and component.cleanupCount == 1)
                                     message: @"effect hooks should clean up and rerun when dependencies change"];

    AUITestUnmountComponent(&harness);
    [AsyncRuntimeTestSupport assertCondition: (component.cleanupCount == 2)
                                     message: @"effect hooks should clean up when the component unmounts"];
    AUITestRenderHarnessDestroy(&harness);
}

static void context_menu_attachment_opens_and_activates(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestContextMenuComponent *component = [[AUITestContextMenuComponent alloc] init];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
    Clay_BoundingBox targetBoundingBox;
    Clay_BoundingBox menuItemBoundingBox;

    AUITestMountComponent(&harness, component, taskGroup);
    (void)AUITestRenderMountedComponent(&harness);
    targetBoundingBox = AUITestBoundingBoxForIdentifier(@"root/node:menu-box");
    AUITestClickSecondary(&harness,
                          targetBoundingBox.x + targetBoundingBox.width / 2.0f,
                          targetBoundingBox.y + targetBoundingBox.height / 2.0f);
    (void)AUITestRenderMountedComponent(&harness);

    [AsyncRuntimeTestSupport assertCondition: ([application _activeContextMenuForTesting] != nilptr)
                                     message: @"context menu attachments should open a menu on secondary click"];

    menuItemBoundingBox = AUITestBoundingBoxForIdentifier(@"__context_menu__/0");
    AUITestClickPrimary(&harness,
                        menuItemBoundingBox.x + menuItemBoundingBox.width / 2.0f,
                        menuItemBoundingBox.y + menuItemBoundingBox.height / 2.0f);
    (void)AUITestRenderMountedComponent(&harness);

    [AsyncRuntimeTestSupport assertCondition: component.didSelect
                                     message: @"context menu item activation should invoke the attached handler"];
    [AsyncRuntimeTestSupport assertCondition: ([application _activeContextMenuForTesting] == nilptr)
                                     message: @"context menus should dismiss after activation"];
    AUITestUnmountComponent(&harness);
    AUITestRenderHarnessDestroy(&harness);
}

static void calculator_keypad_clicks_refresh_shared_display_state(AsyncTaskGroup *taskGroup)
{
    AUITestApplication *application = [[AUITestApplication alloc] init];
    CalculatorRootComponent *component = [[CalculatorRootComponent alloc] init];
    AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
    Clay_BoundingBox digitSevenBoundingBox;
    Clay_BoundingBox plusBoundingBox;
    Clay_BoundingBox digitEightBoundingBox;
    Clay_BoundingBox evaluateBoundingBox;
    Clay_RenderCommandArray commands;

    AUITestMountComponent(&harness, component, taskGroup);
    (void)AUITestRenderMountedComponent(&harness);

    digitSevenBoundingBox = AUITestBoundingBoxForIdentifier(@"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-a/node:digit-7");
    plusBoundingBox = AUITestBoundingBoxForIdentifier(@"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-d/node:plus");
    digitEightBoundingBox = AUITestBoundingBoxForIdentifier(@"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-a/node:digit-8");
    evaluateBoundingBox = AUITestBoundingBoxForIdentifier(@"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:evaluate");

    AUITestClickPrimary(&harness,
                        digitSevenBoundingBox.x + digitSevenBoundingBox.width / 2.0f,
                        digitSevenBoundingBox.y + digitSevenBoundingBox.height / 2.0f);
    (void)AUITestRenderMountedComponent(&harness);

    AUITestClickPrimary(&harness,
                        plusBoundingBox.x + plusBoundingBox.width / 2.0f,
                        plusBoundingBox.y + plusBoundingBox.height / 2.0f);
    (void)AUITestRenderMountedComponent(&harness);

    AUITestClickPrimary(&harness,
                        digitEightBoundingBox.x + digitEightBoundingBox.width / 2.0f,
                        digitEightBoundingBox.y + digitEightBoundingBox.height / 2.0f);
    commands = AUITestRenderMountedComponent(&harness);

    [AsyncRuntimeTestSupport assertCondition: AUITestCommandsContainText(commands, @"7+8")
                                     message: @"calculator keypad clicks should update the shared expression display"];

    AUITestClickPrimary(&harness,
                        evaluateBoundingBox.x + evaluateBoundingBox.width / 2.0f,
                        evaluateBoundingBox.y + evaluateBoundingBox.height / 2.0f);
    commands = AUITestRenderMountedComponent(&harness);

    [AsyncRuntimeTestSupport assertCondition: AUITestCommandsContainText(commands, @"15")
                                     message: @"calculator keypad clicks should drive evaluation results into the display"];
    AUITestUnmountComponent(&harness);
    AUITestRenderHarnessDestroy(&harness);
}

ASYNC_RUNTIME_SYNC_TEST(window_options_expose_content_scaling_configuration)
ASYNC_RUNTIME_SYNC_TEST(headless_window_content_scale_changes_viewport_and_pointer_space)
ASYNC_RUNTIME_SYNC_TEST(headless_window_scale_with_window_size_keeps_reference_viewport)
ASYNC_RUNTIME_ASYNC_TEST(hook_state_updates_request_render_only_on_change)
ASYNC_RUNTIME_ASYNC_TEST(keyed_child_components_retain_state_across_reorder)
ASYNC_RUNTIME_ASYNC_TEST(editable_text_focus_persists_across_conditional_insertion)
ASYNC_RUNTIME_ASYNC_TEST(effect_cleanup_runs_on_dependency_change_and_unmount)
ASYNC_RUNTIME_ASYNC_TEST(context_menu_attachment_opens_and_activates)
ASYNC_RUNTIME_ASYNC_TEST(calculator_keypad_clicks_refresh_shared_display_state)

#pragma clang assume_nonnull end
