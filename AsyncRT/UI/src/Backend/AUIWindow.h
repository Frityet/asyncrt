#pragma once

#import "Backend/AUIInput.h"
#import "Backend/AUIWindowOptions.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

@interface AUIWindow : OFObject

@property(readonly, nonatomic) AUIApplication *application;
@property(readonly, nonatomic) AUIWindowOptions *options;
@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) AUISize viewportSize;
@property(readonly, nonatomic) double scaleFactor;
@property(nonatomic) bool isDarkMode;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options [[designated_initailiser]];
- (void)openWindow;
- (void)pollEvents;
- (void)renderFrame;
- (void)closeWindow;
- (void)setCursorStyle: (AUICursorStyle)cursorStyle;
- (OFString *nillable)clipboardText;
- (void)setClipboardText: (OFString *nillable)text;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
