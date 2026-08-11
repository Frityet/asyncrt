#import <AsyncRT/Core/AsyncExecutor.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

@interface AsyncExecutorTests : OTTestCase
@end

@implementation AsyncExecutorTests

- (void)testCurrentExecutorIsStableAndDrainsQueuedWork
{
    AsyncExecutor *executor = AsyncExecutor.current;
    __block bool didRun = false;

    OTAssertEqual(executor, AsyncExecutor.current,
        @"current executor must remain stable for the owning thread");

    [executor enqueue: ^{
        didRun = true;
    }];
    [executor runUntil: ^{
        return didRun;
    } timeout: 1.0];

    OTAssertTrue(didRun, @"the current executor must drain queued work");

    /* Leave a drain pending so LeakSanitizer exercises process-exit cleanup. */
    [executor enqueue: ^{}];
}

- (void)testWorkerTerminationCancelsPendingDrain
{
    __block __weak AsyncExecutor *weakExecutor = nilptr;
    __block bool executorWasStable = false;
    OFThread *thread = [OFThread threadWithBlock: ^id nillable {
        AsyncExecutor *executor = AsyncExecutor.current;
        weakExecutor = executor;
        executorWasStable = (executor == AsyncExecutor.current);

        /* Return before the worker run loop can fire the drain timer. */
        [executor enqueue: ^{}];
        return nilptr;
    }];

    [thread start];
    [thread join];

    OTAssertTrue(executorWasStable,
        @"worker threads must have one stable current executor");
    OTAssertNil(weakExecutor,
        @"thread teardown must release an executor with a pending drain");

    /* Keep the main-thread process-exit path covered regardless of test order. */
    [AsyncExecutor.current enqueue: ^{}];
}

@end

#pragma clang assume_nonnull end
