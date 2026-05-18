#pragma once

#import <AsyncRT/Application/UI/AsyncUIAction.h>
#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/AsyncUIControlStyle.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIButton : OFObject<AsyncUIContent>

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, retain, nonatomic) AsyncUIControlStyle *style;
@property(readonly, retain, nonatomic) AsyncUIAction *nillable action;
@property(readonly, nonatomic) bool isEnabled;

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
                  onPress: (AsyncUIActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
                  onPress: (AsyncUIActionHandler nillable)handler
                  enabled: (bool)isEnabled;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)isEnabled;
- (instancetype)initWithTitle: (OFString *)title
                        style: (AsyncUIControlStyle *)style
                       action: (AsyncUIAction *nillable)action
                      enabled: (bool)isEnabled [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
