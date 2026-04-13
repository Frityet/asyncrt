#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@interface AUIException : OFException

@property(readonly, nonatomic) OFString *reason;
@property(readonly, nonatomic) OFException *nillable underlyingException;

- (instancetype)initWithReason: (OFString *nillable)reason;
- (instancetype)initWithReason: (OFString *nillable)reason
             underlyingException: (OFException *nillable)underlyingException designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIInitializationException : AUIException @end
@interface AUIRenderException : AUIException @end

#pragma clang assume_nonnull end
