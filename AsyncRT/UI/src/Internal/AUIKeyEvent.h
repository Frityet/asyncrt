#pragma once

#include "common.h"

#import "Backend/AUIInput.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIKeyEvent : OFObject

@property(readonly, nonatomic) AUIKey key;
@property(readonly, nonatomic) AUIModifierFlags modifiers;
@property(readonly, nonatomic) bool isRepeat;

+ (instancetype)key: (AUIKey)key
          modifiers: (AUIModifierFlags)modifiers
             repeat: (bool)isRepeat;
- (instancetype)initWithKey: (AUIKey)key
                  modifiers: (AUIModifierFlags)modifiers
                     repeat: (bool)isRepeat [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
