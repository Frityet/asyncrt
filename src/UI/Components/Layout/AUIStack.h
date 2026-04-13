#pragma once

#import "UI/Components/Layout/AUIBox.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIStack : AUIBox

+ (instancetype)rowWithLayout: (AUILayout)layout
                   background: (AUIColor)backgroundColor
                       radius: (float)cornerRadius
                       border: (AUIBorder)border
                     children: (OFArray<id<AUIRenderable>> *nillable)children;
+ (instancetype)columnWithLayout: (AUILayout)layout
                      background: (AUIColor)backgroundColor
                          radius: (float)cornerRadius
                          border: (AUIBorder)border
                        children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
