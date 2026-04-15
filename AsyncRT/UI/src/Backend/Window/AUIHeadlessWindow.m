#include <cairo.h>
#include <stdlib.h>

#import "Backend/AUICairoRenderSupport.h"
#import "Backend/Window/AUIHeadlessWindow.h"
#import "AUIInternal.h"

#pragma clang assume_nonnull begin

static char *_Nonnull AUIHeadlessWindowFonts[] = {
    (char *)"Sans"
};

[[direct_members]]
@implementation AUIHeadlessWindow {
    bool _open;
    AUISize _nativeSize;
    double _scaleFactor;
    cairo_surface_t *nillable _surface;
    cairo_t *nillable _cairo;
    unsigned char *nillable _bytes;
    int _stride;
    AUICursorStyle _cursorStyle;
    OFString *nillable _clipboardText;
}

- (instancetype)initWithApplication: (AUIApplication *nonnil)application
                            options: (AUIWindowOptions *nonnil)options
{
    self = [super initWithApplication: application options: options];
    _open = false;
    _nativeSize = options.initialSize;
    _scaleFactor = 1.0;
    _surface = nullptr;
    _cairo = nullptr;
    _bytes = nullptr;
    _stride = 0;
    _cursorStyle = AUICursorStyleDefault;
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

- (AUISize)viewportSize
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

- (void)setViewportSize: (AUISize)viewportSize
{
    [self _setViewportSize: viewportSize];
    [self.application setNeedsRender];
}

- (void)setNativeSize: (AUISize)nativeSize
{
    _nativeSize = nativeSize;
    [self.application setNeedsRender];
}

- (void)_setViewportSize: (AUISize)viewportSize
{
    [super _setViewportSize: viewportSize];
    _nativeSize = [self _nativeSizeForViewportSize: viewportSize];
}

- (void)setCursorStyle: (AUICursorStyle)cursorStyle
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

    const AUISize nativeSize = _nativeSize;
    const AUISize viewportSize = self.viewportSize;
    cairo_save($assert_nonnil(_cairo));
    @try {
        cairo_set_operator($assert_nonnil(_cairo), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_cairo), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_cairo));
        AUICairoTextMeasureContext measureContext = (AUICairoTextMeasureContext){
            .context = $assert_nonnil(_cairo),
            .fonts = AUIHeadlessWindowFonts
        };
        Clay_RenderCommandArray commands = [self _buildRenderCommandsForViewportSize: viewportSize
                                                                  textMeasureFunction: AUICairoMeasureText
                                                                             userData: &measureContext];
        if (viewportSize.width > 0.0f and viewportSize.height > 0.0f)
            cairo_scale($assert_nonnil(_cairo),
                        (double)nativeSize.width / (double)viewportSize.width,
                        (double)nativeSize.height / (double)viewportSize.height);
        [AUICairoRenderSupport renderCommands: commands
                                    onContext: $assert_nonnil(_cairo)
                                        fonts: AUIHeadlessWindowFonts];
        cairo_surface_flush($assert_nonnil(_surface));
    } @finally {
        cairo_restore($assert_nonnil(_cairo));
    }
}

- (void)sendPointerMoveToX: (float)x y: (float)y
{
    AUISize viewportSize = self.viewportSize;
    float viewportX = x;
    float viewportY = y;

    if (_nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportX = x * viewportSize.width / _nativeSize.width;
    if (_nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportY = y * viewportSize.height / _nativeSize.height;

    [self.application._inputState movePointerToX: viewportX y: viewportY];
    [self.application setNeedsRender];
}

- (void)sendMouseDown: (AUIMouseButton)button
{
    [self.application._inputState pressMouseButton: button];
    [self.application setNeedsRender];
}

- (void)sendMouseUp: (AUIMouseButton)button
{
    [self.application._inputState releaseMouseButton: button];
    [self.application setNeedsRender];
}

- (void)sendScrollByX: (float)deltaX y: (float)deltaY
{
    AUISize viewportSize = self.viewportSize;
    float viewportDeltaX = deltaX;
    float viewportDeltaY = deltaY;

    if (_nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportDeltaX = deltaX * viewportSize.width / _nativeSize.width;
    if (_nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportDeltaY = deltaY * viewportSize.height / _nativeSize.height;

    [self.application._inputState scrollByX: viewportDeltaX y: viewportDeltaY];
    [self.application setNeedsRender];
}

- (void)sendKey: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat
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
