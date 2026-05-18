#import <AsyncRT/Application/UI/Internal/AsyncUIInteractionEngine.h>

#import <AsyncRT/Application/UI/Internal/AsyncUIClayRuntime.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUIInteractionEngineSupport)

+ (bool)set: (OFSet<OFString *> *)left equalsSet: (OFSet<OFString *> *)right;
+ (size_t)indexOfIdentifier: (OFString *nillable)identifier
            inRegistrations: (OFArray<AsyncUIInteractionRegistration *> *)registrations;
+ (OFMutableSet<OFString *> *)hoveredIdentifiersInRegistrations: (OFArray<AsyncUIInteractionRegistration *> *)registrations;
+ (AsyncUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AsyncUIInteractionRegistration *> *)registrations
                                                     hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers;
+ (void)mergeRegistration: (AsyncUIInteractionRegistration *)source
                     into: (AsyncUIInteractionRegistration *)destination;

@end

@namespace_implementation(AsyncUIInteractionEngineSupport)

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
            inRegistrations: (OFArray<AsyncUIInteractionRegistration *> *)registrations
{
    if (identifier == nilptr)
        return OFNotFound;

    for (size_t index = 0; index < registrations.count; index++) {
        if ([registrations[index].identifier isEqual: $assert_nonnil(identifier)])
            return index;
    }

    return OFNotFound;
}

+ (OFMutableSet<OFString *> *)hoveredIdentifiersInRegistrations: (OFArray<AsyncUIInteractionRegistration *> *)registrations
{
    auto hoveredIdentifiers = [OFMutableSet<OFString *> set];

    for (AsyncUIInteractionRegistration *registration in registrations) {
        if ([AsyncUIClayRuntime pointerIsHoveringOverElementWithID: registration.elementID])
            [hoveredIdentifiers addObject: registration.identifier];
    }

    return hoveredIdentifiers;
}

+ (AsyncUIInteractionRegistration *nillable)topHoveredRegistrationIn: (OFArray<AsyncUIInteractionRegistration *> *)registrations
                                                     hoveredIDs: (OFSet<OFString *> *)hoveredIdentifiers
{
    for (size_t index = registrations.count; index > 0; index--) {
        AsyncUIInteractionRegistration *registration = registrations[index - 1];

        if (registration.isEnabled and [hoveredIdentifiers containsObject: registration.identifier])
            return registration;
    }

    return nilptr;
}

+ (void)mergeRegistration: (AsyncUIInteractionRegistration *)source
                     into: (AsyncUIInteractionRegistration *)destination
{
    destination.isEnabled = source.isEnabled;
    destination.isFocusable = source.isFocusable;

    if (source.text != nilptr)
        destination.text = source.text;
    if (source.contextMenu != nilptr)
        destination.contextMenu = source.contextMenu;
    if (source.cursorStyle != AsyncUICursorStyleDefault)
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
@implementation AsyncUIInteractionEngine {
    OFMutableArray<AsyncUIInteractionRegistration *> *_registrationsThisFrame;
    OFMutableSet<OFString *> *_hoveredIdentifiers;
    OFString *nillable _pressedIdentifier;
    OFString *nillable _focusedIdentifier;
    AsyncUIContextMenu *nillable _activeContextMenu;
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

- (void)registerInteraction: (AsyncUIInteractionRegistration *)registration
{
    const size_t existingIndex = [AsyncUIInteractionEngineSupport indexOfIdentifier: registration.identifier
                                                                inRegistrations: _registrationsThisFrame];
    if (existingIndex != OFNotFound) {
        [AsyncUIInteractionEngineSupport mergeRegistration: registration into: [_registrationsThisFrame objectAtIndex: existingIndex]];
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

- (bool)updateHoverStateFromCurrentLayoutWithInputState: (AsyncUIInputState *)inputState
                                            cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter
{
    OFArray<AsyncUIInteractionRegistration *> *registrations = [_registrationsThisFrame copy];
    bool didChange = false;

    if ([AsyncUIClayRuntime currentContext] == nullptr or registrations.count == 0) {
        if (_hoveredIdentifiers.count > 0) {
            [_hoveredIdentifiers removeAllObjects];
            didChange = true;
        }

        cursorSetter(AsyncUICursorStyleDefault);
        return didChange;
    }

    [AsyncUIClayRuntime updatePointerPositionX: inputState.pointerX
                                      y: inputState.pointerY
                                   down: inputState.isPrimaryButtonDown];
    OFMutableSet<OFString *> *hoveredIdentifiers = [AsyncUIInteractionEngineSupport hoveredIdentifiersInRegistrations: registrations];
    if (not [AsyncUIInteractionEngineSupport set: _hoveredIdentifiers equalsSet: hoveredIdentifiers]) {
        _hoveredIdentifiers = hoveredIdentifiers;
        didChange = true;
    }

    AsyncUIInteractionRegistration *nillable topHoveredRegistration =
        [AsyncUIInteractionEngineSupport topHoveredRegistrationIn: registrations hoveredIDs: hoveredIdentifiers];
    cursorSetter(topHoveredRegistration != nilptr ? topHoveredRegistration.cursorStyle : AsyncUICursorStyleDefault);
    return didChange;
}

- (void)completeFrameWithInputState: (AsyncUIInputState *)inputState
                        textInput: (AsyncUITextInputEngine *)textInput
                     clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
               setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
                    cursorSetter: (void (^nonnil)(AsyncUICursorStyle cursorStyle))cursorSetter
                 renderRequester: (void (^nonnil)(void))renderRequester
{
    OFArray<AsyncUIInteractionRegistration *> *registrations = [_registrationsThisFrame copy];
    OFMutableSet<OFString *> *hoveredIdentifiers = [AsyncUIInteractionEngineSupport hoveredIdentifiersInRegistrations: registrations];
    AsyncUIInteractionRegistration *nillable topHoveredRegistration =
        [AsyncUIInteractionEngineSupport topHoveredRegistrationIn: registrations hoveredIDs: hoveredIdentifiers];
    bool shouldScheduleRender = false;

    if (not [AsyncUIInteractionEngineSupport set: _hoveredIdentifiers equalsSet: hoveredIdentifiers]) {
        _hoveredIdentifiers = hoveredIdentifiers;
        shouldScheduleRender = true;
    }

    cursorSetter(topHoveredRegistration != nilptr ? topHoveredRegistration.cursorStyle : AsyncUICursorStyleDefault);

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
            size_t registrationIndex = [AsyncUIInteractionEngineSupport indexOfIdentifier: releasedIdentifier inRegistrations: registrations];

            if (registrationIndex != OFNotFound) {
                AsyncUIInteractionRegistration *registration = registrations[registrationIndex];

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

    for (AsyncUIKeyEvent *keyEvent in inputState.keyEvents) {
        if (keyEvent.key != AsyncUIKeyTab)
            continue;

        OFMutableArray<AsyncUIInteractionRegistration *> *focusables = [OFMutableArray array];
        bool reverse = ((keyEvent.modifiers & AsyncUIModifierFlagShift) != 0);
        size_t currentIndex = OFNotFound;

        for (AsyncUIInteractionRegistration *registration in registrations) {
            if (registration.isEnabled and registration.isFocusable)
                [focusables addObject: registration];
        }

        if (focusables.count == 0)
            continue;

        currentIndex = [AsyncUIInteractionEngineSupport indexOfIdentifier: _focusedIdentifier inRegistrations: focusables];
        if (reverse)
            currentIndex = (currentIndex == OFNotFound or currentIndex == 0 ? focusables.count - 1 : currentIndex - 1);
        else
            currentIndex = (currentIndex == OFNotFound or currentIndex + 1 >= focusables.count ? 0 : currentIndex + 1);

        _focusedIdentifier = [focusables objectAtIndex: currentIndex].identifier;
        shouldScheduleRender = true;
    }

    if (_focusedIdentifier != nilptr) {
        size_t registrationIndex = [AsyncUIInteractionEngineSupport indexOfIdentifier: _focusedIdentifier inRegistrations: registrations];

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

- (OFArray<AsyncUIInteractionRegistration *> *)registrationsThisFrame
{
    return _registrationsThisFrame;
}

- (OFSet<OFString *> *)registeredInteractionIdentifiers
{
    OFMutableSet<OFString *> *identifiers = [OFMutableSet set];

    for (AsyncUIInteractionRegistration *registration in _registrationsThisFrame)
        [identifiers addObject: registration.identifier];

    return identifiers;
}

@end

#pragma clang assume_nonnull end
