#include <cairo.h>
#include <stdlib.h>

#import <AsyncRT/Application/UI/Backend/AsyncUICairoRenderSupport.h>
#import <AsyncRT/Application/UI/Backend/AsyncUIWindow+Private.h>
#import <AsyncRT/Application/UI/Backend/Window/AsyncUIHeadlessWindow.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIApplication+Private.h>

#pragma clang assume_nonnull begin

static char *_Nonnull AsyncUIHeadlessWindowFonts[] = {
    (char *)"Sans"
};

[[direct_members]]
@implementation AsyncUIHeadlessWindow {
    bool _open;
    AsyncUISize _nativeSize;
    double _scaleFactor;
    cairo_surface_t *nillable _surface;
    cairo_t *nillable _cairo;
    unsigned char *nillable _bytes;
    int _stride;
    AsyncUICursorStyle _cursorStyle;
    OFString *nillable _clipboardText;
}

- (instancetype)initWithApplication: (AsyncUIApplication *nonnil)application
                      configuration: (AsyncUIWindowConfiguration *nonnil)configuration
{
    self = [super initWithApplication: application configuration: configuration];
    _open = false;
    _nativeSize = configuration.initialSize;
    _scaleFactor = 1.0;
    _surface = nullptr;
    _cairo = nullptr;
    _bytes = nullptr;
    _stride = 0;
    _cursorStyle = AsyncUICursorStyleDefault;
    _clipboardText = nilptr;
    return self;
}

- (void)dealloc
{
    [self closeWindow];
}

- (bool)isOpen
{
    return _open;
}

- (AsyncUISize)viewportSize
{
    return [self _viewportSizeForNativeSize: _nativeSize];
}

- (double)scaleFactor
{
    return _scaleFactor;
}

- (void)openWindow
{
    _open = true;
}

- (void)pollEvents
{
}

- (void)closeWindow
{
    _open = false;

    if (_cairo != nullptr) {
        cairo_destroy(_cairo);
        _cairo = nullptr;
    }

    if (_surface != nullptr) {
        cairo_surface_destroy(_surface);
        _surface = nullptr;
    }

    if (_bytes != nullptr) {
        free(_bytes);
        _bytes = nullptr;
    }

    _stride = 0;
}

- (void)setViewportSize: (AsyncUISize)viewportSize
{
    [self _setViewportSize: viewportSize];
    [self.application setNeedsRender];
}

- (void)setNativeSize: (AsyncUISize)nativeSize
{
    _nativeSize = nativeSize;
    [self.application setNeedsRender];
}

- (void)_setViewportSize: (AsyncUISize)viewportSize
{
    [super _setViewportSize: viewportSize];
    _nativeSize = [self _nativeSizeForViewportSize: viewportSize];
}

- (void)setCursorStyle: (AsyncUICursorStyle)cursorStyle
{
    _cursorStyle = cursorStyle;
}

- (OFString *nillable)clipboardText
{
    return _clipboardText;
}

- (void)setClipboardText: (OFString *nillable)text
{
    _clipboardText = [text copy];
}

- (bool)_ensureSurface
{
    int width = (int)_nativeSize.width;
    int height = (int)_nativeSize.height;

    if (width <= 0 or height <= 0)
        return false;

    if (_surface != nullptr and cairo_image_surface_get_width($assert_nonnil(_surface)) == width and
        cairo_image_surface_get_height($assert_nonnil(_surface)) == height)
        return true;

    if (_cairo != nullptr) {
        cairo_destroy(_cairo);
        _cairo = nullptr;
    }

    if (_surface != nullptr) {
        cairo_surface_destroy(_surface);
        _surface = nullptr;
    }

    if (_bytes != nullptr) {
        free(_bytes);
        _bytes = nullptr;
    }

    const int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
    if (stride <= 0)
        return false;

    _bytes = calloc((size_t)height, (size_t)stride);
    if (_bytes == nullptr)
        return false;

    _surface = cairo_image_surface_create_for_data(_bytes,
                                                   CAIRO_FORMAT_ARGB32,
                                                   width,
                                                   height,
                                                   stride);
    if (cairo_surface_status($assert_nonnil(_surface)) != CAIRO_STATUS_SUCCESS)
        return false;

    _cairo = cairo_create($assert_nonnil(_surface));
    if (cairo_status($assert_nonnil(_cairo)) != CAIRO_STATUS_SUCCESS)
        return false;

    _stride = stride;
    return true;
}

- (void)renderFrame
{
    if (not _open or not [self _ensureSurface])
        return;

    const AsyncUISize nativeSize = _nativeSize;
    const AsyncUISize viewportSize = self.viewportSize;
    cairo_save($assert_nonnil(_cairo));
    @try {
        cairo_set_operator($assert_nonnil(_cairo), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_cairo), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_cairo));
        AsyncUICairoTextMeasureContext measureContext = (AsyncUICairoTextMeasureContext){
            .context = $assert_nonnil(_cairo),
            .fonts = AsyncUIHeadlessWindowFonts
        };
        Clay_RenderCommandArray commands = [self _buildRenderCommandsForViewportSize: viewportSize
                                                                  textMeasureFunction: AsyncUICairoMeasureText
                                                                             userData: &measureContext];
        if (viewportSize.width > 0.0f and viewportSize.height > 0.0f)
            cairo_scale($assert_nonnil(_cairo),
                        (double)nativeSize.width / (double)viewportSize.width,
                        (double)nativeSize.height / (double)viewportSize.height);
        [AsyncUICairoRenderSupport renderCommands: commands
                                    onContext: $assert_nonnil(_cairo)
                                        fonts: AsyncUIHeadlessWindowFonts];
        cairo_surface_flush($assert_nonnil(_surface));
    } @finally {
        cairo_restore($assert_nonnil(_cairo));
    }
}

- (void)sendPointerMoveToX: (float)x y: (float)y
{
    AsyncUISize viewportSize = self.viewportSize;
    float viewportX = x;
    float viewportY = y;

    if (_nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportX = x * viewportSize.width / _nativeSize.width;
    if (_nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportY = y * viewportSize.height / _nativeSize.height;

    [self.application._inputState movePointerToX: viewportX y: viewportY];
    [self.application setNeedsRender];
}

- (void)sendMouseDown: (AsyncUIMouseButton)button
{
    [self.application._inputState pressMouseButton: button];
    [self.application setNeedsRender];
}

- (void)sendMouseUp: (AsyncUIMouseButton)button
{
    [self.application._inputState releaseMouseButton: button];
    [self.application setNeedsRender];
}

- (void)sendScrollByX: (float)deltaX y: (float)deltaY
{
    AsyncUISize viewportSize = self.viewportSize;
    float viewportDeltaX = deltaX;
    float viewportDeltaY = deltaY;

    if (_nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportDeltaX = deltaX * viewportSize.width / _nativeSize.width;
    if (_nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportDeltaY = deltaY * viewportSize.height / _nativeSize.height;

    [self.application._inputState scrollByX: viewportDeltaX y: viewportDeltaY];
    [self.application setNeedsRender];
}

- (void)sendKey: (AsyncUIKey)key modifiers: (AsyncUIModifierFlags)modifiers repeat: (bool)repeat
{
    [self.application._inputState addKey: key modifiers: modifiers repeat: repeat];
    [self.application setNeedsRender];
}

- (void)sendText: (OFString *nillable)text
{
    [self.application._inputState insertText: text];
    [self.application setNeedsRender];
}

@end

#pragma clang assume_nonnull end
