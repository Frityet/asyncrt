#pragma once

#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIClayRuntime.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIComponentHost.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIInputState.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIInteractionEngine.h>
#import <AsyncRT/Application/UI/Internal/AsyncUITextInputEngine.h>

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
