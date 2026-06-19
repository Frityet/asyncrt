#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Action.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ControlColors.h>
#import <AsyncRT/Application/UI/Window/Input.h>

@class AsyncUIContextMenu;

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIInteraction : OFObject

@property(nonatomic) bool isEnabled;
@property(nonatomic) bool isFocusable;
@property(nonatomic) AsyncUICursorStyle cursorStyle;
@property(retain, nonatomic) AsyncUIControlColors *nillable feedbackColors;
@property(retain, nonatomic) AsyncUIAction *nillable activationAction;
@property(retain, nonatomic) AsyncUIContextMenu *nillable contextMenu;
@property(class, readonly, nonatomic) AsyncUIInteraction *enabled;

+ (instancetype)enabled;
+ (instancetype)withActivation: (AsyncUIActionHandler nillable)handler;
+ (instancetype)withAsyncActivation: (AsyncUIAsyncActionHandler nillable)handler;
+ (instancetype)withAsyncActivation: (AsyncUIAsyncActionHandler nillable)handler
                              named: (OFString *nillable)name;

@end

#pragma clang assume_nonnull end
