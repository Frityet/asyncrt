#pragma once

#import "UI/Components/AUIValues.h"

#pragma clang assume_nonnull begin

@interface AUIBox : OFObject<AUIRenderable>

@property(readonly, nonatomic) AUILayout layout;
@property(readonly, nonatomic) AUIColor backgroundColor;
@property(readonly, nonatomic) float cornerRadius;
@property(readonly, nonatomic) AUIBorder border;
@property(readonly, nonatomic) AUIScrollAxis scrollAxis;
@property(readonly, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)layout: (AUILayout)layout
            background: (AUIColor)backgroundColor
                radius: (float)cornerRadius
                border: (AUIBorder)border
              children: (OFArray<id<AUIRenderable>> *nillable)children;
+ (instancetype)layout: (AUILayout)layout
            background: (AUIColor)backgroundColor
                radius: (float)cornerRadius
                border: (AUIBorder)border
                scroll: (AUIScrollAxis)scrollAxis
              children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
