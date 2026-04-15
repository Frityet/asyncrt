#import "TestSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
static void run_async_test_case(AsyncRuntimeTestCase *self,
                                SEL _cmd,
                                void (*test)(id, SEL, AsyncTaskGroup *))
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        test(self, _cmd, rootTaskGroup);
    }];
}

[[subclassing_restricted]]
@interface AsyncRuntimeTaskTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeTaskTests

- (void)test_task_await
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            OFString *fulfilledValue;
            OFString *immediateValue;
            Task<OFString *> *awaitableTask;

            OTAssert((Task.currentTask != nilptr), @"Task.currentTask should be set inside AsyncRuntime.run");
            OTAssert((AsyncTaskGroup.currentTaskGroup == rootScope), @"AsyncTaskGroup.currentTaskGroup should point at the root scope inside AsyncRuntime.run");

            fulfilledValue = [AsyncRuntimeTestSupport timerResolvedStringForScheduler: scheduler seconds: 0.01 value: @"timer-value"].await;
            immediateValue = [Task resolved: @"immediate-value"].await;
            awaitableTask = [Task resolved: @"awaitable-task"];

            OTAssert(([fulfilledValue isEqual: @"timer-value"]), @"await should return the fulfilled timer value");
            OTAssert(([immediateValue isEqual: @"immediate-value"]), @"await on an already fulfilled task should return immediately");
            OTAssert(([awaitableTask.await isEqual: @"awaitable-task"]), @"Task.await should use the runtime task await implementation");
    }];
}

- (void)test_task_rejection_paths
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtRejectedAwait), @"await should rethrow the original timer rejection exception");
            OTAssert((caughtImmediateRejection), @"await on an already rejected task should rethrow immediately");
    }];
}

- (void)test_task_combinators
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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
                OTAssert(([exception isKindOfClass: TestRejectionException.class]), @"recover should receive the original rejection");
                return @"recovered";
            }].await;
            flatRecoveredValue = [[AsyncRuntimeTestSupport timerRejectedStringForScheduler: scheduler seconds: 0.01 exception: [[TestRejectionException alloc] init]] flatRecover: ^Task<OFString *> *(OFException *exception) {
                OTAssert(([exception isKindOfClass: TestRejectionException.class]), @"flatRecover should receive the original rejection");
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

            OTAssert(([mappedValue isEqual: @"alpha-mapped"]), @"map should transform fulfilled tasks");
            OTAssert(([flatMappedValue isEqual: @"BETA"]), @"flatMap should flatten pending task chains");
            OTAssert(([recoveredValue isEqual: @"recovered"]), @"recover should turn rejections into fulfilled values");
            OTAssert(([flatRecoveredValue isEqual: @"flat-recovered"]), @"flatRecover should flatten recovery tasks");
            OTAssert(([ensuredValue isEqual: @"ensured"]), @"ensure should preserve fulfilled values");
            OTAssert((ensureCalledOnFulfilled), @"ensure should run for fulfilled tasks");
            OTAssert((ensureCalledOnRejected), @"ensure should run for rejected tasks");
            OTAssert((caughtRejectedEnsure), @"ensure should preserve the original rejection when the ensure block succeeds");
            OTAssert((caughtMapThrow), @"map should reject when its transform throws");
            OTAssert((caughtRecoverThrow), @"recover should reject when its handler throws");
            OTAssert((caughtNilMap), @"map should reject with AsyncTaskNilResolutionValueException when its transform returns nilptr");
            OTAssert((caughtNilRecover), @"recover should reject with AsyncTaskNilResolutionValueException when its handler returns nilptr");
    }];
}

- (void)test_task_continuation_scheduler_capture
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert(([transformedValue isEqual: @"thread-value-mapped"]), @"default task combinators should resolve the transformed value");
            OTAssert((continuationThread == expectedThread), @"default task combinators should resume on the current task scheduler thread");
            OTAssert((Task.currentTask.scheduler == scheduler), @"awaiting the transformed task should preserve the current task scheduler");
            (void)[thread join];
    }];
}

- (void)test_task_collection_helpers
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((emptyAll.isCompleted), @"Task.all should resolve immediately for empty input");
            OTAssert((emptyAll.value.count == 0), @"Task.all should fulfill empty input with an empty array");

            singleAllResult = [Task all: @[[Task resolved: @"only"]]].await;
            OTAssert((singleAllResult.count == 1), @"Task.all should preserve single-element input");
            OTAssert(([[singleAllResult objectAtIndex: 0] isEqual: @"only"]), @"Task.all should preserve single-element values");

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

            OTAssert((orderedAllResult.count == 3), @"Task.all should return every result");
            OTAssert(([[orderedAllResult objectAtIndex: 0] isEqual: @"first"]), @"Task.all should preserve input order for the first result");
            OTAssert(([[orderedAllResult objectAtIndex: 1] isEqual: @"second"]), @"Task.all should preserve input order for mixed Task inputs");
            OTAssert(([[orderedAllResult objectAtIndex: 2] isEqual: @"third"]), @"Task.all should preserve input order for the last result");

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

            OTAssert((caughtAllFailure), @"Task.all should reject on the first failure");
            OTAssert((allSiblingCancelled), @"Task.all should cancel unresolved sibling tasks after a failure");
            OTAssert((caughtEmptyRace), @"Task.race should reject empty input");
            OTAssert(([singleRaceWinner isEqual: @"winner"]), @"Task.race should preserve single-element input");
            OTAssert(([resolvedRaceWinner isEqual: @"race-winner"]), @"Task.race should resolve with the first settled fulfillment");
            OTAssert((raceResolvedSiblingCancelled), @"Task.race should cancel unresolved sibling tasks after a fulfilled winner");
            OTAssert((caughtRaceRejection), @"Task.race should reject with the first settled rejection");
            OTAssert((raceRejectedSiblingCancelled), @"Task.race should cancel unresolved sibling tasks after a rejected winner");
    }];
}

- (void)test_task_metadata_and_resolution
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            Task<AsyncUnit *> *unitTask = [rootScope spawnTask: ^{
                [[scheduler sleepForTimeInterval: 0.01] await];
                return AsyncUnit.unit;
            } name: @"unit-task"];

            [unitTask await];

            OTAssert((unitTask.scheduler == scheduler), @"spawned tasks should inherit the current scheduler");
            OTAssert((unitTask.taskGroup == rootScope), @"spawned tasks should belong to the current task group");
            OTAssert((unitTask.taskID > 0), @"spawned tasks should receive a stable task ID");
            OTAssert(([unitTask.name isEqual: @"unit-task"]), @"spawned tasks should preserve their name");
            OTAssert((unitTask.status == AsyncTaskStatus_FULFILLED), @"Task<AsyncUnit *> should fulfill successfully");
            OTAssert((unitTask.executionState == AsyncTaskExecutionState_RESOLVED), @"awaited tasks should end in the resolved execution state");
    }];
}

- (void)test_task_returned_nil_exception
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtScopeFailure), @"a scope containing a task that returns nilptr should fail with TaskReturnedNilException");
            OTAssert(([task.failureException isKindOfClass: TaskReturnedNilException.class]), @"tasks returning nilptr should reject with TaskReturnedNilException");
            OTAssert((task.failureException == primary_exception), @"the scope primary exception should match the task rejection exception");
            OTAssert((task.status == AsyncTaskStatus_REJECTED), @"tasks returning nilptr should be rejected");
            OTAssert((task.executionState == AsyncTaskExecutionState_RESOLVED), @"tasks returning nilptr should still finish with a resolved execution state");
    }];
}

- (void)test_cross_thread_task_resolution
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
            auto crossThreadResolver = [[AsyncCompletionSource<OFString *> alloc] init];
            auto thread = [[CrossThreadResolverThread alloc] initWithResolver: crossThreadResolver value: @"thread-value" delay: 0.01];
            OFString *crossThreadValue;

            [thread start];
            crossThreadValue = crossThreadResolver.task.await;

            OTAssert(([crossThreadValue isEqual: @"thread-value"]), @"cross-thread resolution should deliver the resolved value");
            OTAssert((OFThread.currentThread == expectedThread), @"await continuations should resume on the scheduler run-loop thread");
            OTAssert((Task.currentTask.scheduler == scheduler), @"cross-thread awaits should preserve the current task scheduler");
            (void)[thread join];
    }];
}

- (void)test_self_await_rejected
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            block_reference Task *selfAwaitTask = nilptr;

            selfAwaitTask = [rootScope spawnTask: ^{
                @try {
                    [selfAwaitTask await];
                } @catch (AsyncTaskSelfAwaitException *exception) {
                    OTAssert((exception.task == selfAwaitTask), @"self-await should throw AsyncTaskSelfAwaitException for the task itself");
                    return AsyncUnit.unit;
                }

                OTAssert(false, @"self-await did not throw AsyncTaskSelfAwaitException");
                return AsyncUnit.unit;
            } name: @"self-await"];

            [selfAwaitTask await];
    }];
}

- (void)test_task_cancellation_checkpoint
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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
                        OTAssert((exception.task == Task.currentTask), @"Task.checkCancellation should report the current task");
                        return AsyncUnit.unit;
                    }

                    OTAssert(false, @"task cancellation should only be observed at an explicit checkpoint");
                    return AsyncUnit.unit;
                } name: @"checkpoint-child"];

                cancellationThread = [[TaskCancellationThread alloc] initWithTask: checkpointTask delay: 0.01 cancelIssuedFlag: &cancelIssued];
                [cancellationThread start];
                return AsyncUnit.unit;
            }];

            (void)[cancellationThread join];
            OTAssert((reachedCheckpoint), @"the cancelled task should continue running until it reaches a cancellation checkpoint");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeScopeTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeScopeTests

- (void)test_scope_waits_for_children
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((scopeEvents.count == 3), @"nested scopes should wait for all children before returning");
            OTAssert(([scopeEvents[0] isEqual: @"body-enter"]), @"nested scope event ordering should preserve the body start");
            OTAssert(([scopeEvents[1] isEqual: @"body-exit"]), @"nested scope event ordering should preserve the body end before child completion");
            OTAssert(([scopeEvents[2] isEqual: @"child-finished"]), @"nested scope should return only after the child task finishes");
    }];
}

- (void)test_scope_failure_cancels_siblings
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtAggregate), @"a child failure should surface as TestRejectionException");
            OTAssert((failureEvents.count == 2), @"structured failure should still give siblings a chance to clean up");
            OTAssert(([failureEvents[0] isEqual: @"failing-child"]), @"the failing child should run before sibling cancellation cleanup");
            OTAssert(([failureEvents[1] isEqual: @"cleanup-child"]), @"sibling cleanup should happen before the scope reports failure");
    }];
}

- (void)test_scope_spawn_all
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((emptyResult.count == 0), @"spawnAll should resolve empty input with an empty array");
            OTAssert((orderedResult.count == 3), @"spawnAll should return every child result");
            OTAssert(([[orderedResult objectAtIndex: 0] isEqual: @"first"]), @"spawnAll should preserve the first child result ordering");
            OTAssert(([[orderedResult objectAtIndex: 1] isEqual: @"second"]), @"spawnAll should preserve the second child result ordering");
            OTAssert(([[orderedResult objectAtIndex: 2] isEqual: @"third"]), @"spawnAll should preserve the third child result ordering");
            OTAssert((caughtSpawnAllFailure), @"spawnAll should reject when one child fails");
            OTAssert((cancelledSibling), @"spawnAll should cancel unresolved sibling tasks after a child failure");
            OTAssert((caughtSpawnAllTimeout), @"spawnAll should cooperate with scope timeouts");
            OTAssert((timedOutChildCancelled), @"spawnAll child tasks should be cancelled before a timeout unwinds the scope");
    }];
}

- (void)test_timeout_cancels_children
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtTimeout), @"performWithTimeout should throw AsyncTaskGroupTimeoutException when the deadline expires");
            OTAssert((timedOutChildCancelled), @"timeout should cancel descendant tasks before the scope unwinds");
    }];
}

- (void)test_past_deadline_fails_immediately
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            bool caughtImmediateDeadline = false;

            @try {
                auto pastDeadline = [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01];

                (void)[rootScope performWithDeadline: pastDeadline block: ^id(AsyncTaskGroup *) {
                    return AsyncUnit.unit;
                }];
            } @catch (AsyncTaskGroupTimeoutException *) {
                caughtImmediateDeadline = true;
            }

            OTAssert((caughtImmediateDeadline), @"performWithDeadline should fail immediately for a past deadline");
    }];
}

- (void)test_parent_scope_cancellation_propagates
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((grandchildCancelled), @"scope cancellation should propagate from a parent scope down to descendants");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeSchedulerTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeSchedulerTests

- (void)test_scheduler_offload_roundtrip
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
            OFThread *workerThread = [scheduler offload: ^{
                return $assert_nonnil(OFThread.currentThread);
            }].await;

            OTAssert((workerThread != expectedThread), @"offloaded work should run on a worker thread");
            OTAssert((OFThread.currentThread == expectedThread), @"awaiting offloaded work should resume on the original scheduler thread");
    }];
}

- (void)test_scheduler_snapshot_waiting_task
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;

            (void)[rootScope performInChildTaskGroupNamed: @"snapshot-scope" block: ^id(AsyncTaskGroup *scope) {
                Task *snapshotTask = [scope spawnTask: ^{
                    [[scheduler sleepForTimeInterval: 0.05] await];
                    return AsyncUnit.unit;
                } name: @"snapshot-child"];

                [[scheduler sleepForTimeInterval: 0.01] await];

                AsyncSchedulerSnapshot *snapshot = scheduler.snapshot;
                auto taskSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"snapshot-child" inSnapshot: snapshot];

                OTAssert((taskSnapshot != nilptr), @"scheduler.snapshot should include active tasks");
                OTAssert((taskSnapshot.taskID == snapshotTask.taskID), @"scheduler.snapshot should preserve task IDs");
                OTAssert((taskSnapshot.executionState == AsyncTaskExecutionState_WAITING), @"scheduler.snapshot should report waiting execution state");
                OTAssert(([taskSnapshot.waitReason isEqual: @"await task"]), @"scheduler.snapshot should report why a task is waiting");
                OTAssert(([taskSnapshot.taskGroupName isEqual: @"snapshot-scope"]), @"scheduler.snapshot should expose the current task group name");
                OTAssert((not taskSnapshot.isCancellationRequested), @"scheduler.snapshot should reflect cancellation state");
                OTAssert((snapshot.tasks.count > 0), @"scheduler.snapshot should expose active task entries");

                [snapshotTask await];
                return AsyncUnit.unit;
            }];
    }];
}

- (void)test_scheduler_shutdown_rejects_offload
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *parentScheduler = rootScope.scheduler;
            auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: parentScheduler.runLoop mode: parentScheduler.mode maxWorkerCount: 1 maxDrainBatchSize: 1];
            OFThread *workerThread = [scheduler offload: ^{
                return $assert_nonnil(OFThread.currentThread);
            }].await;
            bool caughtShutdownOffload = false;

            OTAssert((workerThread != OFThread.currentThread), @"dedicated schedulers should execute offloaded work on worker threads");

            [scheduler shutdown];
            [scheduler shutdown];

            @try {
                (void)[scheduler offload: ^{
                    return AsyncUnit.unit;
                }];
            } @catch (OFInvalidArgumentException *) {
                caughtShutdownOffload = true;
            }

            OTAssert((caughtShutdownOffload), @"shutdown schedulers should reject further offload requests");
    }];
}

- (void)test_scheduler_cancellation_counter
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtTimeout), @"the cancellation counter scenario should still time out");
            OTAssert((cancelledTask != nilptr), @"the cancellation counter scenario should create a child task");
            OTAssert((cancelledTask.status == AsyncTaskStatus_REJECTED), @"timeout-cancelled tasks should reject");
            OTAssert(([cancelledTask.failureException isKindOfClass: TaskCancelledException.class]), @"timeout-cancelled tasks should reject with TaskCancelledException");
            OTAssert((scheduler.snapshot.cancelledTaskCount > cancelledTaskCountBefore), @"scheduler.snapshot.cancelledTaskCount should advance when a task is cancelled");
    }];
}

- (void)test_scheduler_offload_failure_paths
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((caughtNilOffload), @"offloaded blocks returning nilptr should reject with OFInvalidArgumentException");
            OTAssert((caughtThrownOffload), @"offloaded blocks should propagate their original exception");
    }];
}

- (void)test_scheduler_sleep_shortcuts
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            Task<AsyncUnit *> *zeroSleep = [scheduler sleepForTimeInterval: 0];
            Task<AsyncUnit *> *pastSleep = [scheduler sleepUntilDate: [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01]];

            OTAssert((zeroSleep.isCompleted), @"zero-length sleeps should complete immediately");
            OTAssert((zeroSleep.status == AsyncTaskStatus_FULFILLED), @"zero-length sleeps should fulfill immediately");
            OTAssert((zeroSleep.await == AsyncUnit.unit), @"zero-length sleeps should resolve to AsyncUnit.unit");
            OTAssert((pastSleep.isCompleted), @"sleepUntilDate with a past deadline should complete immediately");
            OTAssert((pastSleep.status == AsyncTaskStatus_FULFILLED), @"sleepUntilDate with a past deadline should fulfill immediately");
            OTAssert((pastSleep.await == AsyncUnit.unit), @"sleepUntilDate with a past deadline should resolve to AsyncUnit.unit");
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeChannelTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeChannelTests

- (void)test_channel_rendezvous
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert(([receivedValue isEqual: @"ping"]), @"an unbuffered channel should rendezvous between sender and receiver");
    }];
}

- (void)test_channel_buffer_backpressure_and_snapshot
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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
                OTAssert((senderSnapshot != nilptr), @"buffered sender should appear in scheduler snapshots while blocked");
                OTAssert((senderSnapshot.executionState == AsyncTaskExecutionState_WAITING), @"buffered sender should block when the channel is full");
                OTAssert(([senderSnapshot.waitReason isEqual: @"channel send"]), @"buffered sender should report channel send as the wait reason");

                firstBufferedValue = channel.receive;
                [[scheduler sleepForTimeInterval: 0.01] await];
                secondBufferedValue = channel.receive;
                return AsyncUnit.unit;
            }];

            OTAssert(([firstBufferedValue isEqual: @"one"]), @"bounded channels should preserve the first buffered value");
            OTAssert(([secondBufferedValue isEqual: @"two"]), @"bounded channels should eventually deliver values blocked by backpressure");
            OTAssert((bufferedEvents.count == 4), @"bounded channel sender should resume after capacity becomes available");
            OTAssert(([bufferedEvents[3] isEqual: @"after-second-send"]), @"the second send should only complete after a receive frees space");
    }];
}

- (void)test_channel_close_semantics
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            (void)rootScope;
            auto closedChannel = [[AsyncChannel<OFString *> alloc] initWithCapacity: 1];
            bool caughtClosedSend = false;
            bool caughtClosedReceive = false;

            [closedChannel send: @"buffered-before-close"];
            [closedChannel close];

            OTAssert((closedChannel.isClosed), @"close should mark the channel as closed");
            OTAssert(([closedChannel.receive isEqual: @"buffered-before-close"]), @"closing a channel should still allow buffered values to be drained");

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

            OTAssert((caughtClosedSend), @"sending on a closed channel should throw AsyncChannelClosedException");
            OTAssert((caughtClosedReceive), @"receiving from an exhausted closed channel should throw AsyncChannelClosedException");
    }];
}

- (void)test_channel_close_unblocks_waiters
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                    OTAssert(false, @"blocked receiver should observe channel close");
                    return AsyncUnit.unit;
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

                    OTAssert(false, @"blocked sender should observe channel close");
                    return AsyncUnit.unit;
                } name: @"blocked-sender"];

                [scope spawnTask: ^{
                    [[scheduler sleepForTimeInterval: 0.01] await];
                    [senderChannel close];
                    return AsyncUnit.unit;
                } name: @"sender-closer"];

                return AsyncUnit.unit;
            }];

            OTAssert((blockedReceiverClosed), @"closing a channel should wake blocked receivers with AsyncChannelClosedException");
            OTAssert((blockedSenderClosed), @"closing a channel should wake blocked senders with AsyncChannelClosedException");
    }];
}

- (void)test_channel_send_cancellation
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                    OTAssert(false, @"blocked send should observe cancellation");
                    return AsyncUnit.unit;
                } name: @"blocked-sender"];

                [scope spawnTask: ^{
                    [[scheduler sleepForTimeInterval: 0.01] await];
                    [scope cancel];
                    return AsyncUnit.unit;
                } name: @"send-canceller"];

                return AsyncUnit.unit;
            }];

            OTAssert((blockedSendCancelled), @"blocked sends should be cancellation checkpoints");
    }];
}

- (void)test_channel_receive_cancellation
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                    OTAssert(false, @"blocked receive should observe cancellation");
                    return AsyncUnit.unit;
                } name: @"blocked-receiver"];

                [scope spawnTask: ^{
                    [[scheduler sleepForTimeInterval: 0.01] await];
                    [scope cancel];
                    return AsyncUnit.unit;
                } name: @"receive-canceller"];

                return AsyncUnit.unit;
            }];

            OTAssert((blockedReceiveCancelled), @"blocked receives should be cancellation checkpoints");
    }];
}

- (void)test_channel_multi_producer_consumer
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

            OTAssert((receivedValues.count == itemsPerProducer * 2), @"multi-producer/multi-consumer channels should deliver every produced value exactly once");

            for (size_t producerIndex = 0; producerIndex < 2; producerIndex++) {
                for (size_t itemIndex = 0; itemIndex < itemsPerProducer; itemIndex++) {
                    OFString *expectedValue = [OFString stringWithFormat: @"p%zu-%zu", producerIndex, itemIndex];
                    OTAssert(([receivedValues containsObject: expectedValue]), @"%@", ([OFString stringWithFormat: @"missing channel value %@", expectedValue]));
                }
            }
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeHTTPTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeHTTPTests

- (void)test_http_concurrent_requests
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            auto server = [[LocalHTTPTestServer alloc] init];
            auto client = [[OFHTTPClient alloc] init];
            Task<OFHTTPResponse *> *alphaTask;
            Task<OFHTTPResponse *> *betaTask;
            OFHTTPResponse *alphaResponse;
            OFHTTPResponse *betaResponse;

            OTAssert((OFTLSStreamImplementation != Nil), @"Async runtime should force ObjFWTLS to load so https support is available");

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

                OTAssert(([alphaResponse.readString isEqual: @"alpha"]), @"HTTP request bridge should resolve the first concurrent request correctly");
                OTAssert(([betaResponse.readString isEqual: @"beta"]), @"HTTP request bridge should resolve the second concurrent request correctly");
            } @finally {
                [server stop];
            }
    }];
}

- (void)test_http_timeout_cancellation_and_reuse
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                OTAssert((caughtTimeout), @"cancelling a task waiting on HTTP should unwind via timeout");
                gammaResponse = [AsyncRuntimeTestSupport taskToPerformHTTPRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/gamma"]]
                                                                    withHTTPClient: client
                                                                         redirects: 0
                                                                       onScheduler: scheduler
                                                          cancelOnTaskCancellation: false].await;
                OTAssert(([gammaResponse.readString isEqual: @"gamma"]), @"HTTP request bridge should remain usable after cancelling an in-flight request");
            } @finally {
                [server stop];
            }
    }];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeStressTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeStressTests

- (void)test_stress_timeout_repetitions
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                OTAssert((caughtTimeout), @"%@", ([OFString stringWithFormat: @"stress timeout iteration %zu should time out", iteration]));
                OTAssert((childCancelled), @"%@", ([OFString stringWithFormat: @"stress timeout iteration %zu should cancel its child task", iteration]));
            }
    }];
}

- (void)test_stress_channel_repetitions
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
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

                OTAssert((values.count == 8), @"%@", ([OFString stringWithFormat: @"stress channel iteration %zu should receive every value", iteration]));
            }
    }];
}

@end
#pragma clang assume_nonnull end
