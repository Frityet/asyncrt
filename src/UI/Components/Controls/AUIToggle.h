#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIToggle : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFString *label;
@property(readonly, nonatomic) bool isChecked;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, copy, nonatomic) void (^nillable changeHandler)(bool value);

+ (instancetype)label: (OFString *nillable)label
              checked: (bool)checked
              enabled: (bool)enabled
             onChange: (void (^nillable)(bool value))changeHandler;

@end

#pragma clang assume_nonnull end
