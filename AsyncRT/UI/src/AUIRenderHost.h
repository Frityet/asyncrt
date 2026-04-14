#pragma once

#import "AUIInteractionController.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIRenderHost : OFObject

@property(readonly, nonatomic) AUIViewComponent *nillable rootViewComponent;

- (instancetype)initWithApplication: (AUIApplication *nillable)application [[designated_initailiser]];
- (void)attachRootViewComponent: (AUIViewComponent *nillable)rootViewComponent
                      taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)detachRootViewComponent;
- (void)setRootViewComponentForTesting: (AUIViewComponent *nillable)rootViewComponent;
- (void)enqueuePostRenderEffect: (void (^nillable)(void))effectBlock;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *nillable)inputState
                                                        window: (AUIWindow *nillable)window
                                         interactionController: (AUIInteractionController *nillable)interactionController
                                         textEditingController: (AUITextEditingController *nillable)textEditingController
                                                 clipboardText: (OFString *nillable (^nillable)(void))clipboardTextProvider
                                           setClipboardText: (void (^nillable)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nillable)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nillable)(void))renderRequester;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
