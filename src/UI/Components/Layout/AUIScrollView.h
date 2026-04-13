#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUIScrollView : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) AUIScrollAxis axis;
@property(readonly, retain, nonatomic) id<AUIRenderable> child;

+ (instancetype)axis: (AUIScrollAxis)axis child: (id<AUIRenderable>)child;

@end

#pragma clang assume_nonnull end
