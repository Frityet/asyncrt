#import <TestSupport/TestSupport.h>

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

- (void)runAsyncBlock: (void (^)(void))block
{
    auto task = [AsyncRuntime run: ^id {
        block();
        return AsyncUnit.unit;
    }];

    [AsyncRuntime runUntilTaskCompletes: task];

    if (task.status == AsyncTaskStatus_REJECTED)
        @throw task.failureException;
}

- (void)tearDown
{
    [AsyncRuntime shutdown];
    [super tearDown];
}

@end

#pragma clang assume_nonnull end
