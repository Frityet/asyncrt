#pragma once

#import "UI/AUIInternal.h"
#import "UI/AUITextEditingController.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIInteractionController : OFObject

@property(readonly, nonatomic) AUIContextMenu *nillable activeContextMenu;
@property(readonly, nonatomic) float activeContextMenuX;
@property(readonly, nonatomic) float activeContextMenuY;

- (void)beginFrame;
- (void)registerInteraction: (AUIInteractionRegistration *nillable)registration;
- (bool)isIdentifierFocused: (OFString *nillable)identifier;
- (bool)isIdentifierPressed: (OFString *nillable)identifier;
- (bool)isIdentifierHovered: (OFString *nillable)identifier;
- (bool)updateHoverStateFromCurrentLayoutWithInputState: (AUIInputState *nillable)inputState
                                            cursorSetter: (void (^nillable)(AUICursorStyle cursorStyle))cursorSetter;
- (void)completeFrameWithInputState: (AUIInputState *nillable)inputState
               textEditingController: (AUITextEditingController *nillable)textEditingController
                      clipboardText: (OFString *nillable (^nillable)(void))clipboardTextProvider
                setClipboardText: (void (^nillable)(OFString *nillable text))clipboardTextSetter
                     cursorSetter: (void (^nillable)(AUICursorStyle cursorStyle))cursorSetter
                renderRequester: (void (^nillable)(void))renderRequester;
- (void)resetState;
- (OFArray<AUIInteractionRegistration *> *)registrationsThisFrame;
- (OFSet<OFString *> *)registeredInteractionIdentifiers;

@end

#pragma clang assume_nonnull end
