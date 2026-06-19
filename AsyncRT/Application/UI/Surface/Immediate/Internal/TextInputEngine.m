#import <AsyncRT/Application/UI/Surface/Immediate/Internal/TextInputEngine.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUITextInputEngineSupport)

+ (size_t)selectionStartForState: (AsyncUITextInputState *)state;
+ (size_t)selectionLengthForState: (AsyncUITextInputState *)state;
+ (bool)stateHasSelection: (AsyncUITextInputState *)state;
+ (void)collapseSelectionForState: (AsyncUITextInputState *)state atIndex: (size_t)index;
+ (OFString *)stringByInsertingString: (OFString *)inserted into: (OFString *)source atIndex: (size_t)index;
+ (OFString *)stringByRemovingRangeFrom: (OFString *)source location: (size_t)location length: (size_t)length;
+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AsyncUITextInputState *)state replacement: (OFString *)replacement;
+ (OFString *)selectedTextIn: (OFString *)source state: (AsyncUITextInputState *)state;
+ (OFString *)maskedStringWithLength: (size_t)length;

@end

@namespace_implementation(AsyncUITextInputEngineSupport)

+ (size_t)selectionStartForState: (AsyncUITextInputState *)state
{
    return (state.selectionAnchorIndex < state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);
}

+ (size_t)selectionLengthForState: (AsyncUITextInputState *)state
{
    size_t start = [self selectionStartForState: state];
    size_t end = (state.selectionAnchorIndex > state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);

    return (end - start);
}

+ (bool)stateHasSelection: (AsyncUITextInputState *)state
{
    return (state.selectionAnchorIndex != state.selectionFocusIndex);
}

+ (void)collapseSelectionForState: (AsyncUITextInputState *)state atIndex: (size_t)index
{
    state.caretIndex = index;
    state.selectionAnchorIndex = index;
    state.selectionFocusIndex = index;
}

+ (OFString *)stringByInsertingString: (OFString *)inserted into: (OFString *)source atIndex: (size_t)index
{
    OFString *head = [source substringToIndex: index];
    OFString *tail = [source substringFromIndex: index];

    return [OFString stringWithFormat: @"%@%@%@", head, inserted, tail];
}

+ (OFString *)stringByRemovingRangeFrom: (OFString *)source location: (size_t)location length: (size_t)length
{
    OFString *head = [source substringToIndex: location];
    OFString *tail = [source substringFromIndex: location + length];

    return [OFString stringWithFormat: @"%@%@", head, tail];
}

+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AsyncUITextInputState *)state replacement: (OFString *)replacement
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];

    if (length > 0)
        source = [self stringByRemovingRangeFrom: source location: start length: length];

    source = [self stringByInsertingString: replacement into: source atIndex: start];
    [self collapseSelectionForState: state atIndex: start + replacement.length];
    return source;
}

+ (OFString *)selectedTextIn: (OFString *)source state: (AsyncUITextInputState *)state
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];

    if (length == 0)
        return @"";

    return [source substringWithRange: OFMakeRange(start, length)];
}

+ (OFString *)maskedStringWithLength: (size_t)length
{
    OFMutableString *string = [OFMutableString string];

    for (size_t index = 0; index < length; index++)
        [string appendString: @"*"];

    return string;
}

@end

[[direct_members]]
@implementation AsyncUITextInputEngine {
    OFMutableDictionary<OFString *, AsyncUITextInputState *> *_statesByIdentifier;
}

- (instancetype)init
{
    self = [super init];
    _statesByIdentifier = [OFMutableDictionary dictionary];
    return self;
}

- (AsyncUITextInputState *)inputStateForIdentifier: (OFString *)identifier
                                    textLength: (size_t)textLength
{
    AsyncUITextInputState *state = _statesByIdentifier[identifier];

    if (state == nilptr) {
        state = [AsyncUITextInputState caretIndex: textLength
                         selectionAnchorIndex: textLength
                          selectionFocusIndex: textLength];
        _statesByIdentifier[identifier] = state;
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

- (OFString *)displayStringForText: (OFString *nillable)text
                        identifier: (OFString *nillable)identifier
                          isSecure: (bool)isSecure
                           focused: (bool)isFocused
{
    OFString *value = (text ?: @"");
    OFString *displayText = value;
    size_t caretIndex = value.length;

    if (identifier != nilptr)
        caretIndex = [self inputStateForIdentifier: $assert_nonnil(identifier) textLength: value.length].caretIndex;

    if (isSecure)
        displayText = [AsyncUITextInputEngineSupport maskedStringWithLength: value.length];

    if (displayText.length == 0 and not isFocused)
        return @"";

    if (isFocused) {
        OFString *head = [displayText substringToIndex: caretIndex];
        OFString *tail = [displayText substringFromIndex: caretIndex];

        return [OFString stringWithFormat: @"%@|%@", head, tail];
    }

    return displayText;
}

- (bool)applyInputState: (AsyncUIInputState *)inputState
            registration: (AsyncUIInteractionRegistration *)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
{
    bool textChanged = false;

    if (registration.textChangeHandler == nilptr and registration.submitHandler == nilptr)
        return false;

    OFString *text = (registration.text ?: @"");
    AsyncUITextInputState *editingState = [self inputStateForIdentifier: registration.identifier textLength: text.length];
    const size_t previousCaretIndex = editingState.caretIndex;
    const size_t previousAnchorIndex = editingState.selectionAnchorIndex;
    const size_t previousFocusIndex = editingState.selectionFocusIndex;

    if (inputState.typedText.length > 0) {
        OFString *insertedText = [inputState.typedText stringByReplacingOccurrencesOfString: @"\n" withString: @""];

        if (insertedText.length > 0) {
            text = [AsyncUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: insertedText];
            textChanged = true;
        }
    }

    for (AsyncUIKeyEvent *keyEvent in inputState.keyEvents) {
        bool commandLike = ((keyEvent.modifiers & (AsyncUIModifierFlagCommand | AsyncUIModifierFlagControl)) != 0);

        if (commandLike) {
            switch (keyEvent.key) {
                case AsyncUIKeyA:
                    editingState.selectionAnchorIndex = 0;
                    editingState.selectionFocusIndex = text.length;
                    editingState.caretIndex = text.length;
                    break;
                case AsyncUIKeyC:
                    if ([AsyncUITextInputEngineSupport stateHasSelection: editingState])
                        clipboardTextSetter([AsyncUITextInputEngineSupport selectedTextIn: text state: editingState]);
                    break;
                case AsyncUIKeyX:
                    if ([AsyncUITextInputEngineSupport stateHasSelection: editingState]) {
                        clipboardTextSetter([AsyncUITextInputEngineSupport selectedTextIn: text state: editingState]);
                        text = [AsyncUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                        textChanged = true;
                    }
                    break;
                case AsyncUIKeyV: {
                    OFString *nillable clipboardText = clipboardTextProvider();

                    if (clipboardText != nilptr and $assert_nonnil(clipboardText).length > 0) {
                        OFString *pastedText = [$assert_nonnil(clipboardText) stringByReplacingOccurrencesOfString: @"\n"
                                                                                                         withString: @""];

                        if (pastedText.length == 0)
                            break;
                        text = [AsyncUITextInputEngineSupport stringByReplacingSelectionIn: text
                                                                                  state: editingState
                                                                            replacement: pastedText];
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
            case AsyncUIKeyLeft:
                if ([AsyncUITextInputEngineSupport stateHasSelection: editingState])
                    [AsyncUITextInputEngineSupport collapseSelectionForState: editingState
                                                                  atIndex: [AsyncUITextInputEngineSupport selectionStartForState: editingState]];
                else if (editingState.caretIndex > 0)
                    [AsyncUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                break;
            case AsyncUIKeyRight:
                if ([AsyncUITextInputEngineSupport stateHasSelection: editingState])
                    [AsyncUITextInputEngineSupport collapseSelectionForState: editingState
                                                                  atIndex: [AsyncUITextInputEngineSupport selectionStartForState: editingState] +
                                                                          [AsyncUITextInputEngineSupport selectionLengthForState: editingState]];
                else if (editingState.caretIndex < text.length)
                    [AsyncUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex + 1];
                break;
            case AsyncUIKeyHome:
                [AsyncUITextInputEngineSupport collapseSelectionForState: editingState atIndex: 0];
                break;
            case AsyncUIKeyEnd:
                [AsyncUITextInputEngineSupport collapseSelectionForState: editingState atIndex: text.length];
                break;
            case AsyncUIKeyBackspace:
                if ([AsyncUITextInputEngineSupport stateHasSelection: editingState]) {
                    text = [AsyncUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex > 0) {
                    text = [AsyncUITextInputEngineSupport stringByRemovingRangeFrom: text
                                                                        location: editingState.caretIndex - 1
                                                                          length: 1];
                    [AsyncUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                    textChanged = true;
                }
                break;
            case AsyncUIKeyDelete:
                if ([AsyncUITextInputEngineSupport stateHasSelection: editingState]) {
                    text = [AsyncUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex < text.length) {
                    text = [AsyncUITextInputEngineSupport stringByRemovingRangeFrom: text
                                                                        location: editingState.caretIndex
                                                                          length: 1];
                    textChanged = true;
                }
                break;
            case AsyncUIKeyEnter:
            case AsyncUIKeyKeypadEnter:
                if (registration.submitHandler != nilptr)
                    registration.submitHandler(text);
                break;
            default:
                break;
        }
    }

    if (textChanged and registration.textChangeHandler != nilptr)
        registration.textChangeHandler(text);

    return (textChanged or editingState.caretIndex != previousCaretIndex or
            editingState.selectionAnchorIndex != previousAnchorIndex or
            editingState.selectionFocusIndex != previousFocusIndex);
}

- (void)retainStatesForIdentifiers: (OFSet<OFString *> *)identifiers
{
    OFArray<OFString *> *keys = [_statesByIdentifier.allKeys copy];

    for (OFString *identifier in keys) {
        if (not [identifiers containsObject: identifier])
            [_statesByIdentifier removeObjectForKey: identifier];
    }
}

- (void)resetState
{
    [_statesByIdentifier removeAllObjects];
}

@end

#pragma clang assume_nonnull end
