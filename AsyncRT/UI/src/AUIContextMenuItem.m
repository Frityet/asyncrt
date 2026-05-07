#import "AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIContextMenuItem {
    OFString *_title;
    bool _isEnabled;
    AUIAction *nillable _action;
}

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AUIActionHandler nillable)handler
{
    return [[self alloc] initWithTitle: title
                               enabled: true
                                action: [AUIAction withHandler: handler]];
}

+ (instancetype)withTitle: (OFString *nonnil)title
                  onPress: (AUIActionHandler nillable)handler
                  enabled: (bool)enabled
{
    return [[self alloc] initWithTitle: title
                               enabled: enabled
                                action: [AUIAction withHandler: handler]];
}

+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AUIAsyncActionHandler nillable)handler
{
    return [self withTitle: title
              onPressAsync: handler
                     named: nilptr
                   enabled: true];
}

+ (instancetype)withTitle: (OFString *nonnil)title
             onPressAsync: (AUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)enabled
{
    return [[self alloc] initWithTitle: title
                               enabled: enabled
                                action: [AUIAction withName: name asyncHandler: handler]];
}

- (instancetype)initWithTitle: (OFString *nonnil)title
                      enabled: (bool)enabled
                       action: (AUIAction *nillable)action
{
    self = [super init];
    _title = [title copy];
    _isEnabled = enabled;
    _action = action;
    return self;
}

@end

#pragma clang assume_nonnull end
