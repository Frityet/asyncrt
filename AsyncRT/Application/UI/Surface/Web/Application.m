#import <AsyncRT/Application/UI/Surface/Web/Application.h>

#pragma clang assume_nonnull begin

@interface AsyncWebUIDefaultRootComponent : AsyncWebUIComponent

@end

@implementation AsyncWebUIDefaultRootComponent

+ (OFString *)layout
{
    return @$raw(
        <div class="root">
            <h1>Welcome to AsyncRT Web UI!</h1>
            <p>This is the default root component. Please override AsyncWebUIApplication`s rootComponent method to provide your own root component.</p>
        </div>
    );
}

+ (OFString *)styling
{
    return @$raw(
        .root {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            color: #333;
        }
    );
}

@end

@implementation AsyncWebUIApplication {
    AsyncWebUIView *nillable _webView;
    AsyncWebUIComponent *nillable _rootComponent;
}

- (bool)shouldTerminateAfterLaunchTaskCompletes
{ return false; }

- (AsyncWebUIView *nillable)webView
{ return _webView; }

- (AsyncWebUIComponent *nillable)rootComponent
{ return _rootComponent; }

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;

    auto webView = [[AsyncWebUIView alloc] initWithConfiguration: $assert_nonnil(self.windowConfiguration) scheduler: $assert_nonnil(self.scheduler)];
    _webView = webView;

    Class rootComponentClass = self.rootComponentClass;
    if (![rootComponentClass isSubclassOfClass: AsyncWebUIComponent.class])
        @throw [OFInvalidArgumentException exception];

    auto rootComponent = (AsyncWebUIComponent *)[[rootComponentClass alloc] init];
    _rootComponent = rootComponent;
    [rootComponent mountToWebView: webView componentID: @"root"];

    [webView bindAction: [AsyncWebUIComponent invokeActionName]
               toHandler: ^AsyncTask<OFString *> *(AsyncWebUIRequest request) {
                   return [rootComponent taskToHandleActionRequest: request];
               }];

    [webView loadHTML: [OFString stringWithFormat: @$raw(
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <script>%@</script>
        </head>
        <body>
            %@
        </body>
        </html>
    ), [rootComponentClass definitionJavaScript], rootComponent.elementHTML]];

    [self applicationDidStartWithWebView: webView taskGroup: taskGroup];
    while (not webView.isClosed) {
        [[taskGroup.scheduler sleepForTimeInterval: (1.0 / 60.0)] await];
        [webView pollEvents];
    }
    return @0;
}

- (AsyncUIWindowConfiguration *)windowConfiguration
{
    auto configuration = super.windowConfiguration;
    configuration.title = @"AsyncRT Web UI";
    configuration.initialSize = (AsyncUISize){ .width = 800.0f, .height = 600.0f };
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (Class)rootComponentClass
{ return AsyncWebUIDefaultRootComponent.class; }

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)webView;
    (void)taskGroup;
}

- (void)asyncApplicationWillTerminate: (OFNotification *)notification
{
    (void)notification;

    AsyncWebUIView *nillable webView = _webView;
    if (webView != nilptr)
        [$assert_nonnil(webView) close];

    _webView = nilptr;
    _rootComponent = nilptr;
}

@end

#pragma clang assume_nonnull end
