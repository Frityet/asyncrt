#pragma once

#import <AsyncRT/Application/UI/Backend/AsyncUIInput.h>
#import <AsyncRT/Application/UI/AsyncUIRenderContext.h>
#import <AsyncRT/Application/UI/AsyncUIWindowConfiguration.h>

#pragma clang assume_nonnull begin

@class AsyncUIApplication;

@interface AsyncUIWindow : OFObject

@property(readonly, nonatomic) AsyncUIApplication *application;
@property(readonly, nonatomic) AsyncUIWindowConfiguration *configuration;
@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) AsyncUISize viewportSize;
@property(readonly, nonatomic) double scaleFactor;
@property(nonatomic) bool isDarkMode;

- (instancetype)initWithApplication: (AsyncUIApplication *nonnil)application
                      configuration: (AsyncUIWindowConfiguration *nonnil)configuration [[designated_initailiser]];
- (void)openWindow;
- (void)pollEvents;
- (void)renderFrame;
- (void)closeWindow;
- (void)setCursorStyle: (AsyncUICursorStyle)cursorStyle;
- (OFString *nillable)clipboardText;
- (void)setClipboardText: (OFString *nillable)text;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
