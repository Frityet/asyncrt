#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIPadding : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) AUIInsets insets;
@property(readonly, retain, nonatomic) id<AUIRenderable> child;

+ (instancetype)insets: (AUIInsets)insets child: (id<AUIRenderable>)child;

@end

#pragma clang assume_nonnull end
