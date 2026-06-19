#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ControlStyle.h>
#import <AsyncRT/Application/UI/Surface/Immediate/TextInputHandlers.h>

@class AsyncUIContextMenu;

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUITextField : OFObject<AsyncUIContent>

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, copy, nonatomic) OFString *placeholder;
@property(readonly, retain, nonatomic) AsyncUIControlStyle *style;
@property(readonly, retain, nonatomic) AsyncUIContextMenu *nillable contextMenu;
@property(readonly, copy, nonatomic) AsyncUITextChangeHandler nillable changeHandler;
@property(readonly, copy, nonatomic) AsyncUITextSubmitHandler nillable submitHandler;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, nonatomic) bool isSecure;

+ (instancetype)withText: (OFString *nillable)text
              placeholder: (OFString *)placeholder
                styledBy: (AsyncUIControlStyle *)style
              contextMenu: (AsyncUIContextMenu *nillable)contextMenu
                onChange: (AsyncUITextChangeHandler nillable)changeHandler
                onSubmit: (AsyncUITextSubmitHandler nillable)submitHandler
                 enabled: (bool)isEnabled
                  secure: (bool)isSecure;
- (instancetype)initWithText: (OFString *nillable)text
                  placeholder: (OFString *)placeholder
                        style: (AsyncUIControlStyle *)style
                   contextMenu: (AsyncUIContextMenu *nillable)contextMenu
                     onChange: (AsyncUITextChangeHandler nillable)changeHandler
                     onSubmit: (AsyncUITextSubmitHandler nillable)submitHandler
                      enabled: (bool)isEnabled
                       secure: (bool)isSecure [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
