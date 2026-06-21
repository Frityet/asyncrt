#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Action.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>
#import <AsyncRT/Application/UI/Surface/Immediate/TextField.h>
#import <AsyncRT/Application/UI/Surface/Immediate/TextInputHandlers.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ContextMenu.h>
#import <AsyncRT/Application/UI/Window/Input.h>

#pragma clang assume_nonnull begin

@class AsyncUIAction;
@class AsyncUIContextMenu;

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
@property(copy, nonatomic) AsyncUITextChangeHandler nillable textChangeHandler;
@property(copy, nonatomic) AsyncUITextSubmitHandler nillable submitHandler;

+ (instancetype)identifier: (OFString *)identifier
                  elementID: (Clay_ElementId)elementID;
- (instancetype)initWithIdentifier: (OFString *)identifier
                         elementID: (Clay_ElementId)elementID [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
