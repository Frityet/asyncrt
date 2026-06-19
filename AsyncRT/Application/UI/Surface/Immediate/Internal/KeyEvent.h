#pragma once

#include <AsyncRT/Common/common.h>

#import <AsyncRT/Application/UI/Window/Input.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIKeyEvent : OFObject

@property(readonly, nonatomic) AsyncUIKey key;
@property(readonly, nonatomic) AsyncUIModifierFlags modifiers;
@property(readonly, nonatomic) bool isRepeat;

+ (instancetype)key: (AsyncUIKey)key
          modifiers: (AsyncUIModifierFlags)modifiers
             repeat: (bool)isRepeat;
- (instancetype)initWithKey: (AsyncUIKey)key
                  modifiers: (AsyncUIModifierFlags)modifiers
                     repeat: (bool)isRepeat [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
