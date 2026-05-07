#pragma once

#import "AUIRenderContext.h"

#pragma clang assume_nonnull begin

@interface AUIRenderContext ()

+ (void)_pushCurrentContext: (AUIRenderContext *)context;
+ (void)_popCurrentContext;

@end

#pragma clang assume_nonnull end
