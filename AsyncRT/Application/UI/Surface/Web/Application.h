#pragma once

#import <AsyncRT/Application/UI/Application.h>
#import "View.h"
#import "Component.h"

#pragma clang assume_nonnull begin

@interface AsyncWebUIApplication : AsyncUIApplication

@property(readonly, nonatomic) AsyncWebUIView *nillable webView;
@property(readonly, nonatomic) AsyncWebUIComponent *nillable rootComponent;

- (Class)rootComponentClass;
- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView taskGroup: (AsyncTaskGroup *)taskGroup;

@end

#define AsyncWebUI_APPLICATION_MAIN(applicationClass_) OF_APPLICATION_DELEGATE(applicationClass_)

#pragma clang assume_nonnull end
