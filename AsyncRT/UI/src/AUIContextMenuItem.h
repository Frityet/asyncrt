#pragma once

#import "AUIAction.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIContextMenuItem : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, retain, nonatomic) AUIAction *nillable action;

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AUIActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AUIActionHandler nillable)handler
                  enabled: (bool)enabled;
+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AUIAsyncActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)enabled;
- (instancetype)initWithTitle: (OFString *nonnil)title
                      enabled: (bool)enabled
                       action: (AUIAction *nillable)action [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
