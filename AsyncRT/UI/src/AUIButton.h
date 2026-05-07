#pragma once

#import "AUIAction.h"
#import "AUIContent.h"
#import "AUIControlStyle.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIButton : OFObject<AUIContent>

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, retain, nonatomic) AUIControlStyle *style;
@property(readonly, retain, nonatomic) AUIAction *nillable action;
@property(readonly, nonatomic) bool isEnabled;

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
                  onPress: (AUIActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
                  onPress: (AUIActionHandler nillable)handler
                  enabled: (bool)isEnabled;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
             onPressAsync: (AUIAsyncActionHandler nillable)handler;
+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
             onPressAsync: (AUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)isEnabled;
- (instancetype)initWithTitle: (OFString *)title
                        style: (AUIControlStyle *)style
                       action: (AUIAction *nillable)action
                      enabled: (bool)isEnabled [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
