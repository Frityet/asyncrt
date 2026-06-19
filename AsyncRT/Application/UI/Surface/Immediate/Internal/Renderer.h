#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/ClayRuntime.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/ComponentHost.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InputState.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InteractionEngine.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/TextInputEngine.h>

#pragma clang assume_nonnull begin

@class AsyncUIWindow;

[[subclassing_restricted, direct_members]]
@interface AsyncUIRenderer : OFObject

@property(readonly, nonatomic) id<AsyncUIContent> nillable rootContent;

- (instancetype)initWithApplication: (AsyncUIApplication *)application [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attachRootContent: (id<AsyncUIContent>)rootContent
                taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)detachRootContent;
- (void)enqueuePostRenderEffect: (void (^nonnil)(void))effectBlock;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AsyncUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AsyncUIInputState *)inputState
                                                        window: (AsyncUIWindow *)window
                                             interactionEngine: (AsyncUIInteractionEngine *)interactionEngine
                                                 textInput: (AsyncUITextInputEngine *)textInput
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester;

@end

#pragma clang assume_nonnull end
