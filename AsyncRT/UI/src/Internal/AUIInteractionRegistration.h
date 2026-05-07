#pragma once

#import "AUIAction.h"
#import "AUITextField.h"
#import "AUIContextMenu.h"
#import "Backend/AUIInput.h"
#import "clay.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIInteractionRegistration : OFObject

@property(readonly, copy, nonatomic) OFString *identifier;
@property(readonly, nonatomic) Clay_ElementId elementID;
@property(nonatomic) bool isEnabled;
@property(nonatomic) bool isFocusable;
@property(copy, nonatomic) OFString *nillable text;
@property(nonatomic) AUICursorStyle cursorStyle;
@property(retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(retain, nonatomic) AUIAction *nillable activationAction;
@property(retain, nonatomic) AsyncTaskGroup *nillable taskGroup;
@property(copy, nonatomic) AUITextChangeHandler nillable textChangeHandler;
@property(copy, nonatomic) AUITextSubmitHandler nillable submitHandler;

+ (instancetype)identifier: (OFString *)identifier
                  elementID: (Clay_ElementId)elementID;
- (instancetype)initWithIdentifier: (OFString *)identifier
                         elementID: (Clay_ElementId)elementID [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
