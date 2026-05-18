#pragma once

#import <AsyncRT/Application/UI/AsyncUIApplication.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIRuntime.h>

#pragma clang assume_nonnull begin

@interface AsyncUIApplication ()

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
