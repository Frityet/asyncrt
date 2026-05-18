#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AsyncUIContentKind {
    AsyncUIContentKindComponent,
    AsyncUIContentKindKeyed,
    AsyncUIContentKindGroup,
    AsyncUIContentKindStack,
    AsyncUIContentKindBox,
    AsyncUIContentKindText,
    AsyncUIContentKindButton,
    AsyncUIContentKindTextField
} AsyncUIContentKind;

@protocol AsyncUIContent

@property(readonly, nonatomic) AsyncUIContentKind contentKind;

@end

#pragma clang assume_nonnull end
