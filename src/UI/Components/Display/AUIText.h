#pragma once

#import "UI/Components/AUIValues.h"

#pragma clang assume_nonnull begin

@interface AUIText : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, nonatomic) AUITextStyle style;

+ (instancetype)string: (OFString *nillable)text;
+ (instancetype)string: (OFString *nillable)text style: (AUITextStyle)style;
+ (instancetype)format: (OFConstantString *nillable)format, ...;
+ (instancetype)style: (AUITextStyle)style format: (OFConstantString *nillable)format, ...;

@end

#pragma clang assume_nonnull end
