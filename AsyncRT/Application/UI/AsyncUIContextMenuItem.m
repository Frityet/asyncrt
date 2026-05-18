#import <AsyncRT/Application/UI/AsyncUIContextMenuItem.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIContextMenuItem {
    OFString *_title;
    bool _isEnabled;
    AsyncUIAction *nillable _action;
}

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AsyncUIActionHandler nillable)handler
{
    return [[self alloc] initWithTitle: title
                               enabled: true
                                action: [AsyncUIAction withHandler: handler]];
}

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AsyncUIActionHandler nillable)handler
                  enabled: (bool)enabled
{
    return [[self alloc] initWithTitle: title
                               enabled: enabled
                                action: [AsyncUIAction withHandler: handler]];
}

+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
{
    return [self withTitle: title
              onPressAsync: handler
                     named: nilptr
                   enabled: true];
}

+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)enabled
{
    return [[self alloc] initWithTitle: title
                               enabled: enabled
                                action: [AsyncUIAction withName: name asyncHandler: handler]];
}

- (instancetype)initWithTitle: (OFString *nonnil)title
                      enabled: (bool)enabled
                       action: (AsyncUIAction *nillable)action
{
    self = [super init];
    _title = [title copy];
    _isEnabled = enabled;
    _action = action;
    return self;
}

@end

#pragma clang assume_nonnull end
