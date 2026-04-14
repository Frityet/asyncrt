#include <objc/runtime.h>
#import "UI/AUIApplication.h"
#import "UI/AUIInternal.h"
#import "UI/AUIRenderHost.h"
#import "UI/Backend/Window/AUIHeadlessWindow.h"

#if AUI_HAS_CORE_GRAPHICS_WINDOW
#   import "UI/Backend/Window/AUICoreGraphicsWindow.h"
#endif

#if AUI_HAS_CAIRO_X11_WINDOW
#   import "UI/Backend/Window/AUICairoX11Window.h"
#endif

#pragma clang assume_nonnull begin

[[direct_members]]
@interface AUIApplication ()

- (Task<AsyncUnit *> *)_renderWakeTask;
- (void)_signalRenderWake;
- (void)_resetRuntimeState;

@end

[[direct_members]]
@implementation AUIApplication {
    AUIWindow *nillable _window;
    AUIRenderHost *_renderHost;
    AUIInteractionController *_interactionController;
    AUITextEditingController *_textEditingController;
    AUIInputState *_inputState;
    OFMutex *_renderWakeLock;
    AsyncCompletionSource<AsyncUnit *> *nillable _renderWakeCompletionSource;
    atomic_t(bool) _needsRender;
}

- (instancetype)init
{
    self = [super init];
    _renderHost = [[AUIRenderHost alloc] initWithApplication: self];
    _interactionController = [[AUIInteractionController alloc] init];
    _textEditingController = [[AUITextEditingController alloc] init];
    _inputState = [[AUIInputState alloc] init];
    _renderWakeLock = [OFMutex mutex];
    atomic_init(&_needsRender, false);
    return self;
}

- (AUIViewComponent *nillable)rootViewComponent
{
    return _renderHost.rootViewComponent;
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    AUIViewComponent *rootViewComponent;

    (void)notification;

    _window = [self makeWindow];
    rootViewComponent = [self makeRootViewComponent];

    if (rootViewComponent == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"-makeRootViewComponent must return a nonnil root view component"];

    [_renderHost attachRootViewComponent: rootViewComponent taskGroup: taskGroup];

    @try {
        [_window openWindow];
        [self setNeedsRender];

        while (_window.isOpen) {
            OFTimeInterval pollInterval;
            bool didRender = false;
            Task<AsyncUnit *> *renderWakeTask = [self _renderWakeTask];

            [_window pollEvents];
            if (not _window.isOpen)
                break;

            if ([self _consumePendingRenderRequest]) {
                [_window renderFrame];
                didRender = true;
            }

            if (_inputState.isPrimaryButtonDown or _inputState.isSecondaryButtonDown)
                pollInterval = (1.0 / 120.0);
            else if (didRender)
                pollInterval = (1.0 / 120.0);
            else
                pollInterval = (1.0 / 60.0);

            if ([self _hasPendingRenderRequest])
                continue;

            (void)[Task<AsyncUnit *> race: @[
                [taskGroup.scheduler sleepForTimeInterval: pollInterval],
                renderWakeTask
            ]].await;
        }
    } @finally {
        [self _resetRuntimeState];
        [_renderHost detachRootViewComponent];
        [_window closeWindow];
        _window = nilptr;
    }

    return @(0);
}

- (AUIViewComponent *)makeRootViewComponent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AUIWindowOptions *)windowOptions
{
    return AUIWindowOptions.defaultOptions;
}

- (AUIWindow *)makeWindow
{
#if AUI_HAS_CORE_GRAPHICS_WINDOW
    return [[AUICoreGraphicsWindow alloc] initWithApplication: self options: self.windowOptions];
#elif AUI_HAS_CAIRO_X11_WINDOW
    return [[AUICairoX11Window alloc] initWithApplication: self options: self.windowOptions];
#else
    return [[AUIHeadlessWindow alloc] initWithApplication: self options: self.windowOptions];
#endif
}

- (void)setNeedsRender
{
    atomic_store_explicit(&_needsRender, true, memory_order_release);
    [self _signalRenderWake];
}

- (AUIInputState *)_inputState
{
    return _inputState;
}

- (AUIInteractionController *)_interactionController
{
    return _interactionController;
}

- (AUITextEditingController *)_textEditingController
{
    return _textEditingController;
}

- (AUIRenderHost *)_renderHost
{
    return _renderHost;
}

- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                       deltaTime: (float)deltaTime
{
    return [_renderHost buildRenderCommandsWithViewportSize: viewportSize
                                                  deltaTime: deltaTime
                                                 inputState: _inputState
                                                     window: $assert_nonnil(_window)
                                      interactionController: _interactionController
                                      textEditingController: _textEditingController
                                              clipboardText: ^OFString *nillable {
        return [self _clipboardText];
    }
                                        setClipboardText: ^(OFString *nillable text) {
        [self _setClipboardText: text];
    }
                                             cursorSetter: ^(AUICursorStyle cursorStyle) {
        [self _setCursorStyle: cursorStyle];
    }
                                        renderRequester: ^{
        [self setNeedsRender];
    }];
}

- (OFString *nillable)_clipboardText
{
    return (_window != nilptr ? _window.clipboardText : nilptr);
}

- (void)_setClipboardText: (OFString *nillable)text
{
    if (_window != nilptr)
        _window.clipboardText = text;
}

- (void)_setCursorStyle: (AUICursorStyle)cursorStyle
{
    if (_window != nilptr)
        _window.cursorStyle = cursorStyle;
}

- (AUIContextMenu *nillable)_activeContextMenuForTesting
{
    return _interactionController.activeContextMenu;
}

- (void)_setWindowForTesting: (AUIWindow *nillable)window
{
    _window = window;
}

- (void)_setRootViewComponentForTesting: (AUIViewComponent *nillable)rootViewComponent
{
    [self _resetRuntimeState];
    _renderHost.rootViewComponentForTesting = rootViewComponent;
}

- (bool)_updateHoverStateFromCurrentLayout
{
    return [_interactionController updateHoverStateFromCurrentLayoutWithInputState: _inputState
                                                                      cursorSetter: ^(AUICursorStyle cursorStyle) {
        [self _setCursorStyle: cursorStyle];
    }];
}

- (bool)_consumePendingRenderRequest
{
    return atomic_exchange_explicit(&_needsRender, false, memory_order_acq_rel);
}

- (bool)_hasPendingRenderRequest
{
    return atomic_load_explicit(&_needsRender, memory_order_acquire);
}

- (Task<AsyncUnit *> *)_renderWakeTask
{
    AsyncCompletionSource<AsyncUnit *> *completionSource;

    [_renderWakeLock lock];
    @try {
        if (_renderWakeCompletionSource == nilptr)
            _renderWakeCompletionSource = [[AsyncCompletionSource<AsyncUnit *> alloc] init];

        completionSource = _renderWakeCompletionSource;
    } @finally {
        [_renderWakeLock unlock];
    }

    return completionSource.task;
}

- (void)_signalRenderWake
{
    AsyncCompletionSource<AsyncUnit *> *nillable completionSource = nilptr;

    [_renderWakeLock lock];
    @try {
        completionSource = _renderWakeCompletionSource;
        _renderWakeCompletionSource = nilptr;
    } @finally {
        [_renderWakeLock unlock];
    }

    if (completionSource != nilptr) {
        @try {
            [completionSource fulfill: AsyncUnit.unit];
        } @catch (AsyncTaskAlreadyResolvedException *) {
        }
    }
}

- (void)_resetRuntimeState
{
    [_interactionController resetState];
    [_textEditingController resetState];
    [_inputState resetTransientState];
}

@end

#pragma clang assume_nonnull end
