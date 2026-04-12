#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@implementation AsyncRuntime

+ (Task<id> *)run: (id (^)(AsyncScope *scope))block
{
    return [self runOnScheduler: AsyncScheduler.defaultScheduler block: block];
}

+ (Task<id> *)runOnScheduler: (AsyncScheduler *)scheduler block: (id (^)(AsyncScope *scope))block
{
    AsyncEnsureObjFWBindingsLoaded();

    block_reference Task *rootTask = nilptr;
    block_reference AsyncScope *rootScope = nilptr;

    rootTask = [[Task alloc] initWithScheduler: scheduler scope: nilptr name: @"root" block: ^{
        if (rootScope == nilptr) {
            rootScope = [[AsyncScope alloc] initWithScheduler: scheduler ownerTask: rootTask parentScope: nilptr name: @"root" deadline: nilptr];
            [rootTask _setScope: rootScope];
        }

        return [rootScope _runScopeBody: block];
    }];

    return rootTask;
}

@end

#pragma clang assume_nonnull end
