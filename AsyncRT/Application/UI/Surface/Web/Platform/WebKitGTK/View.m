#pragma push_macro("__OBJC__")
#undef __OBJC__
#include <gtk/gtk.h>
#include <webkit/webkit.h>
#pragma pop_macro("__OBJC__")

#include "View.h"

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
- (void)webKitGTKViewDidReceiveScriptMessage: (JSCValue *)message;
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
                                          JSCValue *message,
                                          gpointer userData)
{
    (void)manager;
    [(__bridge AsyncWebKitGTKView *)userData webKitGTKViewDidReceiveScriptMessage: message];
}

static gboolean
AsyncWebKitGTKWindowCloseRequest(GtkWindow *window, gpointer userData)
{
    (void)window;
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

    if (!gtk_init_check())
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
    g_signal_connect(_userContentManager,
                     "script-message-received::asyncrt",
                     G_CALLBACK(AsyncWebKitGTKViewDidReceiveScriptMessage),
                     (__bridge gpointer)self);
    webkit_user_content_manager_register_script_message_handler(_userContentManager, "asyncrt", nullptr);
    WebKitUserScript *bridgeUserScript = [self _bridgeUserScript];
    webkit_user_content_manager_add_script(_userContentManager, bridgeUserScript);
    webkit_user_script_unref(bridgeUserScript);

    _webView = WEBKIT_WEB_VIEW(g_object_new(WEBKIT_TYPE_WEB_VIEW,
                                            "user-content-manager", _userContentManager,
                                            nullptr));
    _window = gtk_window_new();
    gtk_window_set_title(GTK_WINDOW(_window), configuration.title.UTF8String);
    gtk_window_set_default_size(GTK_WINDOW(_window), (gint)configuration.initialWidth, (gint)configuration.initialHeight);
    gtk_window_set_resizable(GTK_WINDOW(_window), configuration.isResizable);
    gtk_window_set_child(GTK_WINDOW(_window), GTK_WIDGET(_webView));

    g_signal_connect(_window, "close-request", G_CALLBACK(AsyncWebKitGTKWindowCloseRequest), (__bridge gpointer)self);
    g_signal_connect(_window, "destroy", G_CALLBACK(AsyncWebKitGTKWindowDidDestroy), (__bridge gpointer)self);

    gtk_window_present(GTK_WINDOW(_window));
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
        webkit_user_content_manager_unregister_script_message_handler(_userContentManager, "asyncrt", nullptr);
    }

    if (_window != nilptr) {
        GtkWidget *window = $assert_nonnil(_window);
        _window = NULL;
        _webView = NULL;
        gtk_window_destroy(GTK_WINDOW(window));
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
    if (not self.isClosed)
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

- (void)webKitGTKViewDidReceiveScriptMessage: (JSCValue *)message
{
    id messageObject = [AsyncWebKitGTKApplicationSupport objectFromJavaScriptValue: message];
    if (not [messageObject isKindOfClass: OFArray.class])
        return;

    auto array = (OFArray<id> *)messageObject;
    id nillable actionObject = (array.count > 0 ? array[0] : nilptr);
    id nillable requestIDObject = (array.count > 1 ? array[1] : nilptr);
    id nillable payload = (array.count > 2 ? array[2] : nilptr);

    if (not [actionObject isKindOfClass: OFString.class])
        return;
    if (not [requestIDObject isKindOfClass: OFString.class])
        return;

    OFString *requestID = (OFString *)requestIDObject;
    AsyncWebUIRequest request = (AsyncWebUIRequest){
        .action = (OFString *)actionObject,
        .payload = (payload != OFNull.null ? payload : nilptr),
        .requestID = requestID
    };

    auto task = [[self taskToHandleRequest: request] recover: ^id(OFException *exception) {
        return [AsyncWebKitGTKApplicationSupport responseJSONForException: exception];
    }];
    task = [task map: ^(OFString *responseJSON) {
        OFString *javaScript = [AsyncWebUIView javaScriptToResolveRequestID: requestID
                                                               responseJSON: responseJSON];
        [self taskToEvaluateJavaScript: javaScript];
        return AsyncUnit.unit;
    }];
}

- (WebKitUserScript *)_bridgeUserScript
{
    OFString *source = @$raw(
        (() => {
            const bridge = window.AsyncRT || {};
            let nextRequestID = 1;
            const pendingRequests = new Map();
            bridge.__resolve = (requestID, response) => {
                const resolve = pendingRequests.get(requestID);
                if (!resolve)
                    return;

                pendingRequests.delete(requestID);
                resolve(response);
            };
            bridge.__emit = (name, payload) => {
                window.dispatchEvent(new CustomEvent(name, { detail: payload }));
            };
            bridge.invoke = (action, payload) => new Promise((resolve) => {
                const requestID = String(nextRequestID++);
                pendingRequests.set(requestID, resolve);
                window.webkit.messageHandlers.asyncrt.postMessage([
                    action,
                    requestID,
                    payload === undefined ? null : payload
                ]);
            });
            bridge.__components = bridge.__components || {
                byID: new Map(),
                register(componentID, component) {
                    this.byID.set(componentID, component);
                },
                unregister(componentID, component) {
                    if (this.byID.get(componentID) === component)
                        this.byID.delete(componentID);
                },
                update(componentID, state) {
                    const component = this.byID.get(componentID);
                    if (component && state && typeof state === 'object')
                        component.setState(state);
                }
            };
            bridge.__dom = bridge.__dom || {
                exists(selector) {
                    return document.querySelector(String(selector)) !== null;
                },
                readText(selector) {
                    const el = document.querySelector(String(selector));
                    return el ? el.textContent : null;
                },
                measure(selector) {
                    const el = document.querySelector(String(selector));
                    if (!el)
                        return null;

                    const r = el.getBoundingClientRect();
                    return { x: r.x, y: r.y, width: r.width, height: r.height };
                },
                applyMutations(mutations) {
                    const results = new Array(mutations.length);
                    const elementsBySelector = new Map();

                    const elementForSelector = (selector) => {
                        selector = String(selector);
                        if (!elementsBySelector.has(selector))
                            elementsBySelector.set(selector, document.querySelector(selector));

                        return elementsBySelector.get(selector);
                    };

                    for (let index = 0; index < mutations.length; index++) {
                        const mutation = mutations[index];
                        const el = elementForSelector(mutation[1]);
                        if (!el) {
                            results[index] = false;
                            continue;
                        }

                        const kind = mutation[0];
                        const name = mutation[2];
                        const value = mutation[3];

                        switch (kind) {
                            case 0:
                                el.textContent = value;
                                results[index] = true;
                                break;
                            case 1:
                                el.innerHTML = value;
                                results[index] = true;
                                break;
                            case 2:
                                el.setAttribute(name, value);
                                results[index] = true;
                                break;
                            case 3:
                                el.removeAttribute(name);
                                results[index] = true;
                                break;
                            case 4:
                                el.style.setProperty(name, value);
                                results[index] = true;
                                break;
                            case 5:
                                el.classList.add(name);
                                results[index] = true;
                                break;
                            case 6:
                                el.classList.remove(name);
                                results[index] = true;
                                break;
                            case 7:
                                el.classList.toggle(name, Boolean(mutation[4]));
                                results[index] = true;
                                break;
                            default:
                                results[index] = false;
                                break;
                        }
                    }

                    return results;
                }
            };
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
