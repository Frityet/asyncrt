#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

typedef void (^AsyncUITextChangeHandler)(OFString *text);
typedef void (^AsyncUITextSubmitHandler)(OFString *text);

#pragma clang assume_nonnull end
