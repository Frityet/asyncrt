#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUISecureField : OFObject<AUICompositeRenderable>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, copy, nonatomic) OFString *placeholder;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, copy, nonatomic) void (^nillable changeHandler)(OFString *text);
@property(readonly, copy, nonatomic) void (^nillable submitHandler)(OFString *text);

+ (instancetype)text: (OFString *nillable)text
         placeholder: (OFString *nillable)placeholder
             enabled: (bool)enabled
            onChange: (void (^nillable)(OFString *text))changeHandler
            onSubmit: (void (^nillable)(OFString *text))submitHandler;

@end

#pragma clang assume_nonnull end
