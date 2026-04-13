#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUISection : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *nillable title;
@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)children: (OFArray<id<AUIRenderable>> *nillable)children;
+ (instancetype)title: (OFString *nillable)title children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
