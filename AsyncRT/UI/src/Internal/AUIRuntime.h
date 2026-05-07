#pragma once

#import "AUIWindowConfiguration.h"
#import "Internal/AUIInputState.h"
#import "Internal/AUIInteractionEngine.h"
#import "Internal/AUIRenderer.h"
#import "Internal/AUITextInputEngine.h"

#pragma clang assume_nonnull begin

@class AUIWindow;

[[subclassing_restricted, direct_members]]
@interface AUIRuntime : OFObject

@property(readonly, nonatomic) AUIWindow *nillable window;
@property(readonly, nonatomic) AUIRenderer *renderer;
@property(readonly, nonatomic) AUIInteractionEngine *interactionEngine;
@property(readonly, nonatomic) AUITextInputEngine *textInput;
@property(readonly, nonatomic) AUIInputState *inputState;

- (instancetype)initWithApplication: (AUIApplication *)application [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (id)runWithWindow: (AUIWindow *)window
          rootContent: (id<AUIContent>)rootContent
            taskGroup: (AsyncTaskGroup *)taskGroup;
- (void)setNeedsRender;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime;
- (bool)updateHoverStateFromCurrentLayout;
- (bool)consumePendingRenderRequest;
- (bool)hasPendingRenderRequest;
- (void)useWindowForTesting: (AUIWindow *nillable)window;
- (void)useRootContentForTesting: (id<AUIContent> nillable)rootContent;

@end

#pragma clang assume_nonnull end
