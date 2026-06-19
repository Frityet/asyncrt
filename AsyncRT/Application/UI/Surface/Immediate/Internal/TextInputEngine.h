#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InputState.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InteractionRegistration.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/TextInputState.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUITextInputEngine : OFObject

- (AsyncUITextInputState *)inputStateForIdentifier: (OFString *)identifier
                                    textLength: (size_t)textLength;
- (OFString *)displayStringForText: (OFString *nillable)text
                        identifier: (OFString *nillable)identifier
                          isSecure: (bool)isSecure
                           focused: (bool)isFocused;
- (bool)applyInputState: (AsyncUIInputState *)inputState
            registration: (AsyncUIInteractionRegistration *)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter;
- (void)retainStatesForIdentifiers: (OFSet<OFString *> *)identifiers;
- (void)resetState;

@end

#pragma clang assume_nonnull end
