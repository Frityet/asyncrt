#include "AsyncWebUIApplication.h"

@implementation AsyncWebUIApplication

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification taskGroup: (AsyncTaskGroup *)taskGroup
{
    AsyncWebUIWindowConfiguration *config = [self windowConfiguration];
    _webView = [[AsyncWebUIView alloc] initWithConfiguration:config scheduler:self.scheduler];

    OFString *html = [self initialHTML];
    OFIRI *iri = [self initialIRI];

    if (html != nil) {
        [_webView loadHTML:html];
    } else if (iri != nil) {
        [_webView loadIRI:iri];
    }

    [self applicationDidStartWithWebView:_webView taskGroup:taskGroup];

    return @0;
}

- (AsyncWebUIWindowConfiguration *)windowConfiguration
{
    AsyncWebUIWindowConfiguration *config = [AsyncWebUIWindowConfiguration configuration];
    config.title = [self title];
    return config;
}

- (OFString *nillable)initialHTML
{
    return [self rootContent];
}

- (OFIRI *nillable)initialIRI
{
    return nil;
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView taskGroup: (AsyncTaskGroup *)taskGroup
{
    // Default implementation does nothing
}

// Deprecated stuff for backward compatibility or simple tests
- (OFString *)title
{ return @"AsyncWebUIApplication"; }

- (OFString *)rootContent
{ return @"<html><body><h1>Hello, AsyncWebUIApplication!</h1></body></html>"; }

- (AsyncTask<OFString *> *)taskForContents
{ return [AsyncTask resolved: self.rootContent]; }

@end
