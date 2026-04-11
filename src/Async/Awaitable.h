#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@protocol Awaitable

- (id)await;

@end

#pragma clang assume_nonnull end
