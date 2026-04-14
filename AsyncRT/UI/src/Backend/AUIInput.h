#pragma once

#include <stdint.h>

#pragma clang assume_nonnull begin

typedef enum AUIKey {
    AUIKeyUnknown = 0,
    AUIKeyTab,
    AUIKeyEnter,
    AUIKeyKeypadEnter,
    AUIKeyEscape,
    AUIKeyLeft,
    AUIKeyRight,
    AUIKeyUp,
    AUIKeyDown,
    AUIKeyHome,
    AUIKeyEnd,
    AUIKeyPageUp,
    AUIKeyPageDown,
    AUIKeyBackspace,
    AUIKeyDelete,
    AUIKeyA,
    AUIKeyC,
    AUIKeyV,
    AUIKeyX
} AUIKey;

typedef uint32_t AUIModifierFlags;

enum {
    AUIModifierFlagNone = 0,
    AUIModifierFlagShift = (1u << 0),
    AUIModifierFlagControl = (1u << 1),
    AUIModifierFlagAlt = (1u << 2),
    AUIModifierFlagCommand = (1u << 3),
    AUIModifierFlagSuper = (1u << 4)
};

typedef enum AUIMouseButton {
    AUIMouseButtonPrimary = 0,
    AUIMouseButtonSecondary,
    AUIMouseButtonMiddle
} AUIMouseButton;

typedef enum AUICursorStyle {
    AUICursorStyleDefault = 0,
    AUICursorStylePointer,
    AUICursorStyleText
} AUICursorStyle;

#pragma clang assume_nonnull end
