#import <TestSupport/TestSupport.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeTaskTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeTaskTests

- (void)test_task_await_and_current_context
{
    [self runAsyncBlock: ^{
        AsyncTask *currentTask = $assert_nonnil([AsyncTask currentTask]);
        OFString *timerValue = [[AsyncRuntimeTestSupport timerResolvedStringAfter: 0.01
                                                                            value: @"timer"] await];
        OFString *immediateValue = [[AsyncTask resolved: @"immediate"] await];

        OTAssert((currentTask.scheduler == [AsyncScheduler sharedScheduler]), @"Runtime tasks should use the managed scheduler");
        OTAssert(([timerValue isEqual: @"timer"]), @"await should resume timer-backed tasks");
        OTAssert(([immediateValue isEqual: @"immediate"]), @"await should return already-fulfilled values inside runtime tasks");
    }];
}

- (void)test_task_rejection_and_nil_return_paths
{
    [self runAsyncBlock: ^{
        bool caughtTimerRejection = false;
        bool caughtImmediateRejection = false;
        bool caughtNilReturn = false;

        @try {
            (void)[[AsyncRuntimeTestSupport timerRejectedStringAfter: 0.01
                                                           exception: [[TestRejectionException alloc] init]] await];
        } @catch (TestRejectionException *) {
            caughtTimerRejection = true;
        }

        @try {
            (void)[[AsyncTask rejected: [[TestRejectionException alloc] init]] await];
        } @catch (TestRejectionException *) {
            caughtImmediateRejection = true;
        }

        auto nilTask = [AsyncRuntime spawnNamed: @"nil-return" block: ^id {
            return nilptr;
        }];

        @try {
            (void)[nilTask await];
        } @catch (AsyncTaskReturnedNilException *) {
            caughtNilReturn = true;
        }

        OTAssert(caughtTimerRejection, @"Timer rejections should rethrow the original exception");
        OTAssert(caughtImmediateRejection, @"Immediate rejections should rethrow the original exception");
        OTAssert(caughtNilReturn, @"Runtime tasks returning nilptr should reject");
        OTAssert((nilTask.status == AsyncTaskStatus_REJECTED), @"Nil-returning tasks should be marked rejected");
    }];
}

- (void)test_task_combinators
{
    [self runAsyncBlock: ^{
        block_reference bool ensureFulfilledCalled = false;
        block_reference bool ensureRejectedCalled = false;
        bool caughtEnsureRejection = false;
        bool caughtMapThrow = false;
        bool caughtNilRecover = false;

        OFString *mapped = [[[AsyncTask resolved: @"alpha"] map: ^id(OFString *value) {
            return [value stringByAppendingString: @"-mapped"];
        }] await];

        OFString *flatMapped = [[[AsyncTask resolved: @"beta"] flatMap: ^AsyncTask *(OFString *value) {
            return [AsyncRuntimeTestSupport timerResolvedStringAfter: 0.01
                                                               value: value.uppercaseString];
        }] await];

        OFString *recovered = [[[AsyncTask rejected: [[TestRejectionException alloc] init]] recover: ^id(OFException *exception) {
            OTAssert(([exception isKindOfClass: TestRejectionException.class]), @"recover should receive the original exception");
            return @"recovered";
        }] await];

        OFString *flatRecovered = [[[AsyncTask rejected: [[TestRejectionException alloc] init]] flatRecover: ^AsyncTask *(OFException *exception) {
            OTAssert(([exception isKindOfClass: TestRejectionException.class]), @"flatRecover should receive the original exception");
            return [AsyncRuntimeTestSupport timerResolvedStringAfter: 0.01
                                                               value: @"flat-recovered"];
        }] await];

        OFString *ensured = [[[AsyncTask resolved: @"kept"] ensure: ^{
            ensureFulfilledCalled = true;
        }] await];

        @try {
            (void)[[[AsyncTask rejected: [[TestRejectionException alloc] init]] ensure: ^{
                ensureRejectedCalled = true;
            }] await];
        } @catch (TestRejectionException *) {
            caughtEnsureRejection = true;
        }

        @try {
            (void)[[[AsyncTask resolved: @"throw"] map: ^id(OFString *value) {
                (void)value;
                @throw [[TestRejectionException alloc] init];
            }] await];
        } @catch (TestRejectionException *) {
            caughtMapThrow = true;
        }

        @try {
            (void)[[[AsyncTask rejected: [[TestRejectionException alloc] init]] recover: ^id(OFException *exception) {
                (void)exception;
                return nilptr;
            }] await];
        } @catch (AsyncTaskNilResolutionValueException *) {
            caughtNilRecover = true;
        }

        OTAssert(([mapped isEqual: @"alpha-mapped"]), @"map should transform values");
        OTAssert(([flatMapped isEqual: @"BETA"]), @"flatMap should flatten task values");
        OTAssert(([recovered isEqual: @"recovered"]), @"recover should turn failures into values");
        OTAssert(([flatRecovered isEqual: @"flat-recovered"]), @"flatRecover should flatten recovery tasks");
        OTAssert(([ensured isEqual: @"kept"]), @"ensure should preserve fulfilled values");
        OTAssert(ensureFulfilledCalled, @"ensure should run for fulfilled values");
        OTAssert(ensureRejectedCalled, @"ensure should run for rejected values");
        OTAssert(caughtEnsureRejection, @"ensure should preserve original rejections");
        OTAssert(caughtMapThrow, @"map should reject when transforms throw");
        OTAssert(caughtNilRecover, @"recover should reject nilptr recovery values");
    }];
}

- (void)test_task_all_and_race
{
    [self runAsyncBlock: ^{
        OFArray<id> *allResult = [[AsyncTask all: [OFArray arrayWithObjects:
            [AsyncRuntime spawnNamed: @"all-first" block: ^id {
                [[AsyncRuntime sleepForTimeInterval: 0.02] await];
                return @"first";
            }],
            [AsyncTask resolved: @"second"],
            [AsyncRuntime spawnNamed: @"all-third" block: ^id {
                [[AsyncRuntime sleepForTimeInterval: 0.01] await];
                return @"third";
            }],
            nil]] await];
        OFString *raceWinner = [[AsyncTask race: [OFArray arrayWithObjects:
            [AsyncRuntimeTestSupport timerResolvedStringAfter: 0.03 value: @"slow"],
            [AsyncRuntimeTestSupport timerResolvedStringAfter: 0.01 value: @"fast"],
            nil]] await];
        bool caughtAllFailure = false;
        bool caughtEmptyRace = false;

        @try {
            (void)[[AsyncTask all: [OFArray arrayWithObjects:
                [AsyncTask resolved: @"ok"],
                [AsyncTask rejected: [[TestRejectionException alloc] init]],
                nil]] await];
        } @catch (TestRejectionException *) {
            caughtAllFailure = true;
        }

        @try {
            (void)[AsyncTask race: [OFArray array]];
        } @catch (OFInvalidArgumentException *) {
            caughtEmptyRace = true;
        }

        OTAssert((allResult.count == 3), @"all should keep every result");
        OTAssert(([[allResult objectAtIndex: 0] isEqual: @"first"]), @"all should preserve input order");
        OTAssert(([[allResult objectAtIndex: 1] isEqual: @"second"]), @"all should include immediate values");
        OTAssert(([[allResult objectAtIndex: 2] isEqual: @"third"]), @"all should preserve delayed task order");
        OTAssert(([raceWinner isEqual: @"fast"]), @"race should resolve to the first settled task");
        OTAssert(caughtAllFailure, @"all should reject when an input rejects");
        OTAssert(caughtEmptyRace, @"race should reject empty inputs");
    }];
}

- (void)test_task_cancellation_checkpoint
{
    [self runAsyncBlock: ^{
        block_reference bool observedCancellation = false;
        auto task = [AsyncRuntime spawnNamed: @"checkpoint" block: ^id {
            while (true) {
                @try {
                    [AsyncTask checkCancellation];
                    [[AsyncRuntime sleepForTimeInterval: 0.01] await];
                } @catch (AsyncTaskCancelledException *exception) {
                    observedCancellation = (exception.task == [AsyncTask currentTask]);
                    return AsyncUnit.unit;
                }
            }
        }];

        [[AsyncRuntime sleepForTimeInterval: 0.02] await];
        [task cancel];
        (void)[task await];

        OTAssert(observedCancellation, @"Task cancellation should be delivered at explicit checkpoints");
    }];
}

- (void)test_self_await_rejected
{
    [self runAsyncBlock: ^{
        block_reference AsyncTask *nillable selfAwaitTask = nilptr;

        selfAwaitTask = [AsyncRuntime spawnNamed: @"self-await" block: ^id {
            @try {
                (void)[$assert_nonnil(selfAwaitTask) await];
            } @catch (AsyncTaskSelfAwaitException *exception) {
                OTAssert((exception.task == selfAwaitTask), @"Self-await should report the current task");
                return AsyncUnit.unit;
            }

            OTAssert(false, @"Self-await should throw");
            return AsyncUnit.unit;
        }];

        (void)[selfAwaitTask await];
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeScopeTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeScopeTests

- (void)test_spawned_tasks_share_the_managed_scheduler
{
    [self runAsyncBlock: ^{
        auto task = [AsyncRuntime spawnNamed: @"child" block: ^id {
            OTAssert(([AsyncTask currentTask].scheduler == [AsyncScheduler sharedScheduler]),
                     @"Nested tasks should use the managed scheduler");
            return @"child";
        }];

        OTAssert((task.scheduler == [AsyncScheduler sharedScheduler]), @"Spawned tasks should expose the managed scheduler");
        OTAssert(([[task await] isEqual: @"child"]), @"Spawned tasks should resolve normally");
    }];
}

- (void)test_manual_composition_replaces_structured_scope_waiting
{
    [self runAsyncBlock: ^{
        auto events = [OFMutableArray<OFString *> array];
        auto first = [AsyncRuntime spawnNamed: @"composition-first" block: ^id {
            [[AsyncRuntime sleepForTimeInterval: 0.02] await];
            [events addObject: @"first"];
            return @"first";
        }];
        auto second = [AsyncRuntime spawnNamed: @"composition-second" block: ^id {
            [[AsyncRuntime sleepForTimeInterval: 0.01] await];
            [events addObject: @"second"];
            return @"second";
        }];

        OFArray<id> *values = [[AsyncTask all: [OFArray arrayWithObjects: first, second, nil]] await];

        OTAssert((values.count == 2), @"Manual task composition should wait for all children");
        OTAssert((events.count == 2), @"Both composed tasks should run");
        OTAssert(([[events objectAtIndex: 0] isEqual: @"second"]), @"Independent tasks should complete by readiness");
        OTAssert(([[events objectAtIndex: 1] isEqual: @"first"]), @"Slower composed tasks should finish last");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeSchedulerTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeSchedulerTests

- (void)test_scheduler_snapshot_reports_runtime_tasks
{
    [self runAsyncBlock: ^{
        auto blocker = [[AsyncCompletionSource<OFString *> alloc] init];
        auto task = [AsyncRuntime spawnNamed: @"snapshot-target" block: ^id {
            return [blocker.task await];
        }];

        [[AsyncRuntime sleepForTimeInterval: 0.01] await];

        AsyncSchedulerSnapshot *snapshot = [AsyncRuntime snapshot];
        AsyncTaskSnapshot *taskSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"snapshot-target"
                                                                              inSnapshot: snapshot];

        OTAssert((taskSnapshot != nilptr), @"Snapshots should include active named tasks");
        OTAssert((taskSnapshot.executionState == AsyncTaskExecutionState_WAITING),
                 @"Waiting tasks should be reported as waiting");

        [blocker fulfill: @"released"];
        OTAssert(([[task await] isEqual: @"released"]), @"Snapshot target should resume after fulfillment");
    }];
}

- (void)test_offload_resumes_on_managed_scheduler
{
    [self runAsyncBlock: ^{
        OFThread *schedulerThread = $assert_nonnil(OFThread.currentThread);
        block_reference OFThread *nillable workerThread = nilptr;

        OFString *value = [[AsyncRuntime offload: ^id {
            workerThread = $assert_nonnil(OFThread.currentThread);
            return @"offloaded";
        }] await];

        OTAssert(([value isEqual: @"offloaded"]), @"Offloaded work should return values");
        OTAssert((workerThread != nilptr and workerThread != schedulerThread), @"Offloaded work should run away from the scheduler thread");
        OTAssert((OFThread.currentThread == schedulerThread), @"Offload await should resume on the scheduler thread");
    }];
}

- (void)test_sleep_until_date
{
    [self runAsyncBlock: ^{
        OFDate *targetDate = [OFDate dateWithTimeIntervalSinceNow: 0.01];
        (void)[[AsyncRuntime sleepUntilDate: targetDate] await];
        OTAssert(([targetDate compare: OFDate.date] != OFOrderedDescending), @"sleepUntilDate should wait until the date has arrived");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeChannelTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeChannelTests

- (void)test_rendezvous_channel_transfers_values
{
    [self runAsyncBlock: ^{
        auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
        auto producer = [AsyncRuntime spawnNamed: @"channel-producer" block: ^id {
            [channel send: @"payload"];
            return AsyncUnit.unit;
        }];

        OFString *value = [channel receive];
        (void)[producer await];

        OTAssert(([value isEqual: @"payload"]), @"Rendezvous channels should transfer values");
    }];
}

- (void)test_buffered_channel_preserves_order_and_close_state
{
    [self runAsyncBlock: ^{
        auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 2];
        bool caughtClosedSend = false;
        bool caughtClosedReceive = false;

        [channel send: @"one"];
        [channel send: @"two"];
        [channel close];

        OTAssert(([[channel receive] isEqual: @"one"]), @"Buffered channels should preserve FIFO order");
        OTAssert(([[channel receive] isEqual: @"two"]), @"Buffered channels should drain buffered values after close");

        @try {
            [channel send: @"three"];
        } @catch (AsyncChannelClosedException *) {
            caughtClosedSend = true;
        }

        @try {
            (void)[channel receive];
        } @catch (AsyncChannelClosedException *) {
            caughtClosedReceive = true;
        }

        OTAssert(channel.isClosed, @"Closed channels should expose close state");
        OTAssert(caughtClosedSend, @"Closed channels should reject sends");
        OTAssert(caughtClosedReceive, @"Closed and drained channels should reject receives");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeHTTPTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeHTTPTests

- (void)test_http_client_uses_managed_runtime_scheduler
{
    LocalHTTPTestServer *server = [[LocalHTTPTestServer alloc] init];
    [server start];

    @try {
        [self runAsyncBlock: ^{
            auto client = [AsyncHTTPClient client];
            auto request = [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/hello"]];
            OFHTTPResponse *response = [[client performRequest: request] await];

            OTAssert((response.statusCode == 200), @"HTTP client should return local test responses");
            OTAssert(([response.readString isEqual: @"hello"]), @"HTTP client should expose response bodies");
            OTAssert(([AsyncTask currentTask].scheduler == [AsyncScheduler sharedScheduler]),
                     @"HTTP awaits should stay on the managed scheduler");
        }];
    } @finally {
        [server stop];
    }
}

- (void)test_http_helper_redirect_signature
{
    LocalHTTPTestServer *server = [[LocalHTTPTestServer alloc] init];
    [server start];

    @try {
        [self runAsyncBlock: ^{
            auto client = [AsyncHTTPClient client];
            auto request = [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/root"]];
            OFHTTPResponse *response = [[AsyncRuntimeTestSupport taskToPerformHTTPRequest: request
                                                                           withHTTPClient: client] await];

            OTAssert((response.statusCode == 200), @"Test HTTP helper should use the new client API");
            OTAssert(([response.readString isEqual: @"root"]), @"Test HTTP helper should return response bodies");
        }];
    } @finally {
        [server stop];
    }
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeStressTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeStressTests

- (void)test_many_small_tasks_resolve_on_single_scheduler
{
    [self runAsyncBlock: ^{
        auto tasks = [OFMutableArray<AsyncTask *> array];

        for (size_t index = 0; index < 64; index++) {
            OFString *name = [OFString stringWithFormat: @"stress-%zu", index];
            [tasks addObject: [AsyncRuntime spawnNamed: name block: ^id {
                [[AsyncRuntime sleepForTimeInterval: (OFTimeInterval)(index % 4) * 0.001] await];
                return [OFNumber numberWithUnsignedLongLong: (unsigned long long)index];
            }]];
        }

        OFArray<id> *results = [[AsyncTask all: tasks] await];
        AsyncSchedulerSnapshot *snapshot = [AsyncRuntime snapshot];

        OTAssert((results.count == 64), @"Stress task composition should collect every result");
        OTAssert((snapshot.completedTaskCount >= 64), @"Scheduler snapshots should account for completed tasks");
    }];
}

@end

#pragma clang assume_nonnull end
