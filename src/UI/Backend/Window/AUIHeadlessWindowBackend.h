#pragma once

#import "UI/Backend/AUIWindowBackend.h"

#pragma clang assume_nonnull begin

@interface AUIHeadlessWindowBackend : AUIWindowBackend

- (void)setViewportSize: (AUISize)viewportSize;
- (void)sendPointerMoveToX: (float)x y: (float)y;
- (void)sendMouseDown: (AUIMouseButton)button;
- (void)sendMouseUp: (AUIMouseButton)button;
- (void)sendScrollByX: (float)deltaX y: (float)deltaY;
- (void)sendKey: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat;
- (void)sendText: (OFString *nillable)text;

@end

#pragma clang assume_nonnull end
