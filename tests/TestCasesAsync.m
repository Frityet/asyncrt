#import "TestSupport.h"

#pragma clang assume_nonnull begin

static void task_await_and_awaitable(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFString *fulfilledValue;
    OFString *immediateValue;
    id<Awaitable> awaitableTask;

    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask != nilptr) message: (@"Task.currentTask should be set inside AsyncRuntime.run")];
    [AsyncRuntimeTestSupport assertCondition: (AsyncTaskGroup.currentTaskGroup == rootScope) message: (@"AsyncTaskGroup.currentTaskGroup should point at the root scope inside AsyncRuntime.run")];
    [AsyncRuntimeTestSupport assertCondition: ([Task conformsToProtocol: @protocol(Awaitable)]) message: (@"Task should conform to Awaitable")];

    fulfilledValue = [AsyncRuntimeTestSupport timerResolvedStringForScheduler: scheduler seconds: 0.01 value: @"timer-value"].await;
    immediateValue = [Task resolved: @"immediate-value"].await;
    awaitableTask = [Task resolved: @"awaitable-task"];

    [AsyncRuntimeTestSupport assertCondition: ([fulfilledValue isEqual: @"timer-value"]) message: (@"await should return the fulfilled timer value")];
    [AsyncRuntimeTestSupport assertCondition: ([immediateValue isEqual: @"immediate-value"]) message: (@"await on an already fulfilled task should return immediately")];
    [AsyncRuntimeTestSupport assertCondition: ([[(id)awaitableTask await] isEqual: @"awaitable-task"]) message: (@"Awaitable.await should use the runtime task await implementation")];
}

static void task_rejection_paths(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    bool caughtRejectedAwait = false;
    bool caughtImmediateRejection = false;

    @try {
        [[AsyncRuntimeTestSupport timerRejectedStringForScheduler: scheduler seconds: 0.01 exception: [[TestRejectionException alloc] init]] await];
    } @catch (TestRejectionException *) {
        caughtRejectedAwait = true;
    }

    @try {
        [[Task rejected: [[TestRejectionException alloc] init]] await];
    } @catch (TestRejectionException *) {
        caughtImmediateRejection = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtRejectedAwait) message: (@"await should rethrow the original timer rejection exception")];
    [AsyncRuntimeTestSupport assertCondition: (caughtImmediateRejection) message: (@"await on an already rejected task should rethrow immediately")];
}

static void task_metadata_and_resolution(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Task<AsyncUnit *> *unitTask = [rootScope spawnTask: ^{
        [[scheduler sleepForTimeInterval: 0.01] await];
        return AsyncUnit.unit;
    } name: @"unit-task"];

    [unitTask await];

    [AsyncRuntimeTestSupport assertCondition: (unitTask.scheduler == scheduler) message: (@"spawned tasks should inherit the current scheduler")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.taskGroup == rootScope) message: (@"spawned tasks should belong to the current task group")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.taskID > 0) message: (@"spawned tasks should receive a stable task ID")];
    [AsyncRuntimeTestSupport assertCondition: ([unitTask.name isEqual: @"unit-task"]) message: (@"spawned tasks should preserve their name")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.status == AsyncTaskStatus_FULFILLED) message: (@"Task<AsyncUnit *> should fulfill successfully")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.executionState == AsyncTaskExecutionState_RESOLVED) message: (@"awaited tasks should end in the resolved execution state")];
}

static void task_returned_nil_exception(AsyncTaskGroup *rootScope)
{
    block_reference Task *nillable task = nilptr;
    TaskReturnedNilException *nillable primary_exception = nilptr;
    bool caughtScopeFailure = false;

    @try {
        (void)[rootScope performInChildTaskGroupNamed: @"nil-return-scope" block: ^id(AsyncTaskGroup *scope) {
            task = [scope spawnTask: ^{
                return nilptr;
            } name: @"nil-return"];
            return AsyncUnit.unit;
        }];
    } @catch (TaskReturnedNilException *exception) {
        primary_exception = exception;
        caughtScopeFailure = (primary_exception != nilptr and primary_exception.task == task);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtScopeFailure) message: (@"a scope containing a task that returns nilptr should fail with TaskReturnedNilException")];
    [AsyncRuntimeTestSupport assertCondition: ([task.failureException isKindOfClass: TaskReturnedNilException.class]) message: (@"tasks returning nilptr should reject with TaskReturnedNilException")];
    [AsyncRuntimeTestSupport assertCondition: (task.failureException == primary_exception) message: (@"the scope primary exception should match the task rejection exception")];
    [AsyncRuntimeTestSupport assertCondition: (task.status == AsyncTaskStatus_REJECTED) message: (@"tasks returning nilptr should be rejected")];
    [AsyncRuntimeTestSupport assertCondition: (task.executionState == AsyncTaskExecutionState_RESOLVED) message: (@"tasks returning nilptr should still finish with a resolved execution state")];
}

static void task_combinators(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    block_reference bool ensureCalledOnFulfilled = false;
    block_reference bool ensureCalledOnRejected = false;
    bool caughtRejectedEnsure = false;
    bool caughtMapThrow = false;
    bool caughtRecoverThrow = false;
    bool caughtNilMap = false;
    bool caughtNilRecover = false;
    OFString *mappedValue;
    OFString *flatMappedValue;
    OFString *recoveredValue;
    OFString *flatRecoveredValue;
    OFString *ensuredValue;

    mappedValue = [[Task resolved: @"alpha"] map: ^id(OFString *value) {
        return [value stringByAppendingString: @"-mapped"];
    }].await;
    flatMappedValue = [[AsyncRuntimeTestSupport timerResolvedStringForScheduler: scheduler seconds: 0.01 value: @"beta"] flatMap: ^Task<OFString *> *(OFString *value) {
        return [Task resolved: [value uppercaseString]];
    }].await;
    recoveredValue = [[Task rejected: [[TestRejectionException alloc] init]] recover: ^id(OFException *exception) {
        [AsyncRuntimeTestSupport assertCondition: ([exception isKindOfClass: TestRejectionException.class]) message: (@"recover should receive the original rejection")];
        return @"recovered";
    }].await;
    flatRecoveredValue = [[AsyncRuntimeTestSupport timerRejectedStringForScheduler: scheduler seconds: 0.01 exception: [[TestRejectionException alloc] init]] flatRecover: ^Task<OFString *> *(OFException *exception) {
        [AsyncRuntimeTestSupport assertCondition: ([exception isKindOfClass: TestRejectionException.class]) message: (@"flatRecover should receive the original rejection")];
        return [Task resolved: @"flat-recovered"];
    }].await;
    ensuredValue = [[AsyncRuntimeTestSupport timerResolvedStringForScheduler: scheduler seconds: 0.01 value: @"ensured"] ensure: ^{
        ensureCalledOnFulfilled = true;
    }].await;

    @try {
        (void)[[AsyncRuntimeTestSupport timerRejectedStringForScheduler: scheduler seconds: 0.01 exception: [[TestRejectionException alloc] init]] ensure: ^{
            ensureCalledOnRejected = true;
        }].await;
    } @catch (TestRejectionException *) {
        caughtRejectedEnsure = true;
    }

    @try {
        (void)[[Task resolved: @"throw"] map: ^id(OFString *value) {
            (void)value;
            @throw [[TestRejectionException alloc] init];
        }].await;
    } @catch (TestRejectionException *) {
        caughtMapThrow = true;
    }

    @try {
        (void)[[Task rejected: [[TestRejectionException alloc] init]] recover: ^id(OFException *exception) {
            (void)exception;
            @throw [[TestRejectionException alloc] init];
        }].await;
    } @catch (TestRejectionException *) {
        caughtRecoverThrow = true;
    }

    @try {
        (void)[[Task resolved: @"nil-map"] map: ^id(OFString *value) {
            (void)value;
            return nilptr;
        }].await;
    } @catch (AsyncTaskNilResolutionValueException *) {
        caughtNilMap = true;
    }

    @try {
        (void)[[Task rejected: [[TestRejectionException alloc] init]] recover: ^id(OFException *exception) {
            (void)exception;
            return nilptr;
        }].await;
    } @catch (AsyncTaskNilResolutionValueException *) {
        caughtNilRecover = true;
    }

    [AsyncRuntimeTestSupport assertCondition: ([mappedValue isEqual: @"alpha-mapped"]) message: (@"map should transform fulfilled tasks")];
    [AsyncRuntimeTestSupport assertCondition: ([flatMappedValue isEqual: @"BETA"]) message: (@"flatMap should flatten pending task chains")];
    [AsyncRuntimeTestSupport assertCondition: ([recoveredValue isEqual: @"recovered"]) message: (@"recover should turn rejections into fulfilled values")];
    [AsyncRuntimeTestSupport assertCondition: ([flatRecoveredValue isEqual: @"flat-recovered"]) message: (@"flatRecover should flatten recovery tasks")];
    [AsyncRuntimeTestSupport assertCondition: ([ensuredValue isEqual: @"ensured"]) message: (@"ensure should preserve fulfilled values")];
    [AsyncRuntimeTestSupport assertCondition: (ensureCalledOnFulfilled) message: (@"ensure should run for fulfilled tasks")];
    [AsyncRuntimeTestSupport assertCondition: (ensureCalledOnRejected) message: (@"ensure should run for rejected tasks")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRejectedEnsure) message: (@"ensure should preserve the original rejection when the ensure block succeeds")];
    [AsyncRuntimeTestSupport assertCondition: (caughtMapThrow) message: (@"map should reject when its transform throws")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRecoverThrow) message: (@"recover should reject when its handler throws")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilMap) message: (@"map should reject with AsyncTaskNilResolutionValueException when its transform returns nilptr")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilRecover) message: (@"recover should reject with AsyncTaskNilResolutionValueException when its handler returns nilptr")];
}

static void task_continuation_scheduler_capture(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    auto crossThreadResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto thread = [[CrossThreadResolverThread alloc] initWithResolver: crossThreadResolver value: @"thread-value" delay: 0.01];
    block_reference OFThread *continuationThread = nilptr;
    OFString *transformedValue;

    [thread start];
    transformedValue = [crossThreadResolver.task map: ^id(OFString *value) {
        continuationThread = $assert_nonnil(OFThread.currentThread);
        return [value stringByAppendingString: @"-mapped"];
    }].await;

    [AsyncRuntimeTestSupport assertCondition: ([transformedValue isEqual: @"thread-value-mapped"]) message: (@"default task combinators should resolve the transformed value")];
    [AsyncRuntimeTestSupport assertCondition: (continuationThread == expectedThread) message: (@"default task combinators should resume on the current task scheduler thread")];
    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask.scheduler == scheduler) message: (@"awaiting the transformed task should preserve the current task scheduler")];
    (void)[thread join];
}

static void task_collection_helpers(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Task<OFArray<id> *> *emptyAll = [Task all: @[]];
    bool caughtEmptyRace = false;
    bool caughtAllFailure = false;
    bool caughtRaceRejection = false;
    block_reference bool allSiblingCancelled = false;
    block_reference bool raceResolvedSiblingCancelled = false;
    block_reference bool raceRejectedSiblingCancelled = false;
    OFArray<id> *singleAllResult;
    OFArray<id> *orderedAllResult;
    OFString *singleRaceWinner;
    OFString *resolvedRaceWinner;

    [AsyncRuntimeTestSupport assertCondition: (emptyAll.isCompleted) message: (@"Task.all should resolve immediately for empty input")];
    [AsyncRuntimeTestSupport assertCondition: (emptyAll.value.count == 0) message: (@"Task.all should fulfill empty input with an empty array")];

    singleAllResult = [Task all: @[[Task resolved: @"only"]]].await;
    [AsyncRuntimeTestSupport assertCondition: (singleAllResult.count == 1) message: (@"Task.all should preserve single-element input")];
    [AsyncRuntimeTestSupport assertCondition: ([[singleAllResult objectAtIndex: 0] isEqual: @"only"]) message: (@"Task.all should preserve single-element values")];

    orderedAllResult = [Task all: @[
        [rootScope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.03] await];
            return @"first";
        } name: @"task-all-first"],
        [Task resolved: @"second"],
        [rootScope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            return @"third";
        } name: @"task-all-third"]
    ]].await;

    [AsyncRuntimeTestSupport assertCondition: (orderedAllResult.count == 3) message: (@"Task.all should return every result")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedAllResult objectAtIndex: 0] isEqual: @"first"]) message: (@"Task.all should preserve input order for the first result")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedAllResult objectAtIndex: 1] isEqual: @"second"]) message: (@"Task.all should preserve input order for mixed Task inputs")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedAllResult objectAtIndex: 2] isEqual: @"third"]) message: (@"Task.all should preserve input order for the last result")];

    Task *allSlowSibling = [rootScope spawnTask: ^{
        @try {
            while (true)
                [[scheduler sleepForTimeInterval: 0.05] await];
        } @catch (TaskCancelledException *) {
            allSiblingCancelled = true;
            return AsyncUnit.unit;
        }
    } name: @"task-all-cancelled-sibling"];

    @try {
        [[Task all: @[allSlowSibling, [Task rejected: [[TestRejectionException alloc] init]]]] await];
    } @catch (TestRejectionException *) {
        caughtAllFailure = true;
    }

    [[scheduler sleepForTimeInterval: 0.05] await];

    @try {
        (void)[Task race: @[]];
    } @catch (OFInvalidArgumentException *) {
        caughtEmptyRace = true;
    }

    singleRaceWinner = [Task race: @[[Task resolved: @"winner"]]].await;

    resolvedRaceWinner = [Task race: @[
        [Task resolved: @"race-winner"],
        [rootScope spawnTask: ^{
            @try {
                while (true)
                    [[scheduler sleepForTimeInterval: 0.05] await];
            } @catch (TaskCancelledException *) {
                raceResolvedSiblingCancelled = true;
                return AsyncUnit.unit;
            }
        } name: @"task-race-resolved-sibling"]
    ]].await;

    [[scheduler sleepForTimeInterval: 0.05] await];

    @try {
        (void)[Task race: @[
            [Task rejected: [[TestRejectionException alloc] init]],
            [rootScope spawnTask: ^{
                @try {
                    while (true)
                        [[scheduler sleepForTimeInterval: 0.05] await];
                } @catch (TaskCancelledException *) {
                    raceRejectedSiblingCancelled = true;
                    return AsyncUnit.unit;
                }
            } name: @"task-race-rejected-sibling"]
        ]].await;
    } @catch (TestRejectionException *) {
        caughtRaceRejection = true;
    }

    [[scheduler sleepForTimeInterval: 0.05] await];

    [AsyncRuntimeTestSupport assertCondition: (caughtAllFailure) message: (@"Task.all should reject on the first failure")];
    [AsyncRuntimeTestSupport assertCondition: (allSiblingCancelled) message: (@"Task.all should cancel unresolved sibling tasks after a failure")];
    [AsyncRuntimeTestSupport assertCondition: (caughtEmptyRace) message: (@"Task.race should reject empty input")];
    [AsyncRuntimeTestSupport assertCondition: ([singleRaceWinner isEqual: @"winner"]) message: (@"Task.race should preserve single-element input")];
    [AsyncRuntimeTestSupport assertCondition: ([resolvedRaceWinner isEqual: @"race-winner"]) message: (@"Task.race should resolve with the first settled fulfillment")];
    [AsyncRuntimeTestSupport assertCondition: (raceResolvedSiblingCancelled) message: (@"Task.race should cancel unresolved sibling tasks after a fulfilled winner")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRaceRejection) message: (@"Task.race should reject with the first settled rejection")];
    [AsyncRuntimeTestSupport assertCondition: (raceRejectedSiblingCancelled) message: (@"Task.race should cancel unresolved sibling tasks after a rejected winner")];
}

static void cross_thread_task_resolution(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    auto crossThreadResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto thread = [[CrossThreadResolverThread alloc] initWithResolver: crossThreadResolver value: @"thread-value" delay: 0.01];
    OFString *crossThreadValue;

    [thread start];
    crossThreadValue = crossThreadResolver.task.await;

    [AsyncRuntimeTestSupport assertCondition: ([crossThreadValue isEqual: @"thread-value"]) message: (@"cross-thread resolution should deliver the resolved value")];
    [AsyncRuntimeTestSupport assertCondition: (OFThread.currentThread == expectedThread) message: (@"await continuations should resume on the scheduler run-loop thread")];
    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask.scheduler == scheduler) message: (@"cross-thread awaits should preserve the current task scheduler")];
    (void)[thread join];
}

static void self_await_rejected(AsyncTaskGroup *rootScope)
{
    block_reference Task *selfAwaitTask = nilptr;

    selfAwaitTask = [rootScope spawnTask: ^{
        @try {
            [selfAwaitTask await];
        } @catch (AsyncTaskSelfAwaitException *exception) {
            [AsyncRuntimeTestSupport assertCondition: (exception.task == selfAwaitTask) message: (@"self-await should throw AsyncTaskSelfAwaitException for the task itself")];
            return AsyncUnit.unit;
        }

        @throw [[TestFailureException alloc] initWithMessage: @"self-await did not throw AsyncTaskSelfAwaitException"];
    } name: @"self-await"];

    [selfAwaitTask await];
}

static void scope_waits_for_children(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto scopeEvents = [OFMutableArray<OFString *> array];

    (void)[rootScope performInChildTaskGroupNamed: @"nested-scope" block: ^id(AsyncTaskGroup *scope) {
        [scopeEvents addObject: @"body-enter"];
        [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [scopeEvents addObject: @"child-finished"];
            return AsyncUnit.unit;
        } name: @"nested-child"];
        [scopeEvents addObject: @"body-exit"];
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (scopeEvents.count == 3) message: (@"nested scopes should wait for all children before returning")];
    [AsyncRuntimeTestSupport assertCondition: ([scopeEvents[0] isEqual: @"body-enter"]) message: (@"nested scope event ordering should preserve the body start")];
    [AsyncRuntimeTestSupport assertCondition: ([scopeEvents[1] isEqual: @"body-exit"]) message: (@"nested scope event ordering should preserve the body end before child completion")];
    [AsyncRuntimeTestSupport assertCondition: ([scopeEvents[2] isEqual: @"child-finished"]) message: (@"nested scope should return only after the child task finishes")];
}

static void scope_failure_cancels_siblings(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto failureEvents = [OFMutableArray<OFString *> array];
    bool caughtAggregate = false;

    @try {
        (void)[rootScope performInChildTaskGroupNamed: @"aggregate-scope" block: ^id(AsyncTaskGroup *scope) {
            [scope spawnTask: ^{
                [[scheduler sleepForTimeInterval: 0.01] await];
                [failureEvents addObject: @"failing-child"];
                @throw [[TestRejectionException alloc] init];
                return AsyncUnit.unit;
            } name: @"failing-child"];

            [scope spawnTask: ^{
                @try {
                    while (true)
                        [[scheduler sleepForTimeInterval: 0.05] await];
                } @catch (TaskCancelledException *) {
                    [failureEvents addObject: @"cleanup-child"];
                    return AsyncUnit.unit;
                }
            } name: @"cleanup-child"];

            [[scheduler sleepForTimeInterval: 0.25] await];
            return AsyncUnit.unit;
        }];
    } @catch (TestRejectionException *) {
        caughtAggregate = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtAggregate) message: (@"a child failure should surface as TestRejectionException")];
    [AsyncRuntimeTestSupport assertCondition: (failureEvents.count == 2) message: (@"structured failure should still give siblings a chance to clean up")];
    [AsyncRuntimeTestSupport assertCondition: ([failureEvents[0] isEqual: @"failing-child"]) message: (@"the failing child should run before sibling cancellation cleanup")];
    [AsyncRuntimeTestSupport assertCondition: ([failureEvents[1] isEqual: @"cleanup-child"]) message: (@"sibling cleanup should happen before the scope reports failure")];
}

static void task_cancellation_checkpoint(AsyncTaskGroup *rootScope)
{
    block_reference atomic_t(bool) cancelIssued = false;
    block_reference TaskCancellationThread *cancellationThread = nilptr;
    block_reference bool reachedCheckpoint = false;

    (void)[rootScope performInChildTaskGroupNamed: @"checkpoint-scope" block: ^id(AsyncTaskGroup *scope) {
        Task *checkpointTask = [scope spawnTask: ^{
            while (not atomic_load_explicit(&cancelIssued, memory_order_acquire)) {
                
            }

            reachedCheckpoint = true;

            @try {
                [Task checkCancellation];
            } @catch (TaskCancelledException *exception) {
                [AsyncRuntimeTestSupport assertCondition: (exception.task == Task.currentTask) message: (@"Task.checkCancellation should report the current task")];
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"task cancellation should only be observed at an explicit checkpoint"];
        } name: @"checkpoint-child"];

        cancellationThread = [[TaskCancellationThread alloc] initWithTask: checkpointTask delay: 0.01 cancelIssuedFlag: &cancelIssued];
        [cancellationThread start];
        return AsyncUnit.unit;
    }];

    (void)[cancellationThread join];
    [AsyncRuntimeTestSupport assertCondition: (reachedCheckpoint) message: (@"the cancelled task should continue running until it reaches a cancellation checkpoint")];
}

static void timeout_cancels_children(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    block_reference bool timedOutChildCancelled = false;
    bool caughtTimeout = false;

    @try {
        (void)[rootScope performWithTimeout: 0.02 block: ^id(AsyncTaskGroup *scope) {
            [scope spawnTask: ^{
                @try {
                    while (true)
                        [[scheduler sleepForTimeInterval: 0.05] await];
                } @catch (TaskCancelledException *) {
                    timedOutChildCancelled = true;
                    return AsyncUnit.unit;
                }
            } name: @"timeout-child"];

            [[scheduler sleepForTimeInterval: 0.25] await];
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTaskGroupTimeoutException *exception) {
        caughtTimeout = (exception.taskGroup != nilptr and exception.deadline != nilptr);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"performWithTimeout should throw AsyncTaskGroupTimeoutException when the deadline expires")];
    [AsyncRuntimeTestSupport assertCondition: (timedOutChildCancelled) message: (@"timeout should cancel descendant tasks before the scope unwinds")];
}

static void scope_spawn_all(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFArray<id> *emptyResult = [rootScope spawnAllTasks: @[]].await;
    OFArray<id> *orderedResult;
    bool caughtSpawnAllFailure = false;
    bool caughtSpawnAllTimeout = false;
    block_reference bool cancelledSibling = false;
    block_reference bool timedOutChildCancelled = false;
    auto orderedBlocks = [OFMutableArray<id (^)(void)> array];
    auto failingBlocks = [OFMutableArray<id (^)(void)> array];

    [orderedBlocks addObject: ^{
        [[scheduler sleepForTimeInterval: 0.03] await];
        return @"first";
    }];
    [orderedBlocks addObject: ^{
        return @"second";
    }];
    [orderedBlocks addObject: ^{
        [[scheduler sleepForTimeInterval: 0.01] await];
        return @"third";
    }];

    orderedResult = [rootScope spawnAllTasks: orderedBlocks name: @"ordered-group"].await;

    [failingBlocks addObject: ^{
        [[scheduler sleepForTimeInterval: 0.01] await];
        @throw [[TestRejectionException alloc] init];
        return AsyncUnit.unit;
    }];
    [failingBlocks addObject: ^{
        @try {
            while (true)
                [[scheduler sleepForTimeInterval: 0.05] await];
        } @catch (TaskCancelledException *) {
            cancelledSibling = true;
            return AsyncUnit.unit;
        }
    }];

    @try {
        (void)[rootScope performInChildTaskGroupNamed: @"spawn-all-failure-scope" block: ^id(AsyncTaskGroup *scope) {
            [[scope spawnAllTasks: failingBlocks name: @"failing-group"] await];
            return AsyncUnit.unit;
        }];
    } @catch (TestRejectionException *) {
        caughtSpawnAllFailure = true;
    }

    @try {
        (void)[rootScope performWithTimeout: 0.02 block: ^id(AsyncTaskGroup *scope) {
            auto timeoutBlocks = [OFMutableArray<id (^)(void)> array];

            [timeoutBlocks addObject: ^{
                @try {
                    while (true)
                        [[scheduler sleepForTimeInterval: 0.05] await];
                } @catch (TaskCancelledException *) {
                    timedOutChildCancelled = true;
                    return AsyncUnit.unit;
                }
            }];

            [[scope spawnAllTasks: timeoutBlocks name: @"timed-group"] await];
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTaskGroupTimeoutException *) {
        caughtSpawnAllTimeout = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (emptyResult.count == 0) message: (@"spawnAll should resolve empty input with an empty array")];
    [AsyncRuntimeTestSupport assertCondition: (orderedResult.count == 3) message: (@"spawnAll should return every child result")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedResult objectAtIndex: 0] isEqual: @"first"]) message: (@"spawnAll should preserve the first child result ordering")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedResult objectAtIndex: 1] isEqual: @"second"]) message: (@"spawnAll should preserve the second child result ordering")];
    [AsyncRuntimeTestSupport assertCondition: ([[orderedResult objectAtIndex: 2] isEqual: @"third"]) message: (@"spawnAll should preserve the third child result ordering")];
    [AsyncRuntimeTestSupport assertCondition: (caughtSpawnAllFailure) message: (@"spawnAll should reject when one child fails")];
    [AsyncRuntimeTestSupport assertCondition: (cancelledSibling) message: (@"spawnAll should cancel unresolved sibling tasks after a child failure")];
    [AsyncRuntimeTestSupport assertCondition: (caughtSpawnAllTimeout) message: (@"spawnAll should cooperate with scope timeouts")];
    [AsyncRuntimeTestSupport assertCondition: (timedOutChildCancelled) message: (@"spawnAll child tasks should be cancelled before a timeout unwinds the scope")];
}

static void past_deadline_fails_immediately(AsyncTaskGroup *rootScope)
{
    bool caughtImmediateDeadline = false;

    @try {
        auto pastDeadline = [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01];

        (void)[rootScope performWithDeadline: pastDeadline block: ^id(AsyncTaskGroup *) {
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTaskGroupTimeoutException *) {
        caughtImmediateDeadline = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtImmediateDeadline) message: (@"performWithDeadline should fail immediately for a past deadline")];
}

static void parent_scope_cancellation_propagates(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    block_reference bool grandchildCancelled = false;

    (void)[rootScope performInChildTaskGroupNamed: @"parent-cancel-scope" block: ^id(AsyncTaskGroup *outerScope) {
        [outerScope spawnTask: ^{
            (void)[outerScope performInChildTaskGroupNamed: @"inner-scope" block: ^id(AsyncTaskGroup *innerScope) {
                [innerScope spawnTask: ^{
                    @try {
                        while (true)
                            [[scheduler sleepForTimeInterval: 0.05] await];
                    } @catch (TaskCancelledException *) {
                        grandchildCancelled = true;
                        return AsyncUnit.unit;
                    }
                } name: @"grandchild"];

                [[scheduler sleepForTimeInterval: 1] await];
                return AsyncUnit.unit;
            }];

            return AsyncUnit.unit;
        } name: @"nested-owner"];

        [outerScope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [outerScope cancel];
            return AsyncUnit.unit;
        } name: @"scope-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (grandchildCancelled) message: (@"scope cancellation should propagate from a parent scope down to descendants")];
}

static void scheduler_offload_roundtrip(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    OFThread *workerThread = [scheduler offload: ^{
        return $assert_nonnil(OFThread.currentThread);
    }].await;

    [AsyncRuntimeTestSupport assertCondition: (workerThread != expectedThread) message: (@"offloaded work should run on a worker thread")];
    [AsyncRuntimeTestSupport assertCondition: (OFThread.currentThread == expectedThread) message: (@"awaiting offloaded work should resume on the original scheduler thread")];
}

static void scheduler_snapshot_waiting_task(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    (void)[rootScope performInChildTaskGroupNamed: @"snapshot-scope" block: ^id(AsyncTaskGroup *scope) {
        Task *snapshotTask = [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.05] await];
            return AsyncUnit.unit;
        } name: @"snapshot-child"];

        [[scheduler sleepForTimeInterval: 0.01] await];

        AsyncSchedulerSnapshot *snapshot = scheduler.snapshot;
        auto taskSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"snapshot-child" inSnapshot: snapshot];

        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot != nilptr) message: (@"scheduler.snapshot should include active tasks")];
        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot.taskID == snapshotTask.taskID) message: (@"scheduler.snapshot should preserve task IDs")];
        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot.executionState == AsyncTaskExecutionState_WAITING) message: (@"scheduler.snapshot should report waiting execution state")];
        [AsyncRuntimeTestSupport assertCondition: ([taskSnapshot.waitReason isEqual: @"await task"]) message: (@"scheduler.snapshot should report why a task is waiting")];
        [AsyncRuntimeTestSupport assertCondition: ([taskSnapshot.taskGroupName isEqual: @"snapshot-scope"]) message: (@"scheduler.snapshot should expose the current task group name")];
        [AsyncRuntimeTestSupport assertCondition: (not taskSnapshot.isCancellationRequested) message: (@"scheduler.snapshot should reflect cancellation state")];
        [AsyncRuntimeTestSupport assertCondition: (snapshot.tasks.count > 0) message: (@"scheduler.snapshot should expose active task entries")];

        [snapshotTask await];
        return AsyncUnit.unit;
    }];
}

static void scheduler_shutdown_rejects_offload(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *parentScheduler = rootScope.scheduler;
    auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: parentScheduler.runLoop mode: parentScheduler.mode maxWorkerCount: 1 maxDrainBatchSize: 1];
    OFThread *workerThread = [scheduler offload: ^{
        return $assert_nonnil(OFThread.currentThread);
    }].await;
    bool caughtShutdownOffload = false;

    [AsyncRuntimeTestSupport assertCondition: (workerThread != OFThread.currentThread) message: (@"dedicated schedulers should execute offloaded work on worker threads")];

    [scheduler shutdown];
    [scheduler shutdown];

    @try {
        (void)[scheduler offload: ^{
            return AsyncUnit.unit;
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtShutdownOffload = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtShutdownOffload) message: (@"shutdown schedulers should reject further offload requests")];
}

static void scheduler_cancellation_counter(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    uint64_t cancelledTaskCountBefore = scheduler.snapshot.cancelledTaskCount;
    block_reference Task *cancelledTask = nilptr;
    bool caughtTimeout = false;

    @try {
        (void)[rootScope performWithTimeout: 0.02 block: ^id(AsyncTaskGroup *scope) {
            cancelledTask = [scope spawnTask: ^{
                while (true)
                    [[scheduler sleepForTimeInterval: 0.05] await];
                return AsyncUnit.unit;
            } name: @"cancelled-counter-child"];

            [[scheduler sleepForTimeInterval: 0.25] await];
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTaskGroupTimeoutException *) {
        caughtTimeout = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"the cancellation counter scenario should still time out")];
    [AsyncRuntimeTestSupport assertCondition: (cancelledTask != nilptr) message: (@"the cancellation counter scenario should create a child task")];
    [AsyncRuntimeTestSupport assertCondition: (cancelledTask.status == AsyncTaskStatus_REJECTED) message: (@"timeout-cancelled tasks should reject")];
    [AsyncRuntimeTestSupport assertCondition: ([cancelledTask.failureException isKindOfClass: TaskCancelledException.class]) message: (@"timeout-cancelled tasks should reject with TaskCancelledException")];
    [AsyncRuntimeTestSupport assertCondition: (scheduler.snapshot.cancelledTaskCount > cancelledTaskCountBefore) message: (@"scheduler.snapshot.cancelledTaskCount should advance when a task is cancelled")];
}

static void scheduler_offload_failure_paths(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    bool caughtNilOffload = false;
    bool caughtThrownOffload = false;

    @try {
        (void)[scheduler offload: ^{
            return nilptr;
        }].await;
    } @catch (OFInvalidArgumentException *) {
        caughtNilOffload = true;
    }

    @try {
        (void)[scheduler offload: ^{
            @throw [[TestRejectionException alloc] init];
            return AsyncUnit.unit;
        }].await;
    } @catch (TestRejectionException *) {
        caughtThrownOffload = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilOffload) message: (@"offloaded blocks returning nilptr should reject with OFInvalidArgumentException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtThrownOffload) message: (@"offloaded blocks should propagate their original exception")];
}

static void scheduler_sleep_shortcuts(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Task<AsyncUnit *> *zeroSleep = [scheduler sleepForTimeInterval: 0];
    Task<AsyncUnit *> *pastSleep = [scheduler sleepUntilDate: [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01]];

    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.isCompleted) message: (@"zero-length sleeps should complete immediately")];
    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.status == AsyncTaskStatus_FULFILLED) message: (@"zero-length sleeps should fulfill immediately")];
    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.await == AsyncUnit.unit) message: (@"zero-length sleeps should resolve to AsyncUnit.unit")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.isCompleted) message: (@"sleepUntilDate with a past deadline should complete immediately")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.status == AsyncTaskStatus_FULFILLED) message: (@"sleepUntilDate with a past deadline should fulfill immediately")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.await == AsyncUnit.unit) message: (@"sleepUntilDate with a past deadline should resolve to AsyncUnit.unit")];
}

static void channel_rendezvous(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
    block_reference OFString *receivedValue = nilptr;

    (void)[rootScope performInChildTaskGroupNamed: @"rendezvous-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            receivedValue = channel.receive;
            return AsyncUnit.unit;
        } name: @"rendezvous-receiver"];

        [[scheduler sleepForTimeInterval: 0.01] await];
        [channel send: @"ping"];
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: ([receivedValue isEqual: @"ping"]) message: (@"an unbuffered channel should rendezvous between sender and receiver")];
}

static void channel_buffer_backpressure_and_snapshot(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 1];
    auto bufferedEvents = [OFMutableArray<OFString *> array];
    block_reference OFString *firstBufferedValue = nilptr;
    block_reference OFString *secondBufferedValue = nilptr;

    (void)[rootScope performInChildTaskGroupNamed: @"buffered-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            [bufferedEvents addObject: @"before-first-send"];
            [channel send: @"one"];
            [bufferedEvents addObject: @"after-first-send"];
            [bufferedEvents addObject: @"before-second-send"];
            [channel send: @"two"];
            [bufferedEvents addObject: @"after-second-send"];
            return AsyncUnit.unit;
        } name: @"buffered-sender"];

        [[scheduler sleepForTimeInterval: 0.01] await];

        auto senderSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"buffered-sender" inSnapshot: scheduler.snapshot];
        [AsyncRuntimeTestSupport assertCondition: (senderSnapshot != nilptr) message: (@"buffered sender should appear in scheduler snapshots while blocked")];
        [AsyncRuntimeTestSupport assertCondition: (senderSnapshot.executionState == AsyncTaskExecutionState_WAITING) message: (@"buffered sender should block when the channel is full")];
        [AsyncRuntimeTestSupport assertCondition: ([senderSnapshot.waitReason isEqual: @"channel send"]) message: (@"buffered sender should report channel send as the wait reason")];

        firstBufferedValue = channel.receive;
        [[scheduler sleepForTimeInterval: 0.01] await];
        secondBufferedValue = channel.receive;
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: ([firstBufferedValue isEqual: @"one"]) message: (@"bounded channels should preserve the first buffered value")];
    [AsyncRuntimeTestSupport assertCondition: ([secondBufferedValue isEqual: @"two"]) message: (@"bounded channels should eventually deliver values blocked by backpressure")];
    [AsyncRuntimeTestSupport assertCondition: (bufferedEvents.count == 4) message: (@"bounded channel sender should resume after capacity becomes available")];
    [AsyncRuntimeTestSupport assertCondition: ([bufferedEvents[3] isEqual: @"after-second-send"]) message: (@"the second send should only complete after a receive frees space")];
}

static void channel_close_semantics(AsyncTaskGroup *)
{
    auto closedChannel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 1];
    bool caughtClosedSend = false;
    bool caughtClosedReceive = false;

    [closedChannel send: @"buffered-before-close"];
    [closedChannel close];

    [AsyncRuntimeTestSupport assertCondition: (closedChannel.isClosed) message: (@"close should mark the channel as closed")];
    [AsyncRuntimeTestSupport assertCondition: ([closedChannel.receive isEqual: @"buffered-before-close"]) message: (@"closing a channel should still allow buffered values to be drained")];

    @try {
        [closedChannel send: @"nope"];
    } @catch (AsyncChannelClosedException *exception) {
        caughtClosedSend = [exception.operation isEqual: @"send"];
    }

    @try {
        (void)closedChannel.receive;
    } @catch (AsyncChannelClosedException *exception) {
        caughtClosedReceive = [exception.operation isEqual: @"receive"];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtClosedSend) message: (@"sending on a closed channel should throw AsyncChannelClosedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtClosedReceive) message: (@"receiving from an exhausted closed channel should throw AsyncChannelClosedException")];
}

static void channel_close_unblocks_waiters(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto receiverChannel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
    auto senderChannel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
    block_reference bool blockedReceiverClosed = false;
    block_reference bool blockedSenderClosed = false;

    (void)[rootScope performInChildTaskGroupNamed: @"close-receiver-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            @try {
                (void)receiverChannel.receive;
            } @catch (AsyncChannelClosedException *exception) {
                blockedReceiverClosed = [exception.operation isEqual: @"receive"];
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked receiver should observe channel close"];
        } name: @"blocked-receiver"];

        [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [receiverChannel close];
            return AsyncUnit.unit;
        } name: @"receiver-closer"];

        return AsyncUnit.unit;
    }];

    (void)[rootScope performInChildTaskGroupNamed: @"close-sender-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            @try {
                [senderChannel send: @"value"];
            } @catch (AsyncChannelClosedException *exception) {
                blockedSenderClosed = [exception.operation isEqual: @"send"];
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked sender should observe channel close"];
        } name: @"blocked-sender"];

        [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [senderChannel close];
            return AsyncUnit.unit;
        } name: @"sender-closer"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedReceiverClosed) message: (@"closing a channel should wake blocked receivers with AsyncChannelClosedException")];
    [AsyncRuntimeTestSupport assertCondition: (blockedSenderClosed) message: (@"closing a channel should wake blocked senders with AsyncChannelClosedException")];
}

static void channel_send_cancellation(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
    block_reference bool blockedSendCancelled = false;

    (void)[rootScope performInChildTaskGroupNamed: @"send-cancel-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            @try {
                [channel send: @"blocked-send"];
            } @catch (TaskCancelledException *) {
                blockedSendCancelled = true;
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked send should observe cancellation"];
        } name: @"blocked-sender"];

        [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [scope cancel];
            return AsyncUnit.unit;
        } name: @"send-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedSendCancelled) message: (@"blocked sends should be cancellation checkpoints")];
}

static void channel_receive_cancellation(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 0];
    block_reference bool blockedReceiveCancelled = false;

    (void)[rootScope performInChildTaskGroupNamed: @"receive-cancel-scope" block: ^id(AsyncTaskGroup *scope) {
        [scope spawnTask: ^{
            @try {
                (void)channel.receive;
            } @catch (TaskCancelledException *) {
                blockedReceiveCancelled = true;
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked receive should observe cancellation"];
        } name: @"blocked-receiver"];

        [scope spawnTask: ^{
            [[scheduler sleepForTimeInterval: 0.01] await];
            [scope cancel];
            return AsyncUnit.unit;
        } name: @"receive-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedReceiveCancelled) message: (@"blocked receives should be cancellation checkpoints")];
}

static void channel_multi_producer_consumer(AsyncTaskGroup *rootScope)
{
    auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 2];
    auto receivedValues = [OFMutableSet<OFString *> set];
    size_t const itemsPerProducer = 10;

    (void)[rootScope performInChildTaskGroupNamed: @"multi-producer-consumer-scope" block: ^id(AsyncTaskGroup *scope) {
        for (size_t producerIndex = 0; producerIndex < 2; producerIndex++) {
            OFString *producerName = [OFString stringWithFormat: @"producer-%zu", producerIndex];

            [scope spawnTask: ^{
                for (size_t itemIndex = 0; itemIndex < itemsPerProducer; itemIndex++) {
                    OFString *value = [OFString stringWithFormat: @"p%zu-%zu", producerIndex, itemIndex];
                    [channel send: value];
                }

                return AsyncUnit.unit;
            } name: producerName];
        }

        for (size_t consumerIndex = 0; consumerIndex < 2; consumerIndex++) {
            OFString *consumerName = [OFString stringWithFormat: @"consumer-%zu", consumerIndex];

            [scope spawnTask: ^{
                for (size_t itemIndex = 0; itemIndex < itemsPerProducer; itemIndex++)
                    [receivedValues addObject: channel.receive];

                return AsyncUnit.unit;
            } name: consumerName];
        }

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (receivedValues.count == itemsPerProducer * 2) message: (@"multi-producer/multi-consumer channels should deliver every produced value exactly once")];

    for (size_t producerIndex = 0; producerIndex < 2; producerIndex++) {
        for (size_t itemIndex = 0; itemIndex < itemsPerProducer; itemIndex++) {
            OFString *expectedValue = [OFString stringWithFormat: @"p%zu-%zu", producerIndex, itemIndex];
            [AsyncRuntimeTestSupport assertCondition: ([receivedValues containsObject: expectedValue]) message: ([OFString stringWithFormat: @"missing channel value %@", expectedValue])];
        }
    }
}

static void http_concurrent_requests(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto server = [[LocalHTTPTestServer alloc] init];
    auto client = [[OFHTTPClient alloc] init];
    Task<OFHTTPResponse *> *alphaTask;
    Task<OFHTTPResponse *> *betaTask;
    OFHTTPResponse *alphaResponse;
    OFHTTPResponse *betaResponse;

    [AsyncRuntimeTestSupport assertCondition: (OFTLSStreamImplementation != Nil) message: (@"Async runtime should force ObjFWTLS to load so https support is available")];

    [server start];

    @try {
        alphaTask = [AsyncRuntimeTestSupport taskToPerformHTTPRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/alpha"]]
                                                       withHTTPClient: client
                                                          onScheduler: scheduler];
        betaTask = [AsyncRuntimeTestSupport taskToPerformHTTPRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/beta"]]
                                                      withHTTPClient: client
                                                           redirects: 0
                                                         onScheduler: scheduler];

        alphaResponse = alphaTask.await;
        betaResponse = betaTask.await;

        [AsyncRuntimeTestSupport assertCondition: ([alphaResponse.readString isEqual: @"alpha"]) message: (@"HTTP request bridge should resolve the first concurrent request correctly")];
        [AsyncRuntimeTestSupport assertCondition: ([betaResponse.readString isEqual: @"beta"]) message: (@"HTTP request bridge should resolve the second concurrent request correctly")];
    } @finally {
        [server stop];
    }
}

static void http_timeout_cancellation_and_reuse(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto server = [[LocalHTTPTestServer alloc] init];
    auto client = [[OFHTTPClient alloc] init];
    OFHTTPResponse *gammaResponse;
    bool caughtTimeout = false;

    [server start];

    @try {
        @try {
            (void)[rootScope performWithTimeout: 0.02 block: ^id(AsyncTaskGroup *) {
                [[AsyncRuntimeTestSupport taskToPerformHTTPRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/slow-cancel"]]
                                                    withHTTPClient: client
                                                       onScheduler: scheduler] await];
                return AsyncUnit.unit;
            }];
        } @catch (AsyncTaskGroupTimeoutException *) {
            caughtTimeout = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"cancelling a task waiting on HTTP should unwind via timeout")];
        gammaResponse = [AsyncRuntimeTestSupport taskToPerformHTTPRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/gamma"]]
                                                            withHTTPClient: client
                                                                 redirects: 0
                                                               onScheduler: scheduler
                                                  cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: ([gammaResponse.readString isEqual: @"gamma"]) message: (@"HTTP request bridge should remain usable after cancelling an in-flight request")];
    } @finally {
        [server stop];
    }
}

static void stress_timeout_repetitions(AsyncTaskGroup *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    for (size_t iteration = 0; iteration < 25; iteration++) {
        block_reference bool childCancelled = false;
        bool caughtTimeout = false;

        @try {
            (void)[rootScope performWithTimeout: 0.003 block: ^id(AsyncTaskGroup *scope) {
                [scope spawnTask: ^{
                    @try {
                        [[scheduler sleepForTimeInterval: 0.10] await];
                    } @catch (TaskCancelledException *) {
                        childCancelled = true;
                        return AsyncUnit.unit;
                    }

                    return AsyncUnit.unit;
                } name: [OFString stringWithFormat: @"stress-timeout-child-%zu", iteration]];

                [[scheduler sleepForTimeInterval: 0.10] await];
                return AsyncUnit.unit;
            }];
        } @catch (AsyncTaskGroupTimeoutException *) {
            caughtTimeout = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: ([OFString stringWithFormat: @"stress timeout iteration %zu should time out", iteration])];
        [AsyncRuntimeTestSupport assertCondition: (childCancelled) message: ([OFString stringWithFormat: @"stress timeout iteration %zu should cancel its child task", iteration])];
    }
}

static void stress_channel_repetitions(AsyncTaskGroup *rootScope)
{
    for (size_t iteration = 0; iteration < 20; iteration++) {
        auto channel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 1];
        auto values = [OFMutableArray<OFString *> array];

        (void)[rootScope performInChildTaskGroupNamed: [OFString stringWithFormat: @"stress-channel-%zu", iteration] block: ^id(AsyncTaskGroup *scope) {
            [scope spawnTask: ^{
                for (size_t itemIndex = 0; itemIndex < 8; itemIndex++)
                    [channel send: [OFString stringWithFormat: @"%zu-%zu", iteration, itemIndex]];

                return AsyncUnit.unit;
            } name: @"stress-producer"];

            [scope spawnTask: ^{
                for (size_t itemIndex = 0; itemIndex < 8; itemIndex++)
                    [values addObject: channel.receive];

                return AsyncUnit.unit;
            } name: @"stress-consumer"];

            return AsyncUnit.unit;
        }];

        [AsyncRuntimeTestSupport assertCondition: (values.count == 8) message: ([OFString stringWithFormat: @"stress channel iteration %zu should receive every value", iteration])];
    }
}

ASYNC_RUNTIME_ASYNC_TEST(task_await_and_awaitable)
ASYNC_RUNTIME_ASYNC_TEST(task_rejection_paths)
ASYNC_RUNTIME_ASYNC_TEST(task_combinators)
ASYNC_RUNTIME_ASYNC_TEST(task_continuation_scheduler_capture)
ASYNC_RUNTIME_ASYNC_TEST(task_collection_helpers)
ASYNC_RUNTIME_ASYNC_TEST(task_metadata_and_resolution)
ASYNC_RUNTIME_ASYNC_TEST(task_returned_nil_exception)
ASYNC_RUNTIME_ASYNC_TEST(cross_thread_task_resolution)
ASYNC_RUNTIME_ASYNC_TEST(self_await_rejected)
ASYNC_RUNTIME_ASYNC_TEST(scope_waits_for_children)
ASYNC_RUNTIME_ASYNC_TEST(scope_failure_cancels_siblings)
ASYNC_RUNTIME_ASYNC_TEST(scope_spawn_all)
ASYNC_RUNTIME_ASYNC_TEST(task_cancellation_checkpoint)
ASYNC_RUNTIME_ASYNC_TEST(timeout_cancels_children)
ASYNC_RUNTIME_ASYNC_TEST(past_deadline_fails_immediately)
ASYNC_RUNTIME_ASYNC_TEST(parent_scope_cancellation_propagates)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_offload_roundtrip)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_snapshot_waiting_task)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_shutdown_rejects_offload)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_cancellation_counter)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_offload_failure_paths)
ASYNC_RUNTIME_ASYNC_TEST(scheduler_sleep_shortcuts)
ASYNC_RUNTIME_ASYNC_TEST(channel_rendezvous)
ASYNC_RUNTIME_ASYNC_TEST(channel_buffer_backpressure_and_snapshot)
ASYNC_RUNTIME_ASYNC_TEST(channel_close_semantics)
ASYNC_RUNTIME_ASYNC_TEST(channel_close_unblocks_waiters)
ASYNC_RUNTIME_ASYNC_TEST(channel_send_cancellation)
ASYNC_RUNTIME_ASYNC_TEST(channel_receive_cancellation)
ASYNC_RUNTIME_ASYNC_TEST(channel_multi_producer_consumer)
ASYNC_RUNTIME_ASYNC_TEST(http_concurrent_requests)
ASYNC_RUNTIME_ASYNC_TEST(http_timeout_cancellation_and_reuse)
ASYNC_RUNTIME_ASYNC_TEST(stress_timeout_repetitions)
ASYNC_RUNTIME_ASYNC_TEST(stress_channel_repetitions)

#pragma clang assume_nonnull end
