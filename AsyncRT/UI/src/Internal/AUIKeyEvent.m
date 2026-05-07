#import "Internal/AUIKeyEvent.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIKeyEvent

+ (instancetype)key: (AUIKey)key
          modifiers: (AUIModifierFlags)modifiers
             repeat: (bool)isRepeat
{
    return [[self alloc] initWithKey: key modifiers: modifiers repeat: isRepeat];
}

- (instancetype)initWithKey: (AUIKey)key
                  modifiers: (AUIModifierFlags)modifiers
                     repeat: (bool)isRepeat
{
    self = [super init];
    _key = key;
    _modifiers = modifiers;
    _isRepeat = isRepeat;
    return self;
}

@end

#pragma clang assume_nonnull end
