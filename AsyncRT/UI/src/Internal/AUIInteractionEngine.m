#import "Internal/AUIInteractionEngine.h"

#import "Internal/AUIClayRuntime.h"

#pragma clang assume_nonnull begin

@namespace(AUIInteractionEngineSupport)

+ (bool)set: (OFSet<OFString *> *)left equalsSet: (OFSet<OFString *> *)right;
+ (size_t)indexOfIdentifier: (OFString *nillable)identifier
            inRegistrations: (OFArray<AUIInteractionRegistration *> *)registrations;
+ (OFMutableSet<OFString *> *)hoveredIdentifiersInRegistrations: (OFArray<AUIInteractionRegistration *> *)registrations;
+ (AUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AUIInteractionRegistration *> *)registrations
                                                     hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers;
+ (void)mergeRegistration: (AUIInteractionRegistration *)source
                     into: (AUIInteractionRegistration *)destination;

@end

@namespace_implementation(AUIInteractionEngineSupport)

+ (bool)set: (OFSet<OFString *> *)left equalsSet: (OFSet<OFString *> *)right
{
    if (left.count != right.count)
        return false;

    for (OFString *identifier in left) {
        if (not [right containsObject: identifier])
            return false;
    }

    return true;
}

+ (size_t)indexOfIdentifier: (OFString *nillable)identifier
            inRegistrations: (OFArray<AUIInteractionRegistration *> *)registrations
{
    if (identifier == nilptr)
        return OFNotFound;

    for (size_t index = 0; index < registrations.count; index++) {
        if ([registrations[index].identifier isEqual: $assert_nonnil(identifier)])
            return index;
    }

    return OFNotFound;
}

+ (OFMutableSet<OFString *> *)hoveredIdentifiersInRegistrations: (OFArray<AUIInteractionRegistration *> *)registrations
{
    auto hoveredIdentifiers = [OFMutableSet<OFString *> set];

    for (AUIInteractionRegistration *registration in registrations) {
        if ([AUIClayRuntime pointerIsHoveringOverElementWithID: registration.elementID])
            [hoveredIdentifiers addObject: registration.identifier];
    }

    return hoveredIdentifiers;
}

+ (AUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AUIInteractionRegistration *> *)registrations
                                                     hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers
{
    for (size_t index = registrations.count; index > 0; index--) {
        AUIInteractionRegistration *registration = registrations[index - 1];

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

    if (source.text != nilptr)
        destination.text = source.text;
    if (source.contextMenu != nilptr)
        destination.contextMenu = source.contextMenu;
    if (source.cursorStyle != AUICursorStyleDefault)
        destination.cursorStyle = source.cursorStyle;
    if (source.activationAction != nilptr)
        destination.activationAction = source.activationAction;
    if (source.taskGroup != nilptr)
        destination.taskGroup = source.taskGroup;
    if (source.textChangeHandler != nilptr)
        destination.textChangeHandler = source.textChangeHandler;
    if (source.submitHandler != nilptr)
        destination.submitHandler = source.submitHandler;
}

@end

[[direct_members]]
@implementation AUIInteractionEngine {
    OFMutableArray<AUIInteractionRegistration *> *_registrationsThisFrame;
    OFMutableSet<OFString *> *_hoveredIdentifiers;
    OFString *nillable _pressedIdentifier;
    OFString *nillable _focusedIdentifier;
    AUIContextMenu *nillable _activeContextMenu;
    AsyncTaskGroup *nillable _activeContextMenuTaskGroup;
    float _activeContextMenuX;
    float _activeContextMenuY;
}

- (instancetype)init
{
    self = [super init];
    _registrationsThisFrame = [OFMutableArray array];
    _hoveredIdentifiers = [OFMutableSet set];
    return self;
}

- (void)beginFrame
{
    [_registrationsThisFrame removeAllObjects];
}

- (void)registerInteraction: (AUIInteractionRegistration *)registration
{
    const size_t existingIndex = [AUIInteractionEngineSupport indexOfIdentifier: registration.identifier
                                                                inRegistrations: _registrationsThisFrame];
    if (existingIndex != OFNotFound) {
        [AUIInteractionEngineSupport mergeRegistration: registration into: [_registrationsThisFrame objectAtIndex: existingIndex]];
        return;
    }

    [_registrationsThisFrame addObject: registration];
}

- (bool)isIdentifierFocused: (OFString *nillable)identifier
{
    return (identifier != nilptr and _focusedIdentifier != nilptr and [_focusedIdentifier isEqual: $assert_nonnil(identifier)]);
}

- (bool)isIdentifierPressed: (OFString *nillable)identifier
{
    return (identifier != nilptr and _pressedIdentifier != nilptr and [_pressedIdentifier isEqual: $assert_nonnil(identifier)]);
}

- (bool)isIdentifierHovered: (OFString *nillable)identifier
{
    return (identifier != nilptr and [_hoveredIdentifiers containsObject: $assert_nonnil(identifier)]);
}

- (bool)updateHoverStateFromCurrentLayoutWithInputState: (AUIInputState *)inputState
                                            cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
{
    OFArray<AUIInteractionRegistration *> *registrations = [_registrationsThisFrame copy];
    bool didChange = false;

    if ([AUIClayRuntime currentContext] == nullptr or registrations.count == 0) {
        if (_hoveredIdentifiers.count > 0) {
            [_hoveredIdentifiers removeAllObjects];
            didChange = true;
        }

        cursorSetter(AUICursorStyleDefault);
        return didChange;
    }

    [AUIClayRuntime updatePointerPositionX: inputState.pointerX
                                      y: inputState.pointerY
                                   down: inputState.isPrimaryButtonDown];
    OFMutableSet<OFString *> *hoveredIdentifiers = [AUIInteractionEngineSupport hoveredIdentifiersInRegistrations: registrations];
    if (not [AUIInteractionEngineSupport set: _hoveredIdentifiers equalsSet: hoveredIdentifiers]) {
        _hoveredIdentifiers = hoveredIdentifiers;
        didChange = true;
    }

    AUIInteractionRegistration *nillable topHoveredRegistration =
        [AUIInteractionEngineSupport topHoveredRegistrationIn: registrations hoveredIDs: hoveredIdentifiers];
    cursorSetter(topHoveredRegistration != nilptr ? topHoveredRegistration.cursorStyle : AUICursorStyleDefault);
    return didChange;
}

- (void)completeFrameWithInputState: (AUIInputState *)inputState
                        textInput: (AUITextInputEngine *)textInput
                     clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
               setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                    cursorSetter: (void (^nonnil)(AUICursorStyle cursorStyle))cursorSetter
                 renderRequester: (void (^nonnil)(void))renderRequester
{
    OFArray<AUIInteractionRegistration *> *registrations = [_registrationsThisFrame copy];
    OFMutableSet<OFString *> *hoveredIdentifiers = [AUIInteractionEngineSupport hoveredIdentifiersInRegistrations: registrations];
    AUIInteractionRegistration *nillable topHoveredRegistration =
        [AUIInteractionEngineSupport topHoveredRegistrationIn: registrations hoveredIDs: hoveredIdentifiers];
    bool shouldScheduleRender = false;

    if (not [AUIInteractionEngineSupport set: _hoveredIdentifiers equalsSet: hoveredIdentifiers]) {
        _hoveredIdentifiers = hoveredIdentifiers;
        shouldScheduleRender = true;
    }

    cursorSetter(topHoveredRegistration != nilptr ? topHoveredRegistration.cursorStyle : AUICursorStyleDefault);

    if (inputState.primaryButtonPressedThisFrame) {
        OFString *nillable previousPressedIdentifier = _pressedIdentifier;
        OFString *nillable previousFocusedIdentifier = _focusedIdentifier;

        if (_activeContextMenu != nilptr and
            (topHoveredRegistration == nilptr or not [$assert_nonnil(topHoveredRegistration).identifier hasPrefix: @"context-menu"])) {
            _activeContextMenu = nilptr;
            _activeContextMenuTaskGroup = nilptr;
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

    if (inputState.primaryButtonReleasedThisFrame) {
        OFString *releasedIdentifier = [_pressedIdentifier copy];

        if (releasedIdentifier != nilptr) {
            size_t registrationIndex = [AUIInteractionEngineSupport indexOfIdentifier: releasedIdentifier inRegistrations: registrations];

            if (registrationIndex != OFNotFound) {
                AUIInteractionRegistration *registration = registrations[registrationIndex];

                if (registration.isEnabled and [hoveredIdentifiers containsObject: releasedIdentifier] and registration.activationAction != nilptr)
                    [registration.activationAction invokeWithTaskGroup: registration.taskGroup];
            }
        }

        if (releasedIdentifier != nilptr and [$assert_nonnil(releasedIdentifier) hasPrefix: @"context-menu"] and _activeContextMenu != nilptr) {
            _activeContextMenu = nilptr;
            _activeContextMenuTaskGroup = nilptr;
            shouldScheduleRender = true;
        }

        if (_pressedIdentifier != nilptr)
            shouldScheduleRender = true;
        _pressedIdentifier = nilptr;
    }

    if (inputState.secondaryButtonReleasedThisFrame) {
        if (topHoveredRegistration != nilptr and topHoveredRegistration.contextMenu != nilptr) {
            _activeContextMenu = topHoveredRegistration.contextMenu;
            _activeContextMenuTaskGroup = topHoveredRegistration.taskGroup;
            _activeContextMenuX = inputState.pointerX;
            _activeContextMenuY = inputState.pointerY;
            shouldScheduleRender = true;
        } else if (_activeContextMenu != nilptr) {
            _activeContextMenu = nilptr;
            _activeContextMenuTaskGroup = nilptr;
            shouldScheduleRender = true;
        }
    }

    for (AUIKeyEvent *keyEvent in inputState.keyEvents) {
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

        currentIndex = [AUIInteractionEngineSupport indexOfIdentifier: _focusedIdentifier inRegistrations: focusables];
        if (reverse)
            currentIndex = (currentIndex == OFNotFound or currentIndex == 0 ? focusables.count - 1 : currentIndex - 1);
        else
            currentIndex = (currentIndex == OFNotFound or currentIndex + 1 >= focusables.count ? 0 : currentIndex + 1);

        _focusedIdentifier = [focusables objectAtIndex: currentIndex].identifier;
        shouldScheduleRender = true;
    }

    if (_focusedIdentifier != nilptr) {
        size_t registrationIndex = [AUIInteractionEngineSupport indexOfIdentifier: _focusedIdentifier inRegistrations: registrations];

        if (registrationIndex == OFNotFound) {
            _focusedIdentifier = nilptr;
            shouldScheduleRender = true;
        } else if ([textInput applyInputState: inputState
                                 registration: [registrations objectAtIndex: registrationIndex]
                                clipboardText: clipboardTextProvider
                              setClipboardText: clipboardTextSetter]) {
            shouldScheduleRender = true;
        }
    }

    if (inputState.scrollDeltaX != 0 or inputState.scrollDeltaY != 0 or
        inputState.isPrimaryButtonDown or inputState.isSecondaryButtonDown)
        shouldScheduleRender = true;

    if (shouldScheduleRender)
        renderRequester();

    [textInput retainStatesForIdentifiers: [self registeredInteractionIdentifiers]];
    [inputState resetTransientState];
}

- (void)resetState
{
    [_registrationsThisFrame removeAllObjects];
    [_hoveredIdentifiers removeAllObjects];
    _pressedIdentifier = nilptr;
    _focusedIdentifier = nilptr;
    _activeContextMenu = nilptr;
    _activeContextMenuTaskGroup = nilptr;
    _activeContextMenuX = 0;
    _activeContextMenuY = 0;
}

- (OFArray<AUIInteractionRegistration *> *)registrationsThisFrame
{
    return _registrationsThisFrame;
}

- (OFSet<OFString *> *)registeredInteractionIdentifiers
{
    OFMutableSet<OFString *> *identifiers = [OFMutableSet set];

    for (AUIInteractionRegistration *registration in _registrationsThisFrame)
        [identifiers addObject: registration.identifier];

    return identifiers;
}

@end

#pragma clang assume_nonnull end
