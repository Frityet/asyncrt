#pragma once

#import "Internal/AUIInputState.h"
#import "Internal/AUIInteractionRegistration.h"
#import "Internal/AUITextInputState.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUITextInputEngine : OFObject

- (AUITextInputState *)inputStateForIdentifier: (OFString *)identifier
                                    textLength: (size_t)textLength;
- (OFString *)displayStringForText: (OFString *nillable)text
                        identifier: (OFString *nillable)identifier
                          isSecure: (bool)isSecure
                           focused: (bool)isFocused;
- (bool)applyInputState: (AUIInputState *)inputState
            registration: (AUIInteractionRegistration *)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter;
- (void)retainStatesForIdentifiers: (OFSet<OFString *> *)identifiers;
- (void)resetState;

@end

#pragma clang assume_nonnull end
