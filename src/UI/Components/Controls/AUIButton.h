#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIButton : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) AUIControlVariant variant;
@property(readonly, nonatomic) AUIControlSize size;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, copy, nonatomic) void (^nillable pressHandler)(void);

+ (instancetype)title: (OFString *nillable)title
              variant: (AUIControlVariant)variant
                 size: (AUIControlSize)size
              enabled: (bool)enabled
              onPress: (void (^nillable)(void))pressHandler;

@end

#pragma clang assume_nonnull end
