#pragma once

#import "UI/AUIApplication.h"
#import "UI/Backend/AUIInput.h"
#import "UI/AUIPrimitives.h"
#import "UI/AUIRenderContext.h"
#import "UI/Components/Controls/AUIContextMenu.h"
#import "Utilities/DependencyTracking.h"
#import "extern/clay.h"

#pragma clang assume_nonnull begin

@class AUIBackend;

@interface AUIKeyEvent : OFObject

@property(readonly, nonatomic) AUIKey key;
@property(readonly, nonatomic) AUIModifierFlags modifiers;
@property(readonly, nonatomic, getter=isRepeat) bool repeat;

+ (instancetype)key: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat;
- (instancetype)initWithKey: (AUIKey)key
                  modifiers: (AUIModifierFlags)modifiers
                     repeat: (bool)repeat designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIInputState : OFObject

@property(nonatomic) float pointerX;
@property(nonatomic) float pointerY;
@property(nonatomic, getter=isPrimaryButtonDown) bool primaryButtonDown;
@property(nonatomic) bool primaryButtonPressedThisFrame;
@property(nonatomic) bool primaryButtonReleasedThisFrame;
@property(nonatomic, getter=isSecondaryButtonDown) bool secondaryButtonDown;
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
               selectionFocusIndex: (size_t)selectionFocusIndex designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIInteractionRegistration : OFObject

@property(readonly, copy, nonatomic) OFString *identifier;
@property(readonly, nonatomic) Clay_ElementId elementID;
@property(nonatomic, getter=isEnabled) bool enabled;
@property(nonatomic, getter=isFocusable) bool focusable;
@property(nonatomic, getter=isMultiline) bool multiline;
@property(copy, nonatomic) OFString *nillable text;
@property(nonatomic) AUICursorStyle cursorStyle;
@property(retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(copy, nonatomic) void (^nillable activateHandler)(void);
@property(copy, nonatomic) void (^nillable textChangeHandler)(OFString *text);
@property(copy, nonatomic) void (^nillable submitHandler)(OFString *text);

+ (instancetype)identifier: (OFString *nillable)identifier
                  elementID: (Clay_ElementId)elementID;
- (instancetype)initWithIdentifier: (OFString *nillable)identifier
                         elementID: (Clay_ElementId)elementID designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIRenderContext ()

+ (void)_pushCurrentContext: (AUIRenderContext *nillable)context;
+ (void)_popCurrentContext;

@end

@interface AUIComponent ()

@property(readonly, nonatomic) AUIApplication *nillable application;
@property(readonly, nonatomic) AUIComponent *nillable parent;
@property(readonly, nonatomic) OFArray<AUIComponent *> *renderedChildren;
@property(readonly, nonatomic, getter=_isMounted) bool mounted;

- (void)_attachToApplication: (AUIApplication *nillable)application
                      parent: (AUIComponent *nillable)parent;
- (void)_detachFromApplication;
- (void)_mountRecursivelyInScope: (AsyncScope *nillable)scope;
- (void)_unmountRecursively;
- (void)_renderRecursively;

@end

@interface AUIRenderObserver : OFObject<DependencyTrackingObserver>

- (instancetype)initWithInvalidationHandler: (void (^nillable)(void))invalidationHandler designated_initaliser;
- (void)beginTracking;
- (void)endTracking;
- (void)invalidate;

@end

@interface AUIApplication ()

- (AUIInputState *)_inputState;
- (void)_beginInteractionFrame;
- (void)_registerInteraction: (AUIInteractionRegistration *nillable)registration;
- (void)_completeInteractionFrame;
- (AUITextEditingState *)_editingStateForIdentifier: (OFString *nillable)identifier
                                         textLength: (size_t)textLength;
- (bool)_identifierIsFocused: (OFString *nillable)identifier;
- (bool)_identifierIsPressed: (OFString *nillable)identifier;
- (bool)_identifierIsHovered: (OFString *nillable)identifier;
- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                       deltaTime: (float)deltaTime;
- (OFString *nillable)_clipboardText;
- (void)_setClipboardText: (OFString *nillable)text;
- (void)_setCursorStyle: (AUICursorStyle)cursorStyle;
- (AUIContextMenu *nillable)_activeContextMenuForTesting;
- (void)_setBackendForTesting: (AUIBackend *nillable)backend;
- (void)_setRootComponentForTesting: (AUIComponent *nillable)rootComponent;
- (bool)_consumePendingRenderRequest;

@end

#pragma clang assume_nonnull end
