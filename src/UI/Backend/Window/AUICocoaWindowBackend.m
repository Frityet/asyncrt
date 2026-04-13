#if !defined(__APPLE__)
#   error This file is only supported on Apple platforms.
#endif

#import <ObjFWBridge/ObjFWBridge.h>

#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSTrackingArea.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSThread.h>
#import <Carbon/Carbon.h>
#import <CoreGraphics/CoreGraphics.h>

#include <cairo.h>
#include <stdlib.h>

#import "UI/Backend/Window/AUICocoaWindowBackend.h"
#import "UI/AUIBackend.h"
#import "UI/AUIInternal.h"


#pragma clang assume_nonnull begin

@namespace(AUICocoaEventSupport)

+ (AUIModifierFlags)modifierFlagsFromEvent: (NSEvent *)event;
+ (AUIKey)keyFromEvent: (NSEvent *)event;

@end

@namespace_implementation(AUICocoaEventSupport)

+ (AUIModifierFlags)modifierFlagsFromEvent: (NSEvent *)event
{
    NSEventModifierFlags flags = event.modifierFlags;
    AUIModifierFlags modifiers = AUIModifierFlagNone;

    if ((flags & NSEventModifierFlagShift) != 0)
        modifiers |= AUIModifierFlagShift;
    if ((flags & NSEventModifierFlagControl) != 0)
        modifiers |= AUIModifierFlagControl;
    if ((flags & NSEventModifierFlagOption) != 0)
        modifiers |= AUIModifierFlagAlt;
    if ((flags & NSEventModifierFlagCommand) != 0)
        modifiers |= AUIModifierFlagCommand;

    return modifiers;
}

+ (AUIKey)keyFromEvent: (NSEvent *)event
{
    switch (event.keyCode) {
        case kVK_Return:
            return AUIKeyEnter;
        case kVK_Tab:
            return AUIKeyTab;
        case kVK_Delete:
            return AUIKeyBackspace;
        case kVK_ForwardDelete:
            return AUIKeyDelete;
        case kVK_Escape:
            return AUIKeyEscape;
        case kVK_LeftArrow:
            return AUIKeyLeft;
        case kVK_RightArrow:
            return AUIKeyRight;
        case kVK_DownArrow:
            return AUIKeyDown;
        case kVK_UpArrow:
            return AUIKeyUp;
        case kVK_Home:
            return AUIKeyHome;
        case kVK_End:
            return AUIKeyEnd;
        case kVK_PageUp:
            return AUIKeyPageUp;
        case kVK_PageDown:
            return AUIKeyPageDown;
        case kVK_ANSI_A:
            return AUIKeyA;
        case kVK_ANSI_C:
            return AUIKeyC;
        case kVK_ANSI_V:
            return AUIKeyV;
        case kVK_ANSI_X:
            return AUIKeyX;
        default:
            return AUIKeyUnknown;
    }
}

@end

[[subclassing_restricted]]
@interface AUICocoaRenderView : NSView {
@private
    unretained AUICocoaWindowBackend *_backend;
    NSTrackingArea *nillable _trackingArea;
    //TODO: decouple from cairo
    cairo_surface_t *nillable _imageSurface;
    cairo_t *nillable _imageContext;
    unsigned char *nillable _imageData;
    CGColorSpaceRef nillable _colorSpace;
    CGDataProviderRef nillable _dataProvider;
    CGImageRef nillable _image;
    size_t _stride;
    int _pixelWidth;
    int _pixelHeight;
}

- (instancetype)initWithBackend: (AUICocoaWindowBackend *)backend frame: (NSRect)frameRect;
- (void)disconnectBackend;
- (AUISize)pixelSize;
- (void)renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock;

@end

@implementation AUICocoaRenderView

- (instancetype)initWithBackend: (AUICocoaWindowBackend *)backend frame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    _backend = backend;
    _trackingArea = nilptr;
    _imageSurface = nullptr;
    _imageContext = nullptr;
    _imageData = nullptr;
    _colorSpace = nullptr;
    _dataProvider = nullptr;
    _image = nullptr;
    _stride = 0;
    _pixelWidth = 0;
    _pixelHeight = 0;
    return self;
}

- (void)disconnectBackend
{
    _backend = nilptr;
}

- (void)dealloc
{
    if (_trackingArea != nilptr) {
        [self removeTrackingArea: $assert_nonnil(_trackingArea)];
        _trackingArea = nilptr;
    }

    [self ui_discardBackingStore];
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstMouse: (NSEvent *nillable)event
{
    (void)event;
    return YES;
}

- (AUIApplication *nillable)ui_application
{
    return (_backend != nilptr ? _backend.application : nilptr);
}

- (void)setFrameSize: (NSSize)newSize
{
    AUIApplication *application;

    [super setFrameSize: newSize];
    application = self.ui_application;
    if (application != nilptr)
        [application setNeedsRender];
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];

    if (self.window != nilptr) {
        self.window.acceptsMouseMovedEvents = true;
        [self.window makeFirstResponder: self];
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];

    if (_trackingArea != nilptr)
        [self removeTrackingArea: $assert_nonnil(_trackingArea)];

    _trackingArea = [[NSTrackingArea alloc] initWithRect: NSZeroRect
                                                 options: NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited |
                                                          NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
                                                   owner: self
                                                userInfo: nilptr];
    [self addTrackingArea: $assert_nonnil(_trackingArea)];
}

- (void)viewDidChangeBackingProperties
{
    AUIApplication *application;

    [super viewDidChangeBackingProperties];
    application = self.ui_application;
    if (application != nilptr)
        [application setNeedsRender];
}

- (AUISize)pixelSize
{
    NSRect backingBounds = [self convertRectToBacking: self.bounds];
    return [AUI sizeWithWidth: (float)backingBounds.size.width height: (float)backingBounds.size.height];
}

- (NSPoint)ui_backingPointForEvent: (NSEvent *)event
{
    NSPoint point = [self convertPoint: event.locationInWindow fromView: nilptr];
    NSPoint backingPoint = [self convertPointToBacking: point];
    AUISize viewportSize = self.pixelSize;

    if (viewportSize.height > 0)
        backingPoint.y = viewportSize.height - backingPoint.y;

    return backingPoint;
}

- (void)ui_updatePointerForEvent: (NSEvent *)event
{
    AUIApplication *application;
    NSPoint point = [self ui_backingPointForEvent: event];

    application = self.ui_application;
    if (application == nilptr)
        return;

    [application._inputState movePointerToX: (float)point.x y: (float)point.y];
}

- (void)ui_handleKeyEvent: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;
    AUIKey key = [AUICocoaEventSupport keyFromEvent: event];
    AUIModifierFlags modifiers = [AUICocoaEventSupport modifierFlagsFromEvent: event];
    NSString *characters = event.characters;

    if (application == nilptr)
        return;

    AUIInputState *input = application._inputState;

    if (key != AUIKeyUnknown)
        [input addKey: key modifiers: modifiers repeat: event.isARepeat];

    if (characters.length > 0 and (modifiers & (AUIModifierFlagControl | AUIModifierFlagCommand)) == 0) {
        for (NSUInteger index = 0; index < characters.length; index++) {
            unichar codeUnit = [characters characterAtIndex: index];

            if (codeUnit < 0x20 or codeUnit == 0x7F)
                continue;

            [input appendCodepoint: (unsigned int)codeUnit];
        }
    }

    [application setNeedsRender];
}

- (void)ui_discardBackingStore
{
    if (_image != nullptr) {
        CGImageRelease(_image);
        _image = nullptr;
    }

    if (_dataProvider != nullptr) {
        CGDataProviderRelease(_dataProvider);
        _dataProvider = nullptr;
    }

    if (_colorSpace != nullptr) {
        CGColorSpaceRelease(_colorSpace);
        _colorSpace = nullptr;
    }

    if (_imageContext != nullptr) {
        cairo_destroy(_imageContext);
        _imageContext = nullptr;
    }

    if (_imageSurface != nullptr) {
        cairo_surface_destroy(_imageSurface);
        _imageSurface = nullptr;
    }

    if (_imageData != nullptr) {
        free(_imageData);
        _imageData = nullptr;
    }

    _stride = 0;
    _pixelWidth = 0;
    _pixelHeight = 0;
}

- (bool)ui_ensureBackingStore
{
    NSRect backingBounds = [self convertRectToBacking: self.bounds];
    int pixelWidth = (int)backingBounds.size.width;
    int pixelHeight = (int)backingBounds.size.height;
    int stride;
    CGBitmapInfo bitmapInfo;

    if (pixelWidth <= 0 or pixelHeight <= 0) {
        [self ui_discardBackingStore];
        return false;
    }

    if (_image != nullptr and pixelWidth == _pixelWidth and pixelHeight == _pixelHeight)
        return true;

    [self ui_discardBackingStore];

    stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, pixelWidth);
    if (stride <= 0)
        return false;

    _imageData = calloc((size_t)pixelHeight, (size_t)stride);
    if (_imageData == nullptr)
        return false;

    _imageSurface = cairo_image_surface_create_for_data(_imageData,
                                                        CAIRO_FORMAT_ARGB32,
                                                        pixelWidth,
                                                        pixelHeight,
                                                        stride);
    if (cairo_surface_status(_imageSurface) != CAIRO_STATUS_SUCCESS) {
        [self ui_discardBackingStore];
        return false;
    }

    _imageContext = cairo_create(_imageSurface);
    if (cairo_status(_imageContext) != CAIRO_STATUS_SUCCESS) {
        [self ui_discardBackingStore];
        return false;
    }

    _colorSpace = CGColorSpaceCreateDeviceRGB();
    if (_colorSpace == nullptr) {
        [self ui_discardBackingStore];
        return false;
    }

    _dataProvider = CGDataProviderCreateWithData(nullptr,
                                                 _imageData,
                                                 (size_t)stride * (size_t)pixelHeight,
                                                 nullptr);
    if (_dataProvider == nullptr) {
        [self ui_discardBackingStore];
        return false;
    }

    bitmapInfo = kCGBitmapByteOrder32Host | (CGBitmapInfo)kCGImageAlphaPremultipliedFirst;
    _image = CGImageCreate((size_t)pixelWidth,
                           (size_t)pixelHeight,
                           8,
                           32,
                           (size_t)stride,
                           _colorSpace,
                           bitmapInfo,
                           _dataProvider,
                           nullptr,
                           false,
                           kCGRenderingIntentDefault);
    if (_image == nullptr) {
        [self ui_discardBackingStore];
        return false;
    }

    _stride = (size_t)stride;
    _pixelWidth = pixelWidth;
    _pixelHeight = pixelHeight;
    return true;
}

- (void)renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock
{
    if (renderBlock == nilptr or not [self ui_ensureBackingStore] or _imageContext == nullptr)
        return;

    cairo_save($assert_nonnil(_imageContext));
    @try {
        cairo_reset_clip($assert_nonnil(_imageContext));
        cairo_identity_matrix($assert_nonnil(_imageContext));
        cairo_set_operator($assert_nonnil(_imageContext), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_imageContext), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_imageContext));
        renderBlock($assert_nonnil(_imageContext), self.pixelSize);
    } @finally {
        cairo_restore($assert_nonnil(_imageContext));
    }

    cairo_surface_flush($assert_nonnil(_imageSurface));
    self.needsDisplay = true;
}

- (void)mouseMoved: (NSEvent *)event
{
    AUIApplication *application;

    [self ui_updatePointerForEvent: event];
    application = self.ui_application;
    if (application != nilptr)
        [application setNeedsRender];
}

- (void)mouseDragged: (NSEvent *)event
{
    [self mouseMoved: event];
}

- (void)rightMouseDragged: (NSEvent *)event
{
    [self mouseMoved: event];
}

- (void)mouseDown: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;

    [self.window makeFirstResponder: self];
    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState pressMouseButton: AUIMouseButtonPrimary];
    [application setNeedsRender];
}

- (void)mouseUp: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState releaseMouseButton: AUIMouseButtonPrimary];
    [application setNeedsRender];
}

- (void)rightMouseDown: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;

    [self.window makeFirstResponder: self];
    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState pressMouseButton: AUIMouseButtonSecondary];
    [application setNeedsRender];
}

- (void)rightMouseUp: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState releaseMouseButton: AUIMouseButtonSecondary];
    [application setNeedsRender];
}

- (void)scrollWheel: (NSEvent *)event
{
    AUIApplication *application = self.ui_application;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState scrollByX: (float)event.scrollingDeltaX
                                     y: (float)event.scrollingDeltaY];
    [application setNeedsRender];
}

- (void)keyDown: (NSEvent *)event
{
    [self ui_handleKeyEvent: event];
}

- (void)drawRect: (NSRect)dirtyRect
{
    NSGraphicsContext *graphicsContext;
    CGContextRef cgContext;
    NSRect bounds;

    (void)dirtyRect;

    if (_image == nullptr)
        return;

    graphicsContext = NSGraphicsContext.currentContext;
    if (graphicsContext == nilptr)
        return;

    cgContext = graphicsContext.CGContext;
    if (cgContext == nullptr)
        return;

    bounds = self.bounds;
    CGContextSaveGState($as_nonnil(cgContext));
    CGContextSetInterpolationQuality($as_nonnil(cgContext), kCGInterpolationNone);
    CGContextTranslateCTM($as_nonnil(cgContext), 0.0, bounds.size.height);
    CGContextScaleCTM($as_nonnil(cgContext), 1.0, -1.0);
    CGContextDrawImage($as_nonnil(cgContext),
                       CGRectMake(0.0, 0.0, bounds.size.width, bounds.size.height),
                       $as_nonnil(_image));
    CGContextRestoreGState($as_nonnil(cgContext));
}

@end

@interface AUICocoaWindowBackend ()<NSWindowDelegate>
@end

[[subclassing_restricted]]
@interface AUICocoaApplicationDelegate : NSObject<NSApplicationDelegate>
@end

@namespace(AUICocoaApplicationSupport)

+ (void)configureSharedApplication: (NSApplication *nillable)application;
+ (void)promoteCurrentProcessToForeground;
+ (NSApplication *)ensureCocoaApplication;

@end

@namespace_implementation(AUICocoaApplicationSupport)

+ (void)configureSharedApplication: (NSApplication *nillable)application
{
    NSString *applicationName;
    NSString *emptyString = ((OFString *)@"").NSObject;
    NSString *appString = ((OFString *)@"App").NSObject;
    NSString *windowString = ((OFString *)@"Window").NSObject;
    NSString *minimizeString = ((OFString *)@"Minimize").NSObject;
    NSString *zoomString = ((OFString *)@"Zoom").NSObject;
    NSString *quitFormat = ((OFString *)@"Quit %@").NSObject;
    NSString *qString = ((OFString *)@"q").NSObject;
    NSString *mString = ((OFString *)@"m").NSObject;
    NSMenu *mainMenu;
    NSMenuItem *appMenuItem;
    NSMenu *appMenu;
    NSMenuItem *windowMenuItem;
    NSMenu *windowMenu;

    if (application == nilptr)
        return;

    [application setActivationPolicy: NSApplicationActivationPolicyRegular];
    if (application.mainMenu != nilptr)
        return;

    applicationName = NSProcessInfo.processInfo.processName;
    if (applicationName == nilptr)
        applicationName = appString;

    mainMenu = [[NSMenu alloc] initWithTitle: emptyString];

    appMenuItem = [[NSMenuItem alloc] initWithTitle: emptyString
                                             action: nullptr
                                      keyEquivalent: emptyString];
    [mainMenu addItem: appMenuItem];

    appMenu = [[NSMenu alloc] initWithTitle: applicationName];
    [appMenu addItemWithTitle: [NSString stringWithFormat: quitFormat, applicationName]
                       action: @selector(terminate:)
                keyEquivalent: qString];
    [appMenuItem setSubmenu: appMenu];

    windowMenuItem = [[NSMenuItem alloc] initWithTitle: windowString
                                                action: nullptr
                                         keyEquivalent: emptyString];
    [mainMenu addItem: windowMenuItem];

    windowMenu = [[NSMenu alloc] initWithTitle: windowString];
    [windowMenu addItemWithTitle: minimizeString
                          action: @selector(performMiniaturize:)
                   keyEquivalent: mString];
    [windowMenu addItemWithTitle: zoomString
                          action: @selector(performZoom:)
                   keyEquivalent: emptyString];
    [windowMenuItem setSubmenu: windowMenu];

    application.mainMenu = mainMenu;
    application.windowsMenu = windowMenu;
}

+ (void)promoteCurrentProcessToForeground
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ProcessSerialNumber processSerialNumber = {0, kCurrentProcess};

    if (TransformProcessType(&processSerialNumber, kProcessTransformToForegroundApplication) == noErr)
        SetFrontProcess(&processSerialNumber);
#pragma clang diagnostic pop
}

+ (NSApplication *)ensureCocoaApplication
{
    static bool prepared = false;
    static AUICocoaApplicationDelegate *delegate = nilptr;
    NSApplication *nillable application = NSApplication.sharedApplication;

    if (application == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create the shared NSApplication instance"];

    if (not prepared) {
        delegate = [[AUICocoaApplicationDelegate alloc] init];
        [self promoteCurrentProcessToForeground];
        application.delegate = delegate;
    }

    [self configureSharedApplication: application];

    if (not prepared) {
        [application finishLaunching];
        prepared = true;
    }

    return $assert_nonnil(application);
}

@end

@implementation AUICocoaApplicationDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
    NSApplication *nillable application = notification.object;

    if (application == nilptr)
        return;

    [AUICocoaApplicationSupport configureSharedApplication: application];
    [application activateIgnoringOtherApps: YES];
}

@end

@implementation AUICocoaWindowBackend {
    bool _open;
    NSWindow *nillable _window;
    AUICocoaRenderView *nillable _renderView;
    AUICursorStyle _cursorStyle;
}

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    self = [super initWithApplication: application options: options];
    _open = false;
    _window = nilptr;
    _renderView = nilptr;
    _cursorStyle = AUICursorStyleDefault;
    return self;
}

- (bool)isOpen
{
    return _open;
}

- (AUISize)viewportSize
{
    if (_renderView == nilptr)
        return self.options.initialSize;

    return $assert_nonnil(_renderView).pixelSize;
}

+ (bool)_prepareSharedApplicationForTesting
{
    (void)[AUICocoaApplicationSupport ensureCocoaApplication];
    return true;
}

+ (bool)_sharedApplicationIsForegroundForTesting
{
    NSRunningApplication *currentApplication = NSRunningApplication.currentApplication;

    return (currentApplication != nilptr and currentApplication.activationPolicy == NSApplicationActivationPolicyRegular);
}

+ (bool)_sharedApplicationIsActiveForTesting
{
    NSApplication *application = NSApplication.sharedApplication;

    return (application != nilptr and application.isActive);
}

+ (bool)_sharedApplicationHasMainMenuForTesting
{
    NSApplication *application = NSApplication.sharedApplication;

    return (application != nilptr and application.mainMenu != nilptr);
}

- (void)_performCloseForTesting
{
    [$assert_nonnil(_window) performClose: nilptr];
}

+ (size_t)_sharedApplicationWindowCountForTesting
{
    NSApplication *application = NSApplication.sharedApplication;

    return (application != nilptr ? application.windows.count : 0);
}

- (bool)_windowIsVisibleForTesting
{
    return (_window != nilptr and $assert_nonnil(_window).visible);
}

- (bool)_windowIsKeyForTesting
{
    return (_window != nilptr and $assert_nonnil(_window).keyWindow);
}

- (bool)_windowIsMainForTesting
{
    return (_window != nilptr and $assert_nonnil(_window).mainWindow);
}

- (bool)_renderViewIsFirstResponderForTesting
{
    return (_window != nilptr and _renderView != nilptr and [$assert_nonnil(_window).firstResponder isEqual: $assert_nonnil(_renderView)]);
}

+ (OFString *nillable)_roundTripBridgedStringForTesting: (OFString *nillable)string
{
    NSString *foundationString;

    if (string == nilptr)
        return nilptr;

    foundationString = $assert_nonnil(string).NSObject;
    return (foundationString != nilptr ? foundationString.OFObject : nilptr);
}

- (double)scaleFactor
{
    if (_window == nilptr)
        return 1.0;

    return $assert_nonnil(_window).backingScaleFactor;
}

- (void)ui_detachRenderView
{
    if (_renderView == nilptr)
        return;

    [$assert_nonnil(_renderView) disconnectBackend];
    [$assert_nonnil(_renderView) removeFromSuperview];
    _renderView = nilptr;
}

- (void)ui_activateWindow: (NSWindow *nillable)window application: (NSApplication *nillable)application
{
    NSRunningApplication *currentApplication;

    if (window == nilptr or application == nilptr)
        return;

    [AUICocoaApplicationSupport configureSharedApplication: $assert_nonnil(application)];
    currentApplication = NSRunningApplication.currentApplication;
    [application unhide: nilptr];
    [application activateIgnoringOtherApps: YES];
    if (currentApplication != nilptr)
        [currentApplication activateWithOptions: NSApplicationActivateIgnoringOtherApps | NSApplicationActivateAllWindows];
    [$assert_nonnil(window) makeKeyAndOrderFront: nilptr];
    [$assert_nonnil(window) orderFrontRegardless];
    [$assert_nonnil(window) makeMainWindow];
    if (_renderView != nilptr)
        [$assert_nonnil(window) makeFirstResponder: $assert_nonnil(_renderView)];
    [application updateWindows];
}

- (void)openWindow
{
    NSApplication *sharedApplication;
    NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
    NSRect frame;

    if (not NSThread.isMainThread)
        @throw [[AUIInitializationException alloc] initWithReason: @"AUICocoaWindowBackend must be used on the main thread"];

    sharedApplication = [AUICocoaApplicationSupport ensureCocoaApplication];

    if (_window != nilptr) {
        [self ui_activateWindow: $assert_nonnil(_window) application: sharedApplication];
        _open = true;
        return;
    }

    if (self.options.isResizable)
        styleMask |= NSWindowStyleMaskResizable;

    if ([NSWindow respondsToSelector: @selector(setAllowsAutomaticWindowTabbing:)])
        NSWindow.allowsAutomaticWindowTabbing = NO;

    frame = NSMakeRect(0.0, 0.0, self.options.initialSize.width, self.options.initialSize.height);
    _window = [[NSWindow alloc] initWithContentRect: frame
                                          styleMask: styleMask
                                            backing: NSBackingStoreBuffered
                                              defer: NO];
    if (_window == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create the Cocoa window"];

    {
        NSString *title = self.options.title.NSObject;
        NSString *fallbackTitle = ((OFString *)@"asyncrt UI").NSObject;

        _window.title = (title != nilptr ? title : fallbackTitle);
    }
    if ([_window respondsToSelector: @selector(setTabbingMode:)])
        _window.tabbingMode = NSWindowTabbingModeDisallowed;
    _window.delegate = self;
    _renderView = [[AUICocoaRenderView alloc] initWithBackend: self frame: _window.contentView.bounds];
    if (_renderView == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"Failed to create the Cocoa render view"];

    $assert_nonnil(_renderView).autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [$assert_nonnil(_window).contentView addSubview: $assert_nonnil(_renderView)];
    [_window center];
    _open = true;
    [self ui_activateWindow: $assert_nonnil(_window) application: sharedApplication];
}

- (void)pollEvents
{
    NSApplication *application = NSApplication.sharedApplication;

    if (application == nilptr)
        return;

    for (;;) {
        NSEvent *event = [application nextEventMatchingMask: NSEventMaskAny
                                                  untilDate: NSDate.distantPast
                                                     inMode: NSDefaultRunLoopMode
                                                    dequeue: YES];

        if (event == nilptr)
            break;

        [application sendEvent: event];
    }

    if (_open and _window != nilptr and application.active and (not [$assert_nonnil(_window) isKeyWindow] or not [$assert_nonnil(_window) isMainWindow]))
        [self ui_activateWindow: $assert_nonnil(_window) application: application];

    [application updateWindows];
}

- (void)closeWindow
{
    __unsafe_unretained NSWindow *window = _window;

    _open = false;
    [NSApplication.sharedApplication stop: nilptr];
    [self ui_detachRenderView];

    if (window != nilptr) {
        [$assert_nonnil(window) setDelegate: nilptr];
        if ([$assert_nonnil(window) isVisible] or [$assert_nonnil(window) isMiniaturized])
            [$assert_nonnil(window) close];
    }

    _window = nilptr;
}

- (void)windowWillClose: (NSNotification *)notification
{
    __unsafe_unretained NSWindow *closingWindow = notification.object;

    _open = false;
    [NSApplication.sharedApplication stop: nilptr];
    [self ui_detachRenderView];

    if (closingWindow != nilptr) {
        [$assert_nonnil(closingWindow) setDelegate: nilptr];
        if (_window == closingWindow)
            _window = nilptr;
    }
}

- (void)setCursorStyle: (AUICursorStyle)cursorStyle
{
    _cursorStyle = cursorStyle;

    switch (cursorStyle) {
        case AUICursorStylePointer:
            [NSCursor.pointingHandCursor set];
            break;
        case AUICursorStyleText:
            [NSCursor.IBeamCursor set];
            break;
        case AUICursorStyleDefault:
        default:
            [NSCursor.arrowCursor set];
            break;
    }
}

- (OFString *nillable)clipboardText
{
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    NSString *string = [pasteboard stringForType: NSPasteboardTypeString];

    if (string == nilptr)
        return nilptr;

    return string.OFObject;
}

- (void)setClipboardText: (OFString *nillable)text
{
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;

    [pasteboard clearContents];
    if (text != nilptr) {
        NSString *string = $assert_nonnil(text).NSObject;

        if (string != nilptr)
            [pasteboard setString: string forType: NSPasteboardTypeString];
    }
}

- (void)_renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock
{
    if (not _open or _renderView == nilptr)
        return;

    [$assert_nonnil(_renderView) renderFrameWithBlock: renderBlock];
    [_window displayIfNeeded];
}

@end

#pragma clang assume_nonnull end
