#import "AUIAction.h"

#pragma clang assume_nonnull begin

@implementation AUIAction

+ (instancetype)withHandler: (AUIActionHandler nillable)handler
{
    auto action = [[self alloc] init];
    action.handler = handler;
    return action;
}

+ (instancetype)withName: (OFString *nillable)name
            asyncHandler: (AUIAsyncActionHandler nillable)handler
{
    auto action = [[self alloc] init];
    action.name = name;
    action.asyncHandler = handler;
    return action;
}

- (void)invokeWithTaskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    AsyncTaskGroup *effectiveTaskGroup = (taskGroup ?: AsyncTaskGroup.currentTaskGroup);

    if (self.handler != nilptr)
        self.handler();

    if (self.asyncHandler != nilptr and effectiveTaskGroup != nilptr) {
        AsyncTaskGroup *launchTaskGroup = $as_nonnil(effectiveTaskGroup);
        auto action = self;

        [launchTaskGroup spawnTask: ^{
            AUIAsyncActionHandler asyncHandler = action.asyncHandler;

            if (asyncHandler == nilptr)
                return (id)AsyncUnit.unit;

            return [launchTaskGroup performInChildTaskGroupNamed: action.name
                                                           block: asyncHandler];
        } name: self.name];
    }
}

@end

#pragma clang assume_nonnull end
