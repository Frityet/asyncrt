#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUILabel : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, nonatomic) AUITextStyle style;

+ (instancetype)text: (OFString *nillable)text;
+ (instancetype)text: (OFString *nillable)text style: (AUITextStyle)style;

@end

#pragma clang assume_nonnull end
