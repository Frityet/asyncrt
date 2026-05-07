#pragma once

#import "AUIContent.h"
#import "AUIControlStyle.h"
#import "AUITextInputHandlers.h"

@class AUIContextMenu;

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUITextField : OFObject<AUIContent>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, copy, nonatomic) OFString *placeholder;
@property(readonly, retain, nonatomic) AUIControlStyle *style;
@property(readonly, retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(readonly, copy, nonatomic) AUITextChangeHandler nillable changeHandler;
@property(readonly, copy, nonatomic) AUITextSubmitHandler nillable submitHandler;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, nonatomic) bool isSecure;

+ (instancetype)withText: (OFString *nillable)text
              placeholder: (OFString *)placeholder
                styledBy: (AUIControlStyle *)style
              contextMenu: (AUIContextMenu *nillable)contextMenu
                onChange: (AUITextChangeHandler nillable)changeHandler
                onSubmit: (AUITextSubmitHandler nillable)submitHandler
                 enabled: (bool)isEnabled
                  secure: (bool)isSecure;
- (instancetype)initWithText: (OFString *nillable)text
                  placeholder: (OFString *)placeholder
                        style: (AUIControlStyle *)style
                   contextMenu: (AUIContextMenu *nillable)contextMenu
                     onChange: (AUITextChangeHandler nillable)changeHandler
                     onSubmit: (AUITextSubmitHandler nillable)submitHandler
                      enabled: (bool)isEnabled
                       secure: (bool)isSecure [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
