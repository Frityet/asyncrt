#import "Internal/AUIInputState.h"

#pragma clang assume_nonnull begin

@namespace(AUIInputStateSupport)

+ (OFString *)stringFromCodepoint: (unsigned int)codepoint;

@end

@namespace_implementation(AUIInputStateSupport)

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

[[direct_members]]
@implementation AUIInputState {
    OFMutableArray<AUIKeyEvent *> *_keyEvents;
}

- (instancetype)init
{
    self = [super init];
    _typedText = @"";
    _keyEvents = [OFMutableArray array];
    return self;
}

- (OFArray<AUIKeyEvent *> *)keyEvents
{
    return _keyEvents;
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
            if (not _isSecondaryButtonDown)
                _secondaryButtonPressedThisFrame = true;
            _isSecondaryButtonDown = true;
            break;
        case AUIMouseButtonMiddle:
            break;
        case AUIMouseButtonPrimary:
        default:
            if (not _isPrimaryButtonDown)
                _primaryButtonPressedThisFrame = true;
            _isPrimaryButtonDown = true;
            break;
    }
}

- (void)releaseMouseButton: (AUIMouseButton)button
{
    switch (button) {
        case AUIMouseButtonSecondary:
            if (_isSecondaryButtonDown)
                _secondaryButtonReleasedThisFrame = true;
            _isSecondaryButtonDown = false;
            break;
        case AUIMouseButtonMiddle:
            break;
        case AUIMouseButtonPrimary:
        default:
            if (_isPrimaryButtonDown)
                _primaryButtonReleasedThisFrame = true;
            _isPrimaryButtonDown = false;
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
    OFString *fragment = [AUIInputStateSupport stringFromCodepoint: codepoint];

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

#pragma clang assume_nonnull end
