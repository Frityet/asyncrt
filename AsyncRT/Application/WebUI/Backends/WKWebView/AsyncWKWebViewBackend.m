#if defined(__APPLE__)
#import <ObjFWBridge/ObjFWBridge.h>
#import <WebKit/WebKit.h>
#import <AppKit/AppKit.h>

#import "AsyncWKWebViewBackend.h"

@interface AsyncWKWebViewBackend () <WKScriptMessageHandler, NSWindowDelegate>
@end

@implementation AsyncWKWebViewBackend {
    NSWindow *_window;
    WKWebView *_webView;
    OFMutableDictionary<OFString *, AsyncWebUIActionHandler> *_actionHandlers;
}

- (instancetype)initWithConfiguration:(AsyncWebUIWindowConfiguration *)configuration scheduler:(AsyncScheduler *)scheduler {
    self = [super initWithConfiguration:configuration scheduler:scheduler];
    if (self) {
        _actionHandlers = [OFMutableDictionary dictionary];

        if (NSApplication.sharedApplication == nil) {
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        }

        NSRect windowRect = NSMakeRect(0, 0, configuration.width, configuration.height);
        NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
        if (configuration.resizable) {
            styleMask |= NSWindowStyleMaskResizable;
        }

        _window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
        _window.title = configuration.title.NSObject;
        _window.delegate = self;
        [_window center];

        WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
        [webConfig.userContentController addScriptMessageHandler:self name:@"asyncrt".NSObject];

        _webView = [[WKWebView alloc] initWithFrame:windowRect configuration:webConfig];
        _webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        _window.contentView = _webView;
        [_window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    return self;
}

- (void)bindAction:(OFString *)name toHandler:(AsyncWebUIActionHandler)handler {
    [_actionHandlers setObject:[handler copy] forKey:name];
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript:(OFString *)javaScript {
    AsyncCompletionSource<AsyncUnit *> *completionSource = [[AsyncCompletionSource alloc] init];
    [_webView evaluateJavaScript:javaScript.NSObject completionHandler:^(id _result, NSError *error) {
        (void)_result;
        if (error) {
            [completionSource reject:[OFException exception]];
        } else {
            [completionSource fulfill:AsyncUnit.unit];
        }
    }];
    return completionSource.task;
}

- (void)emitEvent:(OFString *)name withJSONPayload:(OFString *)payloadJSON {
    NSString *js = [NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('%@', {detail: %@}));".NSObject, name.NSObject, payloadJSON.NSObject];
    [_webView evaluateJavaScript:js completionHandler:nil];
}

- (void)close {
    [_window close];
}

- (void)windowWillClose:(NSNotification *)notification {
    [OFApplication.sharedApplication terminate];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"asyncrt".NSObject]) {
        NSDictionary *dict = message.body;
        NSString *action = dict[@"action"];
        NSString *payload = dict[@"payload"];
        NSString *reqId = dict[@"requestID"];

        OFString *ofAction = (OFString *)action.OFObject;
        AsyncWebUIActionHandler handler = [_actionHandlers objectForKey:ofAction];
        if (handler) {
            struct AsyncWebUIRequest req;
            req.action = ofAction;
            req.payloadJSON = (OFString *)payload.OFObject;
            req.requestID = (OFString *)reqId.OFObject;

            auto task = handler(req);
            [task mapOnScheduler:self.scheduler transform:^id(OFString *result) {
                NSString *js = [NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('asyncrt_response_%@', {detail: %@}));".NSObject, reqId, result.NSObject];
                [self->_webView evaluateJavaScript:js completionHandler:nil];
                return AsyncUnit.unit;
            }];
        }
    }
}

// Support initial HTML property by overriding it maybe? Or exposing a way to load HTML.
- (void)loadHTML:(OFString *)html {
    [_webView loadHTMLString:html.NSObject baseURL:nil];
}

- (void)loadIRI:(OFIRI *)iri {
    NSURL *nsURL = [NSURL URLWithString:iri.string.NSObject];
    [_webView loadRequest:[NSURLRequest requestWithURL:nsURL]];
}

@end
#endif
