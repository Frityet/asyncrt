#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef void (^AUITextChangeHandler)(OFString *text);
typedef void (^AUITextSubmitHandler)(OFString *text);

#pragma clang assume_nonnull end
