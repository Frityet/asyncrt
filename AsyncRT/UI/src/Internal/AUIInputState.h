#pragma once

#import "Internal/AUIKeyEvent.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIInputState : OFObject

@property(nonatomic) float pointerX;
@property(nonatomic) float pointerY;
@property(nonatomic) bool isPrimaryButtonDown;
@property(nonatomic) bool primaryButtonPressedThisFrame;
@property(nonatomic) bool primaryButtonReleasedThisFrame;
@property(nonatomic) bool isSecondaryButtonDown;
@property(nonatomic) bool secondaryButtonPressedThisFrame;
@property(nonatomic) bool secondaryButtonReleasedThisFrame;
@property(nonatomic) float scrollDeltaX;
@property(nonatomic) float scrollDeltaY;
@property(copy, nonatomic) OFString *typedText;
@property(readonly, nonatomic) OFArray<AUIKeyEvent *> *keyEvents;

- (void)movePointerToX: (float)x y: (float)y;
- (void)pressMouseButton: (AUIMouseButton)button;
- (void)releaseMouseButton: (AUIMouseButton)button;
- (void)scrollByX: (float)deltaX y: (float)deltaY;
- (void)addKey: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat;
- (void)insertText: (OFString *nillable)text;
- (void)appendCodepoint: (unsigned int)codepoint;
- (void)resetTransientState;

@end

#pragma clang assume_nonnull end
