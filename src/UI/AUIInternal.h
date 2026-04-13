#pragma once

#import "UI/AUIApplication.h"
#import "UI/AUIViewComponent.h"
#import "UI/Backend/AUIInput.h"
#import "UI/AUIPrimitives.h"
#import "UI/AUIRenderContext.h"
#import "UI/Components/Controls/AUIContextMenu.h"
#import "extern/clay.h"

#pragma clang assume_nonnull begin

@class AUIWindow;
@class AUIInteractionController;
@class AUITextEditingController;
@class AUIRenderHost;

typedef Clay_Dimensions (*AUITextMeasureFunction)(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *nillable userData);

[[subclassing_restricted, direct_members]]
@interface AUIKeyEvent : OFObject

@property(readonly, nonatomic) AUIKey key;
@property(readonly, nonatomic) AUIModifierFlags modifiers;
@property(readonly, nonatomic) bool isRepeat;

+ (instancetype)key: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat;
- (instancetype)initWithKey: (AUIKey)key
                  modifiers: (AUIModifierFlags)modifiers
                     repeat: (bool)repeat [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIInputState : OFObject

@property(nonatomic) float pointerX;
@property(nonatomic) float pointerY;
@property(nonatomic) bool isPrimaryButtonDown;
@property(nonatomic) bool primaryButtonPressedThisFrame;
@property(nonatomic) bool primaryButtonReleasedThisFrame;
@property(nonatomic) bool isSecondaryButtonDown;
@property(nonatomic) bool secondaryButtonPressedThisFrame;
@property(nonatomic) bool secondaryButtonReleasedThisFrame;
@property(nonatomic) float scrollDeltaX;
@property(nonatomic) float scrollDeltaY;
@property(copy, nonatomic) OFString *typedText;
@property(readonly, nonatomic) OFArray<AUIKeyEvent *> *keyEvents;

- (void)movePointerToX: (float)x y: (float)y;
- (void)pressMouseButton: (AUIMouseButton)button;
- (void)releaseMouseButton: (AUIMouseButton)button;
- (void)scrollByX: (float)deltaX y: (float)deltaY;
- (void)addKey: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat;
- (void)insertText: (OFString *nillable)text;
- (void)appendCodepoint: (unsigned int)codepoint;
- (void)resetTransientState;

@end

[[subclassing_restricted, direct_members]]
@interface AUITextEditingState : OFObject

@property(nonatomic) size_t caretIndex;
@property(nonatomic) size_t selectionAnchorIndex;
@property(nonatomic) size_t selectionFocusIndex;

+ (instancetype)caretIndex: (size_t)caretIndex
      selectionAnchorIndex: (size_t)selectionAnchorIndex
       selectionFocusIndex: (size_t)selectionFocusIndex;
- (instancetype)initWithCaretIndex: (size_t)caretIndex;
- (instancetype)initWithCaretIndex: (size_t)caretIndex
              selectionAnchorIndex: (size_t)selectionAnchorIndex
               selectionFocusIndex: (size_t)selectionFocusIndex [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIInteractionRegistration : OFObject

@property(readonly, copy, nonatomic) OFString *identifier;
@property(readonly, nonatomic) Clay_ElementId elementID;
@property(nonatomic) bool isEnabled;
@property(nonatomic) bool isFocusable;
@property(nonatomic) bool isMultiline;
@property(copy, nonatomic) OFString *nillable text;
@property(nonatomic) AUICursorStyle cursorStyle;
@property(retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(copy, nonatomic) void (^nillable activateHandler)(void);
@property(copy, nonatomic) void (^nillable textChangeHandler)(OFString *text);
@property(copy, nonatomic) void (^nillable submitHandler)(OFString *text);

+ (instancetype)identifier: (OFString *nillable)identifier
                  elementID: (Clay_ElementId)elementID;
- (instancetype)initWithIdentifier: (OFString *nillable)identifier
                         elementID: (Clay_ElementId)elementID [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIRenderContext ()

+ (void)_pushCurrentContext: (AUIRenderContext *nillable)context [[direct]];
+ (void)_popCurrentContext [[direct]];

@end

@interface AUIViewComponent ()

@property(readwrite, nonatomic) AUIApplication *nillable application;
@property(readwrite, nonatomic) AUIViewComponent *nillable parentViewComponent;
@property(readwrite, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readwrite, nonatomic) bool isMounted;

- (void)_attachToApplication: (AUIApplication *nillable)application
         parentViewComponent: (AUIViewComponent *nillable)parentViewComponent
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)_detachFromApplication;
- (void)_ensureMountedInTaskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)_unmountRecursively;
- (AUIViewNode *)_resolvedRenderedViewNode;

@end

@interface AUIViewNode ()

- (instancetype)initWithNodeFamily: (AUIViewNodeFamily)nodeFamily
                          stableKey: (OFString *nillable)stableKey;

@end

[[subclassing_restricted]]
@interface AUIRetainedChildViewComponentNode : AUIViewNode

@property(readonly, nonatomic) AUIViewComponent *childViewComponent;
@property(readonly, copy, nonatomic) OFString *componentKey;

- (instancetype)initWithChildViewComponent: (AUIViewComponent *nillable)childViewComponent
                               componentKey: (OFString *nillable)componentKey [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIApplication ()

- (AUIInputState *)_inputState;
- (AUIInteractionController *)_interactionController;
- (AUITextEditingController *)_textEditingController;
- (AUIRenderHost *)_renderHost;
- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                       deltaTime: (float)deltaTime;
- (OFString *nillable)_clipboardText;
- (void)_setClipboardText: (OFString *nillable)text;
- (void)_setCursorStyle: (AUICursorStyle)cursorStyle;
- (AUIContextMenu *nillable)_activeContextMenuForTesting;
- (void)_setWindowForTesting: (AUIWindow *nillable)window;
- (void)_setRootViewComponentForTesting: (AUIViewComponent *nillable)rootViewComponent;
- (bool)_updateHoverStateFromCurrentLayout;
- (bool)_consumePendingRenderRequest;
- (bool)_hasPendingRenderRequest;

@end

@interface AUIWindow ()

- (Clay_RenderCommandArray)_buildRenderCommandsForViewportSize: (AUISize)viewportSize
                                           textMeasureFunction: (AUITextMeasureFunction)textMeasureFunction
                                                      userData: (void *nillable)userData;
- (void)_setViewportSize: (AUISize)viewportSize;
- (void)_setDarkMode: (bool)darkMode explicitly: (bool)explicitly;
- (bool)_hasExplicitDarkMode;

@end

#pragma clang assume_nonnull end
