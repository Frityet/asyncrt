#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUICard : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
