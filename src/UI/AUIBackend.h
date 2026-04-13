#pragma once

#import "UI/AUIInternal.h"
#import "UI/Backend/AUIRendererBackend.h"
#import "UI/Backend/AUIWindowBackend.h"

#include <cairo.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIBackend : OFObject

@property(readonly, nonatomic) AUIApplication *application;
@property(readonly, nonatomic) AUIWindowBackend *windowBackend;
@property(readonly, nonatomic) AUIRendererBackend *rendererBackend;
@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) AUISize viewportSize;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                        windowBackend: (AUIWindowBackend *nillable)windowBackend
                      rendererBackend: (AUIRendererBackend *nillable)rendererBackend [[designated_initailiser]];
- (void)openWindow;
- (void)pollEvents;
- (void)renderFrame;
- (void)closeWindow;
- (OFString *nillable)clipboardText;
- (void)setClipboardText: (OFString *nillable)text;
- (void)setCursorStyle: (AUICursorStyle)cursorStyle;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIWindowBackend (AUIBackendInternal)

- (void)_renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock;

@end

@interface AUIRendererBackend (AUIBackendInternal)

- (void)_prepareForViewportSize: (AUISize)viewportSize;
- (void)_renderApplication: (AUIApplication *)application
                 inputState: (AUIInputState *)inputState
               viewportSize: (AUISize)viewportSize
                      cairo: (cairo_t *)cairo;

@end

#pragma clang assume_nonnull end
