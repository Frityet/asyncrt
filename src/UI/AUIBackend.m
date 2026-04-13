#import "UI/AUIBackend.h"

#pragma clang assume_nonnull begin

@implementation AUIBackend {
    AUIApplication *_application;
    AUIWindowBackend *_windowBackend;
    AUIRendererBackend *_rendererBackend;
}

@synthesize application = _application;
@synthesize windowBackend = _windowBackend;
@synthesize rendererBackend = _rendererBackend;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                        windowBackend: (AUIWindowBackend *nillable)windowBackend
                      rendererBackend: (AUIRendererBackend *nillable)rendererBackend
{
    if (application == nilptr or windowBackend == nilptr or rendererBackend == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    _windowBackend = $assert_nonnil(windowBackend);
    _rendererBackend = $assert_nonnil(rendererBackend);
    return self;
}

- (bool)isOpen
{
    return _windowBackend.isOpen;
}

- (AUISize)viewportSize
{
    return _windowBackend.viewportSize;
}

- (void)openWindow
{
    [_windowBackend openWindow];
    [_rendererBackend _prepareForViewportSize: _windowBackend.viewportSize];
}

- (void)pollEvents
{
    [_windowBackend pollEvents];
}

- (void)renderFrame
{
    [_windowBackend _renderFrameWithBlock: ^(cairo_t *cairo, AUISize viewportSize) {
        [_rendererBackend _prepareForViewportSize: viewportSize];
        [_rendererBackend _renderApplication: _application
                                  inputState: [_application _inputState]
                                viewportSize: viewportSize
                                       cairo: cairo];
    }];
}

- (void)closeWindow
{
    [_windowBackend closeWindow];
}

- (OFString *nillable)clipboardText
{
    return _windowBackend.clipboardText;
}

- (void)setClipboardText: (OFString *nillable)text
{
    [_windowBackend setClipboardText: text];
}

- (void)setCursorStyle: (AUICursorStyle)cursorStyle
{
    [_windowBackend setCursorStyle: cursorStyle];
}

@end

@implementation AUIWindowBackend (AUIBackendInternal)

- (void)_renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock
{
    (void)renderBlock;
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

@end

@implementation AUIRendererBackend (AUIBackendInternal)

- (void)_prepareForViewportSize: (AUISize)viewportSize
{
    (void)viewportSize;
}

- (void)_renderApplication: (AUIApplication *)application
                 inputState: (AUIInputState *)inputState
               viewportSize: (AUISize)viewportSize
                      cairo: (cairo_t *)cairo
{
    (void)application;
    (void)inputState;
    (void)viewportSize;
    (void)cairo;
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

@end

#pragma clang assume_nonnull end
