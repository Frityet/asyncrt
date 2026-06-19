#pragma once

#import <AsyncRT/Application/UI/Application.h>
#import <AsyncRT/Application/UI/Surface/Web/View.h>

#pragma clang assume_nonnull begin

@interface AsyncWebUIApplication : AsyncUIApplication

@property(readonly, nonatomic) AsyncWebUIView *webView;

- (Class)webViewClass;
- (OFString *nillable)initialHTML;
- (OFIRI *nillable)initialIRI;
- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
                             taskGroup: (AsyncTaskGroup *)taskGroup;

@end

#define AsyncWebUI_APPLICATION_MAIN(applicationClass_) OF_APPLICATION_DELEGATE(applicationClass_)

#pragma clang assume_nonnull end
