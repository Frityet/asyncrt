#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIDivider : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) bool horizontal;
@property(readonly, nonatomic) uint16_t thickness;
@property(readonly, nonatomic) AUIColor color;

+ (instancetype)horizontalWithThickness: (uint16_t)thickness color: (AUIColor)color;
+ (instancetype)verticalWithThickness: (uint16_t)thickness color: (AUIColor)color;

@end

#pragma clang assume_nonnull end
