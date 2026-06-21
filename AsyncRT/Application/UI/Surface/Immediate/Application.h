#pragma once

#import <AsyncRT/Application/UI/Application.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>
#import <AsyncRT/Application/UI/Window/Configuration.h>
#import <AsyncRT/Core/AsyncRuntime.h>

#pragma clang assume_nonnull begin

@protocol AsyncUIContent;
@class AsyncUIWindowConfiguration;

@interface AsyncImmediateUIApplication : AsyncUIApplication

- (id<AsyncUIContent>)rootContent;
- (AsyncUIWindowConfiguration *)windowConfiguration;
- (void)applicationDidStart;
- (void)setNeedsRender;

@end

#pragma clang assume_nonnull end
