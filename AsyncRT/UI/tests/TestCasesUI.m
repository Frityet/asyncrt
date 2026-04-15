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

static Clay_BoundingBox AUITestBoundingBoxForIdentifier(id self, SEL _cmd, OFString *identifier)
{
    Clay_ElementData data = [AUIClay elementDataForID: [AUIClay elementIDFromString: identifier]];

    OTAssert(data.found, @"Missing element %@", identifier);
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

[[subclassing_restricted]]
@interface AsyncRuntimeUITests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeUITests

- (void)test_window_options_expose_content_scaling_configuration
{
    AUIWindowOptions *options = [AUIWindowOptions title: @"Scaled"
                                                   size: [AUI sizeWithWidth: 360 height: 240]
                                              resizable: true
                                autoResizeToRootComponent: false
                                     scaleWithWindowSize: true
                                            contentScale: 2.5];

    OTAssert(options.scalesWithWindowSize, @"AUIWindowOptions should retain whether content scales with window size");
    OTAssert((options.contentScale == 2.5), @"AUIWindowOptions should retain the requested content scale");
}

- (void)test_headless_window_content_scale_changes_viewport_and_pointer_space
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

    OTAssert(AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120]), @"contentScale should shrink the logical viewport while keeping the native window size");

    [window sendPointerMoveToX: 180 y: 120];
    OTAssert((application._inputState.pointerX == 90.0f and application._inputState.pointerY == 60.0f), @"headless pointer events should be mapped back into logical viewport coordinates");

    [window setNativeSize: [AUI sizeWithWidth: 720 height: 480]];
    OTAssert(AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 360 height: 240]), @"logical viewport should continue to track native size when scaleWithWindowSize is disabled");

    [window sendPointerMoveToX: 360 y: 240];
    OTAssert((application._inputState.pointerX == 180.0f and application._inputState.pointerY == 120.0f), @"pointer mapping should keep respecting contentScale after native resizes");

    [application _setWindowForTesting: nilptr];
    [window closeWindow];
}

- (void)test_headless_window_scale_with_window_size_keeps_reference_viewport
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

    OTAssert(AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120]), @"scaleWithWindowSize should establish a reference logical viewport at open time");

    [window setNativeSize: [AUI sizeWithWidth: 720 height: 480]];
    OTAssert(AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 180 height: 120]), @"scaleWithWindowSize should keep the logical viewport fixed across native resizes");

    [window sendPointerMoveToX: 360 y: 240];
    OTAssert((application._inputState.pointerX == 90.0f and application._inputState.pointerY == 60.0f), @"pointer mapping should use the fixed reference viewport when scaling with window size");

    [window setViewportSize: [AUI sizeWithWidth: 200 height: 100]];
    OTAssert(AUITestSizeEquals(window.viewportSize, [AUI sizeWithWidth: 200 height: 100]), @"setting the viewport explicitly should replace the reference viewport");

    [window sendPointerMoveToX: 200 y: 100];
    OTAssert((application._inputState.pointerX == 100.0f and application._inputState.pointerY == 50.0f), @"pointer mapping should follow the updated reference viewport after explicit viewport changes");

    [application _setWindowForTesting: nilptr];
    [window closeWindow];
}

- (void)test_hook_state_updates_request_render_only_on_change
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            AUITestStateComponent *component = [[AUITestStateComponent alloc] init];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
            Clay_RenderCommandArray commands;

            AUITestMountComponent(&harness, component, rootScope);
            commands = AUITestRenderMountedComponent(&harness);
            OTAssert(AUITestCommandsContainText(commands, @"alpha"), @"initial state should render");

            [[component stateBinding] setValue: @"alpha"];
            OTAssert((not [application _hasPendingRenderRequest]), @"writing the same state value should not request a render");

            [[component stateBinding] setValue: @"beta"];
            OTAssert([application _hasPendingRenderRequest], @"writing a different state value should request a render");

            commands = AUITestRenderMountedComponent(&harness);
            OTAssert(AUITestCommandsContainText(commands, @"beta"), @"updated state should render");
            AUITestUnmountComponent(&harness);
            AUITestRenderHarnessDestroy(&harness);
    }];
}

- (void)test_keyed_child_components_retain_state_across_reorder
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            AUITestLeafComponent *left = [[AUITestLeafComponent alloc] initWithName: @"left"];
            AUITestLeafComponent *right = [[AUITestLeafComponent alloc] initWithName: @"right"];
            AUITestReorderComponent *root = [[AUITestReorderComponent alloc] initWithLeft: left right: right];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
            Clay_RenderCommandArray commands;

            AUITestMountComponent(&harness, root, rootScope);
            (void)AUITestRenderMountedComponent(&harness);
            [[left stateBinding] setValue: @"preserved"];
            root.isReversed = true;
            [root setNeedsViewUpdate];

            commands = AUITestRenderMountedComponent(&harness);
            OTAssert(AUITestCommandsContainText(commands, @"preserved"), @"stable child keys should preserve child hook state through reorder");
            OTAssert((left.mountCount == 1 and right.mountCount == 1), @"stable child keys should retain mounted child instances");
            AUITestUnmountComponent(&harness);
            AUITestRenderHarnessDestroy(&harness);
    }];
}

- (void)test_editable_text_focus_persists_across_conditional_insertion
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            AUITestEditableFieldComponent *component = [[AUITestEditableFieldComponent alloc] init];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
            Clay_BoundingBox boundingBox;

            AUITestMountComponent(&harness, component, rootScope);
            (void)AUITestRenderMountedComponent(&harness);
            boundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:field-root/node:field");
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

            OTAssert([component.latestText isEqual: @"x"], @"focused editable nodes should keep focus when sibling structure changes but key stays stable");
            OTAssert([component.submittedText isEqual: @"x"], @"focused editable nodes should continue to submit after keyed reconciliation");
            AUITestUnmountComponent(&harness);
            AUITestRenderHarnessDestroy(&harness);
    }];
}

- (void)test_effect_cleanup_runs_on_dependency_change_and_unmount
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            AUITestEffectComponent *component = [[AUITestEffectComponent alloc] init];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);

            AUITestMountComponent(&harness, component, rootScope);
            (void)AUITestRenderMountedComponent(&harness);
            OTAssert((component.runCount == 1 and component.cleanupCount == 0), @"effect hooks should run after first commit");

            component.phase = 1;
            [component setNeedsViewUpdate];
            (void)AUITestRenderMountedComponent(&harness);
            OTAssert((component.runCount == 2 and component.cleanupCount == 1), @"effect hooks should clean up and rerun when dependencies change");

            AUITestUnmountComponent(&harness);
            OTAssert((component.cleanupCount == 2), @"effect hooks should clean up when the component unmounts");
            AUITestRenderHarnessDestroy(&harness);
    }];
}

- (void)test_context_menu_attachment_opens_and_activates
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            AUITestContextMenuComponent *component = [[AUITestContextMenuComponent alloc] init];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
            Clay_BoundingBox targetBoundingBox;
            Clay_BoundingBox menuItemBoundingBox;

            AUITestMountComponent(&harness, component, rootScope);
            (void)AUITestRenderMountedComponent(&harness);
            targetBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:menu-box");
            AUITestClickSecondary(&harness,
                                  targetBoundingBox.x + targetBoundingBox.width / 2.0f,
                                  targetBoundingBox.y + targetBoundingBox.height / 2.0f);
            (void)AUITestRenderMountedComponent(&harness);

            OTAssert(([application _activeContextMenuForTesting] != nilptr), @"context menu attachments should open a menu on secondary click");

            menuItemBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"__context_menu__/0");
            AUITestClickPrimary(&harness,
                                menuItemBoundingBox.x + menuItemBoundingBox.width / 2.0f,
                                menuItemBoundingBox.y + menuItemBoundingBox.height / 2.0f);
            (void)AUITestRenderMountedComponent(&harness);

            OTAssert(component.didSelect, @"context menu item activation should invoke the attached handler");
            OTAssert(([application _activeContextMenuForTesting] == nilptr), @"context menus should dismiss after activation");
            AUITestUnmountComponent(&harness);
            AUITestRenderHarnessDestroy(&harness);
    }];
}

- (void)test_calculator_keypad_clicks_refresh_shared_display_state
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AUITestApplication *application = [[AUITestApplication alloc] init];
            CalculatorRootComponent *component = [[CalculatorRootComponent alloc] init];
            AUITestRenderHarness harness = AUITestRenderHarnessMake(application);
            Clay_BoundingBox digitSevenBoundingBox;
            Clay_BoundingBox plusBoundingBox;
            Clay_BoundingBox digitEightBoundingBox;
            Clay_BoundingBox evaluateBoundingBox;
            Clay_RenderCommandArray commands;

            AUITestMountComponent(&harness, component, rootScope);
            (void)AUITestRenderMountedComponent(&harness);

            digitSevenBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-a/node:digit-7");
            plusBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-d/node:plus");
            digitEightBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:digits-row-a/node:digit-8");
            evaluateBoundingBox = AUITestBoundingBoxForIdentifier(self, _cmd, @"root/node:calculator-root/node:content-row/node:main-column/component:keypad/node:evaluate");

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

            OTAssert(AUITestCommandsContainText(commands, @"7+8"), @"calculator keypad clicks should update the shared expression display");

            AUITestClickPrimary(&harness,
                                evaluateBoundingBox.x + evaluateBoundingBox.width / 2.0f,
                                evaluateBoundingBox.y + evaluateBoundingBox.height / 2.0f);
            commands = AUITestRenderMountedComponent(&harness);

            OTAssert(AUITestCommandsContainText(commands, @"15"), @"calculator keypad clicks should drive evaluation results into the display");
            AUITestUnmountComponent(&harness);
            AUITestRenderHarnessDestroy(&harness);
    }];
}

@end
#pragma clang assume_nonnull end
