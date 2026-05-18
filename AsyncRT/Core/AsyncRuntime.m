#import <AsyncRT/Core/AsyncRuntimeInternal.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncRuntime

+ (AsyncTask<id> *)run: (id (^)(AsyncTaskGroup *taskGroup))block
{
    return [self runOnScheduler: AsyncScheduler.defaultScheduler block: block];
}

+ (AsyncTask<id> *)runOnScheduler: (AsyncScheduler *)scheduler block: (id (^)(AsyncTaskGroup *taskGroup))block
{
    block_reference AsyncTask *rootTask = nilptr;
    block_reference AsyncTaskGroup *rootTaskGroup = nilptr;

    rootTask = [[AsyncTask alloc] initWithScheduler: scheduler taskGroup: nilptr name: @"root" block: ^{
        if (rootTaskGroup == nilptr) {
            rootTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler ownerTask: rootTask parentTaskGroup: nilptr name: @"root" deadline: nilptr];
            [rootTask _setTaskGroup: rootTaskGroup];
        }

        return [rootTaskGroup _runTaskGroupBody: block];
    }];

    return rootTask;
}

@end

#pragma clang assume_nonnull end
