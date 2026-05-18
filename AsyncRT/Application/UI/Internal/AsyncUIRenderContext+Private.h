#pragma once

#import <AsyncRT/Application/UI/AsyncUIRenderContext.h>

#pragma clang assume_nonnull begin

@interface AsyncUIRenderContext ()

+ (void)_pushCurrentContext: (AsyncUIRenderContext *)context;
+ (void)_popCurrentContext;

@end

#pragma clang assume_nonnull end
