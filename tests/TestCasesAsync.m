#import "TestSupport.h"

#pragma clang assume_nonnull begin

static void future_await_and_protocol(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFString *fulfilledValue;
    OFString *immediateValue;
    id<Awaitable> awaitableFuture;

    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask != nilptr) message: (@"Task.currentTask should be set inside AsyncRuntime.run")];
    [AsyncRuntimeTestSupport assertCondition: (AsyncScope.currentScope == rootScope) message: (@"AsyncScope.currentScope should point at the root scope inside AsyncRuntime.run")];

    fulfilledValue = [AsyncRuntimeTestSupport timerResolvedStringForScheduler: scheduler seconds: 0.01 value: @"timer-value"].await;
    immediateValue = [Future resolved: @"immediate-value"].await;
    awaitableFuture = [Future resolved: @"awaitable-protocol"];

    [AsyncRuntimeTestSupport assertCondition: ([fulfilledValue isEqual: @"timer-value"]) message: (@"await should return the fulfilled timer value")];
    [AsyncRuntimeTestSupport assertCondition: ([immediateValue isEqual: @"immediate-value"]) message: (@"await on an already fulfilled future should return immediately")];
    [AsyncRuntimeTestSupport assertCondition: ([[(id)awaitableFuture await] isEqual: @"awaitable-protocol"]) message: (@"Awaitable.await should use the runtime future await implementation")];
}

static void future_rejection_paths(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    bool caughtRejectedAwait = false;
    bool caughtImmediateRejection = false;

    @try {
        (void)[AsyncRuntimeTestSupport timerRejectedStringForScheduler: scheduler seconds: 0.01 exception: [[TestRejectionException alloc] init]].await;
    } @catch (TestRejectionException *unusedException) {
        (void)unusedException;
        caughtRejectedAwait = true;
    }

    @try {
        (void)[Future rejected: [[TestRejectionException alloc] init]].await;
    } @catch (TestRejectionException *unusedException) {
        (void)unusedException;
        caughtImmediateRejection = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtRejectedAwait) message: (@"await should rethrow the original timer rejection exception")];
    [AsyncRuntimeTestSupport assertCondition: (caughtImmediateRejection) message: (@"await on an already rejected future should rethrow immediately")];
}

static void task_metadata_and_resolution(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Task<AsyncUnit *> *unitTask = [rootScope spawn: ^id {
        (void)[scheduler sleepForTimeInterval: 0.01].await;
        return AsyncUnit.unit;
    } name: @"unit-task"];

    (void)unitTask.await;

    [AsyncRuntimeTestSupport assertCondition: (unitTask.scheduler == scheduler) message: (@"spawned tasks should inherit the current scheduler")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.scope == rootScope) message: (@"spawned tasks should belong to the current scope")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.taskID > 0) message: (@"spawned tasks should receive a stable task ID")];
    [AsyncRuntimeTestSupport assertCondition: ([unitTask.name isEqual: @"unit-task"]) message: (@"spawned tasks should preserve their name")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.status == FutureStatus_FULFILLED) message: (@"Task<AsyncUnit *> should fulfill successfully")];
    [AsyncRuntimeTestSupport assertCondition: (unitTask.executionState == AsyncTaskExecutionState_RESOLVED) message: (@"awaited tasks should end in the resolved execution state")];
}

static void task_returned_nil_exception(AsyncScope *rootScope)
{
    block_reference Task *nillable task = nilptr;
    TaskReturnedNilException *nillable primary_exception = nilptr;
    bool caughtScopeFailure = false;

    @try {
        (void)[rootScope withChildScopeNamed: @"nil-return-scope" block: ^id(AsyncScope *scope) {
            task = [scope spawn: ^id {
                return nilptr;
            } name: @"nil-return"];
            return AsyncUnit.unit;
        }];
    } @catch (AsyncScopeException *exception) {
        auto maybe_primary_exception = exception.primaryException;

        if ([maybe_primary_exception isKindOfClass: TaskReturnedNilException.class])
            primary_exception = (TaskReturnedNilException *)maybe_primary_exception;

        caughtScopeFailure = (primary_exception != nilptr and
                              primary_exception.task == task and
                              exception.exceptions.count == 1);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtScopeFailure) message: (@"a scope containing a task that returns nilptr should fail with AsyncScopeException")];
    [AsyncRuntimeTestSupport assertCondition: ([task.rejectionException isKindOfClass: TaskReturnedNilException.class]) message: (@"tasks returning nilptr should reject with TaskReturnedNilException")];
    [AsyncRuntimeTestSupport assertCondition: (task.rejectionException == primary_exception) message: (@"the scope primary exception should match the task rejection exception")];
    [AsyncRuntimeTestSupport assertCondition: (task.status == FutureStatus_REJECTED) message: (@"tasks returning nilptr should be rejected")];
    [AsyncRuntimeTestSupport assertCondition: (task.executionState == AsyncTaskExecutionState_RESOLVED) message: (@"tasks returning nilptr should still finish with a resolved execution state")];
}

static void cross_thread_future_resolution(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    FutureResolver<OFString *> *crossThreadResolver = [[FutureResolver alloc] init];
    CrossThreadResolverThread *thread = [[CrossThreadResolverThread alloc] initWithResolver: crossThreadResolver value: @"thread-value" delay: 0.01];
    OFString *crossThreadValue;

    [thread start];
    crossThreadValue = crossThreadResolver.future.await;

    [AsyncRuntimeTestSupport assertCondition: ([crossThreadValue isEqual: @"thread-value"]) message: (@"cross-thread resolution should deliver the resolved value")];
    [AsyncRuntimeTestSupport assertCondition: (OFThread.currentThread == expectedThread) message: (@"await continuations should resume on the scheduler run-loop thread")];
    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask.scheduler == scheduler) message: (@"cross-thread awaits should preserve the current task scheduler")];
    (void)[thread join];
}

static void self_await_rejected(AsyncScope *rootScope)
{
    block_reference Task *selfAwaitTask = nilptr;

    selfAwaitTask = [rootScope spawn: ^id {
        @try {
            (void)selfAwaitTask.await;
        } @catch (FutureSelfAwaitException *exception) {
            [AsyncRuntimeTestSupport assertCondition: (exception.future == selfAwaitTask) message: (@"self-await should throw FutureSelfAwaitException")];
            return AsyncUnit.unit;
        }

        @throw [[TestFailureException alloc] initWithMessage: @"self-await did not throw FutureSelfAwaitException"];
    } name: @"self-await"];

    (void)selfAwaitTask.await;
}

static void scope_waits_for_children(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto scopeEvents = [OFMutableArray<OFString *> array];

    (void)[rootScope withChildScopeNamed: @"nested-scope" block: ^id(AsyncScope *scope) {
        [scopeEvents addObject: @"body-enter"];
        [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
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

static void scope_failure_cancels_siblings(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto failureEvents = [OFMutableArray<OFString *> array];
    bool caughtAggregate = false;

    @try {
        (void)[rootScope withChildScopeNamed: @"aggregate-scope" block: ^id(AsyncScope *scope) {
            [scope spawn: ^id {
                (void)[scheduler sleepForTimeInterval: 0.01].await;
                [failureEvents addObject: @"failing-child"];
                @throw [[TestRejectionException alloc] init];
            } name: @"failing-child"];

            [scope spawn: ^id {
                @try {
                    for (;;)
                        (void)[scheduler sleepForTimeInterval: 0.05].await;
                } @catch (TaskCancelledException *unusedException) {
                    (void)unusedException;
                    [failureEvents addObject: @"cleanup-child"];
                    return AsyncUnit.unit;
                }
            } name: @"cleanup-child"];

            (void)[scheduler sleepForTimeInterval: 0.25].await;
            return AsyncUnit.unit;
        }];
    } @catch (AsyncScopeException *exception) {
        caughtAggregate = true;
        [AsyncRuntimeTestSupport assertCondition: ([exception.primaryException isKindOfClass: TestRejectionException.class]) message: (@"AsyncScopeException should expose the primary child failure")];
        [AsyncRuntimeTestSupport assertCondition: (exception.exceptions.count == 1) message: (@"sibling cancellation cleanup should not contribute an additional failure")];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtAggregate) message: (@"a child failure should surface as AsyncScopeException")];
    [AsyncRuntimeTestSupport assertCondition: (failureEvents.count == 2) message: (@"structured failure should still give siblings a chance to clean up")];
    [AsyncRuntimeTestSupport assertCondition: ([failureEvents[0] isEqual: @"failing-child"]) message: (@"the failing child should run before sibling cancellation cleanup")];
    [AsyncRuntimeTestSupport assertCondition: ([failureEvents[1] isEqual: @"cleanup-child"]) message: (@"sibling cleanup should happen before the scope reports failure")];
}

static void task_cancellation_checkpoint(AsyncScope *rootScope)
{
    block_reference atomic_t(bool) cancelIssued = false;
    block_reference TaskCancellationThread *cancellationThread = nilptr;
    block_reference bool reachedCheckpoint = false;

    (void)[rootScope withChildScopeNamed: @"checkpoint-scope" block: ^id(AsyncScope *scope) {
        Task *checkpointTask = [scope spawn: ^id {
            while (not atomic_load_explicit(&cancelIssued, memory_order_acquire)) { }

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

static void timeout_cancels_children(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    block_reference bool timedOutChildCancelled = false;
    bool caughtTimeout = false;

    @try {
        (void)[rootScope withTimeout: 0.02 block: ^id(AsyncScope *scope) {
            [scope spawn: ^id {
                @try {
                    for (;;)
                        (void)[scheduler sleepForTimeInterval: 0.05].await;
                } @catch (TaskCancelledException *unusedException) {
                    (void)unusedException;
                    timedOutChildCancelled = true;
                    return AsyncUnit.unit;
                }
            } name: @"timeout-child"];

            (void)[scheduler sleepForTimeInterval: 0.25].await;
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTimeoutException *exception) {
        caughtTimeout = (exception.scope != nilptr and exception.deadline != nilptr);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"withTimeout should throw AsyncTimeoutException when the deadline expires")];
    [AsyncRuntimeTestSupport assertCondition: (timedOutChildCancelled) message: (@"timeout should cancel descendant tasks before the scope unwinds")];
}

static void past_deadline_fails_immediately(AsyncScope *rootScope)
{
    bool caughtImmediateDeadline = false;

    @try {
        OFDate *pastDeadline = [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01];

        (void)[rootScope withDeadline: pastDeadline block: ^id(AsyncScope *scope) {
            (void)scope;
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTimeoutException *unusedException) {
        (void)unusedException;
        caughtImmediateDeadline = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtImmediateDeadline) message: (@"withDeadline should fail immediately for a past deadline")];
}

static void parent_scope_cancellation_propagates(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    block_reference bool grandchildCancelled = false;

    (void)[rootScope withChildScopeNamed: @"parent-cancel-scope" block: ^id(AsyncScope *outerScope) {
        [outerScope spawn: ^id {
            (void)[outerScope withChildScopeNamed: @"inner-scope" block: ^id(AsyncScope *innerScope) {
                [innerScope spawn: ^id {
                    @try {
                        for (;;)
                            (void)[scheduler sleepForTimeInterval: 0.05].await;
                    } @catch (TaskCancelledException *unusedException) {
                        (void)unusedException;
                        grandchildCancelled = true;
                        return AsyncUnit.unit;
                    }
                } name: @"grandchild"];

                (void)[scheduler sleepForTimeInterval: 1].await;
                return AsyncUnit.unit;
            }];

            return AsyncUnit.unit;
        } name: @"nested-owner"];

        [outerScope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
            [outerScope cancel];
            return AsyncUnit.unit;
        } name: @"scope-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (grandchildCancelled) message: (@"scope cancellation should propagate from a parent scope down to descendants")];
}

static void scheduler_offload_roundtrip(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    OFThread *workerThread = [scheduler offload: ^id {
        return $assert_nonnil(OFThread.currentThread);
    }].await;

    [AsyncRuntimeTestSupport assertCondition: (workerThread != expectedThread) message: (@"offloaded work should run on a worker thread")];
    [AsyncRuntimeTestSupport assertCondition: (OFThread.currentThread == expectedThread) message: (@"awaiting offloaded work should resume on the original scheduler thread")];
}

static void scheduler_snapshot_waiting_task(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    (void)[rootScope withChildScopeNamed: @"snapshot-scope" block: ^id(AsyncScope *scope) {
        Task *snapshotTask = [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.05].await;
            return AsyncUnit.unit;
        } name: @"snapshot-child"];

        (void)[scheduler sleepForTimeInterval: 0.01].await;

        AsyncSchedulerSnapshot *snapshot = scheduler.snapshot;
        auto taskSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"snapshot-child" inSnapshot: snapshot];

        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot != nilptr) message: (@"scheduler.snapshot should include active tasks")];
        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot.taskID == snapshotTask.taskID) message: (@"scheduler.snapshot should preserve task IDs")];
        [AsyncRuntimeTestSupport assertCondition: (taskSnapshot.executionState == AsyncTaskExecutionState_WAITING) message: (@"scheduler.snapshot should report waiting execution state")];
        [AsyncRuntimeTestSupport assertCondition: ([taskSnapshot.waitReason isEqual: @"await future"]) message: (@"scheduler.snapshot should report why a task is waiting")];
        [AsyncRuntimeTestSupport assertCondition: ([taskSnapshot.scopeName isEqual: @"snapshot-scope"]) message: (@"scheduler.snapshot should expose the current scope name")];
        [AsyncRuntimeTestSupport assertCondition: (not taskSnapshot.cancellationRequested) message: (@"scheduler.snapshot should reflect cancellation state")];
        [AsyncRuntimeTestSupport assertCondition: (snapshot.tasks.count > 0) message: (@"scheduler.snapshot should expose active task entries")];

        (void)snapshotTask.await;
        return AsyncUnit.unit;
    }];
}

static void scheduler_shutdown_rejects_offload(AsyncScope *rootScope)
{
    AsyncScheduler *parentScheduler = rootScope.scheduler;
    AsyncScheduler *scheduler = [[AsyncScheduler alloc] initWithRunLoop: parentScheduler.runLoop mode: parentScheduler.mode maxWorkerCount: 1 maxDrainBatchSize: 1];
    OFThread *workerThread = [scheduler offload: ^id {
        return $assert_nonnil(OFThread.currentThread);
    }].await;
    bool caughtShutdownOffload = false;

    [AsyncRuntimeTestSupport assertCondition: (workerThread != OFThread.currentThread) message: (@"dedicated schedulers should execute offloaded work on worker threads")];

    [scheduler shutdown];
    [scheduler shutdown];

    @try {
        (void)[scheduler offload: ^id {
            return AsyncUnit.unit;
        }];
    } @catch (OFInvalidArgumentException *unusedException) {
        (void)unusedException;
        caughtShutdownOffload = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtShutdownOffload) message: (@"shutdown schedulers should reject further offload requests")];
}

static void scheduler_cancellation_counter(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    uint64_t cancelledTaskCountBefore = scheduler.snapshot.cancelledTaskCount;
    block_reference Task *cancelledTask = nilptr;
    bool caughtTimeout = false;

    @try {
        (void)[rootScope withTimeout: 0.02 block: ^id(AsyncScope *scope) {
            cancelledTask = [scope spawn: ^id {
                for (;;)
                    (void)[scheduler sleepForTimeInterval: 0.05].await;
            } name: @"cancelled-counter-child"];

            (void)[scheduler sleepForTimeInterval: 0.25].await;
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTimeoutException *unusedException) {
        (void)unusedException;
        caughtTimeout = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"the cancellation counter scenario should still time out")];
    [AsyncRuntimeTestSupport assertCondition: (cancelledTask != nilptr) message: (@"the cancellation counter scenario should create a child task")];
    [AsyncRuntimeTestSupport assertCondition: (cancelledTask.status == FutureStatus_REJECTED) message: (@"timeout-cancelled tasks should reject")];
    [AsyncRuntimeTestSupport assertCondition: ([cancelledTask.rejectionException isKindOfClass: TaskCancelledException.class]) message: (@"timeout-cancelled tasks should reject with TaskCancelledException")];
    [AsyncRuntimeTestSupport assertCondition: (scheduler.snapshot.cancelledTaskCount > cancelledTaskCountBefore) message: (@"scheduler.snapshot.cancelledTaskCount should advance when a task is cancelled")];
}

static void scheduler_offload_failure_paths(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    bool caughtNilOffload = false;
    bool caughtThrownOffload = false;

    @try {
        (void)[scheduler offload: ^id {
            return nilptr;
        }].await;
    } @catch (OFInvalidArgumentException *unusedException) {
        (void)unusedException;
        caughtNilOffload = true;
    }

    @try {
        (void)[scheduler offload: ^id {
            @throw [[TestRejectionException alloc] init];
        }].await;
    } @catch (TestRejectionException *unusedException) {
        (void)unusedException;
        caughtThrownOffload = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilOffload) message: (@"offloaded blocks returning nilptr should reject with OFInvalidArgumentException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtThrownOffload) message: (@"offloaded blocks should propagate their original exception")];
}

static void scheduler_sleep_shortcuts(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Future<AsyncUnit *> *zeroSleep = [scheduler sleepForTimeInterval: 0];
    Future<AsyncUnit *> *pastSleep = [scheduler sleepUntilDate: [[OFDate alloc] initWithTimeIntervalSinceNow: -0.01]];

    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.isResolved) message: (@"zero-length sleeps should resolve immediately")];
    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.status == FutureStatus_FULFILLED) message: (@"zero-length sleeps should fulfill immediately")];
    [AsyncRuntimeTestSupport assertCondition: (zeroSleep.await == AsyncUnit.unit) message: (@"zero-length sleeps should resolve to AsyncUnit.unit")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.isResolved) message: (@"sleepUntilDate with a past deadline should resolve immediately")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.status == FutureStatus_FULFILLED) message: (@"sleepUntilDate with a past deadline should fulfill immediately")];
    [AsyncRuntimeTestSupport assertCondition: (pastSleep.await == AsyncUnit.unit) message: (@"sleepUntilDate with a past deadline should resolve to AsyncUnit.unit")];
}

static void channel_rendezvous(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 0];
    block_reference OFString *receivedValue = nilptr;

    (void)[rootScope withChildScopeNamed: @"rendezvous-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            receivedValue = channel.receive;
            return AsyncUnit.unit;
        } name: @"rendezvous-receiver"];

        (void)[scheduler sleepForTimeInterval: 0.01].await;
        [channel send: @"ping"];
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: ([receivedValue isEqual: @"ping"]) message: (@"an unbuffered channel should rendezvous between sender and receiver")];
}

static void channel_buffer_backpressure_and_snapshot(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 1];
    auto bufferedEvents = [OFMutableArray<OFString *> array];
    block_reference OFString *firstBufferedValue = nilptr;
    block_reference OFString *secondBufferedValue = nilptr;

    (void)[rootScope withChildScopeNamed: @"buffered-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            [bufferedEvents addObject: @"before-first-send"];
            [channel send: @"one"];
            [bufferedEvents addObject: @"after-first-send"];
            [bufferedEvents addObject: @"before-second-send"];
            [channel send: @"two"];
            [bufferedEvents addObject: @"after-second-send"];
            return AsyncUnit.unit;
        } name: @"buffered-sender"];

        (void)[scheduler sleepForTimeInterval: 0.01].await;

        auto senderSnapshot = [AsyncRuntimeTestSupport findTaskSnapshotNamed: @"buffered-sender" inSnapshot: scheduler.snapshot];
        [AsyncRuntimeTestSupport assertCondition: (senderSnapshot != nilptr) message: (@"buffered sender should appear in scheduler snapshots while blocked")];
        [AsyncRuntimeTestSupport assertCondition: (senderSnapshot.executionState == AsyncTaskExecutionState_WAITING) message: (@"buffered sender should block when the channel is full")];
        [AsyncRuntimeTestSupport assertCondition: ([senderSnapshot.waitReason isEqual: @"channel send"]) message: (@"buffered sender should report channel send as the wait reason")];

        firstBufferedValue = channel.receive;
        (void)[scheduler sleepForTimeInterval: 0.01].await;
        secondBufferedValue = channel.receive;
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: ([firstBufferedValue isEqual: @"one"]) message: (@"bounded channels should preserve the first buffered value")];
    [AsyncRuntimeTestSupport assertCondition: ([secondBufferedValue isEqual: @"two"]) message: (@"bounded channels should eventually deliver values blocked by backpressure")];
    [AsyncRuntimeTestSupport assertCondition: (bufferedEvents.count == 4) message: (@"bounded channel sender should resume after capacity becomes available")];
    [AsyncRuntimeTestSupport assertCondition: ([bufferedEvents[3] isEqual: @"after-second-send"]) message: (@"the second send should only complete after a receive frees space")];
}

static void channel_close_semantics(AsyncScope *rootScope)
{
    (void)rootScope;
    AsyncChannel<OFString *> *closedChannel = [[AsyncChannel alloc] initWithCapacity: 1];
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

static void channel_close_unblocks_waiters(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    AsyncChannel<OFString *> *receiverChannel = [[AsyncChannel alloc] initWithCapacity: 0];
    AsyncChannel<OFString *> *senderChannel = [[AsyncChannel alloc] initWithCapacity: 0];
    block_reference bool blockedReceiverClosed = false;
    block_reference bool blockedSenderClosed = false;

    (void)[rootScope withChildScopeNamed: @"close-receiver-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            @try {
                (void)receiverChannel.receive;
            } @catch (AsyncChannelClosedException *exception) {
                blockedReceiverClosed = [exception.operation isEqual: @"receive"];
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked receiver should observe channel close"];
        } name: @"blocked-receiver"];

        [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
            [receiverChannel close];
            return AsyncUnit.unit;
        } name: @"receiver-closer"];

        return AsyncUnit.unit;
    }];

    (void)[rootScope withChildScopeNamed: @"close-sender-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            @try {
                [senderChannel send: @"value"];
            } @catch (AsyncChannelClosedException *exception) {
                blockedSenderClosed = [exception.operation isEqual: @"send"];
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked sender should observe channel close"];
        } name: @"blocked-sender"];

        [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
            [senderChannel close];
            return AsyncUnit.unit;
        } name: @"sender-closer"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedReceiverClosed) message: (@"closing a channel should wake blocked receivers with AsyncChannelClosedException")];
    [AsyncRuntimeTestSupport assertCondition: (blockedSenderClosed) message: (@"closing a channel should wake blocked senders with AsyncChannelClosedException")];
}

static void channel_send_cancellation(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 0];
    block_reference bool blockedSendCancelled = false;

    (void)[rootScope withChildScopeNamed: @"send-cancel-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            @try {
                [channel send: @"blocked-send"];
            } @catch (TaskCancelledException *unusedException) {
                (void)unusedException;
                blockedSendCancelled = true;
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked send should observe cancellation"];
        } name: @"blocked-sender"];

        [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
            [scope cancel];
            return AsyncUnit.unit;
        } name: @"send-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedSendCancelled) message: (@"blocked sends should be cancellation checkpoints")];
}

static void channel_receive_cancellation(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 0];
    block_reference bool blockedReceiveCancelled = false;

    (void)[rootScope withChildScopeNamed: @"receive-cancel-scope" block: ^id(AsyncScope *scope) {
        [scope spawn: ^id {
            @try {
                (void)channel.receive;
            } @catch (TaskCancelledException *unusedException) {
                (void)unusedException;
                blockedReceiveCancelled = true;
                return AsyncUnit.unit;
            }

            @throw [[TestFailureException alloc] initWithMessage: @"blocked receive should observe cancellation"];
        } name: @"blocked-receiver"];

        [scope spawn: ^id {
            (void)[scheduler sleepForTimeInterval: 0.01].await;
            [scope cancel];
            return AsyncUnit.unit;
        } name: @"receive-canceller"];

        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (blockedReceiveCancelled) message: (@"blocked receives should be cancellation checkpoints")];
}

static void channel_multi_producer_consumer(AsyncScope *rootScope)
{
    AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 2];
    auto receivedValues = [OFMutableSet<OFString *> set];
    size_t const itemsPerProducer = 10;

    (void)[rootScope withChildScopeNamed: @"multi-producer-consumer-scope" block: ^id(AsyncScope *scope) {
        for (size_t producerIndex = 0; producerIndex < 2; producerIndex++) {
            OFString *producerName = [OFString stringWithFormat: @"producer-%zu", producerIndex];

            [scope spawn: ^id {
                for (size_t itemIndex = 0; itemIndex < itemsPerProducer; itemIndex++) {
                    OFString *value = [OFString stringWithFormat: @"p%zu-%zu", producerIndex, itemIndex];
                    [channel send: value];
                }

                return AsyncUnit.unit;
            } name: producerName];
        }

        for (size_t consumerIndex = 0; consumerIndex < 2; consumerIndex++) {
            OFString *consumerName = [OFString stringWithFormat: @"consumer-%zu", consumerIndex];

            [scope spawn: ^id {
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

static void http_concurrent_requests(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    LocalHTTPTestServer *server = [[LocalHTTPTestServer alloc] init];
    OFHTTPClient *client = [[OFHTTPClient alloc] init];
    Future<OFHTTPResponse *> *alphaFuture;
    Future<OFHTTPResponse *> *betaFuture;
    OFHTTPResponse *alphaResponse;
    OFHTTPResponse *betaResponse;

    [AsyncRuntimeTestSupport assertCondition: (OFTLSStreamImplementation != Nil) message: (@"Async runtime should force ObjFWTLS to load so https support is available")];

    [server start];

    @try {
        alphaFuture = [client futurePerformRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/alpha"]] onScheduler: scheduler];
        betaFuture = [client futurePerformRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/beta"]] redirects: 0 onScheduler: scheduler];

        alphaResponse = alphaFuture.await;
        betaResponse = betaFuture.await;

        [AsyncRuntimeTestSupport assertCondition: ([alphaResponse.readString isEqual: @"alpha"]) message: (@"HTTP future bridge should resolve the first concurrent request correctly")];
        [AsyncRuntimeTestSupport assertCondition: ([betaResponse.readString isEqual: @"beta"]) message: (@"HTTP future bridge should resolve the second concurrent request correctly")];
    } @finally {
        [server stop];
    }
}

static void http_timeout_cancellation_and_reuse(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    LocalHTTPTestServer *server = [[LocalHTTPTestServer alloc] init];
    OFHTTPClient *client = [[OFHTTPClient alloc] init];
    OFHTTPResponse *gammaResponse;
    bool caughtTimeout = false;

    [server start];

    @try {
        @try {
            (void)[rootScope withTimeout: 0.02 block: ^id(AsyncScope *scope) {
                (void)scope;
                (void)[client futurePerformRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/slow-cancel"]] onScheduler: scheduler].await;
                return AsyncUnit.unit;
            }];
        } @catch (AsyncTimeoutException *unusedException) {
            (void)unusedException;
            caughtTimeout = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: (@"cancelling a task waiting on HTTP should unwind via timeout")];
        gammaResponse = [client futurePerformRequest: [[OFHTTPRequest alloc] initWithIRI: [server IRIForPath: @"/gamma"]] redirects: 0 onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: ([gammaResponse.readString isEqual: @"gamma"]) message: (@"HTTP future bridge should remain usable after cancelling an in-flight request")];
    } @finally {
        [server stop];
    }
}

static void stress_timeout_repetitions(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    for (size_t iteration = 0; iteration < 25; iteration++) {
        block_reference bool childCancelled = false;
        bool caughtTimeout = false;

        @try {
            (void)[rootScope withTimeout: 0.003 block: ^id(AsyncScope *scope) {
                [scope spawn: ^id {
                    @try {
                        (void)[scheduler sleepForTimeInterval: 0.10].await;
                    } @catch (TaskCancelledException *unusedException) {
                        (void)unusedException;
                        childCancelled = true;
                        return AsyncUnit.unit;
                    }

                    return AsyncUnit.unit;
                } name: [OFString stringWithFormat: @"stress-timeout-child-%zu", iteration]];

                (void)[scheduler sleepForTimeInterval: 0.10].await;
                return AsyncUnit.unit;
            }];
        } @catch (AsyncTimeoutException *unusedException) {
            (void)unusedException;
            caughtTimeout = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtTimeout) message: ([OFString stringWithFormat: @"stress timeout iteration %zu should time out", iteration])];
        [AsyncRuntimeTestSupport assertCondition: (childCancelled) message: ([OFString stringWithFormat: @"stress timeout iteration %zu should cancel its child task", iteration])];
    }
}

static void stress_channel_repetitions(AsyncScope *rootScope)
{
    for (size_t iteration = 0; iteration < 20; iteration++) {
        AsyncChannel<OFString *> *channel = [[AsyncChannel alloc] initWithCapacity: 1];
        auto values = [OFMutableArray<OFString *> array];

        (void)[rootScope withChildScopeNamed: [OFString stringWithFormat: @"stress-channel-%zu", iteration] block: ^id(AsyncScope *scope) {
            [scope spawn: ^id {
                for (size_t itemIndex = 0; itemIndex < 8; itemIndex++)
                    [channel send: [OFString stringWithFormat: @"%zu-%zu", iteration, itemIndex]];

                return AsyncUnit.unit;
            } name: @"stress-producer"];

            [scope spawn: ^id {
                for (size_t itemIndex = 0; itemIndex < 8; itemIndex++)
                    [values addObject: channel.receive];

                return AsyncUnit.unit;
            } name: @"stress-consumer"];

            return AsyncUnit.unit;
        }];

        [AsyncRuntimeTestSupport assertCondition: (values.count == 8) message: ([OFString stringWithFormat: @"stress channel iteration %zu should receive every value", iteration])];
    }
}

ASYNC_RUNTIME_ASYNC_TEST(future_await_and_protocol)
ASYNC_RUNTIME_ASYNC_TEST(future_rejection_paths)
ASYNC_RUNTIME_ASYNC_TEST(task_metadata_and_resolution)
ASYNC_RUNTIME_ASYNC_TEST(task_returned_nil_exception)
ASYNC_RUNTIME_ASYNC_TEST(cross_thread_future_resolution)
ASYNC_RUNTIME_ASYNC_TEST(self_await_rejected)
ASYNC_RUNTIME_ASYNC_TEST(scope_waits_for_children)
ASYNC_RUNTIME_ASYNC_TEST(scope_failure_cancels_siblings)
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
