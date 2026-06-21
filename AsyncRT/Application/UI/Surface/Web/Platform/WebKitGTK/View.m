#if defined(__linux__)

#pragma push_macro("__OBJC__")
#undef __OBJC__
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#pragma pop_macro("__OBJC__")

#import <AsyncRT/Application/UI/Surface/Web/Platform/WebKitGTK/View.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncWebKitGTKJavaScriptEvaluationException : OFException

@property(readonly, copy, nonatomic) OFString *reason;
@property(readonly, copy, nonatomic) OFString *javaScript;

- (instancetype)initWithError: (GError *)error
                   javaScript: (OFString *)javaScript [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncWebKitGTKJavaScriptEvaluation : OFObject

@property(readonly, nonatomic) AsyncCompletionSource<id> *completionSource;
@property(readonly, copy, nonatomic) OFString *javaScript;

- (instancetype)initWithCompletionSource: (AsyncCompletionSource<id> *)completionSource
                              javaScript: (OFString *)javaScript [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@namespace(AsyncWebKitGTKApplicationSupport)

+ (void)ensureGTKInitialized;
+ (void)pollEvents;
+ (OFString *)responseJSONForException: (OFException *)exception;
+ (id)objectFromJavaScriptValue: (JSCValue *nillable)value;

@end

@interface AsyncWebKitGTKView ()

- (void)webKitGTKWindowDidDestroy;
- (void)webKitGTKViewDidReceiveScriptMessage: (WebKitJavascriptResult *)message;
- (void)_startPollTimer;
- (void)_stopPollTimer;
- (WebKitUserScript *)_bridgeUserScript;

@end

static void
AsyncWebKitGTKWindowDidDestroy(GtkWidget *widget, gpointer userData)
{
    (void)widget;
    [(__bridge AsyncWebKitGTKView *)userData webKitGTKWindowDidDestroy];
}

static void
AsyncWebKitGTKViewDidReceiveScriptMessage(WebKitUserContentManager *manager,
                                          WebKitJavascriptResult *message,
                                          gpointer userData)
{
    (void)manager;
    [(__bridge AsyncWebKitGTKView *)userData webKitGTKViewDidReceiveScriptMessage: message];
}

static gboolean
AsyncWebKitGTKWindowDeleteEvent(GtkWidget *widget, GdkEvent *event, gpointer userData)
{
    (void)widget;
    (void)event;
    [(__bridge AsyncWebKitGTKView *)userData close];
    return TRUE;
}

static void
AsyncWebKitGTKViewDidEvaluateJavaScript(GObject *object, GAsyncResult *result, gpointer userData)
{
    AsyncWebKitGTKJavaScriptEvaluation *evaluation =
        (__bridge_transfer AsyncWebKitGTKJavaScriptEvaluation *)userData;

    GError *error = nullptr;
    JSCValue *value = webkit_web_view_evaluate_javascript_finish(WEBKIT_WEB_VIEW(object), result, &error);

    if (error != nullptr) {
        [evaluation.completionSource reject:
            [[AsyncWebKitGTKJavaScriptEvaluationException alloc] initWithError: error
                                                                    javaScript: evaluation.javaScript]];
        g_error_free(error);
        return;
    }

    [evaluation.completionSource fulfill: [AsyncWebKitGTKApplicationSupport objectFromJavaScriptValue: value]];

    if (value != nullptr)
        g_object_unref(value);
}

@implementation AsyncWebKitGTKJavaScriptEvaluationException

- (instancetype)initWithError: (GError *)error
                   javaScript: (OFString *)javaScript
{
    self = [super init];
    _reason = [[OFString stringWithFormat: @"JavaScript evaluation failed: %s (domain=%u code=%d)",
                                          error->message,
                                          error->domain,
                                          error->code] copy];
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

@implementation AsyncWebKitGTKJavaScriptEvaluation

- (instancetype)initWithCompletionSource: (AsyncCompletionSource<id> *)completionSource
                              javaScript: (OFString *)javaScript
{
    self = [super init];
    _completionSource = completionSource;
    _javaScript = [javaScript copy];
    return self;
}

@end

@namespace_implementation(AsyncWebKitGTKApplicationSupport)

+ (void)ensureGTKInitialized
{
    static bool prepared = false;
    if (prepared)
        return;

    if (!gtk_init_check(nullptr, nullptr))
        @throw [[OFInitializationFailedException alloc] initWithClass: AsyncWebKitGTKView.class];

    prepared = true;
}

+ (void)pollEvents
{
    GMainContext *context = g_main_context_default();
    while (g_main_context_pending(context))
        g_main_context_iteration(context, FALSE);
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

+ (id)objectFromJavaScriptValue: (JSCValue *nillable)value
{
    if (value == nullptr or jsc_value_is_null(value) or jsc_value_is_undefined(value))
        return OFNull.null;

    if (jsc_value_is_boolean(value))
        return [OFNumber numberWithBool: jsc_value_to_boolean(value)];

    if (jsc_value_is_number(value))
        return [OFNumber numberWithDouble: jsc_value_to_double(value)];

    if (jsc_value_is_string(value)) {
        char *string = jsc_value_to_string(value);
        OFString *result = [OFString stringWithUTF8String: string];
        g_free(string);
        return result;
    }

    char *json = jsc_value_to_json(value, 0);
    if (json != nullptr) {
        @try {
            OFString *jsonString = [OFString stringWithUTF8String: json];
            return jsonString.objectByParsingJSON;
        } @finally {
            g_free(json);
        }
    }

    char *description = jsc_value_to_string(value);
    OFString *result = [OFString stringWithUTF8String: description];
    g_free(description);
    return result;
}

@end

@implementation AsyncWebKitGTKView {
    GtkWidget *nillable _window;
    WebKitWebView *nillable _webView;
    WebKitUserContentManager *nillable _userContentManager;
    OFTimer *nillable _pollTimer;
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
{
    self = [super initWithConfiguration: configuration];

    [AsyncWebKitGTKApplicationSupport ensureGTKInitialized];

    _userContentManager = webkit_user_content_manager_new();
    webkit_user_content_manager_register_script_message_handler(_userContentManager, "asyncrt");
    WebKitUserScript *bridgeUserScript = [self _bridgeUserScript];
    webkit_user_content_manager_add_script(_userContentManager, bridgeUserScript);
    webkit_user_script_unref(bridgeUserScript);
    g_signal_connect(_userContentManager,
                     "script-message-received::asyncrt",
                     G_CALLBACK(AsyncWebKitGTKViewDidReceiveScriptMessage),
                     (__bridge gpointer)self);

    _webView = WEBKIT_WEB_VIEW(webkit_web_view_new_with_user_content_manager(_userContentManager));
    _window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(_window), configuration.title.UTF8String);
    gtk_window_set_default_size(GTK_WINDOW(_window), (gint)configuration.initialWidth, (gint)configuration.initialHeight);
    gtk_window_set_resizable(GTK_WINDOW(_window), configuration.isResizable);
    gtk_container_add(GTK_CONTAINER(_window), GTK_WIDGET(_webView));

    g_signal_connect(_window, "delete-event", G_CALLBACK(AsyncWebKitGTKWindowDeleteEvent), (__bridge gpointer)self);
    g_signal_connect(_window, "destroy", G_CALLBACK(AsyncWebKitGTKWindowDidDestroy), (__bridge gpointer)self);

    gtk_widget_show_all(_window);
    gtk_widget_grab_focus(GTK_WIDGET(_webView));
    [self _startPollTimer];

    return self;
}

- (void)dealloc
{
    [self close];
}

- (void)loadHTML: (OFString *)html
{
    [super loadHTML: html];
    webkit_web_view_load_html($assert_nonnil(_webView), html.UTF8String, nullptr);
}

- (void)loadIRI: (OFIRI *)IRI
{
    [super loadIRI: IRI];
    webkit_web_view_load_uri($assert_nonnil(_webView), IRI.string.UTF8String);
}

- (AsyncTask<id> *)taskToEvaluateJavaScriptReturningValue: (OFString *)javaScript
{
    auto completionSource = [[AsyncCompletionSource<id> alloc] init];
    auto evaluation = [[AsyncWebKitGTKJavaScriptEvaluation alloc] initWithCompletionSource: completionSource
                                                                               javaScript: javaScript];
    webkit_web_view_evaluate_javascript($assert_nonnil(_webView),
                                        javaScript.UTF8String,
                                        -1,
                                        nullptr,
                                        nullptr,
                                        nullptr,
                                        AsyncWebKitGTKViewDidEvaluateJavaScript,
                                        (__bridge_retained gpointer)evaluation);
    return completionSource.task;
}

- (void)close
{
    if (self.isClosed)
        return;

    [super close];
    [self _stopPollTimer];

    if (_userContentManager != nilptr) {
        g_signal_handlers_disconnect_by_func(_userContentManager,
                                             G_CALLBACK(AsyncWebKitGTKViewDidReceiveScriptMessage),
                                             (__bridge gpointer)self);
        webkit_user_content_manager_unregister_script_message_handler(_userContentManager, "asyncrt");
    }

    if (_window != nilptr) {
        GtkWidget *window = $assert_nonnil(_window);
        _window = NULL;
        _webView = NULL;
        gtk_widget_destroy(window);
    } else {
        _webView = NULL;
    }

    if (_userContentManager != nilptr) {
        g_object_unref(_userContentManager);
        _userContentManager = NULL;
    }
}

- (void)webKitGTKWindowDidDestroy
{
    if (!self.isClosed)
        [super close];

    _window = NULL;
    _webView = NULL;
    [self _stopPollTimer];
    [OFApplication.sharedApplication terminate];
}

- (void)pollEvents
{
}

- (void)_startPollTimer
{
    if (_pollTimer != nilptr)
        return;

    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: (1.0 / 120.0) repeats: true block: ^(OFTimer *) {
        [AsyncWebKitGTKApplicationSupport pollEvents];
    }];
    _pollTimer = timer;
    [OFRunLoop.currentRunLoop addTimer: timer forMode: OFDefaultRunLoopMode];
}

- (void)_stopPollTimer
{
    if (_pollTimer == nilptr)
        return;

    [$assert_nonnil(_pollTimer) invalidate];
    _pollTimer = nilptr;
}

- (void)webKitGTKViewDidReceiveScriptMessage: (WebKitJavascriptResult *)message
{
    JSCValue *messageValue = webkit_javascript_result_get_js_value(message);
    id messageObject = [AsyncWebKitGTKApplicationSupport objectFromJavaScriptValue: messageValue];
    if (![messageObject isKindOfClass: OFDictionary.class])
        return;

    auto dictionary = (OFDictionary<OFString *, id> *)messageObject;
    id actionObject = [dictionary objectForKey: @"action"];
    id payloadObject = [dictionary objectForKey: @"payload"];
    id requestIDObject = [dictionary objectForKey: @"requestID"];

    if (![actionObject isKindOfClass: OFString.class])
        return;
    if (![requestIDObject isKindOfClass: OFString.class])
        return;

    OFString *payloadJSON = @"null";
    if ([payloadObject isKindOfClass: OFString.class])
        payloadJSON = (OFString *)payloadObject;
    else if (payloadObject != nilptr and payloadObject != OFNull.null and [payloadObject conformsToProtocol: @protocol(OFJSONRepresentation)])
        payloadJSON = ((id<OFJSONRepresentation>)payloadObject).JSONRepresentation;

    OFString *requestID = (OFString *)requestIDObject;
    AsyncWebUIRequest request = (AsyncWebUIRequest){
        .action = (OFString *)actionObject,
        .payloadJSON = payloadJSON,
        .requestID = requestID
    };

    AsyncTask<id> *task = [[self taskToHandleRequest: request] recover: ^id(OFException *exception) {
        return [AsyncWebKitGTKApplicationSupport responseJSONForException: exception];
    }];
    (void)[task map: ^id(OFString *responseJSON) {
        OFString *javaScript = [AsyncWebUIView javaScriptToResolveRequestID: requestID
                                                               responseJSON: responseJSON];
        (void)[self taskToEvaluateJavaScript: javaScript];
        return AsyncUnit.unit;
    }];
}

- (WebKitUserScript *)_bridgeUserScript
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

    return webkit_user_script_new(source.UTF8String,
                                  WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
                                  WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START,
                                  nullptr,
                                  nullptr);
}

@end

#pragma clang assume_nonnull end

#endif
