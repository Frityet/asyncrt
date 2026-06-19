#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Application.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Runtime.h>

#pragma clang assume_nonnull begin

@interface AsyncImmediateUIApplication ()

@property(readonly, nonatomic) AsyncUIRuntime *runtime;

- (AsyncUIInputState *)_inputState;
- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                       deltaTime: (float)deltaTime;
- (bool)_updateHoverStateFromCurrentLayout;
- (bool)_consumePendingRenderRequest;
- (bool)_hasPendingRenderRequest;
- (AsyncUIContextMenu *nillable)_activeContextMenuForTesting;
- (void)_setWindowForTesting: (AsyncUIWindow *nillable)window;
- (void)_setRootContentForTesting: (id<AsyncUIContent> nillable)rootContent;

@end

#pragma clang assume_nonnull end
