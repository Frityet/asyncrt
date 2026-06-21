#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/UI/Surface/Web/Web.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncWebUITestComponent : AsyncWebUIComponent
@end

@implementation AsyncWebUITestComponent

+ (OFString *)layout
{
    return @$raw(<button class="primary" onclick="[self onPress:]">Press {{message}}</button>);
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
@property(nonatomic) OFDictionary<OFString *, id> *nillable lastEvent;

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
            <button onclick="[self onIncrementClick:]">{{counter}}</button>
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
    if ([sender isKindOfClass: OFDictionary.class])
        self.lastEvent = (OFDictionary<OFString *, id> *)sender;
}

@end

[[subclassing_restricted]]
@interface AsyncWebUITestView : AsyncWebUIView

@property(readonly, nonatomic) OFMutableArray<OFString *> *evaluatedJavaScripts;

@end

@implementation AsyncWebUITestView {
    OFMutableArray<OFString *> *_evaluatedJavaScripts;
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler
{
    self = [super initWithConfiguration: configuration scheduler: scheduler];
    _evaluatedJavaScripts = [OFMutableArray array];
    return self;
}

- (OFMutableArray<OFString *> *)evaluatedJavaScripts
{
    return _evaluatedJavaScripts;
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript
{
    [_evaluatedJavaScripts addObject: javaScript];
    return [AsyncTask resolved: AsyncUnit.unit];
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
    OTAssert(([webApplication.rootComponentClass isSubclassOfClass: AsyncWebUIComponent.class]),
             @"Web applications should provide a root component class");
}

- (void)test_web_view_copies_configuration_and_tracks_loaded_content
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto configuration = [AsyncUIWindowConfiguration withTitle: @"Original"
                                                            width: 640
                                                           height: 480];
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: configuration
                                                            scheduler: rootTaskGroup.scheduler];

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

- (void)test_web_component_identifier_and_definition_are_valid_for_custom_elements
{
    OTAssert(([AsyncWebUITestComponent.identifier isEqual: @"awuic-asyncwebuitestcomponent"]),
             @"Component identifiers should be lowercase custom element names");
    OTAssert(([AsyncWebUITestComponent.definitionJavaScript containsString: @"const tagName = \"awuic-asyncwebuitestcomponent\""]),
             @"Component definitions should embed the lowercase identifier");
    OTAssert(([AsyncWebUITestComponent.definitionJavaScript containsString: @"customElements.define(tagName, Component)"]),
             @"Component definitions should register the lowercase identifier");
    OTAssert(([AsyncWebUITestComponent.definitionJavaScript containsString: @"const styleText = \".primary { color: \\\"red\\\"; }\""]),
             @"Component styling should be JSON-escaped before entering JavaScript");
    OTAssert(([AsyncWebUITestComponent.definitionJavaScript containsString: @"const layoutHTML = \"<button class=\\\"primary\\\" onclick=\\\"[self onPress:]\\\">Press {{message}}</button>\""]),
             @"Component layout should be JSON-escaped before entering JavaScript");
    OTAssert(([AsyncWebUITestComponent.definitionJavaScript containsString: @"window.AsyncRT.invoke(invokeActionName"]),
             @"Generated components should call through the AsyncRT browser bridge");
    OTAssert((not [AsyncWebUITestComponent.definitionJavaScript containsString: @"globalThis.AsyncWebUI"]),
             @"Generated components should not depend on the old placeholder global");
}

- (void)test_web_component_state_mounting_and_element_html
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];

        [component mountToWebView: view componentID: @"root"];

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

        OFString *elementHTML = component.elementHTML;
        OTAssert(([elementHTML containsString: @"<awuic-asyncwebuistatefultestcomponent"]),
                 @"Mounted components should render their custom element tag");
        OTAssert(([elementHTML containsString: @"data-async-webui-id=\"root\""]),
                 @"Mounted component HTML should include the component ID");
        OTAssert(([elementHTML containsString: @"&quot;message&quot;"]),
                 @"Mounted component HTML should XML-escape JSON state for attributes");
        OTAssert(([elementHTML containsString: @"Hello &amp; &lt;AsyncRT&gt;"]),
                 @"Mounted component HTML should XML-escape state values for attributes");
    }];
}

- (void)test_web_component_action_dispatch_updates_state
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];
        [component mountToWebView: view componentID: @"root"];

        AsyncWebUIRequest request = (AsyncWebUIRequest){
            .action = AsyncWebUIComponent.invokeActionName,
            .payloadJSON = @"{\"componentID\":\"root\",\"selector\":\"onIncrementClick:\",\"event\":{\"type\":\"click\"}}",
            .requestID = @"component-action"
        };
        OFString *responseJSON = [component taskToHandleActionRequest: request].await;
        auto response = (OFDictionary<OFString *, id> *)responseJSON.objectByParsingJSON;
        auto state = (OFDictionary<OFString *, id> *)[response objectForKey: @"state"];

        OTAssert((component.counter == 3), @"Component action selectors should be invoked");
        OTAssert((component.lastEvent != nilptr), @"Component action selectors should receive the event payload");
        OTAssert(([[component.lastEvent objectForKey: @"type"] isEqual: @"click"]),
                 @"Event payloads should be passed to one-argument selectors");
        OTAssert(([[response objectForKey: @"componentID"] isEqual: @"root"]),
                 @"Action responses should include the component ID");
        OTAssert((((OFNumber *)[state objectForKey: @"counter"]).intValue == 3),
                 @"Action responses should include updated component state");

        @try {
            AsyncWebUIRequest invalidRequest = (AsyncWebUIRequest){
                .action = AsyncWebUIComponent.invokeActionName,
                .payloadJSON = @"{\"componentID\":\"root\",\"selector\":\"missingAction:\"}",
                .requestID = @"component-action-invalid"
            };
            (void)[component taskToHandleActionRequest: invalidRequest].await;
            OTAssert(false, @"Invalid component selectors should reject the action task");
        } @catch (AsyncWebUIComponentException *exception) {
            OTAssert(([exception.description containsString: @"does not respond"]),
                     @"Invalid component selector failures should describe the rejected selector");
        }
    }];
}

- (void)test_web_component_render_task_emits_component_update
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        auto component = [[AsyncWebUIStatefulTestComponent alloc] init];
        [component mountToWebView: view componentID: @"root"];

        component.counter = 9;
        (void)[component taskToRender].await;

        OTAssert((view.evaluatedJavaScripts.count == 1), @"Rendering should evaluate one browser update event");
        OFString *javaScript = [view.evaluatedJavaScripts objectAtIndex: 0];
        OTAssert(([javaScript containsString: AsyncWebUIComponent.updateEventName]),
                 @"Render tasks should emit the component update event");
        OTAssert(([javaScript containsString: @"\"componentID\":\"root\""]),
                 @"Render tasks should include the mounted component ID");
        OTAssert(([javaScript containsString: @"\"counter\":9"]),
                 @"Render tasks should include the current component state");
    }];
}

- (void)test_web_view_event_javascript_is_escaped_and_evaluated
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        OFString *javaScript = [AsyncWebUIView javaScriptToDispatchEventNamed: @"state:ready\"quoted"
                                                                  payloadJSON: @"{\"ok\":true}"];

        OTAssert(([javaScript containsString: @"new CustomEvent(\"state:ready\\\"quoted\""]),
                 @"Event names should be JSON-escaped before JavaScript injection");
        OTAssert(([javaScript containsString: @"{ detail: {\"ok\":true} }"]),
                 @"Event payload JSON should be passed as the CustomEvent detail");

        [view emitEvent: @"state:ready" withJSONPayload: @"{\"phase\":1}"];
        OTAssert((view.evaluatedJavaScripts.count == 1), @"Emitting an event should evaluate one JavaScript snippet");
        OTAssert(([[view.evaluatedJavaScripts objectAtIndex: 0] containsString: @"state:ready"]),
                 @"Emitted JavaScript should contain the event name");
    }];
}

- (void)test_web_view_action_dispatch_and_unbind
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        block_reference AsyncWebUIRequest observedRequest = (AsyncWebUIRequest){0};

        [view bindAction: @"save" toHandler: ^AsyncTask<OFString *> *(AsyncWebUIRequest request) {
            observedRequest = request;
            return [AsyncTask resolved: @"{\"saved\":true}"];
        }];

        AsyncWebUIRequest request = (AsyncWebUIRequest){
            .action = @"save",
            .payloadJSON = @"{\"id\":1}",
            .requestID = @"request-1"
        };
        OFString *result = [view taskToHandleRequest: request].await;

        OTAssert(([result isEqual: @"{\"saved\":true}"]), @"Bound actions should resolve through their handler");
        OTAssert(([observedRequest.action isEqual: @"save"]), @"Action handlers should receive the action name");
        OTAssert(([observedRequest.payloadJSON isEqual: @"{\"id\":1}"]), @"Action handlers should receive payload JSON");
        OTAssert(([observedRequest.requestID isEqual: @"request-1"]), @"Action handlers should receive the request ID");

        [view unbindActionNamed: @"save"];
        OTAssert(([[view taskToHandleRequest: request].await isEqual: @"null"]),
                 @"Unbound actions should resolve to JSON null");
        OTAssert(([[view taskToHandleRequest: (AsyncWebUIRequest){0}].await isEqual: @"null"]),
                 @"Malformed action requests should resolve to JSON null");
    }];
}

- (void)test_web_view_sync_json_action_handler
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];

        [view bindAction: @"sync" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
            return [OFString stringWithFormat: @"{\"action\":%@,\"payload\":%@}",
                                            request.action.JSONRepresentation,
                                            request.payloadJSON ?: @"null"];
        }];

        AsyncWebUIRequest request = (AsyncWebUIRequest){
            .action = @"sync",
            .payloadJSON = @"{\"value\":7}",
            .requestID = @"request-sync"
        };

        OTAssert(([[view taskToHandleRequest: request].await isEqual: @"{\"action\":\"sync\",\"payload\":{\"value\":7}}"]),
                 @"Synchronous JSON handlers should be wrapped in resolved tasks");
    }];
}

- (void)test_web_view_response_javascript_and_close_state
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto view = [[AsyncWebUITestView alloc] initWithConfiguration: AsyncUIWindowConfiguration.defaults
                                                            scheduler: rootTaskGroup.scheduler];
        OFString *javaScript = [AsyncWebUIView javaScriptToResolveRequestID: @"abc"
                                                               responseJSON: @"{\"ok\":true}"];

        OTAssert(([javaScript containsString: @"asyncrt_response_abc"]),
                 @"Responses should dispatch to the request-specific response event");
        OTAssert(([javaScript containsString: @"{\"ok\":true}"]),
                 @"Responses should carry JSON response detail");
        OTAssert((not view.isClosed), @"Fresh web views should start open");
        [view close];
        OTAssert((view.isClosed), @"Closing a web view should update its close state");
    }];
}

@end

#pragma clang assume_nonnull end
