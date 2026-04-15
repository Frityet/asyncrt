#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <cairo-xlib.h>
#include <cairo.h>
#include <stdlib.h>
#include <string.h>

#import "Backend/AUICairoRenderSupport.h"
#import "Backend/Window/AUICairoX11Window.h"
#import "AUIInternal.h"

#pragma clang assume_nonnull begin

static char *_Nonnull AUICairoX11WindowFonts[] = {
    (char *)"Sans"
};

@namespace(AUIX11EventSupport)

+ (AUIModifierFlags)modifierFlagsFromState: (unsigned int)state;
+ (AUIKey)keyFromKeySym: (KeySym)keySym;
+ (float)viewportCoordinateForNativeCoordinate: (float)nativeCoordinate
                               nativeDimension: (float)nativeDimension
                             viewportDimension: (float)viewportDimension;

@end

@namespace_implementation(AUIX11EventSupport)

+ (AUIModifierFlags)modifierFlagsFromState: (unsigned int)state
{
    AUIModifierFlags modifiers = AUIModifierFlagNone;

    if ((state & ShiftMask) != 0)
        modifiers |= AUIModifierFlagShift;
    if ((state & ControlMask) != 0)
        modifiers |= AUIModifierFlagControl;
    if ((state & Mod1Mask) != 0)
        modifiers |= AUIModifierFlagAlt;
    if ((state & Mod4Mask) != 0)
        modifiers |= AUIModifierFlagSuper;

    return modifiers;
}

+ (AUIKey)keyFromKeySym: (KeySym)keySym
{
    switch (keySym) {
        case XK_Tab:
            return AUIKeyTab;
        case XK_Return:
            return AUIKeyEnter;
        case XK_KP_Enter:
            return AUIKeyKeypadEnter;
        case XK_Escape:
            return AUIKeyEscape;
        case XK_Left:
            return AUIKeyLeft;
        case XK_Right:
            return AUIKeyRight;
        case XK_Up:
            return AUIKeyUp;
        case XK_Down:
            return AUIKeyDown;
        case XK_Home:
            return AUIKeyHome;
        case XK_End:
            return AUIKeyEnd;
        case XK_Page_Up:
            return AUIKeyPageUp;
        case XK_Page_Down:
            return AUIKeyPageDown;
        case XK_BackSpace:
            return AUIKeyBackspace;
        case XK_Delete:
            return AUIKeyDelete;
        case XK_a:
        case XK_A:
            return AUIKeyA;
        case XK_c:
        case XK_C:
            return AUIKeyC;
        case XK_v:
        case XK_V:
            return AUIKeyV;
        case XK_x:
        case XK_X:
            return AUIKeyX;
        default:
            return AUIKeyUnknown;
    }
}

+ (float)viewportCoordinateForNativeCoordinate: (float)nativeCoordinate
                               nativeDimension: (float)nativeDimension
                             viewportDimension: (float)viewportDimension
{
    if (nativeDimension <= 0.0f or viewportDimension <= 0.0f)
        return nativeCoordinate;

    return nativeCoordinate * viewportDimension / nativeDimension;
}

@end

@implementation AUICairoX11Window {
    bool _open;
    Display *nillable _display;
    int _screen;
    Window _window;
    cairo_surface_t *nillable _surface;
    Atom _deleteWindowAtom;
    XIM nillable _inputMethod;
    XIC nillable _inputContext;
    AUISize _nativeSize;
    OFString *nillable _clipboardText;
}

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    self = [super initWithApplication: application options: options];
    _open = false;
    _display = nullptr;
    _screen = 0;
    _window = 0;
    _surface = nullptr;
    _deleteWindowAtom = None;
    _inputMethod = nullptr;
    _inputContext = nullptr;
    _nativeSize = $assert_nonnil(options).initialSize;
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

- (void)openWindow
{
    XSetWindowAttributes attributes;
    long eventMask = ExposureMask | StructureNotifyMask | KeyPressMask | KeyReleaseMask |
                     ButtonPressMask | ButtonReleaseMask | PointerMotionMask | FocusChangeMask;

    _display = XOpenDisplay(nullptr);
    if (_display == nullptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to open the X11 display"];

    _screen = DefaultScreen($assert_nonnil(_display));
    attributes.event_mask = eventMask;
    _window = XCreateWindow($assert_nonnil(_display),
                            RootWindow($assert_nonnil(_display), _screen),
                            0,
                            0,
                            (unsigned int)self.options.initialSize.width,
                            (unsigned int)self.options.initialSize.height,
                            0,
                            CopyFromParent,
                            InputOutput,
                            CopyFromParent,
                            CWEventMask,
                            &attributes);
    if (_window == 0)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create the X11 window"];

    XStoreName($assert_nonnil(_display), _window, self.options.title.UTF8String);
    _deleteWindowAtom = XInternAtom($assert_nonnil(_display), "WM_DELETE_WINDOW", False);
    XSetWMProtocols($assert_nonnil(_display), _window, &_deleteWindowAtom, 1);
    XMapWindow($assert_nonnil(_display), _window);

    _inputMethod = XOpenIM($assert_nonnil(_display), nullptr, nullptr, nullptr);
    if (_inputMethod != nullptr) {
        _inputContext = XCreateIC($assert_nonnil(_inputMethod),
                                  XNInputStyle,
                                  XIMPreeditNothing | XIMStatusNothing,
                                  XNClientWindow,
                                  _window,
                                  XNFocusWindow,
                                  _window,
                                  nullptr);
    }

    XWindowAttributes windowAttributes;
    XGetWindowAttributes($assert_nonnil(_display), _window, &windowAttributes);
    _surface = cairo_xlib_surface_create($assert_nonnil(_display),
                                         _window,
                                         windowAttributes.visual,
                                         windowAttributes.width,
                                         windowAttributes.height);
    if (cairo_surface_status($assert_nonnil(_surface)) != CAIRO_STATUS_SUCCESS)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create the X11 Cairo surface"];

    _nativeSize = [AUI sizeWithWidth: (float)windowAttributes.width height: (float)windowAttributes.height];
    _open = true;
}

- (void)pollEvents
{
    while (_open and _display != nullptr and XPending($assert_nonnil(_display)) > 0) {
        XEvent event;

        XNextEvent($assert_nonnil(_display), &event);

        if (_inputContext != nullptr and XFilterEvent(&event, _window))
            continue;

        switch (event.type) {
            case MotionNotify: {
                AUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xmotion.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xmotion.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if ([self.application _updateHoverStateFromCurrentLayout])
                    [self.application setNeedsRender];
                break;
            }
            case ButtonPress: {
                AUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if (event.xbutton.button == Button1)
                    [[self.application _inputState] pressMouseButton: AUIMouseButtonPrimary];
                else if (event.xbutton.button == Button3)
                    [[self.application _inputState] pressMouseButton: AUIMouseButtonSecondary];
                else if (event.xbutton.button == Button4)
                    [[self.application _inputState] scrollByX: 0 y: -1];
                else if (event.xbutton.button == Button5)
                    [[self.application _inputState] scrollByX: 0 y: 1];
                [self.application setNeedsRender];
                break;
            }
            case ButtonRelease: {
                AUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if (event.xbutton.button == Button1)
                    [[self.application _inputState] releaseMouseButton: AUIMouseButtonPrimary];
                else if (event.xbutton.button == Button3)
                    [[self.application _inputState] releaseMouseButton: AUIMouseButtonSecondary];
                [self.application setNeedsRender];
                break;
            }
            case KeyPress: {
                KeySym keySym = NoSymbol;
                Status status = 0;
                char buffer[64] = {0};
                int length = 0;
                AUIModifierFlags modifiers = [AUIX11EventSupport modifierFlagsFromState: event.xkey.state];
                AUIKey key;

                if (_inputContext != nullptr) {
                    length = Xutf8LookupString($assert_nonnil(_inputContext),
                                               &event.xkey,
                                               buffer,
                                               (int)(sizeof(buffer) - 1),
                                               &keySym,
                                               &status);
                } else {
                    length = XLookupString(&event.xkey, buffer, (int)(sizeof(buffer) - 1), &keySym, nullptr);
                    status = XLookupBoth;
                }

                key = [AUIX11EventSupport keyFromKeySym: keySym];
                if (key != AUIKeyUnknown)
                    [[self.application _inputState] addKey: key modifiers: modifiers repeat: false];

                if (length > 0 and (modifiers & (AUIModifierFlagControl | AUIModifierFlagCommand)) == 0) {
                    buffer[length] = '\0';
                    [[self.application _inputState] insertText: [OFString stringWithUTF8String: buffer]];
                }

                [self.application setNeedsRender];
                break;
            }
            case ConfigureNotify:
                _nativeSize = [AUI sizeWithWidth: (float)event.xconfigure.width
                                          height: (float)event.xconfigure.height];
                if (_surface != nullptr)
                    cairo_xlib_surface_set_size($assert_nonnil(_surface),
                                                event.xconfigure.width,
                                                event.xconfigure.height);
                [self.application setNeedsRender];
                break;
            case ClientMessage:
                if ((Atom)event.xclient.data.l[0] == _deleteWindowAtom)
                    _open = false;
                break;
            case DestroyNotify:
                _open = false;
                break;
            default:
                break;
        }
    }
}

- (void)closeWindow
{
    _open = false;

    if (_inputContext != nullptr) {
        XDestroyIC($assert_nonnil(_inputContext));
        _inputContext = nullptr;
    }

    if (_inputMethod != nullptr) {
        XCloseIM($assert_nonnil(_inputMethod));
        _inputMethod = nullptr;
    }

    if (_surface != nullptr) {
        cairo_surface_destroy(_surface);
        _surface = nullptr;
    }

    if (_display != nullptr and _window != 0) {
        XDestroyWindow($assert_nonnil(_display), _window);
        _window = 0;
    }

    if (_display != nullptr) {
        XCloseDisplay($assert_nonnil(_display));
        _display = nullptr;
    }
}

- (void)_setViewportSize: (AUISize)viewportSize
{
    AUISize nativeSize;
    int width;
    int height;

    [super _setViewportSize: viewportSize];
    nativeSize = [self _nativeSizeForViewportSize: viewportSize];
    _nativeSize = nativeSize;
    width = (int)nativeSize.width;
    height = (int)nativeSize.height;

    if (_display != nullptr and _window != 0) {
        XResizeWindow($assert_nonnil(_display), _window, (unsigned int)width, (unsigned int)height);
        XFlush($assert_nonnil(_display));
    }

    if (_surface != nullptr)
        cairo_xlib_surface_set_size($assert_nonnil(_surface), width, height);
}

- (OFString *nillable)clipboardText
{
    return _clipboardText;
}

- (void)setClipboardText: (OFString *nillable)text
{
    _clipboardText = [text copy];
}

- (void)renderFrame
{
    cairo_t *cairo;
    AUICairoTextMeasureContext measureContext;
    Clay_RenderCommandArray commands;
    AUISize nativeSize;
    AUISize viewportSize;

    if (not _open or _surface == nullptr)
        return;

    nativeSize = _nativeSize;
    viewportSize = self.viewportSize;
    cairo = cairo_create($assert_nonnil(_surface));
    if (cairo_status(cairo) != CAIRO_STATUS_SUCCESS) {
        cairo_destroy(cairo);
        return;
    }

    @try {
        measureContext = (AUICairoTextMeasureContext){
            .context = cairo,
            .fonts = AUICairoX11WindowFonts
        };
        commands = [self _buildRenderCommandsForViewportSize: viewportSize
                                         textMeasureFunction: AUICairoMeasureText
                                                    userData: &measureContext];
        if (viewportSize.width > 0.0f and viewportSize.height > 0.0f)
            cairo_scale(cairo,
                        (double)nativeSize.width / (double)viewportSize.width,
                        (double)nativeSize.height / (double)viewportSize.height);
        [AUICairoRenderSupport renderCommands: commands
                                    onContext: cairo
                                        fonts: AUICairoX11WindowFonts];
    } @finally {
        cairo_destroy(cairo);
    }

    cairo_surface_flush($assert_nonnil(_surface));
    XFlush($assert_nonnil(_display));
}

@end

#pragma clang assume_nonnull end
