#import <AsyncRT/Application/Core/AsyncApplication.h>

#import "AsyncWebUIView.h"

@interface AsyncWebUIApplication : AsyncApplication

@property(readonly, nonatomic) AsyncWebUIView *nillable webView;

- (AsyncWebUIWindowConfiguration *)windowConfiguration;
- (OFString *nillable)initialHTML;
- (OFIRI *nillable)initialIRI;

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
                             taskGroup: (AsyncTaskGroup *)taskGroup;

@end

#define AsyncWebUI_APPLICATION_MAIN(applicationClass_) \
    OF_APPLICATION_DELEGATE(applicationClass_)
