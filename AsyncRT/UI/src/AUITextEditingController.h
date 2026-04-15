#pragma once

#import "AUIInternal.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUITextEditingController : OFObject

- (AUITextEditingState *)editingStateForIdentifier: (OFString *nonnil)identifier
                                        textLength: (size_t)textLength;
- (OFString *)displayStringForText: (OFString *nillable)text
                        identifier: (OFString *nillable)identifier
                         isSecure: (bool)isSecure
                           focused: (bool)isFocused;
- (bool)applyInputState: (AUIInputState *nonnil)inputState
           toRegistration: (AUIInteractionRegistration *nonnil)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter;
- (void)retainEditingStatesForIdentifiers: (OFSet<OFString *> *)identifiers;
- (void)resetState;

@end

#pragma clang assume_nonnull end
