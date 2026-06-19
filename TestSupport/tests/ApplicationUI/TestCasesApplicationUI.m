#include <stdlib.h>
#include <string.h>

#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Immediate.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Advanced.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/KeyEvent.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/RenderContext+Private.h>
#import <AsyncRT/Application/UI/Window/Platform/Headless/Window.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Application+Private.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncUITestApplication : AsyncImmediateUIApplication @end

@implementation AsyncUITestApplication

- (id<AsyncUIContent>)rootContent
{
    return [AsyncUIGroup withChildren: [OFArray array]];
}

- (AsyncUIWindowConfiguration *nillable)windowConfiguration
{
    return AsyncUIWindowConfiguration.defaults;
}

@end

typedef struct AsyncUITestRenderHarness {
    AsyncUITestApplication *application;
    AsyncUIHeadlessWindow *window;
    Clay_Context *nillable context;
    void *nillable memory;
    size_t memorySize;
} AsyncUITestRenderHarness;

static Clay_Dimensions AsyncUITestMeasureText(Clay_StringSlice text,
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

static AsyncUITestRenderHarness AsyncUITestRenderHarnessMake(void)
{
    AsyncUITestRenderHarness harness = {0};
    auto configuration = AsyncUIWindowConfiguration.defaults;
    configuration.title = @"UI Test";
    configuration.initialSize = [AsyncUI sizeWithWidth: 360 height: 240];
    configuration.isResizable = false;
    configuration.automaticallyResizesToContent = false;
    configuration.scalesWithWindowSize = false;
    configuration.contentScale = 1;

    harness.application = [[AsyncUITestApplication alloc] init];
    harness.window = [[AsyncUIHeadlessWindow alloc] initWithApplication: harness.application configuration: configuration];
    [harness.window openWindow];
    [harness.application _setWindowForTesting: harness.window];

    harness.memorySize = AsyncUIClay.minimumMemorySize;
    harness.memory = malloc(harness.memorySize);
    harness.context = [AsyncUIClay initializeWithMemory: $assert_nonnil(harness.memory)
                                               size: harness.memorySize
                                         dimensions: harness.window.viewportSize];
    AsyncUIClay.currentContext = harness.context;
    Clay_SetMeasureTextFunction(AsyncUITestMeasureText, nilptr);
    return harness;
}

static void AsyncUITestRenderHarnessDestroy(AsyncUITestRenderHarness *harness)
{
    [harness->application _setRootContentForTesting: nilptr];
    [harness->application _setWindowForTesting: nilptr];
    [harness->window closeWindow];
    AsyncUIClay.currentContext = nullptr;
    free(harness->memory);
    harness->memory = nullptr;
    harness->context = nullptr;
}

static void AsyncUITestMountContent(AsyncUITestRenderHarness *harness, id<AsyncUIContent> nillable content)
{
    [harness->application _setRootContentForTesting: content];
}

static Clay_RenderCommandArray AsyncUITestRenderMountedContent(AsyncUITestRenderHarness *harness)
{
    Clay_RenderCommandArray commands = {0};

    for (size_t iteration = 0; iteration < 4; iteration++) {
        (void)[harness->application _consumePendingRenderRequest];
        AsyncUIClay.currentContext = harness->context;
        AsyncUIClay.layoutDimensions = harness->window.viewportSize;
        commands = [harness->application _buildRenderCommandsWithViewportSize: harness->window.viewportSize
                                                                    deltaTime: (1.0f / 60.0f)];

        if (not [harness->application _hasPendingRenderRequest])
            break;
    }

    return commands;
}

static OFString *AsyncUITestStringFromSlice(Clay_StringSlice slice)
{
    char *buffer = calloc((size_t)slice.length + 1, sizeof(char));
    OFString *string;

    memcpy(buffer, slice.chars, (size_t)slice.length);
    string = [[OFString alloc] initWithUTF8String: buffer];
    free(buffer);
    return string;
}

static bool AsyncUITestCommandsContainText(Clay_RenderCommandArray commands, OFString *expectedText)
{
    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

        if (command == nullptr or command->commandType != CLAY_RENDER_COMMAND_TYPE_TEXT)
            continue;
        if ([AsyncUITestStringFromSlice(command->renderData.text.stringContents) containsString: expectedText])
            return true;
    }

    return false;
}

static Clay_BoundingBox AsyncUITestBoundingBoxForIdentifier(OFString *identifier)
{
    Clay_ElementData data = [AsyncUIClay elementDataForID: [AsyncUIClay elementIDFromString: identifier]];

    if (not data.found)
        @throw [OFOutOfRangeException exception];
    return data.boundingBox;
}

static float AsyncUITestMidX(Clay_BoundingBox boundingBox)
{
    return boundingBox.x + (boundingBox.width / 2.0f);
}

static float AsyncUITestMidY(Clay_BoundingBox boundingBox)
{
    return boundingBox.y + (boundingBox.height / 2.0f);
}

static void AsyncUITestClickPrimary(AsyncUITestRenderHarness *harness, float x, float y)
{
    [harness->window sendPointerMoveToX: x y: y];
    [harness->window sendMouseDown: AsyncUIMouseButtonPrimary];
    [harness->window sendMouseUp: AsyncUIMouseButtonPrimary];
}

static void AsyncUITestClickSecondary(AsyncUITestRenderHarness *harness, float x, float y)
{
    [harness->window sendPointerMoveToX: x y: y];
    [harness->window sendMouseDown: AsyncUIMouseButtonSecondary];
    [harness->window sendMouseUp: AsyncUIMouseButtonSecondary];
}

[[subclassing_restricted]]
@interface AsyncUITestStateComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUIState<OFString *> *nillable textState;

@end

@implementation AsyncUITestStateComponent {
    AsyncUIState<OFString *> *nillable _textState;
}

- (AsyncUIState<OFString *> *nillable)textState
{
    return _textState;
}

- (id<AsyncUIContent>)renderContent
{
    _textState = [self useState: @"alpha"];
    return [AsyncUIText withString: (_textState.value ?: @"")
                       styledBy: AsyncUITextStyle.body];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestLeafComponent : AsyncUIComponent

@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) size_t mountCount;
@property(readonly, nonatomic) AsyncUIState<OFString *> *nillable textState;

- (instancetype)initWithName: (OFString *)name [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncUITestLeafComponent {
    OFString *_name;
    size_t _mountCount;
    AsyncUIState<OFString *> *nillable _textState;
}

- (instancetype)initWithName: (OFString *)name
{
    self = [super init];
    _name = [name copy];
    return self;
}

- (OFString *)name
{
    return _name;
}

- (size_t)mountCount
{
    return _mountCount;
}

- (AsyncUIState<OFString *> *nillable)textState
{
    return _textState;
}

- (void)componentDidMount
{
    _mountCount++;
}

- (id<AsyncUIContent>)renderContent
{
    _textState = [self useState: _name];
    return [AsyncUIText withString: (_textState.value ?: @"")
                       styledBy: AsyncUITextStyle.body];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestKeyedPairComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUITestLeafComponent *leftComponent;
@property(readonly, nonatomic) AsyncUITestLeafComponent *rightComponent;
@property(readonly, nonatomic) AsyncUIState<OFNumber *> *nillable reversedState;

@end

@implementation AsyncUITestKeyedPairComponent {
    AsyncUITestLeafComponent *_leftComponent;
    AsyncUITestLeafComponent *_rightComponent;
    AsyncUIState<OFNumber *> *nillable _reversedState;
}

- (instancetype)init
{
    self = [super init];
    _leftComponent = [[AsyncUITestLeafComponent alloc] initWithName: @"left"];
    _rightComponent = [[AsyncUITestLeafComponent alloc] initWithName: @"right"];
    return self;
}

- (AsyncUITestLeafComponent *)leftComponent
{
    return _leftComponent;
}

- (AsyncUITestLeafComponent *)rightComponent
{
    return _rightComponent;
}

- (AsyncUIState<OFNumber *> *nillable)reversedState
{
    return _reversedState;
}

- (id<AsyncUIContent>)renderContent
{
    _reversedState = [self useState: [OFNumber numberWithBool: false]];
    bool isReversed = (_reversedState.value != nilptr ? _reversedState.value.boolValue : false);
    OFArray<id<AsyncUIContent>> *children;

    if (isReversed) {
        children = [OFArray arrayWithObjects:
            [AsyncUIKeyedContent withKey: @"right" content: _rightComponent],
            [AsyncUIKeyedContent withKey: @"left" content: _leftComponent],
            nil];
    } else {
        children = [OFArray arrayWithObjects:
            [AsyncUIKeyedContent withKey: @"left" content: _leftComponent],
            [AsyncUIKeyedContent withKey: @"right" content: _rightComponent],
            nil];
    }

    return [AsyncUIGroup withChildren: children];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestEffectComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUIState<OFNumber *> *nillable phaseState;
@property(readonly, nonatomic) size_t effectRunCount;
@property(readonly, nonatomic) size_t cleanupCount;

@end

@implementation AsyncUITestEffectComponent {
    AsyncUIState<OFNumber *> *nillable _phaseState;
    size_t _effectRunCount;
    size_t _cleanupCount;
}

- (AsyncUIState<OFNumber *> *nillable)phaseState
{
    return _phaseState;
}

- (size_t)effectRunCount
{
    return _effectRunCount;
}

- (size_t)cleanupCount
{
    return _cleanupCount;
}

- (id<AsyncUIContent>)renderContent
{
    _phaseState = [self useState: [OFNumber numberWithUnsignedInt: 0]];
    [self useEffect: ^AsyncUIEffectCleanupHandler {
        _effectRunCount++;
        return ^{
            _cleanupCount++;
        };
    } dependencies: [OFArray arrayWithObject: (_phaseState.value ?: [OFNumber numberWithUnsignedInt: 0])]];

    return [AsyncUIText withString: [OFString stringWithFormat: @"phase:%@", (_phaseState.value ?: [OFNumber numberWithUnsignedInt: 0]).stringValue]
                       styledBy: AsyncUITextStyle.body];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestTaskComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUIState<OFString *> *nillable statusState;
@property(readonly, nonatomic) AsyncTaskGroup *nillable observedTaskGroup;

@end

@implementation AsyncUITestTaskComponent {
    AsyncUIState<OFString *> *nillable _statusState;
    AsyncTaskGroup *nillable _observedTaskGroup;
}

- (AsyncUIState<OFString *> *nillable)statusState
{
    return _statusState;
}

- (AsyncTaskGroup *nillable)observedTaskGroup
{
    return _observedTaskGroup;
}

- (id<AsyncUIContent>)renderContent
{
    _statusState = [self useState: @"waiting"];
    [self useTask: ^id(AsyncTaskGroup *taskGroup) {
        _observedTaskGroup = taskGroup;
        _statusState.value = @"ready";
        return AsyncUnit.unit;
    } dependencies: [OFArray array] name: @"ui.test.use-task"];

    return [AsyncUIText withString: (_statusState.value ?: @"")
                       styledBy: AsyncUITextStyle.body];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestTextFieldComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUIState<OFString *> *nillable textState;

@end

@implementation AsyncUITestTextFieldComponent {
    AsyncUIState<OFString *> *nillable _textState;
}

- (AsyncUIState<OFString *> *nillable)textState
{
    return _textState;
}

- (id<AsyncUIContent>)renderContent
{
    _textState = [self useState: @""];
    return [AsyncUITextField withText: _textState.value
                       placeholder: @"Type"
                         styledBy: AsyncUIControlStyle.textField
                       contextMenu: nilptr
                         onChange: ^(OFString *text) {
        _textState.value = text;
    }
                         onSubmit: nilptr
                          enabled: true
                           secure: false];
}

@end

[[subclassing_restricted]]
@interface AsyncUITestContextMenuComponent : AsyncUIComponent

@property(readonly, nonatomic) AsyncUIState<OFString *> *nillable selectionState;
@property(readonly, nonatomic) AsyncTaskGroup *nillable actionTaskGroup;

@end

@implementation AsyncUITestContextMenuComponent {
    AsyncUIState<OFString *> *nillable _selectionState;
    AsyncTaskGroup *nillable _actionTaskGroup;
}

- (AsyncUIState<OFString *> *nillable)selectionState
{
    return _selectionState;
}

- (AsyncTaskGroup *nillable)actionTaskGroup
{
    return _actionTaskGroup;
}

- (id<AsyncUIContent>)renderContent
{
    _selectionState = [self useState: @"Idle"];

    auto interaction = AsyncUIInteraction.enabled;
    interaction.contextMenu = [AsyncUIContextMenu withItems: [OFArray arrayWithObject:
        [AsyncUIContextMenuItem withTitle: @"Select Item"
                         onPressAsync: ^id(AsyncTaskGroup *taskGroup) {
            _actionTaskGroup = taskGroup;
            _selectionState.value = @"Selected";
            return AsyncUnit.unit;
        }
                                named: @"ui.test.context-menu"
                              enabled: true]
    ]];

    auto layout = AsyncUIStackLayout.vertical;
    layout.width = [AsyncUIAxisSize fixed: 180];
    layout.height = [AsyncUIAxisSize fixed: 48];
    layout.padding = [AsyncUIEdgeInsets all: 10];

    return [AsyncUIBox withLayout: layout
                     styledBy: AsyncUIBoxStyle.filled
                  interaction: interaction
                     children: [OFArray arrayWithObject:
        [AsyncUIText withString: (_selectionState.value ?: @"")
                    styledBy: AsyncUITextStyle.body]
    ]];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeUITests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeUITests

- (void)test_component_state_invalidates_and_rerenders
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestStateComponent alloc] init];
        Clay_RenderCommandArray commands;

        @try {
            AsyncUITestMountContent(&harness, component);
            commands = AsyncUITestRenderMountedContent(&harness);
            OTAssert((AsyncUITestCommandsContainText(commands, @"alpha")), @"State components should render their initial state");

            component.textState.value = @"beta";
            OTAssert(([harness.application _hasPendingRenderRequest]), @"State updates should request another render");

            commands = AsyncUITestRenderMountedContent(&harness);
            OTAssert((AsyncUITestCommandsContainText(commands, @"beta")), @"State updates should re-render with the new value");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_keyed_content_preserves_child_state_across_reorder
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestKeyedPairComponent alloc] init];
        Clay_RenderCommandArray commands;

        @try {
            AsyncUITestMountContent(&harness, component);
            (void)AsyncUITestRenderMountedContent(&harness);

            component.leftComponent.textState.value = @"kept-left";
            component.reversedState.value = [OFNumber numberWithBool: true];
            commands = AsyncUITestRenderMountedContent(&harness);

            OTAssert((AsyncUITestCommandsContainText(commands, @"kept-left")), @"Keyed content should preserve child state after reorder");
            OTAssert((component.leftComponent.mountCount == 1), @"Reordered keyed children should keep their existing mount");
            OTAssert((component.rightComponent.mountCount == 1), @"Sibling keyed children should not remount during reorder");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_effect_cleanup_runs_on_dependency_change_and_unmount
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestEffectComponent alloc] init];

        @try {
            AsyncUITestMountContent(&harness, component);
            (void)AsyncUITestRenderMountedContent(&harness);
            OTAssert((component.effectRunCount == 1), @"Effects should commit after the initial render");
            OTAssert((component.cleanupCount == 0), @"Initial effect commit should not run cleanup first");

            component.phaseState.value = [OFNumber numberWithUnsignedInt: 1];
            (void)AsyncUITestRenderMountedContent(&harness);
            OTAssert((component.effectRunCount == 2), @"Dependency changes should re-run effects");
            OTAssert((component.cleanupCount == 1), @"Dependency changes should run the previous cleanup");

            AsyncUITestMountContent(&harness, nilptr);
            OTAssert((component.cleanupCount == 2), @"Unmount should run the last effect cleanup");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_use_task_runs_inside_a_child_task_group
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestTaskComponent alloc] init];
        Clay_RenderCommandArray commands;

        @try {
            AsyncUITestMountContent(&harness, component);
            (void)AsyncUITestRenderMountedContent(&harness);
            [[rootTaskGroup.scheduler sleepForTimeInterval: 0.01] await];
            commands = AsyncUITestRenderMountedContent(&harness);

            OTAssert((component.observedTaskGroup != nilptr), @"useTask should receive a mounted child task group");
            OTAssert((component.observedTaskGroup.parentTaskGroup == rootTaskGroup), @"useTask child groups should inherit from the mounted Async task group");
            OTAssert((AsyncUITestCommandsContainText(commands, @"ready")), @"Completed tasks should be able to update component state");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_text_field_retains_focus_while_editing
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestTextFieldComponent alloc] init];
        Clay_RenderCommandArray commands;

        @try {
            AsyncUITestMountContent(&harness, component);
            (void)AsyncUITestRenderMountedContent(&harness);

            Clay_BoundingBox fieldBounds = AsyncUITestBoundingBoxForIdentifier(@"root");
            AsyncUITestClickPrimary(&harness, AsyncUITestMidX(fieldBounds), AsyncUITestMidY(fieldBounds));
            (void)AsyncUITestRenderMountedContent(&harness);
            OTAssert(([harness.application.runtime.interactionEngine isIdentifierFocused: @"root"]), @"Clicking a text field should focus it");

            [harness.window sendText: @"hello"];
            commands = AsyncUITestRenderMountedContent(&harness);

            OTAssert(([$assert_nonnil(component.textState.value) isEqual: @"hello"]), @"Text field edits should flow back through onChange");
            OTAssert(([harness.application.runtime.interactionEngine isIdentifierFocused: @"root"]), @"Focused text fields should remain focused after editing");
            OTAssert((AsyncUITestCommandsContainText(commands, @"hello")), @"Edited text should be visible in the rendered output");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_context_menu_activation_and_async_item_actions
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
        auto component = [[AsyncUITestContextMenuComponent alloc] init];
        Clay_RenderCommandArray commands;

        @try {
            AsyncUITestMountContent(&harness, component);
            (void)AsyncUITestRenderMountedContent(&harness);

            Clay_BoundingBox rootBounds = AsyncUITestBoundingBoxForIdentifier(@"root");
            AsyncUITestClickSecondary(&harness, AsyncUITestMidX(rootBounds), AsyncUITestMidY(rootBounds));
            commands = AsyncUITestRenderMountedContent(&harness);

            OTAssert((harness.application._activeContextMenuForTesting != nilptr), @"Secondary click should activate the nearest context menu");
            OTAssert((AsyncUITestCommandsContainText(commands, @"Select Item")), @"Active context menus should render their items");

            Clay_BoundingBox itemBounds = AsyncUITestBoundingBoxForIdentifier(@"context-menu/0");
            AsyncUITestClickPrimary(&harness, AsyncUITestMidX(itemBounds), AsyncUITestMidY(itemBounds));
            (void)AsyncUITestRenderMountedContent(&harness);
            [[rootTaskGroup.scheduler sleepForTimeInterval: 0.01] await];
            commands = AsyncUITestRenderMountedContent(&harness);

            OTAssert((component.actionTaskGroup != nilptr), @"Context-menu actions should run inside an Async child task group");
            OTAssert((component.actionTaskGroup.parentTaskGroup == rootTaskGroup), @"Menu-item task groups should inherit from the mounted Async task group");
            OTAssert(([$assert_nonnil(component.selectionState.value) isEqual: @"Selected"]), @"Async menu-item actions should update component state");
            OTAssert((harness.application._activeContextMenuForTesting == nilptr), @"Activating a context-menu item should dismiss the active menu");
            OTAssert((AsyncUITestCommandsContainText(commands, @"Selected")), @"Updated menu action state should be visible after re-render");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_button_and_context_menu_item_selectors_and_state
{
    auto buttonStyle = AsyncUIControlStyle.button;
    auto buttonSyncAction = [AsyncUIAction withHandler: ^{
    }];
    auto buttonAsyncAction = [AsyncUIAction withName: @"ui.test.button"
                                    asyncHandler: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return AsyncUnit.unit;
    }];
    auto button = [AsyncUIButton withTitle: @"Launch"
                              styledBy: buttonStyle
                               onPress: ^ {
        buttonSyncAction.handler();
    }
                              enabled: false];
    auto asyncButton = [AsyncUIButton withTitle: @"Async Launch"
                                   styledBy: buttonStyle
                               onPressAsync: ^id(AsyncTaskGroup *taskGroup) {
        return buttonAsyncAction.asyncHandler(taskGroup);
    }
                                      named: @"ui.test.button"
                                    enabled: true];
    auto defaultAsyncButton = [AsyncUIButton withTitle: @"Async Default"
                                          styledBy: buttonStyle
                                      onPressAsync: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return AsyncUnit.unit;
    }];
    auto syncMenuItem = [AsyncUIContextMenuItem withTitle: @"Select"
                                              onPress: ^{
    }];
    auto disabledMenuItem = [AsyncUIContextMenuItem withTitle: @"Disabled"
                                                  onPress: nilptr
                                                  enabled: false];
    auto asyncMenuItem = [AsyncUIContextMenuItem withTitle: @"Async Select"
                                           onPressAsync: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return AsyncUnit.unit;
    }
                                                  named: @"ui.test.menu-item"
                                                enabled: true];
    block_reference bool invokedButtonHandler = false;

    buttonSyncAction.handler = ^{
        invokedButtonHandler = true;
    };

    OTAssert((button.contentKind == AsyncUIContentKindButton), @"Buttons should report their content kind");
    OTAssert(([button.title isEqual: @"Launch"]), @"Buttons should preserve their title");
    OTAssert((button.style == buttonStyle), @"Buttons should retain their configured style");
    OTAssert((button.action != nilptr), @"Buttons should create an action wrapper for synchronous handlers");
    OTAssert((not button.isEnabled), @"Buttons should preserve explicit enabled state");

    [button.action invokeWithTaskGroup: nilptr];
    OTAssert((invokedButtonHandler), @"Button actions should invoke the configured handler");

    OTAssert((asyncButton.contentKind == AsyncUIContentKindButton), @"Async buttons should report the same content kind");
    OTAssert((asyncButton.action != nilptr), @"Async buttons should create an action wrapper");
    OTAssert((asyncButton.action.asyncHandler != nilptr), @"Async button actions should preserve their async handler");
    OTAssert((asyncButton.isEnabled), @"Async button constructors should preserve their enabled state");

    OTAssert((defaultAsyncButton.action != nilptr), @"Async button convenience initializers should create an action wrapper");
    OTAssert((defaultAsyncButton.action.asyncHandler != nilptr), @"Async button convenience initializers should preserve their async handler");
    OTAssert((defaultAsyncButton.action.name == nilptr), @"Unnamed async button convenience initializers should not invent a name");
    OTAssert((defaultAsyncButton.isEnabled), @"Async button convenience initializers should default to enabled");

    OTAssert(([syncMenuItem.title isEqual: @"Select"]), @"Context menu items should preserve their title");
    OTAssert((syncMenuItem.isEnabled), @"Context menu items should default to enabled");
    OTAssert((syncMenuItem.action != nilptr), @"Context menu items should create an action wrapper for synchronous handlers");

    OTAssert(([disabledMenuItem.title isEqual: @"Disabled"]), @"Context menu items should preserve disabled titles");
    OTAssert((not disabledMenuItem.isEnabled), @"Context menu items should preserve explicit disabled state");
    OTAssert((disabledMenuItem.action != nilptr), @"Disabled context menu items should still retain their action wrapper");

    OTAssert(([asyncMenuItem.title isEqual: @"Async Select"]), @"Async context menu items should preserve their title");
    OTAssert((asyncMenuItem.isEnabled), @"Async context menu items should default to enabled");
    OTAssert((asyncMenuItem.action != nilptr), @"Async context menu items should create an action wrapper");
    OTAssert((asyncMenuItem.action.asyncHandler != nilptr), @"Async context menu items should preserve their async handler");
    OTAssert(([asyncMenuItem.action.name isEqual: @"ui.test.menu-item"]), @"Async context menu items should preserve their selector name");
}

- (void)test_stack_layout_and_stack_value_semantics
{
    auto layout = AsyncUIStackLayout.vertical;
    auto horizontalLayout = AsyncUIStackLayout.horizontal;
    auto width = [AsyncUIAxisSize fixed: 120];
    auto height = [AsyncUIAxisSize percent: 0.5f];
    auto padding = [AsyncUIEdgeInsets withLeft: 1 right: 2 top: 3 bottom: 4];
    auto childOne = [AsyncUIText withString: @"one" styledBy: AsyncUITextStyle.body];
    auto childTwo = [AsyncUIText withString: @"two" styledBy: AsyncUITextStyle.label];
    auto mutableChildren = [OFMutableArray arrayWithObjects: childOne, childTwo, nilptr];
    auto stack = [AsyncUIStack withLayout: layout children: mutableChildren];

    [layout sizedWidth: width height: height];
    [layout padded: padding];
    [layout spaced: 7];
    [layout alignedHorizontally: AsyncUIContentAlignmentCenter vertical: AsyncUIContentAlignmentEnd];
    [layout scrolling: AsyncUIScrollBehaviorBoth];

    OTAssert((layout.direction == AsyncUIStackDirectionVertical), @"Vertical layouts should default to column direction");
    OTAssert((horizontalLayout.direction == AsyncUIStackDirectionHorizontal), @"Horizontal layouts should default to row direction");
    OTAssert((layout.width == width), @"Stack layouts should retain the configured width axis");
    OTAssert((layout.height == height), @"Stack layouts should retain the configured height axis");
    OTAssert((layout.padding == padding), @"Stack layouts should retain the configured padding");
    OTAssert((layout.spacing == 7), @"Stack layouts should retain spacing");
    OTAssert((layout.horizontalAlignment == AsyncUIContentAlignmentCenter and layout.verticalAlignment == AsyncUIContentAlignmentEnd),
             @"Stack layouts should retain alignment");
    OTAssert((layout.scrollBehavior == AsyncUIScrollBehaviorBoth), @"Stack layouts should retain scroll behavior");

    OTAssert((stack.contentKind == AsyncUIContentKindStack), @"Stacks should report their content kind");
    OTAssert((stack.layout == layout), @"Stacks should retain their layout object");
    OTAssert((stack.children.count == 2), @"Stacks should copy their children");

    [mutableChildren removeLastObject];
    OTAssert((stack.children.count == 2), @"Stacks should not track later mutations to the source array");
}

- (void)test_text_style_defaults_and_chaining
{
    auto body = AsyncUITextStyle.body;
    auto label = AsyncUITextStyle.label;
    auto accent = [AsyncUIColorValue withRed: 1 green: 2 blue: 3 alpha: 4];
    auto custom = AsyncUITextStyle.body;

    [custom alignedTo: AsyncUITextHorizontalAlignmentCenter];
    [custom fontSize: 18 lineHeight: 22];
    [custom colored: accent];

    [custom wrapped: AsyncUITextWrapStyleNewlines];

    OTAssert((body.fontID == 0 and body.fontSize == 16 and body.letterSpacing == 0 and body.lineHeight == 20),
             @"Body text styles should use the standard body metrics");
    OTAssert((body.color.red == 0 and body.color.green == 0 and body.color.blue == 0 and body.color.alpha == 255
              and body.wrapStyle == AsyncUITextWrapStyleWords and body.alignment == AsyncUITextHorizontalAlignmentLeading),
             @"Body text styles should use the standard body styling");
    OTAssert((label.fontSize == 14 and label.lineHeight == 18),
             @"Label text styles should use the compact label metrics");
    OTAssert((label.color.red == 82 and label.color.green == 82 and label.color.blue == 82 and label.color.alpha == 255),
             @"Label text styles should use the gray label color");
    OTAssert((custom.alignment == AsyncUITextHorizontalAlignmentCenter and custom.fontSize == 18 and custom.lineHeight == 22),
             @"Text style chainers should update alignment and size together");
    OTAssert((custom.color == accent and custom.wrapStyle == AsyncUITextWrapStyleNewlines),
             @"Text style chainers should retain the selected color and wrap style");
}

- (void)test_interaction_defaults_and_handlers
{
    block_reference bool synchronousActivationInvoked = false;
    block_reference bool synchronousEnabledInvoked = false;
    auto defaultInteraction = AsyncUIInteraction.enabled;
    auto activationInteraction = [AsyncUIInteraction withActivation: ^{
        synchronousActivationInvoked = true;
    }];
    auto asyncInteraction = [AsyncUIInteraction withAsyncActivation: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return AsyncUnit.unit;
    } named: @"ui.test.interaction"];
    auto enabledInteraction = [AsyncUIInteraction enabled];

    enabledInteraction.activationAction = [AsyncUIAction withHandler: ^{
        synchronousEnabledInvoked = true;
    }];
    [enabledInteraction.activationAction invokeWithTaskGroup: nilptr];

    OTAssert((defaultInteraction.isEnabled), @"Enabled interactions should default to enabled");
    OTAssert((not defaultInteraction.isFocusable), @"Enabled interactions should default to non-focusable");
    OTAssert((defaultInteraction.cursorStyle == AsyncUICursorStyleDefault), @"Enabled interactions should default to the standard cursor");
    OTAssert((defaultInteraction.feedbackColors == nilptr and defaultInteraction.activationAction == nilptr and defaultInteraction.contextMenu == nilptr),
             @"Enabled interactions should start empty");

    OTAssert((activationInteraction.activationAction != nilptr), @"Activation helpers should attach an action");
    OTAssert((activationInteraction.cursorStyle == AsyncUICursorStylePointer), @"Activation helpers should switch to the pointer cursor");
    [activationInteraction.activationAction invokeWithTaskGroup: nilptr];
    OTAssert((synchronousActivationInvoked), @"Activation handlers should be invokable");

    OTAssert((asyncInteraction.activationAction != nilptr), @"Async activation helpers should attach an action");
    OTAssert((asyncInteraction.activationAction.asyncHandler != nilptr), @"Async activation helpers should preserve the async handler");
    OTAssert(([asyncInteraction.activationAction.name isEqual: @"ui.test.interaction"]), @"Async activation helpers should preserve the action name");
    OTAssert((asyncInteraction.cursorStyle == AsyncUICursorStylePointer), @"Async activation helpers should also use the pointer cursor");
    OTAssert((synchronousEnabledInvoked), @"Actions created from enabled interactions should still invoke");
}

- (void)test_key_event_records_key_and_modifier_state
{
    auto keyEvent = [AsyncUIKeyEvent key: AsyncUIKeyA
                           modifiers: AsyncUIModifierFlagShift | AsyncUIModifierFlagCommand
                              repeat: true];

    OTAssert((keyEvent.key == AsyncUIKeyA), @"Key events should preserve the key code");
    OTAssert((keyEvent.modifiers == (AsyncUIModifierFlagShift | AsyncUIModifierFlagCommand)),
             @"Key events should preserve modifier flags");
    OTAssert((keyEvent.isRepeat), @"Key events should preserve repeat state");
}

- (void)test_render_context_current_context_stack
{
    AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();
    auto contextDate = [OFDate date];
    auto firstContext = [[AsyncUIRenderContext alloc] initWithApplication: harness.application
                                                              window: harness.window
                                                        viewportSize: harness.window.viewportSize
                                                           frameDate: contextDate
                                                         elapsedTime: 0.25];
    auto secondContext = [[AsyncUIRenderContext alloc] initWithApplication: harness.application
                                                               window: harness.window
                                                         viewportSize: harness.window.viewportSize
                                                            frameDate: contextDate
                                                          elapsedTime: 0.5];

    @try {
        OTAssert(([AsyncUIRenderContext currentContext] == nilptr), @"Render context should start empty");

        [AsyncUIRenderContext _pushCurrentContext: firstContext];
        OTAssert(([AsyncUIRenderContext currentContext] == firstContext), @"Pushing a render context should make it current");

        [AsyncUIRenderContext _pushCurrentContext: secondContext];
        OTAssert(([AsyncUIRenderContext currentContext] == secondContext), @"Pushing a second render context should update the current context");

        [AsyncUIRenderContext _popCurrentContext];
        OTAssert(([AsyncUIRenderContext currentContext] == firstContext), @"Popping should restore the previous render context");

        [AsyncUIRenderContext _popCurrentContext];
        OTAssert(([AsyncUIRenderContext currentContext] == nilptr), @"Popping the final render context should clear the stack");

        OTAssert((firstContext.application == harness.application and firstContext.window == harness.window),
                 @"Render contexts should retain their application and window");
        OTAssert((firstContext.viewportSize.width == harness.window.viewportSize.width and firstContext.viewportSize.height == harness.window.viewportSize.height),
                 @"Render contexts should preserve viewport dimensions");
        OTAssert(([firstContext.frameDate isEqual: contextDate]), @"Render contexts should copy the frame date");
        OTAssert((firstContext.elapsedTime == 0.25), @"Render contexts should preserve elapsed time");
    } @finally {
        while ([AsyncUIRenderContext currentContext] != nilptr)
            [AsyncUIRenderContext _popCurrentContext];
        AsyncUITestRenderHarnessDestroy(&harness);
    }
}

- (void)test_action_async_handler_falls_back_to_current_task_group
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        block_reference bool invokedSyncHandler = false;
        block_reference AsyncTaskGroup *nillable observedTaskGroup = nilptr;
        auto action = [AsyncUIAction withName: @"ui.test.standalone-action"
                             asyncHandler: ^id(AsyncTaskGroup *taskGroup) {
            observedTaskGroup = taskGroup;
            return AsyncUnit.unit;
        }];

        action.handler = ^{
            invokedSyncHandler = true;
        };

        [action invokeWithTaskGroup: nilptr];
        [[rootTaskGroup.scheduler sleepForTimeInterval: 0.01] await];

        OTAssert((invokedSyncHandler), @"Actions should still run their synchronous handler when no explicit task group is provided");
        OTAssert((observedTaskGroup != nilptr), @"Async actions should fall back to AsyncTaskGroup.currentTaskGroup when invoked without an explicit group");
        OTAssert((observedTaskGroup.parentTaskGroup == rootTaskGroup), @"Fallback async actions should spawn child task groups under the current Async task group");
    }];
}

- (void)test_window_configuration_defaults_and_convenience_initialiser
{
    auto defaults = AsyncUIWindowConfiguration.defaults;
    auto customConfiguration = [AsyncUIWindowConfiguration withTitle: @"Sample" width: 640 height: 480];
    auto richConfiguration = [AsyncUIWindowConfiguration withTitle: @"Rich"
                                                          size: [AsyncUI sizeWithWidth: 800 height: 600]
                                                     resizable: false
                                  automaticallyResizesToContent: false
                                       scalesWithWindowSize: true
                                               contentScale: 2.0];
    bool caughtInvalidContentScale = false;

    OTAssert(([defaults.title isEqual: @"AsyncRT UI"]), @"Default window configuration should provide a stable title");
    OTAssert((defaults.initialWidth == 960 and defaults.initialHeight == 640),
             @"Default window configuration should expose the standard initial viewport");
    OTAssert((defaults.initialSize.width == 960 and defaults.initialSize.height == 640),
             @"Default window configuration should expose a unified initialSize");
    OTAssert((defaults.automaticallyResizesToContent), @"Default window configuration should auto-size to root content");
    OTAssert(([customConfiguration.title isEqual: @"Sample"]), @"Custom window configuration should preserve its title");
    OTAssert((customConfiguration.initialWidth == 640 and customConfiguration.initialHeight == 480),
             @"Custom window configuration should preserve its initial size");
    OTAssert(([richConfiguration.title isEqual: @"Rich"]), @"Rich window configuration should preserve its title");
    OTAssert((richConfiguration.initialWidth == 800 and richConfiguration.initialHeight == 600),
             @"Size-based window initializers should preserve their size");
    OTAssert((not richConfiguration.isResizable and not richConfiguration.automaticallyResizesToContent and richConfiguration.scalesWithWindowSize),
             @"Rich window configuration should preserve its option flags");
    OTAssert((richConfiguration.contentScale == 2.0), @"Rich window configuration should preserve content scale");

    customConfiguration.initialSize = [AsyncUI sizeWithWidth: 320 height: 240];
    OTAssert((customConfiguration.initialWidth == 320 and customConfiguration.initialHeight == 240),
             @"Setting initialSize should update width and height together");

    @try {
        customConfiguration.contentScale = 0.0;
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
        caughtInvalidContentScale = true;
    }

    OTAssert((caughtInvalidContentScale), @"Window configurations should reject invalid content scales");
}

@end

#pragma clang assume_nonnull end
