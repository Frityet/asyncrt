#import <AsyncRT/Application/UI/Surface/Immediate/Action.h>

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

- (void)invoke
{
    if (self.handler != nilptr)
        self.handler();

    if (self.asyncHandler != nilptr) {
        auto action = self;

        (void)[AsyncRuntime spawnNamed: self.name block: ^{
            AsyncUIAsyncActionHandler asyncHandler = action.asyncHandler;

            if (asyncHandler == nilptr)
                return (id)AsyncUnit.unit;

            id nillable result = asyncHandler();
            return (result != nilptr ? $assert_nonnil(result) : (id)AsyncUnit.unit);
        }];
    }
}

@end

#pragma clang assume_nonnull end
