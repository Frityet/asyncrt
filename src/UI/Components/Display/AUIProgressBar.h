#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUIProgressBar : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) float progress;
@property(readonly, nonatomic) AUIControlVariant variant;

+ (instancetype)progress: (float)progress;
+ (instancetype)progress: (float)progress variant: (AUIControlVariant)variant;

@end

#pragma clang assume_nonnull end
