#pragma once

#import "UI/Components/AUIValues.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIGroup : OFObject<AUIRenderable>

@property(readonly, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
