#import <TestSupport/TestSupport.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeCoverageExtrasTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeCoverageExtrasTests

- (void)test_task_exception_descriptions_include_current_context
{
    [self runAsyncBlock: ^{
        auto task = [AsyncRuntime spawnNamed: @"description-target" block: ^id {
            [[AsyncRuntime sleepForTimeInterval: 0.01] await];
            return AsyncUnit.unit;
        }];
        auto returnedNil = [[AsyncTaskReturnedNilException alloc] initWithTask: task];
        auto cancelled = [[AsyncTaskCancelledException alloc] initWithTask: task];

        OTAssert(([returnedNil.description containsString: @"returned nilptr"]), @"Returned-nil exceptions should describe the failure");
        OTAssert(([returnedNil.description containsString: @"description-target"]), @"Returned-nil descriptions should include task context");
        OTAssert(([cancelled.description containsString: @"cancellation checkpoint"]), @"Cancellation exceptions should describe checkpoint delivery");

        (void)[task await];
    }];
}

- (void)test_completion_source_cancellation_handler_runs_once
{
    [self runAsyncBlock: ^{
        auto completionSource = [[AsyncCompletionSource<OFString *> alloc] init];
        block_reference size_t cancellationCount = 0;

        [completionSource setPendingTaskCancellationHandler: ^{
            cancellationCount++;
        }];

        auto waiter = [AsyncRuntime spawnNamed: @"coverage-cancel-waiter" block: ^id {
            @try {
                return [completionSource.task await];
            } @catch (AsyncTaskCancelledException *) {
                return AsyncUnit.unit;
            }
        }];

        [[AsyncRuntime sleepForTimeInterval: 0.01] await];
        [waiter cancel];
        (void)[waiter await];

        OTAssert((cancellationCount == 1), @"Cancellation handlers should run once for pending tasks");
        OTAssert(waiter.isCancellationRequested, @"Waiting task cancellation should be observable");
    }];
}

- (void)test_scheduler_snapshot_counts_and_descriptions
{
    [self runAsyncBlock: ^{
        auto blocker = [[AsyncCompletionSource<OFString *> alloc] init];
        auto task = [AsyncRuntime spawnNamed: @"coverage-snapshot" block: ^id {
            return [blocker.task await];
        }];

        [[AsyncRuntime sleepForTimeInterval: 0.01] await];

        AsyncSchedulerSnapshot *snapshot = [AsyncRuntime snapshot];
        AsyncTaskSnapshot *taskSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"coverage-snapshot"
                                                                              inSnapshot: snapshot];

        OTAssert((snapshot.tasks.count > 0), @"Snapshots should expose active tasks");
        OTAssert((taskSnapshot != nilptr), @"Snapshots should find named active tasks");
        OTAssert((taskSnapshot.taskID == task.taskID), @"Task snapshots should expose task IDs");
        OTAssert((taskSnapshot.isCancellationRequested == false), @"Task snapshots should expose cancellation state");
        OTAssert(([[AsyncScheduler sharedScheduler].description containsString: [AsyncScheduler sharedScheduler].mode]),
                 @"Scheduler descriptions should include the run-loop mode");

        [blocker fulfill: @"done"];
        OTAssert(([[task await] isEqual: @"done"]), @"Snapshot task should finish after release");
    }];
}

- (void)test_runtime_shutdown_clears_managed_scheduler_state
{
    AsyncScheduler *firstScheduler = [AsyncScheduler sharedScheduler];
    auto task = [AsyncRuntime run: ^id {
        return AsyncUnit.unit;
    }];

    [AsyncRuntime runUntilTaskCompletes: task];
    [AsyncRuntime shutdown];

    AsyncScheduler *secondScheduler = [AsyncScheduler sharedScheduler];

    OTAssert((firstScheduler != secondScheduler), @"Runtime shutdown should clear the managed scheduler instance");

    [AsyncRuntime shutdown];
}

@end

#pragma clang assume_nonnull end
