#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUIFrame : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) AUILayoutAxis width;
@property(readonly, nonatomic) AUILayoutAxis height;
@property(readonly, nonatomic) AUIChildAlignment alignment;
@property(readonly, retain, nonatomic) id<AUIRenderable> child;

+ (instancetype)width: (AUILayoutAxis)width height: (AUILayoutAxis)height child: (id<AUIRenderable>)child;
+ (instancetype)width: (AUILayoutAxis)width
               height: (AUILayoutAxis)height
            alignment: (AUIChildAlignment)alignment
                child: (id<AUIRenderable>)child;

@end

#pragma clang assume_nonnull end
