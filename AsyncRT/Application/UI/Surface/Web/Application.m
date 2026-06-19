#import <AsyncRT/Application/UI/Surface/Web/Application.h>

#pragma clang assume_nonnull begin

@implementation AsyncWebUIApplication {
    AsyncWebUIView *_webView;
}

- (bool)shouldTerminateAfterLaunchTaskCompletes
{
    return false;
}

- (AsyncWebUIView *)webView
{
    return _webView;
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;

    AsyncUIWindowConfiguration *nillable configuration = self.windowConfiguration;
    if (configuration == nilptr)
        configuration = AsyncUIWindowConfiguration.defaults;

    Class webViewClass = self.webViewClass;
    _webView = [[webViewClass alloc] initWithConfiguration: $assert_nonnil(configuration)
                                                 scheduler: $assert_nonnil(self.scheduler)];

    OFString *nillable html = self.initialHTML;
    OFIRI *nillable IRI = self.initialIRI;

    if (html != nilptr)
        [_webView loadHTML: $assert_nonnil(html)];
    else if (IRI != nilptr)
        [_webView loadIRI: $assert_nonnil(IRI)];

    [self applicationDidStartWithWebView: _webView taskGroup: taskGroup];

    while (not _webView.isClosed) {
        [_webView pollEvents];
        if (_webView.isClosed)
            break;

        (void)[taskGroup.scheduler sleepForTimeInterval: (1.0 / 60.0)].await;
    }

    return @0;
}

- (AsyncUIWindowConfiguration *nillable)windowConfiguration
{
    auto configuration = super.windowConfiguration;
    configuration.title = @"AsyncRT Web UI";
    configuration.initialSize = (AsyncUISize){ .width = 800.0f, .height = 600.0f };
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (Class)webViewClass
{
    return AsyncWebUIView.class;
}

- (OFString *nillable)initialHTML
{
    return @"<!doctype html><html><head><meta charset=\"utf-8\"></head><body></body></html>";
}

- (OFIRI *nillable)initialIRI
{
    return nilptr;
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
                             taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)webView;
    (void)taskGroup;
}

- (void)asyncApplicationWillTerminate: (OFNotification *)notification
{
    (void)notification;

    if (_webView != nilptr)
        [$assert_nonnil(_webView) close];
}

@end

#pragma clang assume_nonnull end
