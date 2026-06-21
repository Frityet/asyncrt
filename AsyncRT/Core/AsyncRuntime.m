#import <AsyncRT/Core/AsyncRuntimeInternal.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncRuntime

+ (AsyncScheduler *)_scheduler
{
    return AsyncScheduler.sharedScheduler;
}

+ (AsyncTask<id> *)run: (id (^)(void))block
{
    return [self spawnNamed: @"root" block: block];
}

+ (AsyncTask<id> *)spawn: (id (^)(void))block
{
    return [self spawnNamed: nilptr block: block];
}

+ (AsyncTask<id> *)spawnNamed: (OFString *nillable)name block: (id (^)(void))block
{
    auto scheduler = [self _scheduler];
    auto task = [[AsyncTask alloc] initWithScheduler: scheduler name: name block: block];
    return task;
}

+ (AsyncTask<AsyncUnit *> *)sleepForTimeInterval: (OFTimeInterval)timeInterval
{
    return [[self _scheduler] sleepForTimeInterval: timeInterval];
}

+ (AsyncTask<AsyncUnit *> *)sleepUntilDate: (OFDate *)date
{
    return [[self _scheduler] sleepUntilDate: date];
}

+ (AsyncTask<id> *)offload: (id (^)(void))block
{
    return [[self _scheduler] offload: block];
}

+ (void)runUntilTaskCompletes: (AsyncTask *)task
{
    [[self _scheduler] runUntilTaskCompletes: task];
}

+ (bool)runUntilTaskCompletes: (AsyncTask *)task timeout: (OFTimeInterval)timeout
{
    return [[self _scheduler] runUntilTaskCompletes: task timeout: timeout];
}

+ (void)runUntilIdle
{
    [[self _scheduler] runUntilIdle];
}

+ (AsyncSchedulerSnapshot *)snapshot
{
    return [[self _scheduler] snapshot];
}

+ (void)shutdown
{
    [AsyncScheduler shutdownSharedScheduler];
}

@end

#pragma clang assume_nonnull end
