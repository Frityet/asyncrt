#import "TestSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface OTAssertionFailedException : OFException @end
[[subclassing_restricted]]
@interface OTTestSkippedException : OFException @end

@interface AsyncScheduler (AsyncRuntimeTests)
- (void)_drainReadyQueue;
@end

@implementation AsyncRuntimeTestCase

+ (void)initialize
{
    if (self != AsyncRuntimeTestCase.class)
        return;

    (void)OTAssertionFailedException.class;
    (void)OTTestSkippedException.class;
}

- (void)runAsyncBlock: (void (^)(AsyncTaskGroup *rootTaskGroup))block
{
    auto scheduler = AsyncScheduler.defaultScheduler;
    auto task = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *rootTaskGroup) {
        block(rootTaskGroup);
        return AsyncUnit.unit;
    }];

    while (not task.isCompleted) {
        [scheduler _drainReadyQueue];
        if (task.isCompleted)
            break;

        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }

    if (task.status == AsyncTaskStatus_REJECTED)
        @throw task.failureException;
}

- (void)tearDown
{
    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
    [super tearDown];
}

@end

#pragma clang assume_nonnull end
