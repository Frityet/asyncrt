#import "AUITextEditingController.h"

#pragma clang assume_nonnull begin

@namespace(AUITextEditingControllerSupport)

+ (size_t)selectionStartForState: (AUITextEditingState *)state;
+ (size_t)selectionLengthForState: (AUITextEditingState *)state;
+ (bool)stateHasSelection: (AUITextEditingState *)state;
+ (void)collapseSelectionForState: (AUITextEditingState *)state atIndex: (size_t)index;
+ (OFString *)stringByInsertingString: (OFString *)inserted into: (OFString *)source atIndex: (size_t)index;
+ (OFString *)stringByRemovingRangeFrom: (OFString *)source location: (size_t)location length: (size_t)length;
+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AUITextEditingState *)state replacement: (OFString *)replacement;
+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextEditingState *)state;
+ (OFString *)maskedStringWithLength: (size_t)length;

@end

@namespace_implementation(AUITextEditingControllerSupport)

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

+ (OFString *)stringByReplacingSelectionIn: (OFString *)source state: (AUITextEditingState *)state replacement: (OFString *)replacement
{
    size_t start = [self selectionStartForState: state];
    size_t length = [self selectionLengthForState: state];

    if (length > 0)
        source = [self stringByRemovingRangeFrom: source location: start length: length];

    source = [self stringByInsertingString: replacement into: source atIndex: start];
    [self collapseSelectionForState: state atIndex: start + replacement.length];
    return source;
}

+ (OFString *)selectedTextIn: (OFString *)source state: (AUITextEditingState *)state
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
@implementation AUITextEditingController {
    OFMutableDictionary<OFString *, AUITextEditingState *> *_editingStates;
}

- (instancetype)init
{
    self = [super init];
    _editingStates = [OFMutableDictionary dictionary];
    return self;
}

- (AUITextEditingState *)editingStateForIdentifier: (OFString *nonnil)identifier
                                        textLength: (size_t)textLength
{
    AUITextEditingState *state;

    state = _editingStates[identifier];
    if (state == nilptr) {
        state = [AUITextEditingState caretIndex: textLength
                           selectionAnchorIndex: textLength
                            selectionFocusIndex: textLength];
        _editingStates[identifier] = state;
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
        caretIndex = [self editingStateForIdentifier: $assert_nonnil(identifier) textLength: value.length].caretIndex;

    if (isSecure)
        displayText = [AUITextEditingControllerSupport maskedStringWithLength: value.length];

    if (displayText.length == 0 and not isFocused)
        return @"";

    if (isFocused) {
        OFString *head = [displayText substringToIndex: caretIndex];
        OFString *tail = [displayText substringFromIndex: caretIndex];

        return [OFString stringWithFormat: @"%@|%@", head, tail];
    }

    return displayText;
}

- (bool)applyInputState: (AUIInputState *nonnil)inputState
           toRegistration: (AUIInteractionRegistration *nonnil)registration
           clipboardText: (OFString *nillable (^nonnil)(void))clipboardTextProvider
     setClipboardText: (void (^nonnil)(OFString *nillable text))clipboardTextSetter
{
    bool textChanged = false;

    if (registration.textChangeHandler == nilptr and registration.submitHandler == nilptr)
        return false;

    OFString *text = (registration.text ?: @"");
    AUITextEditingState *editingState = [self editingStateForIdentifier: registration.identifier textLength: text.length];
    const size_t previousCaretIndex = editingState.caretIndex;
    const size_t previousAnchorIndex = editingState.selectionAnchorIndex;
    const size_t previousFocusIndex = editingState.selectionFocusIndex;

    if (inputState.typedText.length > 0) {
        OFString *insertedText = inputState.typedText;

        if (not registration.isMultiline)
            insertedText = [insertedText stringByReplacingOccurrencesOfString: @"\n" withString: @""];

        if (insertedText.length > 0) {
            text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text state: editingState replacement: insertedText];
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
                    if ([AUITextEditingControllerSupport stateHasSelection: editingState])
                        clipboardTextSetter([AUITextEditingControllerSupport selectedTextIn: text state: editingState]);
                    break;
                case AUIKeyX:
                    if ([AUITextEditingControllerSupport stateHasSelection: editingState]) {
                        clipboardTextSetter([AUITextEditingControllerSupport selectedTextIn: text state: editingState]);
                        text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                        textChanged = true;
                    }
                    break;
                case AUIKeyV: {
                    OFString *nillable clipboardText = clipboardTextProvider();

                    if (clipboardText != nilptr and $assert_nonnil(clipboardText).length > 0) {
                        text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text
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
                if ([AUITextEditingControllerSupport stateHasSelection: editingState])
                    [AUITextEditingControllerSupport collapseSelectionForState: editingState
                                                                       atIndex: [AUITextEditingControllerSupport selectionStartForState: editingState]];
                else if (editingState.caretIndex > 0)
                    [AUITextEditingControllerSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                break;
            case AUIKeyRight:
                if ([AUITextEditingControllerSupport stateHasSelection: editingState])
                    [AUITextEditingControllerSupport collapseSelectionForState: editingState
                                                                       atIndex: [AUITextEditingControllerSupport selectionStartForState: editingState] +
                                                                               [AUITextEditingControllerSupport selectionLengthForState: editingState]];
                else if (editingState.caretIndex < text.length)
                    [AUITextEditingControllerSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex + 1];
                break;
            case AUIKeyHome:
                [AUITextEditingControllerSupport collapseSelectionForState: editingState atIndex: 0];
                break;
            case AUIKeyEnd:
                [AUITextEditingControllerSupport collapseSelectionForState: editingState atIndex: text.length];
                break;
            case AUIKeyBackspace:
                if ([AUITextEditingControllerSupport stateHasSelection: editingState]) {
                    text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex > 0) {
                    text = [AUITextEditingControllerSupport stringByRemovingRangeFrom: text
                                                                             location: editingState.caretIndex - 1
                                                                               length: 1];
                    [AUITextEditingControllerSupport collapseSelectionForState: editingState atIndex: editingState.caretIndex - 1];
                    textChanged = true;
                }
                break;
            case AUIKeyDelete:
                if ([AUITextEditingControllerSupport stateHasSelection: editingState]) {
                    text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text state: editingState replacement: @""];
                    textChanged = true;
                } else if (editingState.caretIndex < text.length) {
                    text = [AUITextEditingControllerSupport stringByRemovingRangeFrom: text
                                                                             location: editingState.caretIndex
                                                                               length: 1];
                    textChanged = true;
                }
                break;
            case AUIKeyEnter:
            case AUIKeyKeypadEnter:
                if (registration.isMultiline) {
                    text = [AUITextEditingControllerSupport stringByReplacingSelectionIn: text state: editingState replacement: @"\n"];
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

    return (textChanged or editingState.caretIndex != previousCaretIndex or
            editingState.selectionAnchorIndex != previousAnchorIndex or
            editingState.selectionFocusIndex != previousFocusIndex);
}

- (void)retainEditingStatesForIdentifiers: (OFSet<OFString *> *)identifiers
{
    OFArray<OFString *> *keys = [_editingStates.allKeys copy];

    for (OFString *identifier in keys) {
        if (not [identifiers containsObject: identifier])
            [_editingStates removeObjectForKey: identifier];
    }
}

- (void)resetState
{
    [_editingStates removeAllObjects];
}

@end

#pragma clang assume_nonnull end
