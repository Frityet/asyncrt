#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InputState.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InteractionRegistration.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/TextInputEngine.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIInteractionEngine : OFObject

@property(readonly, nonatomic) AsyncUIContextMenu *nillable activeContextMenu;
@property(readonly, nonatomic) AsyncTaskGroup *nillable activeContextMenuTaskGroup;
@property(readonly, nonatomic) float activeContextMenuX;
@property(readonly, nonatomic) float activeContextMenuY;

- (void)beginFrame;
- (void)registerInteraction: (AsyncUIInteractionRegistration *)registration;
- (bool)isIdentifierFocused: (OFString *nillable)identifier;
- (bool)isIdentifierPressed: (OFString *nillable)identifier;
- (bool)isIdentifierHovered: (OFString *nillable)identifier;
- (bool)updateHoverStateFromCurrentLayoutWithInputState: (AsyncUIInputState *)inputState
                                            cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter;
- (void)completeFrameWithInputState: (AsyncUIInputState *)inputState
                        textInput: (AsyncUITextInputEngine *)textInput
                     clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
               setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                    cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter
                 renderRequester: (void (^nonnil)(void))renderRequester;
- (void)resetState;
- (OFArray<AsyncUIInteractionRegistration *> *)registrationsThisFrame;
- (OFSet<OFString *> *)registeredInteractionIdentifiers;

@end

#pragma clang assume_nonnull end
