#pragma once

#import "AUIApplication.h"
#import "Internal/AUIRuntime.h"

#pragma clang assume_nonnull begin

@interface AUIApplication ()

@property(readonly, nonatomic) AUIRuntime *runtime;

- (AUIInputState *)_inputState;
- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                       deltaTime: (float)deltaTime;
- (bool)_updateHoverStateFromCurrentLayout;
- (bool)_consumePendingRenderRequest;
- (bool)_hasPendingRenderRequest;
- (AUIContextMenu *nillable)_activeContextMenuForTesting;
- (void)_setWindowForTesting: (AUIWindow *nillable)window;
- (void)_setRootContentForTesting: (id<AUIContent> nillable)rootContent;

@end

#pragma clang assume_nonnull end
