#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

@interface AUIException : OFException

@property(readonly, nonatomic) OFString *reason;
@property(readonly, nonatomic) OFException *nillable underlyingException;

- (instancetype)initWithReason: (OFString *nonnil)reason;
- (instancetype)initWithReason: (OFString *nonnil)reason
             underlyingException: (OFException *nillable)underlyingException [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIInitializationException : AUIException @end
[[subclassing_restricted, direct_members]]
@interface AUIRenderException : AUIException @end

#pragma clang assume_nonnull end
