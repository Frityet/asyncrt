#if defined(__APPLE__)

#import <ObjFWBridge/ObjFWBridge.h>

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import <AsyncRT/Application/UI/Surface/Web/Platform/WKWebKit/View.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncWKWebKitJavaScriptEvaluationException : OFException

@property(readonly, copy, nonatomic) OFString *reason;
@property(readonly, copy, nonatomic) OFString *javaScript;

- (instancetype)initWithError: (NSError *)error
                   javaScript: (OFString *)javaScript [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWKWebKitScriptMessageHandler : NSObject<WKScriptMessageHandler>

- (instancetype)initWithView: (AsyncWKWebKitView *)view [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncWKWebKitWindowDelegate : NSObject<NSWindowDelegate>

- (instancetype)initWithView: (AsyncWKWebKitView *)view [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncWKWebKitApplicationDelegate : NSObject<NSApplicationDelegate>
@end

@namespace(AsyncWKWebKitApplicationSupport)

+ (NSApplication *)ensureSharedApplication;
+ (void)pollEventsForWindow: (NSWindow *nillable)window;
+ (OFString *)responseJSONForException: (OFException *)exception;

@end

@interface AsyncWKWebKitView ()

- (void)webKitWindowWillClose: (NSNotification *)notification;
- (void)webKitViewDidReceiveScriptMessage: (WKScriptMessage *)message;
- (WKUserScript *)_bridgeUserScript;

@end

@implementation AsyncWKWebKitJavaScriptEvaluationException

- (instancetype)initWithError: (NSError *)error
                   javaScript: (OFString *)javaScript
{
    self = [super init];

    OFString *localizedDescription = (OFString *)error.localizedDescription.OFObject;
    OFString *domain = (OFString *)error.domain.OFObject;
    OFString *userInfo = (OFString *)error.userInfo.description.OFObject;

    _reason = [[OFString stringWithFormat: @"JavaScript evaluation failed: %@ (domain=%@ code=%ld userInfo=%@)",
                                       localizedDescription,
                                       domain,
                                       (long)error.code,
                                       userInfo] copy];
    _javaScript = [javaScript copy];

    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"%@: %@\nJavaScript:\n%@",
                                      self.className,
                                      self.reason,
                                      self.javaScript];
}

@end

@implementation AsyncWKWebKitScriptMessageHandler {
    unretained AsyncWKWebKitView *_view;
}

- (instancetype)initWithView: (AsyncWKWebKitView *)view
{
    self = [super init];
    _view = view;
    return self;
}

- (void)userContentController: (WKUserContentController *)userContentController
      didReceiveScriptMessage: (WKScriptMessage *)message
{
    (void)userContentController;
    [_view webKitViewDidReceiveScriptMessage: message];
}

@end

@implementation AsyncWKWebKitWindowDelegate {
    unretained AsyncWKWebKitView *_view;
}

- (instancetype)initWithView: (AsyncWKWebKitView *)view
{
    self = [super init];
    _view = view;
    return self;
}

- (void)windowWillClose: (NSNotification *)notification
{
    [_view webKitWindowWillClose: notification];
}

@end

@implementation AsyncWKWebKitApplicationDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
    NSApplication *nillable application = notification.object;

    if (application != nilptr)
        [$assert_nonnil(application) activateIgnoringOtherApps: YES];
}

@end

@namespace_implementation(AsyncWKWebKitApplicationSupport)

+ (NSApplication *)ensureSharedApplication
{
    static bool prepared = false;
    static AsyncWKWebKitApplicationDelegate *delegate = nilptr;
    NSApplication *app = [NSApplication sharedApplication];
    if (not prepared) {
        delegate = [[AsyncWKWebKitApplicationDelegate alloc] init];
        app.delegate = delegate;
        app.activationPolicy = NSApplicationActivationPolicyRegular;

        if ([NSWindow respondsToSelector: @selector(setAllowsAutomaticWindowTabbing:)])
            NSWindow.allowsAutomaticWindowTabbing = NO;

        [app finishLaunching];
        prepared = true;
    }

    return app;
}

+ (void)pollEventsForWindow: (NSWindow *nillable)window
{
    NSApplication *application = NSApplication.sharedApplication;
    bool didProcessEvent = false;

    while (true) {
        NSEvent *event = [application nextEventMatchingMask: NSEventMaskAny
                                                                  untilDate: NSDate.distantPast
                                                                     inMode: NSDefaultRunLoopMode
                                                                    dequeue: YES];

        if (event == nilptr)
            break;

        [application sendEvent: $assert_nonnil(event)];
        didProcessEvent = true;
    }

    if (application.active and (not window.isKeyWindow or not window.isMainWindow)) {
        [window makeKeyAndOrderFront: nilptr];
        didProcessEvent = true;
    }

    if (didProcessEvent)
        [application updateWindows];
}

+ (OFString *)responseJSONForException: (OFException *)exception
{
    auto error = [OFMutableDictionary<OFString *, id> dictionary];
    [error setObject: exception.className forKey: @"className"];
    [error setObject: exception.description forKey: @"description"];
    [error makeImmutable];

    auto response = [OFMutableDictionary<OFString *, id> dictionary];
    [response setObject: error forKey: @"error"];
    [response makeImmutable];

    return response.JSONRepresentation;
}

@end

@implementation AsyncWKWebKitView {
    NSWindow *nillable _window;
    WKWebView *nillable _webView;
    AsyncWKWebKitScriptMessageHandler *nillable _scriptMessageHandler;
    AsyncWKWebKitWindowDelegate *nillable _windowDelegate;
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler
{
    self = [super initWithConfiguration: configuration scheduler: scheduler];

    NSApplication *sharedApplication = [AsyncWKWebKitApplicationSupport ensureSharedApplication];
    auto windowRect = NSMakeRect(0.0, 0.0, (CGFloat)configuration.initialWidth, (CGFloat)configuration.initialHeight);
    auto styleMask = (NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable);

    if (configuration.isResizable)
        styleMask |= NSWindowStyleMaskResizable;

    _window = [[NSWindow alloc] initWithContentRect: windowRect
                                         styleMask: styleMask
                                           backing: NSBackingStoreBuffered
                                             defer: NO];
    _window.title = configuration.title.NSObject;
    if ([_window respondsToSelector: @selector(setTabbingMode:)])
        _window.tabbingMode = NSWindowTabbingModeDisallowed;
    _windowDelegate = [[AsyncWKWebKitWindowDelegate alloc] initWithView: self];
    _window.delegate = _windowDelegate;
    [_window center];

    _scriptMessageHandler = [[AsyncWKWebKitScriptMessageHandler alloc] initWithView: self];

    WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
    [webConfiguration.userContentController addScriptMessageHandler: $assert_nonnil(_scriptMessageHandler)
                                                               name: ((OFString *)@"asyncrt").NSObject];
    [webConfiguration.userContentController addUserScript: [self _bridgeUserScript]];

    _webView = [[WKWebView alloc] initWithFrame: windowRect configuration: webConfiguration];
    _webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    _window.contentView = _webView;
    [_window makeKeyAndOrderFront: nilptr];
    [_window makeFirstResponder: _webView];
    [sharedApplication activateIgnoringOtherApps: YES];
    return self;
}

- (void)loadHTML: (OFString *)html
{
    [super loadHTML: html];
    [$assert_nonnil(_webView) loadHTMLString: html.NSObject baseURL: nilptr];
}

- (void)loadIRI: (OFIRI *)IRI
{
    [super loadIRI: IRI];

    NSURL *URL = [NSURL URLWithString: IRI.string.NSObject];
    if (URL == nilptr)
        @throw [OFInvalidArgumentException exception];

    [$assert_nonnil(_webView) loadRequest: [NSURLRequest requestWithURL: $assert_nonnil(URL)]];
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript
{
    auto completionSource = [[AsyncCompletionSource<AsyncUnit *> alloc] init];
    [$assert_nonnil(_webView) evaluateJavaScript: javaScript.NSObject
                               completionHandler: ^(id _Nullable result, NSError * _Nullable error) {
        (void)result;

        if (error != nilptr)
            [completionSource reject: [[AsyncWKWebKitJavaScriptEvaluationException alloc] initWithError: $assert_nonnil(error)
                                                                                            javaScript: javaScript]];
        else
            [completionSource fulfill: AsyncUnit.unit];
    }];
    return completionSource.task;
}

- (void)close
{
    [super close];

    if (_webView != nilptr) {
        [[$assert_nonnil(_webView) configuration].userContentController removeScriptMessageHandlerForName: ((OFString *)@"asyncrt").NSObject];
        _webView = nilptr;
    }

    if (_window != nilptr) {
        [$assert_nonnil(_window) close];
        _window = nilptr;
    }

    _windowDelegate = nilptr;
    _scriptMessageHandler = nilptr;
}

- (void)webKitWindowWillClose: (NSNotification *)notification
{
    (void)notification;

    [super close];
    _window = nilptr;
    _webView = nilptr;
    _windowDelegate = nilptr;
    _scriptMessageHandler = nilptr;
    [OFApplication.sharedApplication terminate];
}

- (void)pollEvents
{
    [AsyncWKWebKitApplicationSupport pollEventsForWindow: _window];
}

- (void)webKitViewDidReceiveScriptMessage: (WKScriptMessage *)message
{
    if (not [message.name isEqualToString: @"asyncrt".NSObject])
        return;
    if (not [message.body isKindOfClass: NSDictionary.class])
        return;

    auto dictionary = (NSDictionary *)message.body;
    id actionObject = dictionary[@"action".NSObject];
    id payloadObject = dictionary[@"payload".NSObject];
    id requestIDObject = dictionary[@"requestID".NSObject];

    if (not [actionObject isKindOfClass: NSString.class])
        return;
    if (not [requestIDObject isKindOfClass: NSString.class])
        return;

    OFString *action = ((NSString *)actionObject).OFObject;
    OFString *requestID = ((NSString *)requestIDObject).OFObject;
    OFString *payloadJSON = @"null";

    if ([payloadObject isKindOfClass: NSString.class])
        payloadJSON = (OFString *)((NSString *)payloadObject).OFObject;
    else if (payloadObject != nilptr and payloadObject != (id)NSNull.null)
        payloadJSON = (OFString *)((NSObject *)payloadObject).description.OFObject;

    AsyncWebUIRequest request = (AsyncWebUIRequest){
        .action = action,
        .payloadJSON = payloadJSON,
        .requestID = requestID
    };

    AsyncTask<id> *task = [[self taskToHandleRequest: request] recoverOnScheduler: self.scheduler
                                                                          handler: ^id(OFException *exception) {
        return [AsyncWKWebKitApplicationSupport responseJSONForException: exception];
    }];
    (void)[task mapOnScheduler: self.scheduler transform: ^id(OFString *responseJSON) {
        OFString *javaScript = [AsyncWebUIView javaScriptToResolveRequestID: requestID
                                                               responseJSON: responseJSON];
        (void)[self taskToEvaluateJavaScript: javaScript];
        return AsyncUnit.unit;
    }];
}

- (WKUserScript *)_bridgeUserScript
{
    OFString *source = @$raw(
        (() => {
            const bridge = window.AsyncRT || {};
            bridge.invoke = (action, payload) => new Promise((resolve) => {
                const requestID = Math.random().toString(36).slice(2) + Date.now().toString(36);
                const eventName = 'asyncrt_response_' + requestID;
                window.addEventListener(eventName, (event) => resolve(event.detail), { once: true });
                window.webkit.messageHandlers.asyncrt.postMessage({
                    action: String(action),
                    payload: payload === undefined ? null : JSON.stringify(payload),
                    requestID
                });
            });
            window.AsyncRT = bridge;
        })();
    );

    return [[WKUserScript alloc] initWithSource: source.NSObject
                                  injectionTime: WKUserScriptInjectionTimeAtDocumentStart
                               forMainFrameOnly: NO];
}

@end

#pragma clang assume_nonnull end

#endif
