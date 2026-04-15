#pragma once

#import "AUIInteractionController.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIRenderHost : OFObject

@property(readonly, nonatomic) AUIViewComponent *nillable rootViewComponent;

- (instancetype)initWithApplication: (AUIApplication *nonnil)application [[designated_initailiser]];
- (void)attachRootViewComponent: (AUIViewComponent *nonnil)rootViewComponent
                      taskGroup: (AsyncTaskGroup *nonnil)taskGroup;
- (void)detachRootViewComponent;
- (void)setRootViewComponentForTesting: (AUIViewComponent *nillable)rootViewComponent;
- (void)enqueuePostRenderEffect: (void (^nonnil)(void))effectBlock;
- (Clay_RenderCommandArray)buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                     deltaTime: (float)deltaTime
                                                    inputState: (AUIInputState *nonnil)inputState
                                                        window: (AUIWindow *nonnil)window
                                         interactionController: (AUIInteractionController *nonnil)interactionController
                                         textEditingController: (AUITextEditingController *nonnil)textEditingController
                                                 clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
                                           setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                                                cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                                           renderRequester: (void (^nonnil)(void))renderRequester;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
