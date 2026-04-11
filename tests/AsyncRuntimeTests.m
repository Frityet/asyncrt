#import "TestSupport.h"

#pragma clang assume_nonnull begin

@interface OTAssertionFailedException : OFException @end
@interface OTTestSkippedException : OFException @end

@implementation AsyncRuntimeTestCase

+ (void)initialize
{
    if (self != AsyncRuntimeTestCase.class)
        return;

    (void)OTAssertionFailedException.class;
    (void)OTTestSkippedException.class;
}

- (void)runAsyncBlock: (void (^)(AsyncScope *rootScope))block
{
    auto scheduler = AsyncScheduler.defaultScheduler;
    auto task = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncScope *rootScope) {
        block(rootScope);
        return AsyncUnit.unit;
    }];

    while (not task.isResolved) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }

    if (task.status == FutureStatus_REJECTED)
        @throw task.rejectionException;
}

- (void)tearDown
{
    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
    [super tearDown];
}

@end

#pragma clang assume_nonnull end
