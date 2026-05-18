#pragma once

#import <AsyncRT/Application/UI/AsyncUIAction.h>
#import <AsyncRT/Application/UI/AsyncUIClaySupport.h>
#import <AsyncRT/Application/UI/AsyncUITextField.h>
#import <AsyncRT/Application/UI/AsyncUITextInputHandlers.h>
#import <AsyncRT/Application/UI/AsyncUIContextMenu.h>
#import <AsyncRT/Application/UI/Backend/AsyncUIInput.h>

#pragma clang assume_nonnull begin

@class AsyncUIAction;
@class AsyncUIContextMenu;
@class AsyncTaskGroup;

[[subclassing_restricted, direct_members]]
@interface AsyncUIInteractionRegistration : OFObject

@property(readonly, copy, nonatomic) OFString *identifier;
@property(readonly, nonatomic) Clay_ElementId elementID;
@property(nonatomic) bool isEnabled;
@property(nonatomic) bool isFocusable;
@property(copy, nonatomic) OFString *nillable text;
@property(nonatomic) AsyncUICursorStyle cursorStyle;
@property(retain, nonatomic) AsyncUIContextMenu *nillable contextMenu;
@property(retain, nonatomic) AsyncUIAction *nillable activationAction;
@property(retain, nonatomic) AsyncTaskGroup *nillable taskGroup;
@property(copy, nonatomic) AsyncUITextChangeHandler nillable textChangeHandler;
@property(copy, nonatomic) AsyncUITextSubmitHandler nillable submitHandler;

+ (instancetype)identifier: (OFString *)identifier
                  elementID: (Clay_ElementId)elementID;
- (instancetype)initWithIdentifier: (OFString *)identifier
                         elementID: (Clay_ElementId)elementID [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
