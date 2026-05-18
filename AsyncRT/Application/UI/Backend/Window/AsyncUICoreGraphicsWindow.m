#if !defined(__APPLE__)
#   error This file is only supported on Apple platforms.
#endif

#import <ObjFWBridge/ObjFWBridge.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColorSpace.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSTrackingArea.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSThread.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>
#import <Carbon/Carbon.h>
#import <CoreGraphics/CoreGraphics.h>

#include <stdlib.h>

#import <AsyncRT/Application/UI/AsyncUIExceptions.h>
#import <AsyncRT/Application/UI/AsyncUIPrimitives.h>
#import <AsyncRT/Application/UI/Backend/AsyncUICoreGraphicsRenderSupport.h>
#import <AsyncRT/Application/UI/Backend/AsyncUIWindow+Private.h>
#import <AsyncRT/Application/UI/Backend/Window/AsyncUICoreGraphicsWindow.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIApplication+Private.h>


#pragma clang assume_nonnull begin

@namespace(AsyncUICocoaEventSupport)

+ (AsyncUIModifierFlags)modifierFlagsFromEvent: (NSEvent *)event;
+ (AsyncUIKey)keyFromEvent: (NSEvent *)event;

@end

@namespace_implementation(AsyncUICocoaEventSupport)

+ (AsyncUIModifierFlags)modifierFlagsFromEvent: (NSEvent *)event
{
    NSEventModifierFlags flags = event.modifierFlags;
    AsyncUIModifierFlags modifiers = AsyncUIModifierFlagNone;

    if ((flags & NSEventModifierFlagShift) != 0)
        modifiers |= AsyncUIModifierFlagShift;
    if ((flags & NSEventModifierFlagControl) != 0)
        modifiers |= AsyncUIModifierFlagControl;
    if ((flags & NSEventModifierFlagOption) != 0)
        modifiers |= AsyncUIModifierFlagAlt;
    if ((flags & NSEventModifierFlagCommand) != 0)
        modifiers |= AsyncUIModifierFlagCommand;

    return modifiers;
}

+ (AsyncUIKey)keyFromEvent: (NSEvent *)event
{
    switch (event.keyCode) {
        case kVK_Return:
            return AsyncUIKeyEnter;
        case kVK_Tab:
            return AsyncUIKeyTab;
        case kVK_Delete:
            return AsyncUIKeyBackspace;
        case kVK_ForwardDelete:
            return AsyncUIKeyDelete;
        case kVK_Escape:
            return AsyncUIKeyEscape;
        case kVK_LeftArrow:
            return AsyncUIKeyLeft;
        case kVK_RightArrow:
            return AsyncUIKeyRight;
        case kVK_DownArrow:
            return AsyncUIKeyDown;
        case kVK_UpArrow:
            return AsyncUIKeyUp;
        case kVK_Home:
            return AsyncUIKeyHome;
        case kVK_End:
            return AsyncUIKeyEnd;
        case kVK_PageUp:
            return AsyncUIKeyPageUp;
        case kVK_PageDown:
            return AsyncUIKeyPageDown;
        case kVK_ANSI_A:
            return AsyncUIKeyA;
        case kVK_ANSI_C:
            return AsyncUIKeyC;
        case kVK_ANSI_V:
            return AsyncUIKeyV;
        case kVK_ANSI_X:
            return AsyncUIKeyX;
        default:
            return AsyncUIKeyUnknown;
    }
}

@end

@protocol AsyncUINativeWindowDelegate <NSObject>

- (void)nativeWindowWillClose: (NSWindow *)window;
- (void)nativeWindowDidBecomeKey: (NSWindow *)window;
- (void)nativeWindowDidBecomeMain: (NSWindow *)window;

@end

[[subclassing_restricted]]
@interface AsyncUICoreGraphicsNativeWindow : NSWindow<NSWindowDelegate>

@property(nonatomic, assign) id<AsyncUINativeWindowDelegate> nillable windowDelegate;

@end

@implementation AsyncUICoreGraphicsNativeWindow {
    unretained id<AsyncUINativeWindowDelegate> nillable _windowDelegate;
}

@synthesize windowDelegate = _windowDelegate;

- (instancetype)initWithContentRect: (NSRect)contentRect
                          styleMask: (NSWindowStyleMask)style
                            backing: (NSBackingStoreType)bufferingType
                              defer: (BOOL)flag
{
    self = [super initWithContentRect: contentRect
                            styleMask: style
                              backing: bufferingType
                                defer: flag];
    if (self == nilptr)
        return nilptr;

    self.delegate = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.releasedWhenClosed = NO;
#pragma clang diagnostic pop
    return self;
}

- (void)windowWillClose: (NSNotification *)notification
{
    (void)notification;

    if (_windowDelegate != nilptr)
        [$assert_nonnil(_windowDelegate) nativeWindowWillClose: self];
}

- (void)windowDidBecomeKey: (NSNotification *)notification
{
    (void)notification;

    if (_windowDelegate != nilptr)
        [$assert_nonnil(_windowDelegate) nativeWindowDidBecomeKey: self];
}

- (void)windowDidBecomeMain: (NSNotification *)notification
{
    (void)notification;

    if (_windowDelegate != nilptr)
        [$assert_nonnil(_windowDelegate) nativeWindowDidBecomeMain: self];
}

@end

[[subclassing_restricted]]
@interface AsyncUICoreGraphicsRenderView : NSView {
@private
    unretained AsyncUICoreGraphicsWindow *_backend;
    NSTrackingArea *nillable _trackingArea;
    CGContextRef nillable _bitmapContext;
    unsigned char *nillable _imageData;
    CGColorSpaceRef nillable _colorSpace;
    CGImageRef nillable _image;
    size_t _stride;
    int _pixelWidth;
    int _pixelHeight;
}

- (instancetype)initWithBackend: (AsyncUICoreGraphicsWindow *)backend frame: (NSRect)frameRect;
- (void)disconnectBackend;
- (AsyncUISize)viewportSize;
- (AsyncUISize)pixelSize;
- (NSPoint)ui_renderPointForViewPoint: (NSPoint)point;
- (NSPoint)ui_renderPointForEvent: (NSEvent *)event;
- (CGFloat)ui_contentsScale;
- (void)ui_updateLayerConfiguration;
- (void)ui_takeInputFocus;
- (void)renderFrameWithBlock: (void (^)(CGContextRef context, AsyncUISize viewportSize))renderBlock;

@end

@implementation AsyncUICoreGraphicsRenderView

- (instancetype)initWithBackend: (AsyncUICoreGraphicsWindow *)backend frame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    _backend = backend;
    _trackingArea = nilptr;
    _bitmapContext = nullptr;
    _imageData = nullptr;
    _colorSpace = nullptr;
    _image = nullptr;
    _stride = 0;
    _pixelWidth = 0;
    _pixelHeight = 0;
    self.wantsLayer = YES;
    [self ui_updateLayerConfiguration];
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

- (AsyncUIApplication *nillable)ui_application
{
    return (_backend != nilptr ? _backend.application : nilptr);
}

- (void)setFrameSize: (NSSize)newSize
{
    AsyncUIApplication *application;

    super.frameSize = newSize;
    application = self.ui_application;
    if (application != nilptr)
        [application setNeedsRender];
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    [self ui_updateLayerConfiguration];
    [self ui_takeInputFocus];
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
    AsyncUIApplication *application;

    [super viewDidChangeBackingProperties];
    [self ui_updateLayerConfiguration];
    application = self.ui_application;
    if (application != nilptr)
        [application setNeedsRender];
}

- (AsyncUISize)viewportSize
{
    if (_backend == nilptr)
        return [AsyncUI sizeWithWidth: (float)self.bounds.size.width
                           height: (float)self.bounds.size.height];

    const AsyncUISize nativeSize = [AsyncUI sizeWithWidth: (float)self.bounds.size.width
                                           height: (float)self.bounds.size.height];
    return [$assert_nonnil(_backend) _viewportSizeForNativeSize: nativeSize];
}

- (AsyncUISize)pixelSize
{
    NSRect backingBounds = [self convertRectToBacking: self.bounds];
    return [AsyncUI sizeWithWidth: (float)backingBounds.size.width height: (float)backingBounds.size.height];
}

- (NSPoint)ui_renderPointForViewPoint: (NSPoint)point
{
    AsyncUISize nativeSize = [AsyncUI sizeWithWidth: (float)self.bounds.size.width
                                     height: (float)self.bounds.size.height];
    AsyncUISize viewportSize = self.viewportSize;
    CGFloat viewportX = point.x;
    CGFloat viewportY = point.y;

    if (nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportX = point.x * (CGFloat)viewportSize.width / (CGFloat)nativeSize.width;
    if (nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportY = point.y * (CGFloat)viewportSize.height / (CGFloat)nativeSize.height;

    return NSMakePoint(viewportX, viewportY);
}

- (NSPoint)ui_renderPointForEvent: (NSEvent *)event
{
    NSPoint point = [self convertPoint: event.locationInWindow fromView: nilptr];

    return [self ui_renderPointForViewPoint: point];
}

- (CGFloat)ui_contentsScale
{
    CGFloat contentsScale = (self.window != nilptr
        ? self.window.backingScaleFactor
        : [NSScreen mainScreen].backingScaleFactor);

    if (contentsScale <= 0.0)
        return 1.0;

    return contentsScale;
}

- (void)ui_takeInputFocus
{
    if (self.window != nilptr) {
        self.window.acceptsMouseMovedEvents = true;
        [self.window makeFirstResponder: self];
    }
}

- (void)ui_updateLayerConfiguration
{
    CALayer *layer = self.layer;

    if (layer == nilptr)
        return;

    layer.opaque = YES;
    layer.contentsGravity = kCAGravityResize;
    layer.contentsScale = self.ui_contentsScale;
    layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
}

- (void)ui_updatePointerForEvent: (NSEvent *)event
{
    AsyncUIApplication *application;
    NSPoint point = [self ui_renderPointForEvent: event];

    application = self.ui_application;
    if (application == nilptr)
        return;

    [application._inputState movePointerToX: (float)point.x y: (float)point.y];
}

- (void)ui_handleKeyEvent: (NSEvent *)event
{
    AsyncUIApplication *application = self.ui_application;
    AsyncUIKey key = [AsyncUICocoaEventSupport keyFromEvent: event];
    AsyncUIModifierFlags modifiers = [AsyncUICocoaEventSupport modifierFlagsFromEvent: event];
    NSString *characters = event.characters;

    if (application == nilptr)
        return;

    AsyncUIInputState *input = application._inputState;

    if (key != AsyncUIKeyUnknown)
        [input addKey: key modifiers: modifiers repeat: event.isARepeat];

    if (characters.length > 0 and (modifiers & (AsyncUIModifierFlagControl | AsyncUIModifierFlagCommand)) == 0) {
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

    if (self.layer != nilptr)
        self.layer.contents = nilptr;

    if (_colorSpace != nullptr) {
        CGColorSpaceRelease(_colorSpace);
        _colorSpace = nullptr;
    }

    if (_bitmapContext != nullptr) {
        CGContextRelease(_bitmapContext);
        _bitmapContext = nullptr;
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
    CGBitmapInfo bitmapInfo;

    if (pixelWidth <= 0 or pixelHeight <= 0) {
        [self ui_discardBackingStore];
        return false;
    }

    if (_bitmapContext != nullptr and pixelWidth == _pixelWidth and pixelHeight == _pixelHeight)
        return true;

    [self ui_discardBackingStore];

    _stride = ((size_t)pixelWidth * 4u + 15u) & ~(size_t)15u;
    if (_stride == 0)
        return false;

    _imageData = calloc((size_t)pixelHeight, _stride);
    if (_imageData == nullptr)
        return false;

    _colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    if (_colorSpace == nullptr) {
        [self ui_discardBackingStore];
        return false;
    }

    bitmapInfo = kCGBitmapByteOrder32Host | (CGBitmapInfo)kCGImageAlphaPremultipliedFirst;
    _bitmapContext = CGBitmapContextCreate(_imageData,
                                           (size_t)pixelWidth,
                                           (size_t)pixelHeight,
                                           8,
                                           _stride,
                                           _colorSpace,
                                           bitmapInfo);
    if (_bitmapContext == nullptr) {
        [self ui_discardBackingStore];
        return false;
    }

    _pixelWidth = pixelWidth;
    _pixelHeight = pixelHeight;
    return true;
}

- (void)renderFrameWithBlock: (void (^)(CGContextRef context, AsyncUISize viewportSize))renderBlock
{
    if (renderBlock == nilptr or not [self ui_ensureBackingStore] or _bitmapContext == nullptr)
        return;

    const AsyncUISize pixelSize = self.pixelSize;
    const AsyncUISize viewportSize = self.viewportSize;
    const CGFloat scaleX = (viewportSize.width > 0.0f ? (CGFloat)pixelSize.width / (CGFloat)viewportSize.width : self.ui_contentsScale);
    const CGFloat scaleY = (viewportSize.height > 0.0f ? (CGFloat)pixelSize.height / (CGFloat)viewportSize.height : self.ui_contentsScale);
    CGContextSaveGState($assert_nonnil(_bitmapContext));
    @try {
        CGContextResetClip($assert_nonnil(_bitmapContext));
        CGContextSetBlendMode($assert_nonnil(_bitmapContext), kCGBlendModeCopy);
        CGContextClearRect($assert_nonnil(_bitmapContext),
                           CGRectMake(0.0, 0.0, pixelSize.width, pixelSize.height));
        CGContextSetBlendMode($assert_nonnil(_bitmapContext), kCGBlendModeNormal);
        CGContextTranslateCTM($assert_nonnil(_bitmapContext), 0.0, pixelSize.height);
        CGContextScaleCTM($assert_nonnil(_bitmapContext), scaleX, -scaleY);
        renderBlock($assert_nonnil(_bitmapContext), viewportSize);
    } @finally {
        CGContextRestoreGState($assert_nonnil(_bitmapContext));
    }

    if (_image != nullptr) {
        CGImageRelease(_image);
        _image = nullptr;
    }

    _image = CGBitmapContextCreateImage($assert_nonnil(_bitmapContext));
    [self ui_updateLayerConfiguration];
    if (self.layer != nilptr)
        self.layer.contents = (__bridge id)$assert_nonnil(_image);
    else
        self.needsDisplay = true;
}

- (void)mouseMoved: (NSEvent *)event
{
    AsyncUIApplication *application;

    [self ui_updatePointerForEvent: event];
    application = self.ui_application;
    if (application != nilptr and [application _updateHoverStateFromCurrentLayout])
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
    AsyncUIApplication *application = self.ui_application;

    [self.window makeFirstResponder: self];
    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState pressMouseButton: AsyncUIMouseButtonPrimary];
    [application setNeedsRender];
}

- (void)mouseUp: (NSEvent *)event
{
    AsyncUIApplication *application = self.ui_application;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState releaseMouseButton: AsyncUIMouseButtonPrimary];
    [application setNeedsRender];
}

- (void)rightMouseDown: (NSEvent *)event
{
    AsyncUIApplication *application = self.ui_application;

    [self.window makeFirstResponder: self];
    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState pressMouseButton: AsyncUIMouseButtonSecondary];
    [application setNeedsRender];
}

- (void)rightMouseUp: (NSEvent *)event
{
    AsyncUIApplication *application = self.ui_application;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    [application._inputState releaseMouseButton: AsyncUIMouseButtonSecondary];
    [application setNeedsRender];
}

- (void)scrollWheel: (NSEvent *)event
{
    AsyncUIApplication *application = self.ui_application;
    AsyncUISize nativeSize = [AsyncUI sizeWithWidth: (float)self.bounds.size.width
                                     height: (float)self.bounds.size.height];
    AsyncUISize viewportSize = self.viewportSize;
    float viewportDeltaX = (float)event.scrollingDeltaX;
    float viewportDeltaY = (float)event.scrollingDeltaY;

    [self ui_updatePointerForEvent: event];
    if (application == nilptr)
        return;

    if (nativeSize.width > 0.0f and viewportSize.width > 0.0f)
        viewportDeltaX *= viewportSize.width / nativeSize.width;
    if (nativeSize.height > 0.0f and viewportSize.height > 0.0f)
        viewportDeltaY *= viewportSize.height / nativeSize.height;

    [application._inputState scrollByX: viewportDeltaX
                                     y: viewportDeltaY];
    [application setNeedsRender];
}

- (void)keyDown: (NSEvent *)event
{
    [self ui_handleKeyEvent: event];
}

- (void)drawRect: (NSRect)dirtyRect
{
    (void)dirtyRect;

    if (_image == nullptr)
        return;

    NSGraphicsContext *graphicsContext = NSGraphicsContext.currentContext;
    if (graphicsContext == nilptr)
        return;

    CGContextRef cgContext = graphicsContext.CGContext;
    if (cgContext == nullptr)
        return;

    const NSRect bounds = self.bounds;
    // Clay leaves uncovered regions transparent, so the native view must
    // paint the window background before compositing the bitmap.
    [NSColor.windowBackgroundColor setFill];
    NSRectFill(bounds);

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

[[direct_members]]
@interface AsyncUICoreGraphicsWindow ()<AsyncUINativeWindowDelegate>

- (bool)ui_systemUsesDarkModeForApplication: (NSApplication *nillable)application;
- (void)ui_applyAppearance;
- (bool)ui_shouldCoalesceEvent: (NSEvent *)event;
- (void)ui_dispatchEvent: (NSEvent *nillable)event
                 onApplication: (NSApplication *nillable)application
               didProcessEvent: (bool *)didProcessEvent;

@end

[[subclassing_restricted]]
@interface AsyncUICocoaApplicationDelegate : NSObject<NSApplicationDelegate>
@end

@namespace(AsyncUICocoaApplicationSupport)

+ (void)configureSharedApplication: (NSApplication *nillable)application;
+ (void)promoteCurrentProcessToForeground;
+ (NSApplication *)ensureCocoaApplication;

@end

@namespace_implementation(AsyncUICocoaApplicationSupport)

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

    application.activationPolicy = NSApplicationActivationPolicyRegular;
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
    appMenuItem.submenu = appMenu;

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
    windowMenuItem.submenu = windowMenu;

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
    static AsyncUICocoaApplicationDelegate *delegate = nilptr;
    NSApplication *nillable application = NSApplication.sharedApplication;

    if (application == nilptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create the shared NSApplication instance"];

    if (not prepared) {
        delegate = [[AsyncUICocoaApplicationDelegate alloc] init];
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

@implementation AsyncUICocoaApplicationDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
    NSApplication *nillable application = notification.object;

    if (application == nilptr)
        return;

    [AsyncUICocoaApplicationSupport configureSharedApplication: application];
    [application activateIgnoringOtherApps: YES];
}

@end

[[direct_members]]
@implementation AsyncUICoreGraphicsWindow {
    bool _open;
    AsyncUICoreGraphicsNativeWindow *nillable _window;
    AsyncUICoreGraphicsRenderView *nillable _renderView;
    AsyncUICursorStyle _cursorStyle;
}

- (instancetype)initWithApplication: (AsyncUIApplication *nonnil)application
                      configuration: (AsyncUIWindowConfiguration *nonnil)configuration
{
    self = [super initWithApplication: application configuration: configuration];
    _open = false;
    _window = nilptr;
    _renderView = nilptr;
    _cursorStyle = AsyncUICursorStyleDefault;
    return self;
}

- (bool)isOpen
{
    return _open;
}

- (AsyncUISize)viewportSize
{
    if (_renderView == nilptr)
        return [self _viewportSizeForNativeSize: self.configuration.initialSize];

    return $assert_nonnil(_renderView).viewportSize;
}

+ (bool)_prepareSharedApplicationForTesting
{
    (void)[AsyncUICocoaApplicationSupport ensureCocoaApplication];
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

- (bool)ui_systemUsesDarkModeForApplication: (NSApplication *nillable)application
{
    NSString *nillable appearanceName = nilptr;

    if (application == nilptr)
        return false;

    appearanceName = [$assert_nonnil(application).effectiveAppearance bestMatchFromAppearancesWithNames:
        [NSArray arrayWithObjects:
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua,
            nil]];

    return (appearanceName != nilptr and [$assert_nonnil(appearanceName) isEqualToString: NSAppearanceNameDarkAqua]);
}

- (void)ui_applyAppearance
{
    NSString *appearanceName = (self.isDarkMode ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua);
    NSAppearance *nillable appearance = [NSAppearance appearanceNamed: appearanceName];

    if (_window != nilptr)
        $assert_nonnil(_window).appearance = appearance;
    if (_renderView != nilptr)
        $assert_nonnil(_renderView).appearance = appearance;
}

- (void)ui_detachRenderViewFromWindow: (AsyncUICoreGraphicsNativeWindow *nillable)window
{
    if (_renderView == nilptr)
        return;

    if (window != nilptr and [$assert_nonnil(window) firstResponder] == $assert_nonnil(_renderView))
        [$assert_nonnil(window) makeFirstResponder: nilptr];

    [$assert_nonnil(_renderView) disconnectBackend];
    [$assert_nonnil(_renderView) removeFromSuperview];
    _renderView = nilptr;
}

- (void)ui_activateWindow: (AsyncUICoreGraphicsNativeWindow *nillable)window application: (NSApplication *nillable)application
{
    NSRunningApplication *currentApplication;

    if (window == nilptr or application == nilptr)
        return;

    [AsyncUICocoaApplicationSupport configureSharedApplication: $assert_nonnil(application)];
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

- (bool)ui_shouldCoalesceEvent: (NSEvent *)event
{
    switch (event.type) {
        case NSEventTypeMouseMoved:
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeRightMouseDragged:
        case NSEventTypeOtherMouseDragged:
            return true;
        default:
            return false;
    }
}

- (void)ui_dispatchEvent: (NSEvent *nillable)event
                 onApplication: (NSApplication *nillable)application
               didProcessEvent: (bool *)didProcessEvent
{
    if (event == nilptr or application == nilptr)
        return;

    [$assert_nonnil(application) sendEvent: $assert_nonnil(event)];
    *didProcessEvent = true;
}

- (void)ui_updateTestingPointerForViewX: (float)x y: (float)y
{
    if (_renderView == nilptr)
        return;

    NSPoint point = [$assert_nonnil(_renderView) ui_renderPointForViewPoint: NSMakePoint((CGFloat)x, (CGFloat)y)];

    [self.application._inputState movePointerToX: (float)point.x y: (float)point.y];
}

- (void)_sendPointerMoveForTestingWithViewX: (float)x y: (float)y
{
    [self ui_updateTestingPointerForViewX: x y: y];
    [self.application setNeedsRender];
}

- (void)_sendMouseDownForTestingWithViewX: (float)x y: (float)y
{
    if (_window != nilptr and _renderView != nilptr)
        [$assert_nonnil(_window) makeFirstResponder: $assert_nonnil(_renderView)];

    [self ui_updateTestingPointerForViewX: x y: y];
    [self.application._inputState pressMouseButton: AsyncUIMouseButtonPrimary];
    [self.application setNeedsRender];
}

- (void)_sendMouseUpForTestingWithViewX: (float)x y: (float)y
{
    [self ui_updateTestingPointerForViewX: x y: y];
    [self.application._inputState releaseMouseButton: AsyncUIMouseButtonPrimary];
    [self.application setNeedsRender];
}

- (void)ui_finishClosingWindow: (AsyncUICoreGraphicsNativeWindow *nillable)window
               performNativeClose: (bool)performNativeClose
{
    if (window == nilptr)
        return;

    [self ui_detachRenderViewFromWindow: $assert_nonnil(window)];
    $assert_nonnil(window).windowDelegate = nilptr;

    if (_window == window)
        _window = nilptr;

    if (performNativeClose) {
        [$assert_nonnil(window) orderOut: nilptr];
        [$assert_nonnil(window) close];
    }
}

- (void)openWindow
{
    NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;

    if (not NSThread.isMainThread)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"AsyncUICoreGraphicsWindow must be used on the main thread"];

    NSApplication *sharedApplication = [AsyncUICocoaApplicationSupport ensureCocoaApplication];
    if (not self._hasExplicitDarkMode)
        [self _setDarkMode: [self ui_systemUsesDarkModeForApplication: sharedApplication] explicitly: false];

    if (_window != nilptr) {
        [self ui_applyAppearance];
        [self ui_activateWindow: $assert_nonnil(_window) application: sharedApplication];
        _open = true;
        return;
    }

    if (self.configuration.isResizable)
        styleMask |= NSWindowStyleMaskResizable;

    if ([NSWindow respondsToSelector: @selector(setAllowsAutomaticWindowTabbing:)])
        NSWindow.allowsAutomaticWindowTabbing = NO;

    const NSRect frame = NSMakeRect(0.0, 0.0, self.configuration.initialSize.width, self.configuration.initialSize.height);
    _window = [[AsyncUICoreGraphicsNativeWindow alloc] initWithContentRect: frame
                                                             styleMask: styleMask
                                                               backing: NSBackingStoreBuffered
                                                                 defer: NO];
    if (_window == nilptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create the CoreGraphics window"];

    _window.colorSpace = [NSColorSpace sRGBColorSpace];

    {
        NSString *title = self.configuration.title.NSObject;
        NSString *fallbackTitle = ((OFString *)@"asyncrt UI").NSObject;

        _window.title = (title != nilptr ? title : fallbackTitle);
    }
    if ([_window respondsToSelector: @selector(setTabbingMode:)])
        _window.tabbingMode = NSWindowTabbingModeDisallowed;
    _window.windowDelegate = self;
    _renderView = [[AsyncUICoreGraphicsRenderView alloc] initWithBackend: self frame: _window.contentView.bounds];
    if (_renderView == nilptr)
        @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to create the CoreGraphics render view"];

    $assert_nonnil(_renderView).autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [$assert_nonnil(_window).contentView addSubview: $assert_nonnil(_renderView)];
    [self ui_applyAppearance];
    [_window center];
    _open = true;
    [self ui_activateWindow: $assert_nonnil(_window) application: sharedApplication];
}

- (void)pollEvents
{
    NSApplication *application = NSApplication.sharedApplication;
    bool didProcessEvent = false;
    NSEvent *nillable pendingMotionEvent = nilptr;

    if (application == nilptr)
        return;

    for (;;) {
        NSEvent *event = [application nextEventMatchingMask: NSEventMaskAny
                                                  untilDate: NSDate.distantPast
                                                     inMode: NSDefaultRunLoopMode
                                                    dequeue: YES];

        if (event == nilptr)
            break;

        if ([self ui_shouldCoalesceEvent: event]) {
            pendingMotionEvent = event;
            continue;
        }

        if (pendingMotionEvent != nilptr) {
            [self ui_dispatchEvent: pendingMotionEvent
                     onApplication: application
                   didProcessEvent: &didProcessEvent];
            pendingMotionEvent = nilptr;
        }

        [self ui_dispatchEvent: event
                 onApplication: application
               didProcessEvent: &didProcessEvent];
    }

    if (pendingMotionEvent != nilptr)
        [self ui_dispatchEvent: pendingMotionEvent onApplication: application didProcessEvent: &didProcessEvent];

    if (_open and _window != nilptr and application.active and (not [$assert_nonnil(_window) isKeyWindow] or not [$assert_nonnil(_window) isMainWindow])) {
        [self ui_activateWindow: $assert_nonnil(_window) application: application];
        didProcessEvent = true;
    }

    if (didProcessEvent and not [self.application _hasPendingRenderRequest])
        [application updateWindows];
}

- (void)closeWindow
{
    AsyncUICoreGraphicsNativeWindow *window = _window;

    _open = false;
    [NSApplication.sharedApplication stop: nilptr];
    [self ui_finishClosingWindow: window performNativeClose: true];
}

- (void)nativeWindowWillClose: (NSWindow *)window
{
    _open = false;
    [NSApplication.sharedApplication stop: nilptr];

    [self ui_finishClosingWindow: (AsyncUICoreGraphicsNativeWindow *)window performNativeClose: false];
}

- (void)nativeWindowDidBecomeKey: (NSWindow *)window
{
    if (_renderView != nilptr and _window != nilptr and window == $assert_nonnil(_window))
        [$assert_nonnil(_renderView) ui_takeInputFocus];
}

- (void)nativeWindowDidBecomeMain: (NSWindow *)window
{
    [self nativeWindowDidBecomeKey: window];
}

- (void)_setViewportSize: (AsyncUISize)viewportSize
{
    [super _setViewportSize: viewportSize];
    if (_window == nilptr)
        return;

    const AsyncUISize nativeSize = [self _nativeSizeForViewportSize: viewportSize];
    _window.contentSize = NSMakeSize((CGFloat)nativeSize.width, (CGFloat)nativeSize.height);
    if (_renderView != nilptr)
        _renderView.frame = _window.contentView.bounds;
}

- (void)setDarkMode: (bool)darkMode
{
    super.isDarkMode = darkMode;
    [self ui_applyAppearance];
}

- (void)setCursorStyle: (AsyncUICursorStyle)cursorStyle
{
    if (_cursorStyle == cursorStyle)
        return;

    _cursorStyle = cursorStyle;

    switch (cursorStyle) {
        case AsyncUICursorStylePointer:
            [NSCursor.pointingHandCursor set];
            break;
        case AsyncUICursorStyleText:
            [NSCursor.IBeamCursor set];
            break;
        case AsyncUICursorStyleDefault:
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

- (void)renderFrame
{
    if (not _open or _renderView == nilptr)
        return;

    [$assert_nonnil(_renderView) renderFrameWithBlock: ^(CGContextRef context, AsyncUISize viewportSize) {
        AsyncUICoreGraphicsTextMeasureContext measureContext = {
            .fontFamilies = nullptr
        };
        Clay_RenderCommandArray commands = [self _buildRenderCommandsForViewportSize: viewportSize
                                                                 textMeasureFunction: AsyncUICoreGraphicsMeasureText
                                                                            userData: &measureContext];

        [AsyncUICoreGraphicsRenderSupport renderCommands: commands
                                           onContext: context
                                        viewportSize: viewportSize
                                        fontFamilies: nullptr];
    }];
    if ($assert_nonnil(_renderView).layer != nilptr)
        [CATransaction flush];
    else
        [$assert_nonnil(_renderView) displayIfNeeded];
}

@end

#pragma clang assume_nonnull end
