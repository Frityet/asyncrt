#import <AsyncRT/Application/UI/Surface/Immediate/Interaction.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ContextMenu.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIInteraction

- (instancetype)init
{
    self = [super init];
    _isEnabled = true;
    _isFocusable = false;
    _cursorStyle = AsyncUICursorStyleDefault;
    _feedbackColors = nilptr;
    _activationAction = nilptr;
    _contextMenu = nilptr;
    return self;
}

+ (instancetype)enabled
{
    return [[self alloc] init];
}

+ (instancetype)withActivation: (AsyncUIActionHandler nillable)handler
{
    auto interaction = [[self alloc] init];
    interaction.activationAction = [AsyncUIAction withHandler: handler];
    interaction.cursorStyle = AsyncUICursorStylePointer;
    return interaction;
}

+ (instancetype)withAsyncActivation: (AsyncUIAsyncActionHandler nillable)handler
{
    return [self withAsyncActivation: handler named: nilptr];
}

+ (instancetype)withAsyncActivation: (AsyncUIAsyncActionHandler nillable)handler
                              named: (OFString *nillable)name
{
    auto interaction = [[self alloc] init];
    interaction.activationAction = [AsyncUIAction withName: name asyncHandler: handler];
    interaction.cursorStyle = AsyncUICursorStylePointer;
    return interaction;
}

@end

#pragma clang assume_nonnull end
