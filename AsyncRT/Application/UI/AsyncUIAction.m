#import <AsyncRT/Application/UI/AsyncUIAction.h>

#pragma clang assume_nonnull begin

@implementation AsyncUIAction

+ (instancetype)withHandler: (AsyncUIActionHandler nillable)handler
{
    auto action = [[self alloc] init];
    action.handler = handler;
    return action;
}

+ (instancetype)withName: (OFString *nillable)name
            asyncHandler: (AsyncUIAsyncActionHandler nillable)handler
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
        AsyncTaskGroup *nonnil launchTaskGroup =
            (AsyncTaskGroup *nonnil)effectiveTaskGroup;
        auto action = self;

        [launchTaskGroup spawnTask: ^{
            AsyncUIAsyncActionHandler asyncHandler = action.asyncHandler;

            if (asyncHandler == nilptr)
                return (id)AsyncUnit.unit;

            return [launchTaskGroup performInChildTaskGroupNamed: action.name
                                                           block: asyncHandler];
        } name: self.name];
    }
}

@end

#pragma clang assume_nonnull end
