#pragma once

#include <stdint.h>

#pragma clang assume_nonnull begin

typedef enum AsyncUIKey {
    AsyncUIKeyUnknown = 0,
    AsyncUIKeyTab,
    AsyncUIKeyEnter,
    AsyncUIKeyKeypadEnter,
    AsyncUIKeyEscape,
    AsyncUIKeyLeft,
    AsyncUIKeyRight,
    AsyncUIKeyUp,
    AsyncUIKeyDown,
    AsyncUIKeyHome,
    AsyncUIKeyEnd,
    AsyncUIKeyPageUp,
    AsyncUIKeyPageDown,
    AsyncUIKeyBackspace,
    AsyncUIKeyDelete,
    AsyncUIKeyA,
    AsyncUIKeyC,
    AsyncUIKeyV,
    AsyncUIKeyX
} AsyncUIKey;

typedef uint32_t AsyncUIModifierFlags;

enum {
    AsyncUIModifierFlagNone = 0,
    AsyncUIModifierFlagShift = (1u << 0),
    AsyncUIModifierFlagControl = (1u << 1),
    AsyncUIModifierFlagAlt = (1u << 2),
    AsyncUIModifierFlagCommand = (1u << 3),
    AsyncUIModifierFlagSuper = (1u << 4)
};

typedef enum AsyncUIMouseButton {
    AsyncUIMouseButtonPrimary = 0,
    AsyncUIMouseButtonSecondary,
    AsyncUIMouseButtonMiddle
} AsyncUIMouseButton;

typedef enum AsyncUICursorStyle {
    AsyncUICursorStyleDefault = 0,
    AsyncUICursorStylePointer,
    AsyncUICursorStyleText
} AsyncUICursorStyle;

#pragma clang assume_nonnull end
