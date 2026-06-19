#import <AsyncRT/Application/UI/Surface/Immediate/Button.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIButton

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
                  onPress: (AsyncUIActionHandler nillable)handler
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AsyncUIAction withHandler: handler]
                               enabled: true];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
                  onPress: (AsyncUIActionHandler nillable)handler
                  enabled: (bool)isEnabled
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AsyncUIAction withHandler: handler]
                               enabled: isEnabled];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
{
    return [self withTitle: title
                  styledBy: style
              onPressAsync: handler
                     named: nilptr
                   enabled: true];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AsyncUIControlStyle *)style
             onPressAsync: (AsyncUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)isEnabled
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AsyncUIAction withName: name asyncHandler: handler]
                               enabled: isEnabled];
}

- (instancetype)initWithTitle: (OFString *)title
                        style: (AsyncUIControlStyle *)style
                       action: (AsyncUIAction *nillable)action
                      enabled: (bool)isEnabled
{
    self = [super init];
    _title = [title copy];
    _style = style;
    _action = action;
    _isEnabled = isEnabled;
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindButton;
}

@end

#pragma clang assume_nonnull end
