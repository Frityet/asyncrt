#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

@interface AUICheckbox : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *label;
@property(readonly, nonatomic, getter=isChecked) bool checked;
@property(readonly, nonatomic, getter=isEnabled) bool enabled;
@property(readonly, copy, nonatomic) void (^nillable changeHandler)(bool value);

+ (instancetype)label: (OFString *nillable)label
              checked: (bool)checked
              enabled: (bool)enabled
             onChange: (void (^nillable)(bool value))changeHandler;

@end

#pragma clang assume_nonnull end
