#import "AUIInteraction.h"
#import "AUIContextMenu.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIInteraction

- (instancetype)init
{
    self = [super init];
    _isEnabled = true;
    _isFocusable = false;
    _cursorStyle = AUICursorStyleDefault;
    _feedbackColors = nilptr;
    _activationAction = nilptr;
    _contextMenu = nilptr;
    return self;
}

+ (instancetype)enabled
{
    return [[self alloc] init];
}

+ (instancetype)withActivation: (AUIActionHandler nillable)handler
{
    auto interaction = [[self alloc] init];
    interaction.activationAction = [AUIAction withHandler: handler];
    interaction.cursorStyle = AUICursorStylePointer;
    return interaction;
}

+ (instancetype)withAsyncActivation: (AUIAsyncActionHandler nillable)handler
{
    return [self withAsyncActivation: handler named: nilptr];
}

+ (instancetype)withAsyncActivation: (AUIAsyncActionHandler nillable)handler
                              named: (OFString *nillable)name
{
    auto interaction = [[self alloc] init];
    interaction.activationAction = [AUIAction withName: name asyncHandler: handler];
    interaction.cursorStyle = AUICursorStylePointer;
    return interaction;
}

@end

#pragma clang assume_nonnull end
