#import "UI/AUIInternal.h"

#pragma clang assume_nonnull begin

@namespace(AUIInputSupport)

+ (OFString *)stringFromCodepoint: (unsigned int)codepoint;

@end

@namespace_implementation(AUIInputSupport)

+ (OFString *)stringFromCodepoint: (unsigned int)codepoint
{
    char buffer[5] = {0};

    if (codepoint <= 0x7F) {
        buffer[0] = (char)codepoint;
    } else if (codepoint <= 0x7FF) {
        buffer[0] = (char)(0xC0 | ((codepoint >> 6) & 0x1F));
        buffer[1] = (char)(0x80 | (codepoint & 0x3F));
    } else if (codepoint <= 0xFFFF) {
        if (codepoint >= 0xD800 and codepoint <= 0xDFFF)
            return @"";

        buffer[0] = (char)(0xE0 | ((codepoint >> 12) & 0x0F));
        buffer[1] = (char)(0x80 | ((codepoint >> 6) & 0x3F));
        buffer[2] = (char)(0x80 | (codepoint & 0x3F));
    } else if (codepoint <= 0x10FFFF) {
        buffer[0] = (char)(0xF0 | ((codepoint >> 18) & 0x07));
        buffer[1] = (char)(0x80 | ((codepoint >> 12) & 0x3F));
        buffer[2] = (char)(0x80 | ((codepoint >> 6) & 0x3F));
        buffer[3] = (char)(0x80 | (codepoint & 0x3F));
    } else {
        return @"";
    }

    return [[OFString alloc] initWithUTF8String: buffer];
}

@end

@implementation AUIKeyEvent {
    AUIKey _key;
    AUIModifierFlags _modifiers;
    bool _repeat;
}

@synthesize isRepeat = _repeat;

+ (instancetype)key: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat
{
    return [[self alloc] initWithKey: key modifiers: modifiers repeat: repeat];
}

- (instancetype)initWithKey: (AUIKey)key
                  modifiers: (AUIModifierFlags)modifiers
                     repeat: (bool)repeat
{
    self = [super init];
    _key = key;
    _modifiers = modifiers;
    _repeat = repeat;
    return self;
}

@end

@implementation AUIInputState {
    float _pointerX;
    float _pointerY;
    bool _primaryButtonDown;
    bool _primaryButtonPressedThisFrame;
    bool _primaryButtonReleasedThisFrame;
    bool _secondaryButtonDown;
    bool _secondaryButtonPressedThisFrame;
    bool _secondaryButtonReleasedThisFrame;
    float _scrollDeltaX;
    float _scrollDeltaY;
    OFString *_typedText;
    OFMutableArray<AUIKeyEvent *> *_keyEvents;
}

@synthesize isPrimaryButtonDown = _primaryButtonDown;
@synthesize isSecondaryButtonDown = _secondaryButtonDown;

- (instancetype)init
{
    self = [super init];
    _typedText = @"";
    _keyEvents = [OFMutableArray array];
    return self;
}

- (void)movePointerToX: (float)x y: (float)y
{
    _pointerX = x;
    _pointerY = y;
}

- (void)pressMouseButton: (AUIMouseButton)button
{
    switch (button) {
        case AUIMouseButtonSecondary:
            if (not _secondaryButtonDown)
                _secondaryButtonPressedThisFrame = true;
            _secondaryButtonDown = true;
            break;
        case AUIMouseButtonMiddle:
            break;
        case AUIMouseButtonPrimary:
        default:
            if (not _primaryButtonDown)
                _primaryButtonPressedThisFrame = true;
            _primaryButtonDown = true;
            break;
    }
}

- (void)releaseMouseButton: (AUIMouseButton)button
{
    switch (button) {
        case AUIMouseButtonSecondary:
            if (_secondaryButtonDown)
                _secondaryButtonReleasedThisFrame = true;
            _secondaryButtonDown = false;
            break;
        case AUIMouseButtonMiddle:
            break;
        case AUIMouseButtonPrimary:
        default:
            if (_primaryButtonDown)
                _primaryButtonReleasedThisFrame = true;
            _primaryButtonDown = false;
            break;
    }
}

- (void)scrollByX: (float)deltaX y: (float)deltaY
{
    _scrollDeltaX += deltaX;
    _scrollDeltaY += deltaY;
}

- (void)addKey: (AUIKey)key modifiers: (AUIModifierFlags)modifiers repeat: (bool)repeat
{
    [_keyEvents addObject: [AUIKeyEvent key: key modifiers: modifiers repeat: repeat]];
}

- (void)insertText: (OFString *nillable)text
{
    if (text == nilptr or $assert_nonnil(text).length == 0)
        return;

    _typedText = [OFString stringWithFormat: @"%@%@", _typedText, $assert_nonnil(text)];
}

- (void)appendCodepoint: (unsigned int)codepoint
{
    OFString *fragment = [AUIInputSupport stringFromCodepoint: codepoint];

    if (fragment.length == 0)
        return;

    [self insertText: fragment];
}

- (void)resetTransientState
{
    _primaryButtonPressedThisFrame = false;
    _primaryButtonReleasedThisFrame = false;
    _secondaryButtonPressedThisFrame = false;
    _secondaryButtonReleasedThisFrame = false;
    _scrollDeltaX = 0;
    _scrollDeltaY = 0;
    _typedText = @"";
    [_keyEvents removeAllObjects];
}

@end

@implementation AUITextEditingState {
    size_t _caretIndex;
    size_t _selectionAnchorIndex;
    size_t _selectionFocusIndex;
}


+ (instancetype)caretIndex: (size_t)caretIndex
      selectionAnchorIndex: (size_t)selectionAnchorIndex
       selectionFocusIndex: (size_t)selectionFocusIndex
{
    return [[self alloc] initWithCaretIndex: caretIndex
                       selectionAnchorIndex: selectionAnchorIndex
                        selectionFocusIndex: selectionFocusIndex];
}

- (instancetype)initWithCaretIndex: (size_t)caretIndex
{
    return [self initWithCaretIndex: caretIndex
               selectionAnchorIndex: caretIndex
                selectionFocusIndex: caretIndex];
}

- (instancetype)initWithCaretIndex: (size_t)caretIndex
              selectionAnchorIndex: (size_t)selectionAnchorIndex
               selectionFocusIndex: (size_t)selectionFocusIndex
{
    self = [super init];
    _caretIndex = caretIndex;
    _selectionAnchorIndex = selectionAnchorIndex;
    _selectionFocusIndex = selectionFocusIndex;
    return self;
}

@end

@implementation AUIInteractionRegistration {
    OFString *_identifier;
    Clay_ElementId _elementID;
    bool _enabled;
    bool _focusable;
    bool _multiline;
    OFString *nillable _text;
    AUICursorStyle _cursorStyle;
    AUIContextMenu *nillable _contextMenu;
    void (^nillable _activateHandler)(void);
    void (^nillable _textChangeHandler)(OFString *text);
    void (^nillable _submitHandler)(OFString *text);
}

@synthesize isEnabled = _enabled;
@synthesize isFocusable = _focusable;
@synthesize isMultiline = _multiline;

+ (instancetype)identifier: (OFString *nillable)identifier
                  elementID: (Clay_ElementId)elementID
{
    return [[self alloc] initWithIdentifier: identifier elementID: elementID];
}

- (instancetype)initWithIdentifier: (OFString *nillable)identifier
                         elementID: (Clay_ElementId)elementID
{
    if (identifier == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _identifier = [identifier copy];
    _elementID = elementID;
    _enabled = true;
    _focusable = false;
    _multiline = false;
    _text = nilptr;
    _cursorStyle = AUICursorStyleDefault;
    _contextMenu = nilptr;
    return self;
}

@end

#pragma clang assume_nonnull end
