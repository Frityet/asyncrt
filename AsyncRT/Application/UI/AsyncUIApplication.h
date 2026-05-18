#pragma once

#import <AsyncRT/Application/Core.h>
#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/AsyncUIWindowConfiguration.h>
#import <AsyncRT/Core/AsyncRuntime.h>

#pragma clang assume_nonnull begin

@protocol AsyncUIContent;
@class AsyncUIWindowConfiguration;

@interface AsyncUIApplication : AsyncApplication

- (id<AsyncUIContent>)rootContent;
- (AsyncUIWindowConfiguration *nillable)windowConfiguration;
- (void)applicationDidStartWithTaskGroup: (AsyncTaskGroup *)taskGroup;
- (void)setNeedsRender;

@end

#define AsyncUI_APPLICATION_MAIN(applicationClass_) OF_APPLICATION_DELEGATE(applicationClass_)

#pragma clang assume_nonnull end
