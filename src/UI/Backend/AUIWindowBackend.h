#pragma once

#import "UI/Backend/AUIInput.h"
#import "UI/Backend/AUIWindowOptions.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

@interface AUIWindowBackend : OFObject

@property(readonly, nonatomic) AUIApplication *application;
@property(readonly, nonatomic) AUIWindowOptions *options;
@property(readonly, nonatomic, getter=isOpen) bool open;
@property(readonly, nonatomic) AUISize viewportSize;
@property(readonly, nonatomic) double scaleFactor;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options designated_initaliser;
- (void)openWindow;
- (void)pollEvents;
- (void)closeWindow;
- (void)setCursorStyle: (AUICursorStyle)cursorStyle;
- (OFString *nillable)clipboardText;
- (void)setClipboardText: (OFString *nillable)text;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
