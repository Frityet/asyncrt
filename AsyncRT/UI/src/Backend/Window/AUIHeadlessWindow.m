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
    AUISize _viewportSize;
    double _scaleFactor;
    cairo_surface_t *nillable _surface;
    cairo_t *nillable _cairo;
    unsigned char *nillable _bytes;
    int _stride;
    AUICursorStyle _cursorStyle;
    OFString *nillable _clipboardText;
}

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    self = [super initWithApplication: application options: options];
    _open = false;
    _viewportSize = $assert_nonnil(options).initialSize;
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
    return _viewportSize;
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

- (void)_setViewportSize: (AUISize)viewportSize
{
    _viewportSize = viewportSize;
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
    int width = (int)_viewportSize.width;
    int height = (int)_viewportSize.height;
    int stride;

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

    stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
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
    AUICairoTextMeasureContext measureContext;
    Clay_RenderCommandArray commands;

    if (not _open or not [self _ensureSurface])
        return;

    cairo_save($assert_nonnil(_cairo));
    @try {
        cairo_set_operator($assert_nonnil(_cairo), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_cairo), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_cairo));
        measureContext = (AUICairoTextMeasureContext){
            .context = $assert_nonnil(_cairo),
            .fonts = AUIHeadlessWindowFonts
        };
        commands = [self _buildRenderCommandsForViewportSize: _viewportSize
                                         textMeasureFunction: AUICairoMeasureText
                                                    userData: &measureContext];
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
    [self.application._inputState movePointerToX: x y: y];
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
    [self.application._inputState scrollByX: deltaX y: deltaY];
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
