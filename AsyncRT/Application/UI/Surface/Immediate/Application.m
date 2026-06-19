#import <AsyncRT/Application/UI/Surface/Immediate/Application.h>

#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>
#import <AsyncRT/Application/UI/Window/Windowing.h>
#import <AsyncRT/Application/UI/Window/Platform/Headless/Window.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Application+Private.h>

#if AsyncUI_HAS_COCOA_WINDOW
#   import <AsyncRT/Application/UI/Window/Platform/Cocoa/Window.h>
#endif

#if AsyncUI_HAS_X11_WINDOW
#   import <AsyncRT/Application/UI/Window/Platform/X11/Window.h>
#endif

#pragma clang assume_nonnull begin

@implementation AsyncImmediateUIApplication {
    AsyncUIRuntime *_runtime;
}

- (instancetype)init
{
    self = [super init];
    _runtime = [[AsyncUIRuntime alloc] initWithApplication: self];
    return self;
}

- (AsyncUIRuntime *)runtime
{
    return _runtime;
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;

    id<AsyncUIContent> nillable rootContent = [self rootContent];
    if (rootContent == nilptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Applications must return nonnil root content"];

    AsyncUIWindowConfiguration *nillable configuration = [self windowConfiguration];
    if (configuration == nilptr)
        configuration = AsyncUIWindowConfiguration.defaults;

    AsyncUIWindow *window = [self _makeWindowWithConfiguration: $assert_nonnil(configuration)];
    if (window == nilptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create a window for the application"];

    [self applicationDidStartWithTaskGroup: taskGroup];

    return [_runtime runWithWindow: window rootContent: $assert_nonnil(rootContent) taskGroup: taskGroup];
}

- (id<AsyncUIContent>)rootContent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AsyncUIWindowConfiguration *nillable)windowConfiguration
{
    return AsyncUIWindowConfiguration.defaults;
}

- (void)applicationDidStartWithTaskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)taskGroup;
}

- (void)setNeedsRender
{
    [_runtime setNeedsRender];
}

- (AsyncUIInputState *)_inputState
{
    return _runtime.inputState;
}

- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                       deltaTime: (float)deltaTime
{
    return [_runtime buildRenderCommandsWithViewportSize: viewportSize deltaTime: deltaTime];
}

- (bool)_updateHoverStateFromCurrentLayout
{
    return [_runtime updateHoverStateFromCurrentLayout];
}

- (bool)_consumePendingRenderRequest
{
    return [_runtime consumePendingRenderRequest];
}

- (bool)_hasPendingRenderRequest
{
    return [_runtime hasPendingRenderRequest];
}

- (AsyncUIContextMenu *nillable)_activeContextMenuForTesting
{
    return _runtime.interactionEngine.activeContextMenu;
}

- (void)_setWindowForTesting: (AsyncUIWindow *nillable)window
{
    [_runtime useWindowForTesting: window];
}

- (void)_setRootContentForTesting: (id<AsyncUIContent> nillable)rootContent
{
    [_runtime useRootContentForTesting: rootContent];
}

- (AsyncUIWindow *)_makeWindowWithConfiguration: (AsyncUIWindowConfiguration *)configuration
{
#if AsyncUI_HAS_COCOA_WINDOW
    return [[AsyncUICocoaWindow alloc] initWithApplication: self configuration: configuration];
#elif AsyncUI_HAS_X11_WINDOW
    return [[AsyncUIX11Window alloc] initWithApplication: self configuration: configuration];
#else
    return [[AsyncUIHeadlessWindow alloc] initWithApplication: self configuration: configuration];
#endif
}

@end

#pragma clang assume_nonnull end
