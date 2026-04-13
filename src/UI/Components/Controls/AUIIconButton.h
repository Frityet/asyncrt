#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUIIconButton : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *icon;
@property(readonly, nonatomic) AUIControlVariant variant;
@property(readonly, nonatomic) AUIControlSize size;
@property(readonly, nonatomic, getter=isEnabled) bool enabled;
@property(readonly, copy, nonatomic) void (^nillable pressHandler)(void);

+ (instancetype)icon: (OFString *nillable)icon
             variant: (AUIControlVariant)variant
                size: (AUIControlSize)size
             enabled: (bool)enabled
             onPress: (void (^nillable)(void))pressHandler;

@end

#pragma clang assume_nonnull end
