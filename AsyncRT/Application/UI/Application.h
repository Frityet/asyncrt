#pragma once

#import <AsyncRT/Application/Core.h>
#import <AsyncRT/Application/UI/Window/Configuration.h>

#pragma clang assume_nonnull begin

@interface AsyncUIApplication : AsyncApplication

- (AsyncUIWindowConfiguration *)windowConfiguration;
- (void)applicationDidStart;
- (void)setNeedsRender;

@end

#define AsyncUI_APPLICATION_MAIN(applicationClass_) OF_APPLICATION_DELEGATE(applicationClass_)

#pragma clang assume_nonnull end
