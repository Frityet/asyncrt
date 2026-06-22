#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/UI/Surface/Web/Web.h>
#import <AsyncRT/Application/UI/Surface/Web/Internal/Component+Private.h>
#import <AsyncRT/Application/UI/Surface/Web/Platform/HTTPServer/View.h>
#import <AsyncRT/Networking/HTTP.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncWebUITestComponent : AsyncWebUIComponent
@end

@implementation AsyncWebUITestComponent

+ (OFString *)layout
{
    return @$raw(<button class="primary" onclick="onPress:">Press {{message}}</button>);
}

+ (OFString *)styling
{
    return @$raw(.primary { color: "red"; });
}

@end

[[subclassing_restricted]]
@interface AsyncWebUIStatefulTestComponent : AsyncWebUIComponent

@property(nonatomic) OFString *message;
@property(nonatomic) int counter;
@property(nonatomic) bool mounted;
@property(nonatomic) OFArray<id> *nillable lastEvent;

@end

@implementation AsyncWebUIStatefulTestComponent

- (instancetype)init
{
    self = [super init];
    _message = @"Hello & <AsyncRT>";
    _counter = 2;
    _mounted = false;
    _lastEvent = nilptr;
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <section>
            <h1>{{message}}</h1>
            <button onclick="onIncrementClick:">{{counter}}</button>
        </section>
    );
}

- (void)onMountToWebView: (AsyncWebUIView *)webView
{
    (void)webView;
    self.mounted = true;
}

- (void)onIncrementClick: (id)sender
{
    self.counter += 1;
    if ([sender isKindOfClass: OFArray.class])
        self.lastEvent = (OFArray<id> *)sender;
}

@end

[[subclassing_restricted]]
@interface AsyncWebUINestedTestComponent : AsyncWebUIComponent

- (AsyncWebUIStatefulTestComponent *)childComponent;

@end

@implementation AsyncWebUINestedTestComponent {
    AsyncWebUIStatefulTestComponent *_detail;
}

- (instancetype)init
{
    self = [super init];
    _detail = [[AsyncWebUIStatefulTestComponent alloc] init];
    return self;
}

- (AsyncWebUIStatefulTestComponent *)childComponent
{
    return _detail;
}

+ (OFString *)layout
{
    return @$raw(
        <section class="nested">
            <h2>Nested host</h2>
            <slot name="detail"></slot>
        </section>
    );
}

@end

[[subclassing_restricted]]
@interface AsyncWebUITestView : AsyncWebUIView

@property(readonly, nonatomic) OFMutableArray<OFString *> *evaluatedJavaScripts;
@property(retain, nonatomic) id nillable nextJavaScriptValue;

@end

@implementation AsyncWebUITestView {
    OFMutableArray<OFString *> *_evaluatedJavaScripts;
    id nillable _nextJavaScriptValue;
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
{
    self = [super initWithConfiguration: configuration];
    _evaluatedJavaScripts = [OFMutableArray array];
    return self;
}

- (OFMutableArray<OFString *> *)evaluatedJavaScripts
{
    return _evaluatedJavaScripts;
}

- (id nillable)nextJavaScriptValue
{
    return _nextJavaScriptValue;
}

- (void)setNextJavaScriptValue: (id nillable)nextJavaScriptValue
{
    _nextJavaScriptValue = nextJavaScriptValue;
}

- (AsyncTask<id> *)taskToEvaluateJavaScriptReturningValue: (OFString *)javaScript
{
    [_evaluatedJavaScripts addObject: javaScript];
    id nillable value = _nextJavaScriptValue;
    _nextJavaScriptValue = nilptr;
    return [AsyncTask resolved: (value != nilptr ? $assert_nonnil(value) : (id)OFNull.null)];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeWebUITests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeWebUITests

- (void)test_window_configuration_defaults_copy_and_web_defaults
{
    auto defaults = AsyncUIWindowConfiguration.defaults;
    AsyncUIWindowConfiguration *copy = [defaults copy];
    auto webApplication = [[AsyncWebUIApplication alloc] init];
    auto webConfiguration = [webApplication windowConfiguration];

    OTAssert(([defaults.title isEqual: @"AsyncRT UI"]), @"Shared window defaults should keep the UI title");
    OTAssert(([copy.title isEqual: defaults.title]), @"Copied window configurations should preserve title");
    OTAssert((copy.initialSize.width == defaults.initialSize.width and copy.initialSize.height == defaults.initialSize.height),
             @"Copied window configurations should preserve size");
    OTAssert(([webConfiguration.title isEqual: @"AsyncRT Web UI"]), @"Web applications should use a web-specific default title");
    OTAssert((webConfiguration.initialWidth == 800 and webConfiguration.initialHeight == 600),
             @"Web applications should default to the Web surface size");
    OTAssert((not webConfiguration.automaticallyResizesToContent),
             @"Web windows should not inherit immediate content auto-resizing");
    OTAssert((not webApplication.shouldTerminateAfterLaunchTaskCompletes),
             @"Web applications should stay alive while their root component is mounted");
    OTAssert(([webApplication.createRootComponent isKindOfClass: AsyncWebUIComponent.class]),
             @"Web applications should provide a root component instance");
}

- (void)test_web_view_copies_configuration_and_tracks_loaded_content
{
    [self runAsyncBlock: ^{
        auto configuration = [AsyncUIWindowConfiguration withTitle: @"Original"
                                                            width: 640
                                                           height: 480];
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: configuration];

        configuration.title = @"Mutated";
        OTAssert(([view.configuration.title isEqual: @"Original"]),
                 @"Web views should copy their launch configuration");

        [view loadHTML: @"<main>hello</main>"];
        OTAssert(([view.loadedHTML isEqual: @"<main>hello</main>"]), @"HTML loads should be recorded");
        OTAssert((view.loadedIRI == nilptr), @"Loading HTML should clear the previous IRI");

        auto IRI = [OFIRI IRIWithString: @"https://example.com/app"];
        [view loadIRI: IRI];
        OTAssert(([view.loadedIRI.string isEqual: @"https://example.com/app"]), @"IRI loads should be recorded");
        OTAssert((view.loadedHTML == nilptr), @"Loading an IRI should clear previous HTML");
    }];
}

- (void)test_default_web_view_serves_html_over_http_without_window
{
    [self runAsyncBlock: ^{
        AsyncWebUIView *view = [[AsyncWebUIView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];

        @try {
            OTAssert(([view isKindOfClass: AsyncWebHTTPServerView.class]),
                     @"Default WebUI views should use the HTTP server backend");
            OTAssert((view.serverIRI != nilptr), @"HTTP server views should expose their listening IRI");

            [view loadHTML: @"<!doctype html><html><head><title>Test</title></head><body><main>Hello</main></body></html>"];

            auto client = [AsyncHTTPClient client];
            auto request = [[OFHTTPRequest alloc] initWithIRI: $assert_nonnil(view.serverIRI)];
            OFHTTPResponse *response = [[client performRequest: request] await];
            OFString *body = response.readString;

            OTAssert((response.statusCode == 200), @"HTTP WebUI backend should serve the loaded document");
            OTAssert(([body containsString: @"<main>Hello</main>"]), @"Served HTML should include loaded content");
            OTAssert(([body containsString: @"window.AsyncRT = bridge"]),
                     @"Served HTML should include the HTTP browser bridge");
            OTAssert(([body containsString: @"__startHTTPCommandPolling"]),
                     @"Served HTML should poll for runtime commands");

            [view emitEvent: @"ready" withPayload: [OFDictionary dictionaryWithObject: [OFNumber numberWithBool: true]
                                                                                forKey: @"ok"]];
            auto eventsIRI = [OFIRI IRIWithString: [OFString stringWithFormat: @"%@__asyncrt/events?since=0",
                                                                               $assert_nonnil(view.serverIRI).string]];
            auto eventsRequest = [[OFHTTPRequest alloc] initWithIRI: eventsIRI];
            OFHTTPResponse *eventsResponse = [[client performRequest: eventsRequest] await];
            OFString *eventsBody = eventsResponse.readString;

            OTAssert((eventsResponse.statusCode == 200), @"HTTP WebUI backend should expose queued browser commands");
            OTAssert(([eventsBody containsString: @"window.AsyncRT.__emit"]),
                     @"Queued browser commands should include emitted runtime events");
            OTAssert(([eventsBody containsString: @"ready"]),
                     @"Queued browser commands should preserve event names");

            AsyncTask<id> *valueTask = [view taskToEvaluateJavaScriptReturningValue: @"1 + 1"];
            auto valueEventsIRI = [OFIRI IRIWithString: [OFString stringWithFormat: @"%@__asyncrt/events?since=0",
                                                                                    $assert_nonnil(view.serverIRI).string]];
            auto valueEventsRequest = [[OFHTTPRequest alloc] initWithIRI: valueEventsIRI];
            OFHTTPResponse *valueEventsResponse = [[client performRequest: valueEventsRequest] await];
            OFString *valueEventsBody = valueEventsResponse.readString;

            OTAssert((valueEventsResponse.statusCode == 200), @"HTTP WebUI backend should expose queued value evaluations");
            OTAssert(([valueEventsBody containsString: @"\"requestID\""]),
                     @"Value-returning evaluations should carry a browser response request ID");
            OTAssert(([valueEventsBody containsString: @"1 + 1"]),
                     @"Value-returning evaluations should preserve the JavaScript expression");

            [view close];
            @try {
                (void)[valueTask await];
                OTAssert(false, @"Pending HTTP WebUI JavaScript evaluations should reject when the view closes");
            } @catch (OFException *exception) {
                OTAssert(([exception.description containsString: @"closed before the browser returned"]),
                         @"Closed pending JavaScript evaluations should describe the missing browser result");
            }
        } @finally {
            [view close];
        }
    }];
}

- (void)test_web_component_identifier_and_definition_are_valid_for_custom_elements
{
    OTAssert(([AsyncWebUITestComponent.identifier isEqual: @"awuic-asyncwebuitestcomponent"]),
             @"Component identifiers should be lowercase custom element names");
    OFString *definitionJavaScript = [AsyncWebUITestComponent _asyncWebUIDefinitionJavaScript];

    OTAssert(([definitionJavaScript containsString: @"const tagName = \"awuic-asyncwebuitestcomponent\""]),
             @"Component definitions should embed the lowercase identifier");
    OTAssert(([definitionJavaScript containsString: @"customElements.define(tagName, Component)"]),
             @"Component definitions should register the lowercase identifier");
    OTAssert(([definitionJavaScript containsString: @"const styleText = \".primary { color: \\\"red\\\"; }\""]),
             @"Component styling should be JSON-escaped before entering JavaScript");
    OTAssert(([definitionJavaScript containsString: @"const layoutHTML = \"<button class=\\\"primary\\\" onclick=\\\"onPress:\\\">Press {{message}}</button>\""]),
             @"Component layout should be JSON-escaped before entering JavaScript");
    OTAssert(([definitionJavaScript containsString: @"window.AsyncRT.invoke(nativeInvokeAction"]),
             @"Generated components should call through the AsyncRT browser bridge");
}

- (void)test_web_component_state_mounting_and_element_html
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];

        [component _asyncWebUIMountToWebView: view componentID: @"root"];

        OTAssert((component.webView == view), @"Mounted components should retain their web view");
        OTAssert(([component.componentID isEqual: @"root"]), @"Mounted components should retain their component ID");
        OTAssert(component.mounted, @"Mounting should call the component lifecycle hook");
        OTAssert(([AsyncWebUIStatefulTestComponent.observedProperties containsObject: @"message"]),
                 @"Observed properties should include declared object properties");
        OTAssert(([AsyncWebUIStatefulTestComponent.observedProperties containsObject: @"counter"]),
                 @"Observed properties should include declared scalar properties");

        auto state = component.propertyState;
        OTAssert(([[state objectForKey: @"message"] isEqual: @"Hello & <AsyncRT>"]),
                 @"Component state should include object property values");
        OTAssert((((OFNumber *)[state objectForKey: @"counter"]).intValue == 2),
                 @"Component state should include boxed scalar property values");

        OFString *renderedHTML = [component _asyncWebUIElementHTMLWithSlotName: nilptr];
        OTAssert(([renderedHTML containsString: @"<awuic-asyncwebuistatefultestcomponent"]),
                 @"Mounted components should render their custom element tag");
        OTAssert(([renderedHTML containsString: @"data-async-webui-id=\"root\""]),
                 @"Mounted component HTML should include the component ID");
        OTAssert(([renderedHTML containsString: @"&quot;message&quot;"]),
                 @"Mounted component HTML should XML-escape JSON state for attributes");
        OTAssert(([renderedHTML containsString: @"Hello &amp; &lt;AsyncRT&gt;"]),
                 @"Mounted component HTML should XML-escape state values for attributes");
    }];
}

- (void)test_web_component_nested_children_render_as_slotted_light_dom
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        auto parent = [[AsyncWebUINestedTestComponent alloc] init];
        auto child = parent.childComponent;

        [parent _asyncWebUIMountToWebView: view componentID: @"root"];
        [child _asyncWebUIMountToWebView: view componentID: @"root-detail-0"];

        auto childEntries = parent._asyncWebUIChildComponentEntries;
        OFString *parentHTML = [parent _asyncWebUIElementHTMLWithSlotName: nilptr];
        OTAssert(([[AsyncWebUINestedTestComponent _asyncWebUIDefinitionJavaScript] containsString: @"<slot name=\\\"detail\\\"></slot>"]),
                 @"Nested parent definitions should keep named slots in their shadow layout");
        OTAssert((childEntries.count == 1), @"Nested components should be discovered from component ivars");
        OTAssert(([((AsyncWebUIComponentChildEntry *)[childEntries objectAtIndex: 0]).slotName isEqual: @"detail"]),
                 @"Discovered child slots should come from the ivar name");
        OTAssert(([parentHTML containsString: @"<awuic-asyncwebuinestedtestcomponent"]),
                 @"Nested parent HTML should start with the parent component");
        OTAssert(([parentHTML containsString: @"<awuic-asyncwebuistatefultestcomponent slot=\"detail\""]),
                 @"Child component HTML should be rendered as slotted light DOM");
        OTAssert(([parentHTML containsString: @"data-async-webui-id=\"root-detail-0\""]),
                 @"Nested child HTML should include its mounted component ID");
    }];
}

- (void)test_web_component_action_dispatch_updates_state
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];
        [component _asyncWebUIMountToWebView: view componentID: @"root"];

        auto payload = [OFArray arrayWithObjects:
            @"root",
            @"onIncrementClick:",
            [OFArray arrayWithObject: @"click"],
            nil];
        OFString *responseJSON = [component _asyncWebUIHandleActionPayload: payload].await;
        auto state = (OFDictionary<OFString *, id> *)responseJSON.objectByParsingJSON;

        OTAssert((component.counter == 3), @"Component action selectors should be invoked");
        OTAssert((component.lastEvent != nilptr), @"Component action selectors should receive the event payload");
        OTAssert(([[component.lastEvent objectAtIndex: 0] isEqual: @"click"]),
                 @"Compact event payloads should be passed to one-argument selectors");
        OTAssert((((OFNumber *)[state objectForKey: @"counter"]).intValue == 3),
                 @"Action responses should return updated component state directly");

        auto compactPayload = [OFArray arrayWithObjects:
            @"root",
            @"onIncrementClick:",
            [OFArray arrayWithObject: @"click"],
            nil];
        OFString *compactResponseJSON = [component _asyncWebUIHandleActionPayload: compactPayload].await;
        auto compactState = (OFDictionary<OFString *, id> *)compactResponseJSON.objectByParsingJSON;
        OTAssert((component.counter == 4), @"Compact component action payloads should be invoked");
        OTAssert((((OFNumber *)[compactState objectForKey: @"counter"]).intValue == 4),
                 @"Compact component action responses should return updated state directly");

        @try {
            auto invalidPayload = [OFArray arrayWithObjects: @"root", @"missingAction:", nil];
            (void)[component _asyncWebUIHandleActionPayload: invalidPayload].await;
            OTAssert(false, @"Invalid component selectors should reject the action task");
        } @catch (AsyncWebUIComponentException *exception) {
            OTAssert(([exception.description containsString: @"does not respond"]),
                     @"Invalid component selector failures should describe the rejected selector");
        }
    }];
}

- (void)test_web_component_render_task_emits_component_update
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];
        [component _asyncWebUIMountToWebView: view componentID: @"root"];

        component.counter = 9;
        (void)[component taskToRender].await;

        OTAssert((view.evaluatedJavaScripts.count == 1), @"Rendering should evaluate one browser update event");
        OFString *javaScript = [view.evaluatedJavaScripts objectAtIndex: 0];
        OTAssert(([javaScript containsString: @"window.AsyncRT.__components.update(\"root\""]),
                 @"Render tasks should update the injected component registry directly");
        OTAssert(([javaScript containsString: @"\"counter\":9"]),
                 @"Render tasks should include the current component state");
    }];
}

- (void)test_web_view_event_javascript_is_escaped_and_evaluated
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        OFString *javaScript = [AsyncWebUIView javaScriptToDispatchEventNamed: @"state:ready\"quoted"
                                                                       payload: [OFDictionary dictionaryWithObject: [OFNumber numberWithBool: true]
                                                                                                            forKey: @"ok"]];

        OTAssert(([javaScript containsString: @"window.AsyncRT.__emit(\"state:ready\\\"quoted\""]),
                 @"Event names should be passed through the injected event emitter");
        OTAssert(([javaScript containsString: @"{\"ok\":true}"]),
                 @"Event payloads should be JSON-encoded from ObjFW values");

        [view emitEvent: @"state:ready" withPayload: [OFDictionary dictionaryWithObject: [OFNumber numberWithInt: 1]
                                                                                 forKey: @"phase"]];
        OTAssert((view.evaluatedJavaScripts.count == 1), @"Emitting an event should evaluate one JavaScript snippet");
        OTAssert(([[view.evaluatedJavaScripts objectAtIndex: 0] containsString: @"state:ready"]),
                 @"Emitted JavaScript should contain the event name");
    }];
}

- (void)test_web_dom_wrappers_batch_mutations_and_return_values
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        auto document = view.document;
        auto gauge = [document elementMatchingSelector: @".gauge"];

        view.nextJavaScriptValue = [OFArray arrayWithObjects:
            [OFNumber numberWithBool: true],
            [OFNumber numberWithBool: true],
            [OFNumber numberWithBool: true],
            nil];

        auto mutations = [OFArray arrayWithObjects:
            [AsyncWebUIDOMMutation setText: @"42%" selector: @".gauge"],
            [AsyncWebUIDOMMutation setStyleProperty: @"--load" value: @"0.42" selector: @".gauge"],
            [AsyncWebUIDOMMutation toggleClass: @"hot" enabled: true selector: @".gauge"],
            nil];
        OFArray<id> *result = [gauge taskToApplyMutations: mutations].await;

        OTAssert((result.count == 3), @"DOM mutation batches should return one result per operation");
        OTAssert((view.evaluatedJavaScripts.count == 1), @"DOM mutation batches should evaluate one JavaScript snippet");
        OFString *script = [view.evaluatedJavaScripts objectAtIndex: 0];
        OTAssert(([script containsString: @"window.AsyncRT.__dom.applyMutations("]),
                 @"DOM mutations should call the injected browser-side DOM runtime");
        OTAssert(([script containsString: @"[0,\".gauge\",null,\"42%\",false]"]),
                 @"DOM mutations should encode text updates as compact payload operations");
        OTAssert(([script containsString: @"[4,\".gauge\",\"--load\",\"0.42\",false]"]),
                 @"DOM mutations should encode CSS custom property updates as compact payload operations");
        OTAssert(([script containsString: @"[7,\".gauge\",\"hot\",null,true]"]),
                 @"DOM mutations should encode explicit class toggles as compact payload operations");

        view.nextJavaScriptValue = @"ready";
        OTAssert(([[gauge taskToReadText].await isEqual: @"ready"]),
                 @"DOM elements should expose async text reads");
        OTAssert(([[view.evaluatedJavaScripts objectAtIndex: 1] containsString: @"window.AsyncRT.__dom.readText(\".gauge\")"]),
                 @"DOM text reads should use the injected browser-side DOM runtime");
    }];
}

- (void)test_web_view_action_dispatch_and_unbind
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        block_reference AsyncWebUIRequest observedRequest = (AsyncWebUIRequest){0};

        [view bindAction: @"save" toHandler: ^AsyncTask<OFString *> *(AsyncWebUIRequest request) {
            observedRequest = request;
            return [AsyncTask resolved: @"{\"saved\":true}"];
        }];

        AsyncWebUIRequest request = (AsyncWebUIRequest){
            .action = @"save",
            .payload = [OFArray arrayWithObject: [OFNumber numberWithInt: 1]],
            .requestID = @"request-1"
        };
        OFString *result = [view taskToHandleRequest: request].await;

        OTAssert(([result isEqual: @"{\"saved\":true}"]), @"Bound actions should resolve through their handler");
        OTAssert(([observedRequest.action isEqual: @"save"]), @"Action handlers should receive the action name");
        OTAssert(([observedRequest.payload isKindOfClass: OFArray.class]), @"Action handlers should receive compact payload objects");
        OTAssert(([observedRequest.requestID isEqual: @"request-1"]), @"Action handlers should receive the request ID");

        [view unbindActionNamed: @"save"];
        OTAssert(([[view taskToHandleRequest: request].await isEqual: @"null"]),
                 @"Unbound actions should resolve to JSON null");
        OTAssert(([[view taskToHandleRequest: (AsyncWebUIRequest){0}].await isEqual: @"null"]),
                 @"Malformed action requests should resolve to JSON null");
    }];
}

- (void)test_web_view_response_javascript_and_close_state
{
    [self runAsyncBlock: ^{
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults];
        OFString *javaScript = [AsyncWebUIView javaScriptToResolveRequestID: @"abc"
                                                               responseJSON: @"{\"ok\":true}"];

        OTAssert(([javaScript containsString: @"window.AsyncRT.__resolve(\"abc\""]),
                 @"Responses should resolve through the injected request table");
        OTAssert(([javaScript containsString: @"{\"ok\":true}"]),
                 @"Responses should carry JSON response detail");
        OTAssert((not view.isClosed), @"Fresh web views should start open");
        [view close];
        OTAssert((view.isClosed), @"Closing a web view should update its close state");
    }];
}

@end

#pragma clang assume_nonnull end
