#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIVStack : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;
@property(readonly, nonatomic) uint16_t gap;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children;
+ (instancetype)gap: (uint16_t)gap children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
