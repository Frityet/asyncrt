#pragma once

#import "UI/Components/AUIValues.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUITextInput : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, copy, nonatomic) OFString *placeholder;
@property(readonly, nonatomic) AUITextStyle style;
@property(readonly, nonatomic) AUITextInputColors colors;
@property(readonly, nonatomic) AUILayout layout;
@property(readonly, nonatomic) float cornerRadius;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, nonatomic) bool isSecure;
@property(readonly, nonatomic) bool isMultiline;
@property(readonly, copy, nonatomic) void (^nillable changeHandler)(OFString *text);
@property(readonly, copy, nonatomic) void (^nillable submitHandler)(OFString *text);

+ (instancetype)text: (OFString *nillable)text
         placeholder: (OFString *nillable)placeholder
               style: (AUITextStyle)style
              colors: (AUITextInputColors)colors
              layout: (AUILayout)layout
              radius: (float)cornerRadius
             enabled: (bool)enabled
              secure: (bool)secure
           multiline: (bool)multiline
            onChange: (void (^nillable)(OFString *text))changeHandler
            onSubmit: (void (^nillable)(OFString *text))submitHandler;

@end

#pragma clang assume_nonnull end
