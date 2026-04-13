#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUIBadge : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *text;
@property(readonly, nonatomic) AUIControlVariant variant;

+ (instancetype)text: (OFString *nillable)text;
+ (instancetype)text: (OFString *nillable)text variant: (AUIControlVariant)variant;

@end

#pragma clang assume_nonnull end
