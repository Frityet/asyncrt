#pragma once

#import "AUIInternal.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUITextEditingController : OFObject

- (AUITextEditingState *)editingStateForIdentifier: (OFString *nillable)identifier
                                        textLength: (size_t)textLength;
- (OFString *)displayStringForText: (OFString *nillable)text
                        identifier: (OFString *nillable)identifier
                         isSecure: (bool)isSecure
                           focused: (bool)isFocused;
- (bool)applyInputState: (AUIInputState *nillable)inputState
           toRegistration: (AUIInteractionRegistration *nillable)registration
           clipboardText: (OFString *nillable (^nillable)(void))clipboardTextProvider
     setClipboardText: (void (^nillable)(OFString *nillable text))clipboardTextSetter;
- (void)retainEditingStatesForIdentifiers: (OFSet<OFString *> *)identifiers;
- (void)resetState;

@end

#pragma clang assume_nonnull end
