#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/UI/Surface/Web/Web.h>

#pragma clang assume_nonnull begin

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
             @"Web applications should stay alive after their launch task creates the view");
    OTAssert((webApplication.initialHTML != nilptr), @"Web applications should provide default initial HTML");
    OTAssert((webApplication.initialIRI == nilptr), @"Web applications should not load an IRI unless requested");
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
