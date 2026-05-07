#pragma once

#import "AUIContent.h"
#import "AUIWindowConfiguration.h"
#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

@interface AUIApplication : AsyncApplication

- (id<AUIContent>)rootContent;
- (AUIWindowConfiguration *nillable)windowConfiguration;
- (void)applicationDidStartWithTaskGroup: (AsyncTaskGroup *)taskGroup;
- (void)setNeedsRender;

@end

#define AUI_APPLICATION_MAIN(applicationClass_) OF_APPLICATION_DELEGATE(applicationClass_)

#pragma clang assume_nonnull end
