#pragma once

#import "AUIAction.h"
#import "AUIControlColors.h"
#import "Backend/AUIInput.h"

@class AUIContextMenu;

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIInteraction : OFObject

@property(nonatomic) bool isEnabled;
@property(nonatomic) bool isFocusable;
@property(nonatomic) AUICursorStyle cursorStyle;
@property(retain, nonatomic) AUIControlColors *nillable feedbackColors;
@property(retain, nonatomic) AUIAction *nillable activationAction;
@property(retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(class, readonly, nonatomic) AUIInteraction *enabled;

+ (instancetype)enabled;
+ (instancetype)withActivation: (AUIActionHandler nillable)handler;
+ (instancetype)withAsyncActivation: (AUIAsyncActionHandler nillable)handler;
+ (instancetype)withAsyncActivation: (AUIAsyncActionHandler nillable)handler
                              named: (OFString *nillable)name;

@end

#pragma clang assume_nonnull end
