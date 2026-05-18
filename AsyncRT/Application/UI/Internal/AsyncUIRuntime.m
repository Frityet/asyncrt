#import <AsyncRT/Application/UI/Internal/AsyncUIRuntime.h>

#import <AsyncRT/Application/UI/AsyncUIExceptions.h>
#import <AsyncRT/Application/UI/AsyncUIApplication.h>
#import <AsyncRT/Application/UI/Backend/AsyncUIWindow.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIRuntime {
    AsyncUIApplication *_application;
    AsyncUIWindow *nillable _window;
    OFMutex *_renderWakeLock;
    AsyncCompletionSource<AsyncUnit *> *nillable _renderWakeCompletionSource;
    atomic_t(bool) _needsRender;
}

- (instancetype)initWithApplication: (AsyncUIApplication *)application
{
    self = [super init];
    _application = application;
    _renderer = [[AsyncUIRenderer alloc] initWithApplication: application];
    _interactionEngine = [[AsyncUIInteractionEngine alloc] init];
    _textInput = [[AsyncUITextInputEngine alloc] init];
    _inputState = [[AsyncUIInputState alloc] init];
    _renderWakeLock = [OFMutex mutex];
    atomic_init(&_needsRender, false);
    return self;
}

- (id)runWithWindow: (AsyncUIWindow *)window
          rootContent: (id<AsyncUIContent>)rootContent
            taskGroup: (AsyncTaskGroup *)taskGroup
{
    _window = window;
    [_renderer attachRootContent: rootContent taskGroup: taskGroup];

    @try {
        [_window openWindow];
        [self setNeedsRender];

        while (_window.isOpen) {
            bool didRender = false;
            AsyncTask<AsyncUnit *> *renderWakeTask = [self _renderWakeTask];

            [_window pollEvents];
            if (not _window.isOpen)
                break;

            if ([self consumePendingRenderRequest]) {
                [_window renderFrame];
                didRender = true;
            }

            const OFTimeInterval pollInterval = ((_inputState.isPrimaryButtonDown or _inputState.isSecondaryButtonDown or didRender)
                ? (1.0 / 120.0)
                : (1.0 / 60.0));

            if ([self hasPendingRenderRequest])
                continue;

            (void)[AsyncTask<AsyncUnit *> race: [OFArray arrayWithObjects:
                [taskGroup.scheduler sleepForTimeInterval: pollInterval],
                renderWakeTask,
                nil]].await;
        }
    } @finally {
        [self _resetRuntimeState];
        [_renderer detachRootContent];
        [_window closeWindow];
        _window = nilptr;
    }

    return [OFNumber numberWithInt: 0];
}

- (void)setNeedsRender
{
    atomic_store_explicit(&_needsRender, true, memory_order_release);
    [self _signalRenderWake];
}

- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                     deltaTime: (float)deltaTime
{
    return [_renderer buildRenderCommandsWithViewportSize: viewportSize
                                                deltaTime: deltaTime
                                               inputState: _inputState
                                                   window: $assert_nonnil(_window)
                                        interactionEngine: _interactionEngine
                                                textInput: _textInput
                                            clipboardText: ^OFString *nillable {
        return (_window != nilptr ? _window.clipboardText : nilptr);
    }
                                      setClipboardText: ^(OFString *nillable text) {
        if (_window != nilptr)
            _window.clipboardText = text;
    }
                                           cursorSetter: ^(AsyncUICursorStyle cursorStyle) {
        if (_window != nilptr)
            _window.cursorStyle = cursorStyle;
    }
                                      renderRequester: ^{
        [self setNeedsRender];
    }];
}

- (bool)updateHoverStateFromCurrentLayout
{
    return [_interactionEngine updateHoverStateFromCurrentLayoutWithInputState: _inputState
                                                                  cursorSetter: ^(AsyncUICursorStyle cursorStyle) {
        if (_window != nilptr)
            _window.cursorStyle = cursorStyle;
    }];
}

- (bool)consumePendingRenderRequest
{
    return atomic_exchange_explicit(&_needsRender, false, memory_order_acq_rel);
}

- (bool)hasPendingRenderRequest
{
    return atomic_load_explicit(&_needsRender, memory_order_acquire);
}

- (void)useWindowForTesting: (AsyncUIWindow *nillable)window
{
    _window = window;
}

- (void)useRootContentForTesting: (id<AsyncUIContent> nillable)rootContent
{
    AsyncTaskGroup *nillable currentTaskGroup = AsyncTaskGroup.currentTaskGroup;

    [self _resetRuntimeState];
    [_renderer detachRootContent];

    if (rootContent != nilptr)
        [_renderer attachRootContent: $assert_nonnil(rootContent) taskGroup: currentTaskGroup];
}

- (AsyncTask<AsyncUnit *> *)_renderWakeTask
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
    [_interactionEngine resetState];
    [_textInput resetState];
    [_inputState resetTransientState];
}

@end

#pragma clang assume_nonnull end
