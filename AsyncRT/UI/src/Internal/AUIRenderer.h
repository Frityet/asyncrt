#pragma once

#import "AUIContent.h"
#import "Internal/AUIClayRuntime.h"
#import "Internal/AUIComponentHost.h"
#import "Internal/AUIInputState.h"
#import "Internal/AUIInteractionEngine.h"
#import "Internal/AUITextInputEngine.h"

#pragma clang assume_nonnull begin

@class AUIWindow;

[[subclassing_restricted, direct_members]]
@interface AUIRenderer : OFObject

@property(readonly, nonatomic) id<AUIContent> nillable rootContent;

- (instancetype)initWithApplication: (AUIApplication *)application [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attachRootContent: (id<AUIContent>)rootContent
                taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)detachRootContent;
- (void)enqueuePostRenderEffect: (void (^nonnil)(void))effectBlock;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *)inputState
                                                        window: (AUIWindow *)window
                                             interactionEngine: (AUIInteractionEngine *)interactionEngine
                                                 textInput: (AUITextInputEngine *)textInput
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester;

@end

#pragma clang assume_nonnull end
