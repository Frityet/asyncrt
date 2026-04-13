#include <stdlib.h>
#import "UI/AUIApplication.h"
#import "UI/AUIBackend.h"
#import "UI/AUIClaySupport.h"
#import "UI/AUIInternal.h"
#import "UI/Backend/Renderer/AUICairoRendererBackend.h"
#import "UI/Backend/Window/AUICocoaWindowBackend.h"
#import "UI/Backend/Window/AUIX11WindowBackend.h"

#pragma clang assume_nonnull begin

@namespace(AUIAppInteractionSupport)

+ (bool)set: (OFSet<OFString *> *)left isEqualToSet: (OFSet<OFString *> *)right;
+ (OFString *)stringByInsertingString: (OFString *)inserted
                               into: (OFString *)source
                            atIndex: (size_t)index;
+ (OFString *)stringByRemovingRangeFrom: (OFString *)source
                              location: (size_t)location
                                 length: (size_t)length;
+ (size_t)indexOfIdentifier: (OFString *nillable)identifier
                         inArray: (OFArray<AUIInteractionRegistration *> *)registrations;
+ (size_t)selectionStartForState: (AUITextEditingState *)state;
+ (size_t)selectionLengthForState: (AUITextEditingState *)state;
+ (bool)stateHasSelection: (AUITextEditingState *)state;
+ (void)collapseSelectionForState: (AUITextEditingState *)state atIndex: (size_t)index;
+ (OFString *)stringByReplacingSelectionIn: (OFString *)source
                                     state: (AUITextEditingState *)state
                               replacement: (OFString *)replacement;
+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextEditingState *)state;
+ (AUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AUIInteractionRegistration *> *)registrations
                                                       hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers;
+ (void)mergeRegistration: (AUIInteractionRegistration *)source
                     into: (AUIInteractionRegistration *)destination;

@end

@namespace_implementation(AUIAppInteractionSupport)

+ (bool)set: (OFSet<OFString *> *)left isEqualToSet: (OFSet<OFString *> *)right
{
    if (left.count != right.count)
        return false;

    for (OFString *identifier in left) {
        if (not [right containsObject: identifier])
            return false;
    }

    return true;
}

+ (OFString *)stringByInsertingString: (OFString *)inserted
                               into: (OFString *)source
                            atIndex: (size_t)index
{
    OFString *head = [source substringToIndex: index];
    OFString *tail = [source substringFromIndex: index];

    return [OFString stringWithFormat: @"%@%@%@", head, inserted, tail];
}

+ (OFString *)stringByRemovingRangeFrom: (OFString *)source
                              location: (size_t)location
                                 length: (size_t)length
{
    OFString *head = [source substringToIndex: location];
    OFString *tail = [source substringFromIndex: location + length];

    return [OFString stringWithFormat: @"%@%@", head, tail];
}

+ (size_t)indexOfIdentifier: (OFString *nillable)identifier
                    inArray: (OFArray<AUIInteractionRegistration *> *)registrations
{
    if (identifier == nilptr)
        return OFNotFound;

    for (size_t index = 0; index < registrations.count; index++) {
        if ([[registrations objectAtIndex: index].identifier isEqual: $assert_nonnil(identifier)])
            return index;
    }

    return OFNotFound;
}

+ (size_t)selectionStartForState: (AUITextEditingState *)state
{
    return (state.selectionAnchorIndex < state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);
}

+ (size_t)selectionLengthForState: (AUITextEditingState *)state
{
    size_t start = [self selectionStartForState: state];
    size_t end = (state.selectionAnchorIndex > state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);

    return (end - start);
}

+ (bool)stateHasSelection: (AUITextEditingState *)state
{
    return (state.selectionAnchorIndex != state.selectionFocusIndex);
}

+ (void)collapseSelectionForState: (AUITextEditingState *)state atIndex: (size_t)index
{
    state.caretIndex = index;
    state.selectionAnchorIndex = index;
    state.selectionFocusIndex = index;
}

+ (OFString *)stringByReplacingSelectionIn: (OFString *)source
                                     state: (AUITextEditingState *)state
                               replacement: (OFString *)replacement
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];
    OFString *result;

    if (length > 0)
        source = [self stringByRemovingRangeFrom: source location: start length: length];
    result = [self stringByInsertingString: replacement into: source atIndex: start];
    [self collapseSelectionForState: state atIndex: start + replacement.length];
    return result;
}

+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextEditingState *)state
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];

    if (length == 0)
        return @"";

    return [source substringWithRange: OFMakeRange(start, length)];
}

+ (AUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AUIInteractionRegistration *> *)registrations
                                                       hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers
{
    for (size_t index = registrations.count; index > 0; index--) {
        AUIInteractionRegistration *registration = [registrations objectAtIndex: index - 1];

        if (registration.isEnabled and [hoveredIdentifiers containsObject: registration.identifier])
            return registration;
    }

    return nilptr;
}

+ (void)mergeRegistration: (AUIInteractionRegistration *)source
                     into: (AUIInteractionRegistration *)destination
{
    destination.isEnabled = source.isEnabled;
    destination.isFocusable = source.isFocusable;
    destination.isMultiline = source.isMultiline;

    if (source.text != nilptr)
        destination.text = source.text;
    if (source.contextMenu != nilptr)
        destination.contextMenu = source.contextMenu;
    if (source.cursorStyle != AUICursorStyleDefault)
        destination.cursorStyle = source.cursorStyle;
    if (source.activateHandler != nilptr)
        destination.activateHandler = source.activateHandler;
    if (source.textChangeHandler != nilptr)
        destination.textChangeHandler = source.textChangeHandler;
    if (source.submitHandler != nilptr)
        destination.submitHandler = source.submitHandler;
}

@end

@implementation AUIApplication {
    AUIComponent *nillable _rootComponent;
    AUIBackend *nillable _backend;
    AUIRenderObserver *nillable _renderObserver;
    OFDate *nillable _startDate;
    AUIInputState *_inputState;
    OFMutableArray<AUIInteractionRegistration *> *_interactionsThisFrame;
    OFMutableSet<OFString *> *_hoveredIdentifiers;
    OFString *nillable _pressedIdentifier;
    OFString *nillable _focusedIdentifier;
    OFMutableDictionary<OFString *, AUITextEditingState *> *_editingStates;
    AUIContextMenu *nillable _activeContextMenu;
    float _activeContextMenuX;
    float _activeContextMenuY;
    OFMutex *_renderWakeLock;
    PromiseResolver<AsyncUnit *> *nillable _renderWakeResolver;
    atomic_t(bool) _needsRender;
}


- (void)_resetInteractionState
{
    [_interactionsThisFrame removeAllObjects];
    [_hoveredIdentifiers removeAllObjects];
    _pressedIdentifier = nilptr;
    _focusedIdentifier = nilptr;
    _activeContextMenu = nilptr;
    _activeContextMenuX = 0;
    _activeContextMenuY = 0;
    [_editingStates removeAllObjects];
    [_inputState resetTransientState];
}

- (instancetype)init
{
    self = [super init];
    _inputState = [[AUIInputState alloc] init];
    _interactionsThisFrame = [OFMutableArray array];
    _hoveredIdentifiers = [OFMutableSet set];
    _editingStates = [OFMutableDictionary dictionary];
    _renderWakeLock = [OFMutex mutex];
    _renderWakeResolver = nilptr;
    atomic_init(&_needsRender, false);
    return self;
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                                   scope: (AsyncScope *)scope
{
    (void)notification;

    _startDate = OFDate.date;
    _renderObserver = [[AUIRenderObserver alloc] initWithInvalidationHandler: ^{
        [self setNeedsRender];
    }];
    AUIWindowBackend *windowBackend = [self makeWindowBackend];
    AUIRendererBackend *rendererBackend = [self makeRendererBackend];
    _backend = [[AUIBackend alloc] initWithApplication: self
                                          windowBackend: windowBackend
                                        rendererBackend: rendererBackend];
    _rootComponent = [self makeRootComponent];

    if (_rootComponent == nilptr)
        @throw [[AUIInitializationException alloc] initWithReason: @"-makeRootComponent must return a nonnil root component"];

    [_rootComponent _attachToApplication: self parent: nilptr];

    @try {
        [_backend openWindow];
        [_rootComponent _mountRecursivelyInScope: scope];
        [self setNeedsRender];
        while (_backend.isOpen) {
            OFTimeInterval pollInterval;
            bool didRender = false;
            Promise<AsyncUnit *> *renderWakePromise = [self _renderWakePromise];

            [_backend pollEvents];
            if (not _backend.isOpen)
                break;

            if ([self _consumePendingRenderRequest]) {
                [_backend renderFrame];
                didRender = true;
            }

            if (_inputState.isPrimaryButtonDown or _inputState.isSecondaryButtonDown)
                pollInterval = (1.0 / 60.0);
            else if (didRender)
                pollInterval = (1.0 / 60.0);
            else
                pollInterval = (1.0 / 10.0);

            if ([self _hasPendingRenderRequest])
                continue;

            (void)[Promise<AsyncUnit *> race: @[
                [scope.scheduler sleepForTimeInterval: pollInterval],
                renderWakePromise
            ]].await;
        }
    } @finally {
        [self _resetInteractionState];
        [_rootComponent _unmountRecursively];
        [_rootComponent _detachFromApplication];
        [_backend closeWindow];
        _backend = nilptr;
    }

    return @(0);
}

- (AUIComponent *)makeRootComponent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AUIWindowOptions *)windowOptions
{
    return AUIWindowOptions.defaultOptions;
}

- (AUIWindowBackend *)makeWindowBackend
{
#if defined(__APPLE__)
    return [[AUICocoaWindowBackend alloc] initWithApplication: self options: self.windowOptions];
#elif defined(__linux__)
    return [[AUIX11WindowBackend alloc] initWithApplication: self options: self.windowOptions];
#else
    @throw [[AUIInitializationException alloc] initWithReason: @"AUI is only supported on macOS and Linux/X11"];
#endif
}

- (AUIRendererBackend *)makeRendererBackend
{
    return [[AUICairoRendererBackend alloc] initWithApplication: self];
}

- (void)setNeedsRender
{
    atomic_store_explicit(&_needsRender, true, memory_order_release);
    [self _signalRenderWake];
}

- (AUIInputState *)_inputState
{
    return _inputState;
}

- (void)_beginInteractionFrame
{
    [_interactionsThisFrame removeAllObjects];
}

- (void)_registerInteraction: (AUIInteractionRegistration *nillable)registration
{
    size_t existingIndex;

    if (registration == nilptr)
        @throw [OFInvalidArgumentException exception];

    existingIndex = [AUIAppInteractionSupport indexOfIdentifier: $assert_nonnil(registration).identifier
                                                        inArray: _interactionsThisFrame];
    if (existingIndex != OFNotFound) {
        AUIInteractionRegistration *existingRegistration = [_interactionsThisFrame objectAtIndex: existingIndex];

        [AUIAppInteractionSupport mergeRegistration: $assert_nonnil(registration) into: existingRegistration];
        return;
    }

    [_interactionsThisFrame addObject: $assert_nonnil(registration)];
}

- (AUITextEditingState *)_editingStateForIdentifier: (OFString *nillable)identifier
                                         textLength: (size_t)textLength
{
    AUITextEditingState *state;

    if (identifier == nilptr)
        @throw [OFInvalidArgumentException exception];

    state = _editingStates[$assert_nonnil(identifier)];
    if (state == nilptr) {
        state = [AUITextEditingState caretIndex: textLength
                           selectionAnchorIndex: textLength
                            selectionFocusIndex: textLength];
        _editingStates[$assert_nonnil(identifier)] = state;
        return state;
    }

    if (state.caretIndex > textLength)
        state.caretIndex = textLength;
    if (state.selectionAnchorIndex > textLength)
        state.selectionAnchorIndex = textLength;
    if (state.selectionFocusIndex > textLength)
        state.selectionFocusIndex = textLength;

    return state;
}

- (bool)_identifierIsFocused: (OFString *nillable)identifier
{
    return (identifier != nilptr and _focusedIdentifier != nilptr and [_focusedIdentifier isEqual: $assert_nonnil(identifier)]);
}

- (bool)_identifierIsPressed: (OFString *nillable)identifier
{
    return (identifier != nilptr and _pressedIdentifier != nilptr and [_pressedIdentifier isEqual: $assert_nonnil(identifier)]);
}

- (bool)_identifierIsHovered: (OFString *nillable)identifier
{
    return (identifier != nilptr and [_hoveredIdentifiers containsObject: $assert_nonnil(identifier)]);
}

- (void)_completeInteractionFrame
{
    OFArray<AUIInteractionRegistration *> *registrations = [_interactionsThisFrame copy];
    OFMutableSet<OFString *> *hoveredIdentifiers = [OFMutableSet set];
    bool shouldScheduleRender = false;

    for (AUIInteractionRegistration *registration in registrations) {
        if ([AUIClay pointerOverElementWithID: registration.elementID])
            [hoveredIdentifiers addObject: registration.identifier];
    }

    if (not [AUIAppInteractionSupport set: _hoveredIdentifiers isEqualToSet: hoveredIdentifiers]) {
        _hoveredIdentifiers = hoveredIdentifiers;
        shouldScheduleRender = true;
    }

    AUIInteractionRegistration *nillable topHoveredRegistration = [AUIAppInteractionSupport topHoveredRegistrationIn: registrations hoveredIDs: hoveredIdentifiers];
    [self _setCursorStyle: (topHoveredRegistration != nilptr ? topHoveredRegistration.cursorStyle : AUICursorStyleDefault)];

    if (_inputState.primaryButtonPressedThisFrame) {
        OFString *nillable previousPressedIdentifier = _pressedIdentifier;
        OFString *nillable previousFocusedIdentifier = _focusedIdentifier;

        if (_activeContextMenu != nilptr and
            (topHoveredRegistration == nilptr or not [$assert_nonnil(topHoveredRegistration).identifier hasPrefix: @"__context_menu__"])) {
            _activeContextMenu = nilptr;
            shouldScheduleRender = true;
        }

        if (topHoveredRegistration != nilptr) {
            _pressedIdentifier = topHoveredRegistration.identifier;
            _focusedIdentifier = (topHoveredRegistration.isFocusable ? topHoveredRegistration.identifier : nilptr);
        } else {
            _pressedIdentifier = nilptr;
            _focusedIdentifier = nilptr;
        }

        if ((previousPressedIdentifier != _pressedIdentifier and not [previousPressedIdentifier isEqual: _pressedIdentifier]) or
            (previousFocusedIdentifier != _focusedIdentifier and not [previousFocusedIdentifier isEqual: _focusedIdentifier]))
            shouldScheduleRender = true;
    }

    if (_inputState.primaryButtonReleasedThisFrame) {
        OFString *releasedIdentifier = [_pressedIdentifier copy];

        if (releasedIdentifier != nilptr) {
            size_t registrationIndex = [AUIAppInteractionSupport indexOfIdentifier: releasedIdentifier inArray: registrations];

            if (registrationIndex != OFNotFound) {
                AUIInteractionRegistration *registration = [registrations objectAtIndex: registrationIndex];

                if (registration.isEnabled and [hoveredIdentifiers containsObject: releasedIdentifier] and registration.activateHandler != nilptr)
                    registration.activateHandler();
            }
        }

        if (releasedIdentifier != nilptr and [$assert_nonnil(releasedIdentifier) hasPrefix: @"__context_menu__"] and _activeContextMenu != nilptr) {
            _activeContextMenu = nilptr;
            shouldScheduleRender = true;
        }

        if (_pressedIdentifier != nilptr)
            shouldScheduleRender = true;
        _pressedIdentifier = nilptr;
    }

    if (_inputState.secondaryButtonReleasedThisFrame) {
        if (topHoveredRegistration != nilptr and topHoveredRegistration.contextMenu != nilptr) {
            _activeContextMenu = topHoveredRegistration.contextMenu;
            _activeContextMenuX = _inputState.pointerX;
            _activeContextMenuY = _inputState.pointerY;
            shouldScheduleRender = true;
        } else if (_activeContextMenu != nilptr) {
            _activeContextMenu = nilptr;
            shouldScheduleRender = true;
        }
    }

    for (AUIKeyEvent *keyEvent in _inputState.keyEvents) {
        if (keyEvent.key != AUIKeyTab)
            continue;

        OFMutableArray<AUIInteractionRegistration *> *focusables = [OFMutableArray array];
        bool reverse = ((keyEvent.modifiers & AUIModifierFlagShift) != 0);
        size_t currentIndex = OFNotFound;

        for (AUIInteractionRegistration *registration in registrations) {
            if (registration.isEnabled and registration.isFocusable)
                [focusables addObject: registration];
        }

        if (focusables.count == 0)
            continue;

        currentIndex = [AUIAppInteractionSupport indexOfIdentifier: _focusedIdentifier inArray: focusables];
        if (reverse)
            currentIndex = (currentIndex == OFNotFound or currentIndex == 0 ? focusables.count - 1 : currentIndex - 1);
        else
            currentIndex = (currentIndex == OFNotFound or currentIndex + 1 >= focusables.count ? 0 : currentIndex + 1);

        _focusedIdentifier = [focusables objectAtIndex: currentIndex].identifier;
        shouldScheduleRender = true;
    }

    if (_focusedIdentifier != nilptr) {
        size_t registrationIndex = [AUIAppInteractionSupport indexOfIdentifier: _focusedIdentifier inArray: registrations];

        if (registrationIndex == OFNotFound) {
            _focusedIdentifier = nilptr;
            shouldScheduleRender = true;
        } else {
            AUIInteractionRegistration *registration = [registrations objectAtIndex: registrationIndex];

            if (registration.textChangeHandler != nilptr or registration.submitHandler != nilptr) {
                AUITextEditingState *editingState = [self _editingStateForIdentifier: registration.identifier
                                                                          textLength: registration.text.length];
                OFString *text = (registration.text ?: @"");
                size_t previousCaretIndex = editingState.caretIndex;
                size_t previousAnchorIndex = editingState.selectionAnchorIndex;
                size_t previousFocusIndex = editingState.selectionFocusIndex;
                bool textChanged = false;

                if (_inputState.typedText.length > 0) {
                    OFString *insertedText = _inputState.typedText;

                    if (not registration.isMultiline)
                        insertedText = [insertedText stringByReplacingOccurrencesOfString: @"\n" withString: @""];

                    if (insertedText.length > 0) {
                        text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text
                                                                                state: editingState
                                                                          replacement: insertedText];
                        textChanged = true;
                    }
                }

                for (AUIKeyEvent *keyEvent in _inputState.keyEvents) {
                    bool commandLike = ((keyEvent.modifiers & (AUIModifierFlagCommand | AUIModifierFlagControl)) != 0);

                    if (commandLike) {
                        switch (keyEvent.key) {
                            case AUIKeyA:
                                editingState.selectionAnchorIndex = 0;
                                editingState.selectionFocusIndex = text.length;
                                editingState.caretIndex = text.length;
                                break;
                            case AUIKeyC:
                                if ([AUIAppInteractionSupport stateHasSelection: editingState])
                                    [self _setClipboardText: [AUIAppInteractionSupport selectedTextIn: text state: editingState]];
                                break;
                            case AUIKeyX:
                                if ([AUIAppInteractionSupport stateHasSelection: editingState]) {
                                    [self _setClipboardText: [AUIAppInteractionSupport selectedTextIn: text state: editingState]];
                                    text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text
                                                                                            state: editingState
                                                                                      replacement: @""];
                                    textChanged = true;
                                }
                                break;
                            case AUIKeyV: {
                                OFString *nillable clipboardText = [self _clipboardText];

                                if (clipboardText != nilptr and $assert_nonnil(clipboardText).length > 0) {
                                    text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text
                                                                                            state: editingState
                                                                                      replacement: $assert_nonnil(clipboardText)];
                                    textChanged = true;
                                }
                                break;
                            }
                            default:
                                break;
                        }

                        continue;
                    }

                    switch (keyEvent.key) {
                        case AUIKeyLeft:
                            if ([AUIAppInteractionSupport stateHasSelection: editingState])
                                [AUIAppInteractionSupport collapseSelectionForState: editingState
                                                                           atIndex: [AUIAppInteractionSupport selectionStartForState: editingState]];
                            else if (editingState.caretIndex > 0)
                                [AUIAppInteractionSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                            break;
                        case AUIKeyRight:
                            if ([AUIAppInteractionSupport stateHasSelection: editingState])
                                [AUIAppInteractionSupport collapseSelectionForState: editingState
                                                                           atIndex: [AUIAppInteractionSupport selectionStartForState: editingState] +
                                                                                   [AUIAppInteractionSupport selectionLengthForState: editingState]];
                            else if (editingState.caretIndex < text.length)
                                [AUIAppInteractionSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex + 1];
                            break;
                        case AUIKeyHome:
                            [AUIAppInteractionSupport collapseSelectionForState: editingState atIndex: 0];
                            break;
                        case AUIKeyEnd:
                            [AUIAppInteractionSupport collapseSelectionForState: editingState atIndex: text.length];
                            break;
                        case AUIKeyBackspace:
                            if ([AUIAppInteractionSupport stateHasSelection: editingState]) {
                                text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                                textChanged = true;
                            } else if (editingState.caretIndex > 0) {
                                text = [AUIAppInteractionSupport stringByRemovingRangeFrom: text
                                                                                   location: editingState.caretIndex - 1
                                                                                      length: 1];
                                [AUIAppInteractionSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                                textChanged = true;
                            }
                            break;
                        case AUIKeyDelete:
                            if ([AUIAppInteractionSupport stateHasSelection: editingState]) {
                                text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                                textChanged = true;
                            } else if (editingState.caretIndex < text.length) {
                                text = [AUIAppInteractionSupport stringByRemovingRangeFrom: text
                                                                                   location: editingState.caretIndex
                                                                                      length: 1];
                                textChanged = true;
                            }
                            break;
                        case AUIKeyEnter:
                        case AUIKeyKeypadEnter:
                            if (registration.isMultiline) {
                                text = [AUIAppInteractionSupport stringByReplacingSelectionIn: text
                                                                                        state: editingState
                                                                                  replacement: @"\n"];
                                textChanged = true;
                            } else if (registration.submitHandler != nilptr) {
                                registration.submitHandler(text);
                            }
                            break;
                        default:
                            break;
                    }
                }

                if (textChanged and registration.textChangeHandler != nilptr)
                    registration.textChangeHandler(text);

                if (textChanged or editingState.caretIndex != previousCaretIndex or
                    editingState.selectionAnchorIndex != previousAnchorIndex or
                    editingState.selectionFocusIndex != previousFocusIndex)
                    shouldScheduleRender = true;
            }
        }
    }

    if (_inputState.scrollDeltaX != 0 or _inputState.scrollDeltaY != 0 or
        _inputState.isPrimaryButtonDown or _inputState.isSecondaryButtonDown)
        shouldScheduleRender = true;

    if (shouldScheduleRender)
        [self setNeedsRender];

    [_inputState resetTransientState];
}

- (Clay_RenderCommandArray)_buildRenderCommandsWithViewportSize: (AUISize)viewportSize
                                                       deltaTime: (float)deltaTime
{
    AUIRenderContext *context;
    Clay_RenderCommandArray renderCommands;
    OFString *nillable clayError = nilptr;
    OFDate *frameDate = OFDate.date;
    OFTimeInterval elapsedTime = 0;

    if (_rootComponent == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render without a root component"];

    if (_startDate != nilptr)
        elapsedTime = [frameDate timeIntervalSinceDate: $assert_nonnil(_startDate)];

    context = [[AUIRenderContext alloc]
        initWithApplication: self
               viewportSize: viewportSize
                  frameDate: frameDate
                elapsedTime: elapsedTime];

    [AUIClay clearError];
    [AUIClay setLayoutDimensions: viewportSize];
    [AUIClay setPointerPositionX: _inputState.pointerX
                                y: _inputState.pointerY
                             down: _inputState.isPrimaryButtonDown];
    [_renderObserver beginTracking];
    [AUIRenderContext _pushCurrentContext: context];
    [self _beginInteractionFrame];

    @try {
        [AUIClay beginLayout];
        [$assert_nonnil(_rootComponent) _renderRecursively];

        if (_activeContextMenu != nilptr and _activeContextMenu.items.count > 0) {
            Clay_ElementId menuID = [AUIClay elementIDFromString: @"__context_menu__"];
            AUIBoxProps menuProps = [AUI boxProps];
            Clay_ElementDeclaration declaration;

            menuProps.layout.width = [AUI axisFit: 0];
            menuProps.layout.height = [AUI axisFit: 0];
            menuProps.layout.padding = [AUI insetsAll: 6];
            menuProps.layout.childGap = 4;
            menuProps.backgroundColor = [AUI colorWithRed: 248 green: 246 blue: 241 alpha: 255];
            menuProps.cornerRadius = 12;
            menuProps.border = [AUI borderAll: 1 color: [AUI colorWithRed: 212 green: 206 blue: 194 alpha: 255]];
            declaration = [AUIClay boxDeclarationFromProps: menuProps elementID: menuID];
            declaration.floating = (Clay_FloatingElementConfig){
                .offset = { .x = _activeContextMenuX, .y = _activeContextMenuY },
                .zIndex = 32767,
                .pointerCaptureMode = CLAY_POINTER_CAPTURE_MODE_CAPTURE,
                .attachTo = CLAY_ATTACH_TO_ROOT
            };

            [AUIClay openElementWithID: menuID declaration: declaration];
            @try {
                for (size_t index = 0; index < _activeContextMenu.items.count; index++) {
                    AUIContextMenuItem *item = [_activeContextMenu.items objectAtIndex: index];
                    OFString *identifier = [OFString stringWithFormat: @"__context_menu__/%zu", index];
                    Clay_ElementId itemID = [AUIClay elementIDFromString: identifier];
                    AUIBoxProps itemProps = [AUI boxProps];
                    AUITextStyle itemStyle = [AUI textStyle];
                    AUIInteractionRegistration *registration = [AUIInteractionRegistration identifier: identifier elementID: itemID];

                    itemProps.layout.width = [AUI axisFit: 160];
                    itemProps.layout.height = [AUI axisFit: 0];
                    itemProps.layout.padding = [AUI insetsWithLeft: 12 right: 12 top: 8 bottom: 8];
                    itemProps.backgroundColor = (item.isEnabled
                        ? ([self _identifierIsPressed: identifier]
                            ? [AUI colorWithRed: 221 green: 228 blue: 239 alpha: 255]
                            : ([self _identifierIsHovered: identifier]
                                ? [AUI colorWithRed: 232 green: 237 blue: 245 alpha: 255]
                                : [AUI colorWithRed: 248 green: 246 blue: 241 alpha: 255]))
                        : [AUI colorWithRed: 244 green: 242 blue: 238 alpha: 255]);
                    itemProps.cornerRadius = 8;
                    itemProps.border = [AUI borderNone];
                    itemStyle.fontSize = 14;
                    itemStyle.lineHeight = 18;
                    itemStyle.color = (item.isEnabled
                        ? [AUI colorWithRed: 32 green: 36 blue: 42 alpha: 255]
                        : [AUI colorWithRed: 142 green: 146 blue: 150 alpha: 255]);

                    registration.isEnabled = item.isEnabled;
                    registration.cursorStyle = AUICursorStylePointer;
                    registration.activateHandler = ^{
                        if (item.selectHandler != nilptr)
                            item.selectHandler();
                    };
                    [self _registerInteraction: registration];

                    [AUIClay openElementWithID: itemID declaration: [AUIClay boxDeclarationFromProps: itemProps elementID: itemID]];
                    @try {
                        Clay_TextElementConfig textConfig = [AUIClay textConfigFromProps: (AUITextProps){ .style = itemStyle }];
                        CLAY_TEXT([AUIClay stringFromString: item.title], CLAY_TEXT_CONFIG(textConfig));
                    } @finally {
                        [AUIClay closeElement];
                    }
                }
            } @finally {
                [AUIClay closeElement];
            }
        }

        renderCommands = [AUIClay endLayoutWithDeltaTime: deltaTime];
        [AUIClay updateScrollContainersWithDragScrolling: true
                                                  deltaX: _inputState.scrollDeltaX
                                                  deltaY: _inputState.scrollDeltaY
                                               deltaTime: deltaTime];
        [self _completeInteractionFrame];

        clayError = [AUIClay consumeError];
        if (clayError != nilptr)
            @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];
    } @catch (AUIException *exception) {
        @throw exception;
    } @catch (OFException *exception) {
        @throw [[AUIRenderException alloc] initWithReason: @"Root component rendering failed"
                                           underlyingException: exception];
    } @finally {
        [AUIRenderContext _popCurrentContext];
        [_renderObserver endTracking];
    }

    return renderCommands;
}

- (OFString *nillable)_clipboardText
{
    return (_backend != nilptr ? _backend.clipboardText : nilptr);
}

- (void)_setClipboardText: (OFString *nillable)text
{
    if (_backend != nilptr)
        [_backend setClipboardText: text];
}

- (void)_setCursorStyle: (AUICursorStyle)cursorStyle
{
    if (_backend != nilptr)
        [_backend setCursorStyle: cursorStyle];
}

- (AUIContextMenu *nillable)_activeContextMenuForTesting
{
    return _activeContextMenu;
}

- (void)_setBackendForTesting: (AUIBackend *nillable)backend
{
    _backend = backend;
}

- (void)_setRootComponentForTesting: (AUIComponent *nillable)rootComponent
{
    if (_rootComponent != rootComponent)
        [self _resetInteractionState];

    _rootComponent = rootComponent;
}

- (bool)_consumePendingRenderRequest
{
    return atomic_exchange_explicit(&_needsRender, false, memory_order_acq_rel);
}

- (bool)_hasPendingRenderRequest
{
    return atomic_load_explicit(&_needsRender, memory_order_acquire);
}

- (Promise<AsyncUnit *> *)_renderWakePromise
{
    PromiseResolver<AsyncUnit *> *resolver;

    [_renderWakeLock lock];
    @try {
        if (_renderWakeResolver == nilptr)
            _renderWakeResolver = [[PromiseResolver<AsyncUnit *> alloc] init];

        resolver = _renderWakeResolver;
    } @finally {
        [_renderWakeLock unlock];
    }

    return resolver.promise;
}

- (void)_signalRenderWake
{
    PromiseResolver<AsyncUnit *> *nillable resolver = nilptr;

    [_renderWakeLock lock];
    @try {
        resolver = _renderWakeResolver;
        _renderWakeResolver = nilptr;
    } @finally {
        [_renderWakeLock unlock];
    }

    if (resolver != nilptr) {
        @try {
            [resolver resolve: AsyncUnit.unit];
        } @catch (PromiseAlreadyResolvedException *) {
        }
    }
}

@end

#pragma clang assume_nonnull end
