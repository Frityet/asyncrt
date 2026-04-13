#import "UI/AUIClaySupport.h"
#import "UI/AUIInternal.h"
#import "UI/Components/Controls/AUIContextMenuRegion.h"

#pragma clang assume_nonnull begin

@class AUIRenderPassState;

@namespace(AUIRenderTreeSupport)

+ (bool)array: (OFArray *)array containsIdenticalObject: (id)object;
+ (size_t)identityIndexOfObject: (id)object inArray: (OFArray *)array;
+ (AUIRenderException *)validationExceptionWithReason: (OFString *)reason;
+ (OFString *)childPathFromParentPath: (OFString *)parentPath index: (size_t)index;
+ (AUIColor)interactiveBackgroundForBox: (AUIInteractiveBox *)box
                             identifier: (OFString *)identifier
                                  owner: (AUIComponent *)owner;
+ (OFString *)maskedStringWithLength: (size_t)length;
+ (OFString *)displayStringForTextInput: (AUITextInput *)textInput
                             identifier: (OFString *)identifier
                                  owner: (AUIComponent *)owner;
+ (void)renderText: (OFString *nillable)text style: (AUITextStyle)style;
+ (void)renderComponentChild: (AUIComponent *nillable)child
                       owner: (AUIComponent *)owner
                       state: (AUIRenderPassState *)state
                        path: (OFString *)path
          referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
       newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren;
+ (void)renderChildren: (OFArray<id<AUIRenderable>> *nillable)children
                  owner: (AUIComponent *)owner
                  state: (AUIRenderPassState *)state
             parentPath: (OFString *)parentPath
     referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
    newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren;
+ (void)renderRenderable: (id<AUIRenderable> nillable)renderable
                    owner: (AUIComponent *)owner
                    state: (AUIRenderPassState *)state
                     path: (OFString *)path
       referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
      newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren;

@end

[[subclassing_restricted, direct_members]]
@interface AUIRenderPassState : OFObject

@property(readonly, nonatomic) AsyncScope *mountScope;

- (instancetype)initWithMountScope: (AsyncScope *nillable)mountScope [[designated_initailiser]];
- (bool)isRenderingComponent: (AUIComponent *)component;
- (void)pushRenderingComponent: (AUIComponent *nillable)component;
- (void)popRenderingComponent;
- (void)registerChildComponent: (AUIComponent *nillable)child parent: (AUIComponent *nillable)parent;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIComponent ()

- (void)_renderWithState: (AUIRenderPassState *)state path: (OFString *)path;

@end

@implementation AUIRenderPassState {
    AsyncScope *_mountScope;
    OFMutableArray<AUIComponent *> *_componentStack;
    OFMutableArray<AUIComponent *> *_registeredComponents;
    OFMutableArray<AUIComponent *> *_registeredParents;
}


- (instancetype)initWithMountScope: (AsyncScope *nillable)mountScope
{
    if (mountScope == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _mountScope = $assert_nonnil(mountScope);
    _componentStack = [OFMutableArray array];
    _registeredComponents = [OFMutableArray array];
    _registeredParents = [OFMutableArray array];
    return self;
}

- (bool)isRenderingComponent: (AUIComponent *)component
{
    return [AUIRenderTreeSupport array: _componentStack containsIdenticalObject: component];
}

- (void)pushRenderingComponent: (AUIComponent *nillable)component
{
    if (component == nilptr)
        @throw [OFInvalidArgumentException exception];
    if ([self isRenderingComponent: $assert_nonnil(component)])
        @throw [AUIRenderTreeSupport validationExceptionWithReason: @"Component body formed a render cycle"];

    [_componentStack addObject: $assert_nonnil(component)];
}

- (void)popRenderingComponent
{
    if (_componentStack.count == 0)
        @throw [OFOutOfRangeException exception];

    [_componentStack removeObjectAtIndex: _componentStack.count - 1];
}

- (void)registerChildComponent: (AUIComponent *nillable)child parent: (AUIComponent *nillable)parent
{
    size_t existingIndex;
    AUIComponent *nillable existingParent = nilptr;

    if (child == nilptr or parent == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (child == parent)
        @throw [AUIRenderTreeSupport validationExceptionWithReason: @"A component cannot return itself from -body"];
    if ([self isRenderingComponent: $assert_nonnil(child)])
        @throw [AUIRenderTreeSupport validationExceptionWithReason: @"Component body formed a recursive child cycle"];

    existingIndex = [AUIRenderTreeSupport identityIndexOfObject: $assert_nonnil(child) inArray: _registeredComponents];
    if (existingIndex == OFNotFound) {
        [_registeredComponents addObject: $assert_nonnil(child)];
        [_registeredParents addObject: $assert_nonnil(parent)];
        return;
    }

    existingParent = [_registeredParents objectAtIndex: existingIndex];
    if (existingParent == parent)
        @throw [AUIRenderTreeSupport validationExceptionWithReason: @"A component cannot appear twice under the same parent"];

    @throw [AUIRenderTreeSupport validationExceptionWithReason: @"The same component cannot appear under multiple parents in one render pass"];
}

@end

@implementation AUIComponent {
    unretained AUIApplication *_application;
    unretained AUIComponent *_parent;
    OFArray<AUIComponent *> *_renderedChildren;
    AsyncScope *nillable _mountScope;
}


- (instancetype)init
{
    self = [super init];
    _renderedChildren = [OFArray array];
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIGroup children: @[]];
}

- (bool)_isMounted
{
    return (_mountScope != nilptr);
}

- (void)mountInScope: (AsyncScope *)scope
{
    (void)scope;
}

- (void)unmount
{
}

- (void)setNeedsRender
{
    if (_application != nilptr)
        [_application setNeedsRender];
}

- (void)_attachToApplication: (AUIApplication *nillable)application
                      parent: (AUIComponent *nillable)parent
{
    _application = application;
    _parent = parent;

    for (AUIComponent *child in _renderedChildren)
        [child _attachToApplication: application parent: self];
}

- (void)_detachFromApplication
{
    for (AUIComponent *child in _renderedChildren)
        [child _detachFromApplication];

    _application = nilptr;
    _parent = nilptr;
}

- (void)_mountRecursivelyInScope: (AsyncScope *nillable)scope
{
    if (scope == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (_mountScope != nilptr)
        return;

    _mountScope = scope;

    @try {
        [self mountInScope: $assert_nonnil(scope)];
    } @catch (OFException *exception) {
        _mountScope = nilptr;
        @throw exception;
    }

    [self setNeedsRender];
}

- (void)_unmountRecursively
{
    OFArray<AUIComponent *> *children = [_renderedChildren copy];

    if (_mountScope == nilptr)
        return;

    for (AUIComponent *child in children) {
        [child _unmountRecursively];
        [child _detachFromApplication];
    }

    _renderedChildren = [OFArray array];
    _mountScope = nilptr;
    [self unmount];
    [self setNeedsRender];
}

- (void)_renderRecursively
{
    AUIRenderPassState *state;

    if (_mountScope == nilptr)
        @throw [AUIRenderTreeSupport validationExceptionWithReason: @"Cannot render an unmounted component"];

    state = [[AUIRenderPassState alloc] initWithMountScope: $assert_nonnil(_mountScope)];
    [self _renderWithState: state path: @"root"];
}

- (void)_renderWithState: (AUIRenderPassState *)state path: (OFString *)path
{
    id<AUIRenderable> renderable;
    OFArray<AUIComponent *> *previousChildren = [_renderedChildren copy];
    OFMutableArray<AUIComponent *> *referencedChildren = [OFMutableArray array];
    OFMutableArray<AUIComponent *> *newlyMountedChildren = [OFMutableArray array];
    bool didRenderSuccessfully = false;

    [state pushRenderingComponent: self];

    @try {
        renderable = [self body];
        if (renderable == nilptr)
            @throw [AUIRenderTreeSupport validationExceptionWithReason: @"-body must return a nonnil renderable"];

        [AUIRenderTreeSupport renderRenderable: renderable
                                         owner: self
                                         state: state
                                          path: path
                            referencedChildren: referencedChildren
                           newlyMountedChildren: newlyMountedChildren];
        didRenderSuccessfully = true;
    } @finally {
        [state popRenderingComponent];
        if (not didRenderSuccessfully) {
            OFArray<AUIComponent *> *mountedChildren = [newlyMountedChildren copy];

            for (AUIComponent *child in mountedChildren) {
                [child _unmountRecursively];
                [child _detachFromApplication];
            }
        }
    }

    for (AUIComponent *child in previousChildren) {
        if (not [AUIRenderTreeSupport array: referencedChildren containsIdenticalObject: child]) {
            [child _unmountRecursively];
            [child _detachFromApplication];
        }
    }

    _renderedChildren = [referencedChildren copy];
}

@end

@namespace_implementation(AUIRenderTreeSupport)

+ (bool)array: (OFArray *)array containsIdenticalObject: (id)object
{
    for (id currentObject in array) {
        if (currentObject == object)
            return true;
    }

    return false;
}

+ (size_t)identityIndexOfObject: (id)object inArray: (OFArray *)array
{
    for (size_t index = 0; index < array.count; index++) {
        if ([array objectAtIndex: index] == object)
            return index;
    }

    return OFNotFound;
}

+ (AUIRenderException *)validationExceptionWithReason: (OFString *)reason
{
    return [[AUIRenderException alloc] initWithReason: reason];
}

+ (OFString *)childPathFromParentPath: (OFString *)parentPath index: (size_t)index
{
    return [OFString stringWithFormat: @"%@/%zu", parentPath, index];
}

+ (AUIColor)interactiveBackgroundForBox: (AUIInteractiveBox *)box
                             identifier: (OFString *)identifier
                                  owner: (AUIComponent *)owner
{
    AUIApplication *nillable application = owner.application;

    if (not box.isEnabled)
        return box.backgrounds.disabled;
    if (application != nilptr and [application _identifierIsPressed: identifier])
        return box.backgrounds.pressed;
    if (application != nilptr and [application _identifierIsHovered: identifier])
        return box.backgrounds.hover;
    return box.backgrounds.normal;
}

+ (OFString *)maskedStringWithLength: (size_t)length
{
    OFMutableString *string = [OFMutableString string];

    for (size_t index = 0; index < length; index++)
        [string appendString: @"*"];

    return string;
}

+ (OFString *)displayStringForTextInput: (AUITextInput *)textInput
                             identifier: (OFString *)identifier
                                  owner: (AUIComponent *)owner
{
    AUIApplication *nillable application = owner.application;
    OFString *value = (textInput.text ?: @"");
    OFString *displayText = value;
    bool focused = false;
    size_t caretIndex = value.length;

    if (application != nilptr) {
        AUITextEditingState *editingState = [application _editingStateForIdentifier: identifier textLength: value.length];

        focused = [application _identifierIsFocused: identifier];
        caretIndex = editingState.caretIndex;
    }

    if (textInput.isSecure)
        displayText = [self maskedStringWithLength: value.length];

    if (displayText.length == 0 and not focused)
        return textInput.placeholder;

    if (focused) {
        OFString *head = [displayText substringToIndex: caretIndex];
        OFString *tail = [displayText substringFromIndex: caretIndex];

        return [OFString stringWithFormat: @"%@|%@", head, tail];
    }

    return displayText;
}

+ (void)renderText: (OFString *nillable)text style: (AUITextStyle)style
{
    Clay_TextElementConfig config = [AUIClay textConfigFromProps: (AUITextProps){ .style = style }];
    CLAY_TEXT([AUIClay stringFromString: text], CLAY_TEXT_CONFIG(config));
}

+ (void)renderComponentChild: (AUIComponent *nillable)child
                       owner: (AUIComponent *)owner
                       state: (AUIRenderPassState *)state
                        path: (OFString *)path
          referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
       newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren
{
    if (child == nilptr)
        @throw [OFInvalidArgumentException exception];

    [state registerChildComponent: child parent: owner];

    if (child.parent != nilptr and child.parent != owner)
        @throw [self validationExceptionWithReason: @"A child component is already owned by a different parent"];
    if (owner.application != nilptr and child.application != nilptr and child.application != owner.application)
        @throw [self validationExceptionWithReason: @"A child component is already attached to a different application"];

    if (not [self array: referencedChildren containsIdenticalObject: $assert_nonnil(child)])
        [referencedChildren addObject: $assert_nonnil(child)];

    if (child.parent == nilptr or child.application != owner.application)
        [child _attachToApplication: owner.application parent: owner];

    if (not child._isMounted) {
        [child _mountRecursivelyInScope: state.mountScope];
        [newlyMountedChildren addObject: $assert_nonnil(child)];
    }

    [child _renderWithState: state path: path];
}

+ (void)renderChildren: (OFArray<id<AUIRenderable>> *nillable)children
                  owner: (AUIComponent *)owner
                  state: (AUIRenderPassState *)state
             parentPath: (OFString *)parentPath
     referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
    newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren
{
    if (children == nilptr)
        @throw [OFInvalidArgumentException exception];

    for (size_t index = 0; index < children.count; index++) {
        id<AUIRenderable> child = [children objectAtIndex: index];

        if (child == nilptr)
            @throw [self validationExceptionWithReason: @"Children arrays cannot contain nil renderables"];

        [self renderRenderable: child
                         owner: owner
                         state: state
                          path: [self childPathFromParentPath: parentPath index: index]
            referencedChildren: referencedChildren
           newlyMountedChildren: newlyMountedChildren];
    }
}

+ (void)renderRenderable: (id<AUIRenderable> nillable)renderable
                    owner: (AUIComponent *)owner
                    state: (AUIRenderPassState *)state
                     path: (OFString *)path
       referencedChildren: (OFMutableArray<AUIComponent *> *)referencedChildren
      newlyMountedChildren: (OFMutableArray<AUIComponent *> *)newlyMountedChildren
{
    id renderableObject = (id)renderable;

    if (renderable == nilptr)
        @throw [OFInvalidArgumentException exception];

    if ([renderableObject isKindOfClass: AUIComponent.class]) {
        [self renderComponentChild: (AUIComponent *)renderable
                             owner: owner
                             state: state
                              path: path
                referencedChildren: referencedChildren
               newlyMountedChildren: newlyMountedChildren];
        return;
    }

    if ([renderableObject isKindOfClass: AUIContextMenuRegion.class]) {
        AUIContextMenuRegion *region = (AUIContextMenuRegion *)renderable;

        if (owner.application != nilptr) {
            AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: path
                                                                                     elementID: [AUIClay elementIDFromString: path]];

            registration.isEnabled = true;
            registration.contextMenu = region.menu;
            [owner.application _registerInteraction: registration];
        }

        [self renderRenderable: region.child
                         owner: owner
                         state: state
                          path: path
            referencedChildren: referencedChildren
           newlyMountedChildren: newlyMountedChildren];
        return;
    }

    if ([renderableObject respondsToSelector: @selector(renderableBody)]) {
        id<AUIRenderable> expanded = [renderable renderableBody];

        if (expanded == nilptr)
            @throw [self validationExceptionWithReason: @"Renderable expansion hooks must return a nonnil renderable body"];

        [self renderRenderable: expanded
                         owner: owner
                         state: state
                          path: path
            referencedChildren: referencedChildren
           newlyMountedChildren: newlyMountedChildren];
        return;
    }

    if ([renderableObject isKindOfClass: AUIGroup.class]) {
        [self renderChildren: ((AUIGroup *)renderable).children
                       owner: owner
                       state: state
                  parentPath: path
          referencedChildren: referencedChildren
         newlyMountedChildren: newlyMountedChildren];
        return;
    }

    if ([renderableObject isKindOfClass: AUIBox.class]) {
        AUIBox *box = (AUIBox *)renderable;
        Clay_ElementId elementID = [AUIClay elementIDFromString: path];
        Clay_ElementDeclaration declaration = [AUIClay boxDeclarationFromProps: (AUIBoxProps){
            .layout = box.layout,
            .backgroundColor = box.backgroundColor,
            .cornerRadius = box.cornerRadius,
            .border = box.border,
            .scrollAxis = box.scrollAxis
        } elementID: elementID];

        [AUIClay openElementWithID: elementID declaration: declaration];
        @try {
            [self renderChildren: box.children
                           owner: owner
                           state: state
                      parentPath: path
              referencedChildren: referencedChildren
             newlyMountedChildren: newlyMountedChildren];
        } @finally {
            [AUIClay closeElement];
        }
        return;
    }

    if ([renderableObject isKindOfClass: AUIInteractiveBox.class]) {
        AUIInteractiveBox *box = (AUIInteractiveBox *)renderable;
        Clay_ElementId elementID = [AUIClay elementIDFromString: path];
        Clay_ElementDeclaration declaration = [AUIClay boxDeclarationFromProps: (AUIBoxProps){
            .layout = box.layout,
            .backgroundColor = [self interactiveBackgroundForBox: box identifier: path owner: owner],
            .cornerRadius = box.cornerRadius,
            .border = box.border,
            .scrollAxis = AUIScrollAxisNone
        } elementID: elementID];

        [AUIClay openElementWithID: elementID declaration: declaration];
        @try {
            if (owner.application != nilptr) {
                AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: path elementID: elementID];

                registration.isEnabled = box.isEnabled;
                registration.isFocusable = box.isFocusable;
                registration.cursorStyle = AUICursorStylePointer;
                registration.activateHandler = box.activateHandler;
                [owner.application _registerInteraction: registration];
            }

            [self renderChildren: box.children
                           owner: owner
                           state: state
                      parentPath: path
              referencedChildren: referencedChildren
             newlyMountedChildren: newlyMountedChildren];
        } @finally {
            [AUIClay closeElement];
        }
        return;
    }

    if ([renderableObject isKindOfClass: AUITextInput.class]) {
        AUITextInput *textInput = (AUITextInput *)renderable;
        Clay_ElementId elementID = [AUIClay elementIDFromString: path];
        bool focused = (owner.application != nilptr and [owner.application _identifierIsFocused: path]);
        AUIColor backgroundColor = (textInput.isEnabled ? textInput.colors.background : textInput.colors.disabledBackground);
        AUIColor borderColor = textInput.colors.border;
        AUITextStyle textStyle = textInput.style;

        if (textInput.isEnabled and focused)
            borderColor = textInput.colors.focusedBorder;
        else if (not textInput.isEnabled)
            borderColor = textInput.colors.disabledBorder;

        textStyle.color = textInput.isEnabled ? textInput.colors.text : textInput.colors.disabledText;
        if ((textInput.text ?: @"").length == 0 and not focused)
            textStyle.color = textInput.colors.placeholder;

        [AUIClay openElementWithID: elementID declaration: [AUIClay boxDeclarationFromProps: (AUIBoxProps){
            .layout = textInput.layout,
            .backgroundColor = backgroundColor,
            .cornerRadius = textInput.cornerRadius,
            .border = (AUIBorder){
                .color = borderColor,
                .left = 1,
                .right = 1,
                .top = 1,
                .bottom = 1,
                .betweenChildren = 0
            },
            .scrollAxis = AUIScrollAxisNone
        } elementID: elementID]];
        @try {
            if (owner.application != nilptr) {
                AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: path elementID: elementID];
                OFMutableArray<AUIContextMenuItem *> *menuItems = [OFMutableArray array];
                OFString *currentText = (textInput.text ?: @"");
                OFString *nillable clipboardText = [owner.application _clipboardText];

                registration.isEnabled = textInput.isEnabled;
                registration.isFocusable = textInput.isEnabled;
                registration.isMultiline = textInput.isMultiline;
                registration.text = (textInput.text ?: @"");
                registration.cursorStyle = AUICursorStyleText;
                registration.textChangeHandler = textInput.changeHandler;
                registration.submitHandler = textInput.submitHandler;

                if (textInput.isEnabled) {
                    if (currentText.length > 0) {
                        if (not textInput.isSecure) {
                            [menuItems addObject: [AUIContextMenuItem title: @"Copy"
                                                                  enabled: true
                                                                 onSelect: ^{
                                                                     [owner.application _setClipboardText: currentText];
                                                                 }]];
                        }

                        if (textInput.changeHandler != nilptr and not textInput.isSecure) {
                            [menuItems addObject: [AUIContextMenuItem title: @"Cut"
                                                                  enabled: true
                                                                 onSelect: ^{
                                                                     [owner.application _setClipboardText: currentText];
                                                                     textInput.changeHandler(@"");
                                                                 }]];
                        }

                        [menuItems addObject: [AUIContextMenuItem title: @"Select All"
                                                              enabled: true
                                                             onSelect: ^{
                                                                 AUITextEditingState *editingState =
                                                                     [owner.application _editingStateForIdentifier: path
                                                                                                         textLength: currentText.length];

                                                                 editingState.selectionAnchorIndex = 0;
                                                                 editingState.selectionFocusIndex = currentText.length;
                                                                 editingState.caretIndex = currentText.length;
                                                                 [owner.application setNeedsRender];
                                                             }]];
                    }

                    [menuItems addObject: [AUIContextMenuItem title: @"Paste"
                                                          enabled: (clipboardText != nilptr and $assert_nonnil(clipboardText).length > 0 and
                                                                    textInput.changeHandler != nilptr)
                                                         onSelect: ^{
                                                             OFString *nillable pastedText = [owner.application _clipboardText];

                                                             if (pastedText != nilptr and textInput.changeHandler != nilptr)
                                                                 textInput.changeHandler([OFString stringWithFormat: @"%@%@",
                                                                     currentText,
                                                                     $assert_nonnil(pastedText)]);
                                                         }]];
                }

                if (menuItems.count > 0)
                    registration.contextMenu = [AUIContextMenu items: menuItems];
                [owner.application _registerInteraction: registration];
            }

            [self renderText: [self displayStringForTextInput: textInput identifier: path owner: owner]
                      style: textStyle];
        } @finally {
            [AUIClay closeElement];
        }
        return;
    }

    if ([renderableObject isKindOfClass: AUIText.class]) {
        AUIText *text = (AUIText *)renderable;

        [self renderText: text.text style: text.style];
        return;
    }

    @throw [self validationExceptionWithReason:
        [OFString stringWithFormat: @"Unsupported renderable type %@", [renderableObject className]]];
}

@end

#pragma clang assume_nonnull end
