#import <AsyncRT/Application/UI/Surface/Immediate/Internal/KeyEvent.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIKeyEvent

+ (instancetype)key: (AsyncUIKey)key
          modifiers: (AsyncUIModifierFlags)modifiers
             repeat: (bool)isRepeat
{
    return [[self alloc] initWithKey: key modifiers: modifiers repeat: isRepeat];
}

- (instancetype)initWithKey: (AsyncUIKey)key
                  modifiers: (AsyncUIModifierFlags)modifiers
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
