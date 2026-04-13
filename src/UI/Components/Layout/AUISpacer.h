#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUISpacer : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) AUILayoutAxis width;
@property(readonly, nonatomic) AUILayoutAxis height;

+ (instancetype)width: (AUILayoutAxis)width height: (AUILayoutAxis)height;
+ (instancetype)grow;

@end

#pragma clang assume_nonnull end
