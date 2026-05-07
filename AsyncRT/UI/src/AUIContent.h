#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AUIContentKind {
    AUIContentKindComponent,
    AUIContentKindKeyed,
    AUIContentKindGroup,
    AUIContentKindStack,
    AUIContentKindBox,
    AUIContentKindText,
    AUIContentKindButton,
    AUIContentKindTextField
} AUIContentKind;

@protocol AUIContent

@property(readonly, nonatomic) AUIContentKind contentKind;

@end

#pragma clang assume_nonnull end
