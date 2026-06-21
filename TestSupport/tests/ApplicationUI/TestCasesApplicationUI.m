#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Immediate.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeUITests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeUITests

- (void)test_window_configuration_defaults_and_copy
{
    auto configuration = [AsyncUIWindowConfiguration defaults];
    configuration.title = @"Test Window";
    configuration.initialWidth = 320;
    configuration.initialHeight = 240;
    configuration.isResizable = false;
    configuration.automaticallyResizesToContent = false;
    configuration.scalesWithWindowSize = true;
    configuration.contentScale = 2.0;

    AsyncUIWindowConfiguration *copy = [configuration copy];

    OTAssert(([copy.title isEqual: @"Test Window"]), @"Window configuration copies should keep titles");
    OTAssert((copy.initialWidth == 320 and copy.initialHeight == 240), @"Window configuration copies should keep sizes");
    OTAssertFalse(copy.isResizable, @"Window configuration copies should keep resize flags");
    OTAssertFalse(copy.automaticallyResizesToContent, @"Window configuration copies should keep content resize flags");
    OTAssert(copy.scalesWithWindowSize, @"Window configuration copies should keep scale flags");
    OTAssert((copy.contentScale == 2.0), @"Window configuration copies should keep content scale");
}

- (void)test_window_configuration_rejects_invalid_content_scale
{
    auto configuration = [AsyncUIWindowConfiguration defaults];
    bool caught = false;

    @try {
        configuration.contentScale = 0.0;
    } @catch (OFInvalidArgumentException *) {
        caught = true;
    }

    OTAssert(caught, @"Window configurations should reject invalid content scales");
}

- (void)test_sync_and_async_actions_invoke_without_task_groups
{
    [self runAsyncBlock: ^{
        block_reference bool syncRan = false;
        block_reference bool asyncRan = false;

        auto syncAction = [AsyncUIAction withHandler: ^{
            syncRan = true;
        }];
        auto asyncAction = [AsyncUIAction withName: @"ui-action" asyncHandler: ^id {
            asyncRan = ([AsyncTask currentTask].scheduler == [AsyncScheduler sharedScheduler]);
            return AsyncUnit.unit;
        }];

        [syncAction invoke];
        [asyncAction invoke];
        (void)[[AsyncRuntime sleepForTimeInterval: 0.01] await];

        OTAssert(syncRan, @"Synchronous actions should run immediately");
        OTAssert(asyncRan, @"Async actions should run on the managed scheduler");
    }];
}

- (void)test_button_async_action_wiring
{
    [self runAsyncBlock: ^{
        block_reference bool ran = false;
        auto button = [AsyncUIButton withTitle: @"Run"
                                      styledBy: [AsyncUIControlStyle button]
                                  onPressAsync: ^id {
            ran = true;
            return AsyncUnit.unit;
        }
                                         named: @"button-action"
                                       enabled: true];

        OTAssert(([button.title isEqual: @"Run"]), @"Buttons should preserve titles");
        OTAssert(button.isEnabled, @"Buttons should preserve enabled state");
        OTAssert((button.action != nilptr), @"Buttons with async handlers should create actions");

        [$assert_nonnil(button.action) invoke];
        (void)[[AsyncRuntime sleepForTimeInterval: 0.01] await];

        OTAssert(ran, @"Button async actions should be invokable");
    }];
}

- (void)test_interaction_activation_actions_use_current_action_api
{
    [self runAsyncBlock: ^{
        block_reference bool syncRan = false;
        block_reference bool asyncRan = false;
        auto syncInteraction = [AsyncUIInteraction withActivation: ^{
            syncRan = true;
        }];
        auto asyncInteraction = [AsyncUIInteraction withAsyncActivation: ^id {
            asyncRan = true;
            return AsyncUnit.unit;
        } named: @"interaction-action"];

        OTAssert(syncInteraction.isEnabled, @"Interactions should be enabled by default");
        OTAssert((syncInteraction.cursorStyle == AsyncUICursorStylePointer), @"Activation interactions should use pointer cursors");
        [$assert_nonnil(syncInteraction.activationAction) invoke];
        [$assert_nonnil(asyncInteraction.activationAction) invoke];
        (void)[[AsyncRuntime sleepForTimeInterval: 0.01] await];

        OTAssert(syncRan, @"Sync interaction actions should run");
        OTAssert(asyncRan, @"Async interaction actions should run");
    }];
}

@end

#pragma clang assume_nonnull end
