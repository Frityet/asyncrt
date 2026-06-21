#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InteractionRegistration.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIInteractionRegistration

+ (instancetype)identifier: (OFString *)identifier
                  elementID: (Clay_ElementId)elementID
{
    return [[self alloc] initWithIdentifier: identifier elementID: elementID];
}

- (instancetype)initWithIdentifier: (OFString *)identifier
                         elementID: (Clay_ElementId)elementID
{
    self = [super init];
    _identifier = [identifier copy];
    _elementID = elementID;
    _isEnabled = true;
    _isFocusable = false;
    _text = nilptr;
    _cursorStyle = AsyncUICursorStyleDefault;
    _contextMenu = nilptr;
    _activationAction = nilptr;
    return self;
}

@end

#pragma clang assume_nonnull end
