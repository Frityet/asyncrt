#pragma once

#import "AUIInternal.h"
#import "AUITextEditingController.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIInteractionController : OFObject

@property(readonly, nonatomic) AUIContextMenu *nillable activeContextMenu;
@property(readonly, nonatomic) float activeContextMenuX;
@property(readonly, nonatomic) float activeContextMenuY;

- (void)beginFrame;
- (void)registerInteraction: (AUIInteractionRegistration *nonnil)registration;
- (bool)isIdentifierFocused: (OFString *nillable)identifier;
- (bool)isIdentifierPressed: (OFString *nillable)identifier;
- (bool)isIdentifierHovered: (OFString *nillable)identifier;
- (bool)updateHoverStateFromCurrentLayoutWithInputState: (AUIInputState *nonnil)inputState
                                            cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter;
- (void)completeFrameWithInputState: (AUIInputState *nonnil)inputState
               textEditingController: (AUITextEditingController *nonnil)textEditingController
                      clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                     cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                renderRequester: (void (^nonnil)(void))renderRequester;
- (void)resetState;
- (OFArray<AUIInteractionRegistration *> *)registrationsThisFrame;
- (OFSet<OFString *> *)registeredInteractionIdentifiers;

@end

#pragma clang assume_nonnull end
