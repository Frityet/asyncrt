#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <cairo-xlib.h>
#include <cairo.h>
#include <stdlib.h>
#include <string.h>

#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Primitives.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Platform/Cairo/RenderSupport.h>
#import <AsyncRT/Application/UI/Window/Window+Private.h>
#import <AsyncRT/Application/UI/Window/Platform/X11/Window.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Application+Private.h>

#pragma clang assume_nonnull begin

static char *_Nonnull AsyncUIX11WindowFonts[] = {
    (char *)"Sans"
};

@namespace(AsyncUIX11EventSupport)

+ (AsyncUIModifierFlags)modifierFlagsFromState: (unsigned int)state;
+ (AsyncUIKey)keyFromKeySym: (KeySym)keySym;
+ (float)viewportCoordinateForNativeCoordinate: (float)nativeCoordinate
                               nativeDimension: (float)nativeDimension
                             viewportDimension: (float)viewportDimension;

@end

@namespace_implementation(AsyncUIX11EventSupport)

+ (AsyncUIModifierFlags)modifierFlagsFromState: (unsigned int)state
{
    AsyncUIModifierFlags modifiers = AsyncUIModifierFlagNone;

    if ((state & ShiftMask) != 0)
        modifiers |= AsyncUIModifierFlagShift;
    if ((state & ControlMask) != 0)
        modifiers |= AsyncUIModifierFlagControl;
    if ((state & Mod1Mask) != 0)
        modifiers |= AsyncUIModifierFlagAlt;
    if ((state & Mod4Mask) != 0)
        modifiers |= AsyncUIModifierFlagSuper;

    return modifiers;
}

+ (AsyncUIKey)keyFromKeySym: (KeySym)keySym
{
    switch (keySym) {
        case XK_Tab:
            return AsyncUIKeyTab;
        case XK_Return:
            return AsyncUIKeyEnter;
        case XK_KP_Enter:
            return AsyncUIKeyKeypadEnter;
        case XK_Escape:
            return AsyncUIKeyEscape;
        case XK_Left:
            return AsyncUIKeyLeft;
        case XK_Right:
            return AsyncUIKeyRight;
        case XK_Up:
            return AsyncUIKeyUp;
        case XK_Down:
            return AsyncUIKeyDown;
        case XK_Home:
            return AsyncUIKeyHome;
        case XK_End:
            return AsyncUIKeyEnd;
        case XK_Page_Up:
            return AsyncUIKeyPageUp;
        case XK_Page_Down:
            return AsyncUIKeyPageDown;
        case XK_BackSpace:
            return AsyncUIKeyBackspace;
        case XK_Delete:
            return AsyncUIKeyDelete;
        case XK_a:
        case XK_A:
            return AsyncUIKeyA;
        case XK_c:
        case XK_C:
            return AsyncUIKeyC;
        case XK_v:
        case XK_V:
            return AsyncUIKeyV;
        case XK_x:
        case XK_X:
            return AsyncUIKeyX;
        default:
            return AsyncUIKeyUnknown;
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

@implementation AsyncUIX11Window {
    bool _open;
    Display *nillable _display;
    int _screen;
    Window _window;
    cairo_surface_t *nillable _surface;
    Atom _deleteWindowAtom;
    XIM nillable _inputMethod;
    XIC nillable _inputContext;
    AsyncUISize _nativeSize;
    OFString *nillable _clipboardText;
}

- (instancetype)initWithApplication: (AsyncImmediateUIApplication *nonnil)application
                      configuration: (AsyncUIWindowConfiguration *nonnil)configuration
{
    self = [super initWithApplication: application configuration: configuration];
    _open = false;
    _display = nullptr;
    _screen = 0;
    _window = 0;
    _surface = nullptr;
    _deleteWindowAtom = None;
    _inputMethod = nullptr;
    _inputContext = nullptr;
    _nativeSize = configuration.initialSize;
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

- (void)openWindow
{
    long eventMask = ExposureMask | StructureNotifyMask | KeyPressMask | KeyReleaseMask |
                     ButtonPressMask | ButtonReleaseMask | PointerMotionMask | FocusChangeMask;

    _display = XOpenDisplay(nullptr);
    if (_display == nullptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to open the X11 display"];

    _screen = DefaultScreen($assert_nonnil(_display));
    XSetWindowAttributes attributes = (XSetWindowAttributes){0};
    attributes.event_mask = eventMask;
    _window = XCreateWindow($assert_nonnil(_display),
                            RootWindow($assert_nonnil(_display), _screen),
                            0,
                            0,
                            (unsigned int)self.configuration.initialSize.width,
                            (unsigned int)self.configuration.initialSize.height,
                            0,
                            CopyFromParent,
                            InputOutput,
                            CopyFromParent,
                            CWEventMask,
                            &attributes);
    if (_window == 0)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create the X11 window"];

    XStoreName($assert_nonnil(_display), _window, self.configuration.title.UTF8String);
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

    XWindowAttributes windowAttributes = (XWindowAttributes){0};
    XGetWindowAttributes($assert_nonnil(_display), _window, &windowAttributes);
    _surface = cairo_xlib_surface_create($assert_nonnil(_display),
                                         _window,
                                         windowAttributes.visual,
                                         windowAttributes.width,
                                         windowAttributes.height);
    if (cairo_surface_status($assert_nonnil(_surface)) != CAIRO_STATUS_SUCCESS)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create the X11 Cairo surface"];

    _nativeSize = [AsyncUI sizeWithWidth: (float)windowAttributes.width height: (float)windowAttributes.height];
    _open = true;
}

- (void)pollEvents
{
    while (_open and _display != nullptr and XPending($assert_nonnil(_display)) > 0) {
        XEvent event = (XEvent){0};

        XNextEvent($assert_nonnil(_display), &event);

        if (_inputContext != nullptr and XFilterEvent(&event, _window))
            continue;

        switch (event.type) {
            case MotionNotify: {
                AsyncUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xmotion.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xmotion.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if ([self.application _updateHoverStateFromCurrentLayout])
                    [self.application setNeedsRender];
                break;
            }
            case ButtonPress: {
                AsyncUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if (event.xbutton.button == Button1)
                    [[self.application _inputState] pressMouseButton: AsyncUIMouseButtonPrimary];
                else if (event.xbutton.button == Button3)
                    [[self.application _inputState] pressMouseButton: AsyncUIMouseButtonSecondary];
                else if (event.xbutton.button == Button4)
                    [[self.application _inputState] scrollByX: 0 y: -1];
                else if (event.xbutton.button == Button5)
                    [[self.application _inputState] scrollByX: 0 y: 1];
                [self.application setNeedsRender];
                break;
            }
            case ButtonRelease: {
                AsyncUISize viewportSize = self.viewportSize;

                [[self.application _inputState]
                    movePointerToX: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.x
                                                                               nativeDimension: _nativeSize.width
                                                                             viewportDimension: viewportSize.width]
                               y: [AsyncUIX11EventSupport viewportCoordinateForNativeCoordinate: (float)event.xbutton.y
                                                                               nativeDimension: _nativeSize.height
                                                                             viewportDimension: viewportSize.height]];
                if (event.xbutton.button == Button1)
                    [[self.application _inputState] releaseMouseButton: AsyncUIMouseButtonPrimary];
                else if (event.xbutton.button == Button3)
                    [[self.application _inputState] releaseMouseButton: AsyncUIMouseButtonSecondary];
                [self.application setNeedsRender];
                break;
            }
            case KeyPress: {
                KeySym keySym = NoSymbol;
                Status status = 0;
                char buffer[64] = {0};
                int length = 0;
                AsyncUIModifierFlags modifiers = [AsyncUIX11EventSupport modifierFlagsFromState: event.xkey.state];
                AsyncUIKey key = AsyncUIKeyUnknown;

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

                key = [AsyncUIX11EventSupport keyFromKeySym: keySym];
                if (key != AsyncUIKeyUnknown)
                    [[self.application _inputState] addKey: key modifiers: modifiers repeat: false];

                if (length > 0 and (modifiers & (AsyncUIModifierFlagControl | AsyncUIModifierFlagCommand)) == 0) {
                    buffer[length] = '\0';
                    [[self.application _inputState] insertText: [OFString stringWithUTF8String: buffer]];
                }

                [self.application setNeedsRender];
                break;
            }
            case ConfigureNotify:
                _nativeSize = [AsyncUI sizeWithWidth: (float)event.xconfigure.width
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

- (void)_setViewportSize: (AsyncUISize)viewportSize
{
    [super _setViewportSize: viewportSize];
    const AsyncUISize nativeSize = [self _nativeSizeForViewportSize: viewportSize];
    _nativeSize = nativeSize;
    const int width = (int)nativeSize.width;
    const int height = (int)nativeSize.height;

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
    if (not _open or _surface == nullptr)
        return;

    const AsyncUISize nativeSize = _nativeSize;
    const AsyncUISize viewportSize = self.viewportSize;
    cairo_t *cairo = cairo_create($assert_nonnil(_surface));
    if (cairo_status(cairo) != CAIRO_STATUS_SUCCESS) {
        cairo_destroy(cairo);
        return;
    }

    @try {
        AsyncUICairoTextMeasureContext measureContext = (AsyncUICairoTextMeasureContext){
            .context = cairo,
            .fonts = AsyncUIX11WindowFonts
        };
        Clay_RenderCommandArray commands = [self _buildRenderCommandsForViewportSize: viewportSize
                                                                  textMeasureFunction: AsyncUICairoMeasureText
                                                                             userData: &measureContext];
        if (viewportSize.width > 0.0f and viewportSize.height > 0.0f)
            cairo_scale(cairo,
                        (double)nativeSize.width / (double)viewportSize.width,
                        (double)nativeSize.height / (double)viewportSize.height);
        [AsyncUICairoRenderSupport renderCommands: commands
                                    onContext: cairo
                                        fonts: AsyncUIX11WindowFonts];
    } @finally {
        cairo_destroy(cairo);
    }

    cairo_surface_flush($assert_nonnil(_surface));
    XFlush($assert_nonnil(_display));
}

@end

#pragma clang assume_nonnull end
