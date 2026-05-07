#import "AUIButton.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIButton

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
                  onPress: (AUIActionHandler nillable)handler
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AUIAction withHandler: handler]
                               enabled: true];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
                  onPress: (AUIActionHandler nillable)handler
                  enabled: (bool)isEnabled
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AUIAction withHandler: handler]
                               enabled: isEnabled];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
             onPressAsync: (AUIAsyncActionHandler nillable)handler
{
    return [self withTitle: title
                  styledBy: style
              onPressAsync: handler
                     named: nilptr
                   enabled: true];
}

+ (instancetype)withTitle: (OFString *)title
                 styledBy: (AUIControlStyle *)style
             onPressAsync: (AUIAsyncActionHandler nillable)handler
                    named: (OFString *nillable)name
                  enabled: (bool)isEnabled
{
    return [[self alloc] initWithTitle: title
                                 style: style
                                action: [AUIAction withName: name asyncHandler: handler]
                               enabled: isEnabled];
}

- (instancetype)initWithTitle: (OFString *)title
                        style: (AUIControlStyle *)style
                       action: (AUIAction *nillable)action
                      enabled: (bool)isEnabled
{
    self = [super init];
    _title = [title copy];
    _style = style;
    _action = action;
    _isEnabled = isEnabled;
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindButton;
}

@end

#pragma clang assume_nonnull end
