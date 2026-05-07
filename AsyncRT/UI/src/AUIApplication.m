#import "AUIApplication.h"

#import "AUIExceptions.h"
#import "Backend/AUIBackend.h"
#import "Backend/Window/AUIHeadlessWindow.h"
#import "Internal/AUIApplication+Private.h"

#if AUI_HAS_CORE_GRAPHICS_WINDOW
#   import "Backend/Window/AUICoreGraphicsWindow.h"
#endif

#if AUI_HAS_CAIRO_X11_WINDOW
#   import "Backend/Window/AUICairoX11Window.h"
#endif

#pragma clang assume_nonnull begin

@implementation AUIApplication {
    AUIRuntime *_runtime;
}

- (instancetype)init
{
    self = [super init];
    _runtime = [[AUIRuntime alloc] initWithApplication: self];
    return self;
}

- (AUIRuntime *)runtime
{
    return _runtime;
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;

    id<AUIContent> nillable rootContent = [self rootContent];
    if (rootContent == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Applications must return nonnil root content"];

    AUIWindowConfiguration *nillable configuration = [self windowConfiguration];
    if (configuration == nilptr)
        configuration = AUIWindowConfiguration.defaults;

    AUIWindow *window = [self _makeWindowWithConfiguration: $assert_nonnil(configuration)];
    if (window == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create a window for the application"];

    [self applicationDidStartWithTaskGroup: taskGroup];

    return [_runtime runWithWindow: window rootContent: $assert_nonnil(rootContent) taskGroup: taskGroup];
}

- (id<AUIContent>)rootContent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AUIWindowConfiguration *nillable)windowConfiguration
{
    return AUIWindowConfiguration.defaults;
}

- (void)applicationDidStartWithTaskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)taskGroup;
}

- (void)setNeedsRender
{
    [_runtime setNeedsRender];
}

- (AUIInputState *)_inputState
{
    return _runtime.inputState;
}

- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
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

- (AUIContextMenu *nillable)_activeContextMenuForTesting
{
    return _runtime.interactionEngine.activeContextMenu;
}

- (void)_setWindowForTesting: (AUIWindow *nillable)window
{
    [_runtime useWindowForTesting: window];
}

- (void)_setRootContentForTesting: (id<AUIContent> nillable)rootContent
{
    [_runtime useRootContentForTesting: rootContent];
}

- (AUIWindow *)_makeWindowWithConfiguration: (AUIWindowConfiguration *)configuration
{
#if AUI_HAS_CORE_GRAPHICS_WINDOW
    return [[AUICoreGraphicsWindow alloc] initWithApplication: self configuration: configuration];
#elif AUI_HAS_CAIRO_X11_WINDOW
    return [[AUICairoX11Window alloc] initWithApplication: self configuration: configuration];
#else
    return [[AUIHeadlessWindow alloc] initWithApplication: self configuration: configuration];
#endif
}

@end

#pragma clang assume_nonnull end
