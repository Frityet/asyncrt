#pragma once

#import <AsyncRT/Application/UI/Backend/AsyncUIWindow.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIHeadlessWindow : AsyncUIWindow

- (void)setViewportSize: (AsyncUISize)viewportSize;
- (void)setNativeSize: (AsyncUISize)nativeSize;
- (void)sendPointerMoveToX: (float)x y: (float)y;
- (void)sendMouseDown: (AsyncUIMouseButton)button;
- (void)sendMouseUp: (AsyncUIMouseButton)button;
- (void)sendScrollByX: (float)deltaX y: (float)deltaY;
- (void)sendKey: (AsyncUIKey)key modifiers: (AsyncUIModifierFlags)modifiers repeat: (bool)repeat;
- (void)sendText: (OFString *nillable)text;

@end

#pragma clang assume_nonnull end
