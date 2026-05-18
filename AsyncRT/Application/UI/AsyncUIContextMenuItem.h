#pragma once

#import <AsyncRT/Application/UI/AsyncUIAction.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIContextMenuItem : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, retain, nonatomic) AsyncUIAction *nillable action;

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AsyncUIActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AsyncUIActionHandler nillable)handler
                  enabled: (bool)enabled;
+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)enabled;
- (instancetype)initWithTitle: (OFString *nonnil)title
                      enabled: (bool)enabled
                       action: (AsyncUIAction *nillable)action [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
