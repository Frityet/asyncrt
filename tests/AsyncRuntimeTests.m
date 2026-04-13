#import "TestSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface OTAssertionFailedException : OFException @end
[[subclassing_restricted]]
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

    if (task.status == PromiseStatus_REJECTED)
        @throw task.rejectionException;
}

- (void)tearDown
{
    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
    [super tearDown];
}

@end

#pragma clang assume_nonnull end
