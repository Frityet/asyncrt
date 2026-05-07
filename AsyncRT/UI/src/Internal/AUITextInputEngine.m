#import "Internal/AUITextInputEngine.h"

#pragma clang assume_nonnull begin

@namespace(AUITextInputEngineSupport)

+ (size_t)selectionStartForState: (AUITextInputState *)state;
+ (size_t)selectionLengthForState: (AUITextInputState *)state;
+ (bool)stateHasSelection: (AUITextInputState *)state;
+ (void)collapseSelectionForState: (AUITextInputState *)state atIndex: (size_t)index;
+ (OFString *)stringByInsertingString: (OFString *)inserted into: (OFString *)source atIndex: (size_t)index;
+ (OFString *)stringByRemovingRangeFrom: (OFString *)source location: (size_t)location length: (size_t)length;
+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AUITextInputState *)state replacement: (OFString *)replacement;
+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextInputState *)state;
+ (OFString *)maskedStringWithLength: (size_t)length;

@end

@namespace_implementation(AUITextInputEngineSupport)

+ (size_t)selectionStartForState: (AUITextInputState *)state
{
    return (state.selectionAnchorIndex < state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);
}

+ (size_t)selectionLengthForState: (AUITextInputState *)state
{
    size_t start = [self selectionStartForState: state];
    size_t end = (state.selectionAnchorIndex > state.selectionFocusIndex
        ? state.selectionAnchorIndex
        : state.selectionFocusIndex);

    return (end - start);
}

+ (bool)stateHasSelection: (AUITextInputState *)state
{
    return (state.selectionAnchorIndex != state.selectionFocusIndex);
}

+ (void)collapseSelectionForState: (AUITextInputState *)state atIndex: (size_t)index
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

+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AUITextInputState *)state replacement: (OFString *)replacement
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];

    if (length > 0)
        source = [self stringByRemovingRangeFrom: source location: start length: length];

    source = [self stringByInsertingString: replacement into: source atIndex: start];
    [self collapseSelectionForState: state atIndex: start + replacement.length];
    return source;
}

+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextInputState *)state
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
@implementation AUITextInputEngine {
    OFMutableDictionary<OFString *, AUITextInputState *> *_statesByIdentifier;
}

- (instancetype)init
{
    self = [super init];
    _statesByIdentifier = [OFMutableDictionary dictionary];
    return self;
}

- (AUITextInputState *)inputStateForIdentifier: (OFString *)identifier
                                    textLength: (size_t)textLength
{
    AUITextInputState *state = _statesByIdentifier[identifier];

    if (state == nilptr) {
        state = [AUITextInputState caretIndex: textLength
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
        displayText = [AUITextInputEngineSupport maskedStringWithLength: value.length];

    if (displayText.length == 0 and not isFocused)
        return @"";

    if (isFocused) {
        OFString *head = [displayText substringToIndex: caretIndex];
        OFString *tail = [displayText substringFromIndex: caretIndex];

        return [OFString stringWithFormat: @"%@|%@", head, tail];
    }

    return displayText;
}

- (bool)applyInputState: (AUIInputState *)inputState
            registration: (AUIInteractionRegistration *)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
{
    bool textChanged = false;

    if (registration.textChangeHandler == nilptr and registration.submitHandler == nilptr)
        return false;

    OFString *text = (registration.text ?: @"");
    AUITextInputState *editingState = [self inputStateForIdentifier: registration.identifier textLength: text.length];
    const size_t previousCaretIndex = editingState.caretIndex;
    const size_t previousAnchorIndex = editingState.selectionAnchorIndex;
    const size_t previousFocusIndex = editingState.selectionFocusIndex;

    if (inputState.typedText.length > 0) {
        OFString *insertedText = [inputState.typedText stringByReplacingOccurrencesOfString: @"\n" withString: @""];

        if (insertedText.length > 0) {
            text = [AUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: insertedText];
            textChanged = true;
        }
    }

    for (AUIKeyEvent *keyEvent in inputState.keyEvents) {
        bool commandLike = ((keyEvent.modifiers & (AUIModifierFlagCommand | AUIModifierFlagControl)) != 0);

        if (commandLike) {
            switch (keyEvent.key) {
                case AUIKeyA:
                    editingState.selectionAnchorIndex = 0;
                    editingState.selectionFocusIndex = text.length;
                    editingState.caretIndex = text.length;
                    break;
                case AUIKeyC:
                    if ([AUITextInputEngineSupport stateHasSelection: editingState])
                        clipboardTextSetter([AUITextInputEngineSupport selectedTextIn: text state: editingState]);
                    break;
                case AUIKeyX:
                    if ([AUITextInputEngineSupport stateHasSelection: editingState]) {
                        clipboardTextSetter([AUITextInputEngineSupport selectedTextIn: text state: editingState]);
                        text = [AUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                        textChanged = true;
                    }
                    break;
                case AUIKeyV: {
                    OFString *nillable clipboardText = clipboardTextProvider();

                    if (clipboardText != nilptr and $assert_nonnil(clipboardText).length > 0) {
                        OFString *pastedText = [$assert_nonnil(clipboardText) stringByReplacingOccurrencesOfString: @"\n"
                                                                                                         withString: @""];

                        if (pastedText.length == 0)
                            break;
                        text = [AUITextInputEngineSupport stringByReplacingSelectionIn: text
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
            case AUIKeyLeft:
                if ([AUITextInputEngineSupport stateHasSelection: editingState])
                    [AUITextInputEngineSupport collapseSelectionForState: editingState
                                                                  atIndex: [AUITextInputEngineSupport selectionStartForState: editingState]];
                else if (editingState.caretIndex > 0)
                    [AUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                break;
            case AUIKeyRight:
                if ([AUITextInputEngineSupport stateHasSelection: editingState])
                    [AUITextInputEngineSupport collapseSelectionForState: editingState
                                                                  atIndex: [AUITextInputEngineSupport selectionStartForState: editingState] +
                                                                          [AUITextInputEngineSupport selectionLengthForState: editingState]];
                else if (editingState.caretIndex < text.length)
                    [AUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex + 1];
                break;
            case AUIKeyHome:
                [AUITextInputEngineSupport collapseSelectionForState: editingState atIndex: 0];
                break;
            case AUIKeyEnd:
                [AUITextInputEngineSupport collapseSelectionForState: editingState atIndex: text.length];
                break;
            case AUIKeyBackspace:
                if ([AUITextInputEngineSupport stateHasSelection: editingState]) {
                    text = [AUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex > 0) {
                    text = [AUITextInputEngineSupport stringByRemovingRangeFrom: text
                                                                        location: editingState.caretIndex - 1
                                                                          length: 1];
                    [AUITextInputEngineSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                    textChanged = true;
                }
                break;
            case AUIKeyDelete:
                if ([AUITextInputEngineSupport stateHasSelection: editingState]) {
                    text = [AUITextInputEngineSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex < text.length) {
                    text = [AUITextInputEngineSupport stringByRemovingRangeFrom: text
                                                                        location: editingState.caretIndex
                                                                          length: 1];
                    textChanged = true;
                }
                break;
            case AUIKeyEnter:
            case AUIKeyKeypadEnter:
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
