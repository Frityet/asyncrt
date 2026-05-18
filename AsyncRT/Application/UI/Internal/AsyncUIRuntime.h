#pragma once

#import <AsyncRT/Application/UI/AsyncUIWindowConfiguration.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIInputState.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIInteractionEngine.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIRenderer.h>
#import <AsyncRT/Application/UI/Internal/AsyncUITextInputEngine.h>

#pragma clang assume_nonnull begin

@class AsyncUIWindow;

[[subclassing_restricted, direct_members]]
@interface AsyncUIRuntime : OFObject

@property(readonly, nonatomic) AsyncUIWindow *nillable window;
@property(readonly, nonatomic) AsyncUIRenderer *renderer;
@property(readonly, nonatomic) AsyncUIInteractionEngine *interactionEngine;
@property(readonly, nonatomic) AsyncUITextInputEngine *textInput;
@property(readonly, nonatomic) AsyncUIInputState *inputState;

- (instancetype)initWithApplication: (AsyncUIApplication *)application [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (id)runWithWindow: (AsyncUIWindow *)window
          rootContent: (id<AsyncUIContent>)rootContent
            taskGroup: (AsyncTaskGroup *)taskGroup;
- (void)setNeedsRender;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                     deltaTime: (float)deltaTime;
- (bool)updateHoverStateFromCurrentLayout;
- (bool)consumePendingRenderRequest;
- (bool)hasPendingRenderRequest;
- (void)useWindowForTesting: (AsyncUIWindow *nillable)window;
- (void)useRootContentForTesting: (id<AsyncUIContent> nillable)rootContent;

@end

#pragma clang assume_nonnull end
