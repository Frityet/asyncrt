#import "TestSupport.h"

#pragma clang assume_nonnull begin

static void drain_scheduler_until_task_resolved(AsyncScheduler *scheduler, Task *task)
{
    for (size_t iteration = 0; iteration < 200 and not task.isCompleted; iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }

    [AsyncRuntimeTestSupport assertCondition: (task.isCompleted) message: (@"scheduler run loop should eventually resolve the task")];
}

static void default_scheduler_lifecycle(void)
{
    AsyncScheduler *firstScheduler = AsyncScheduler.defaultScheduler;
    AsyncScheduler *sameScheduler = AsyncScheduler.defaultScheduler;
    block_reference AsyncScheduler *otherThreadScheduler = nilptr;

    auto thread = [[OFThread alloc] initWithBlock: ^{
        otherThreadScheduler = AsyncScheduler.defaultScheduler;
        [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
        return nilptr;
    }];

    [thread start];
    (void)[thread join];

    [AsyncRuntimeTestSupport assertCondition: (firstScheduler == sameScheduler) message: (@"defaultScheduler should be memoized per thread")];
    [AsyncRuntimeTestSupport assertCondition: (otherThreadScheduler != nilptr) message: (@"defaultScheduler should be available on worker threads")];
    [AsyncRuntimeTestSupport assertCondition: (otherThreadScheduler != firstScheduler) message: (@"defaultScheduler should be thread-local")];

    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];

    AsyncScheduler *replacementScheduler = AsyncScheduler.defaultScheduler;
    [AsyncRuntimeTestSupport assertCondition: (replacementScheduler != firstScheduler) message: (@"shutdownDefaultSchedulerForCurrentThread should replace the scheduler for task callers")];
    [AsyncRuntimeTestSupport assertCondition: (replacementScheduler == AsyncScheduler.defaultScheduler) message: (@"replacement defaultScheduler should also be memoized")];

    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
}

static void coroutine_roundtrip_states(void)
{
    auto roundtripCoroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *co) {
        [co yield: @"yield-1"];
        [co yield: @"yield-2"];
        return @"done";
    }];

    [AsyncRuntimeTestSupport assertCondition: (roundtripCoroutine.status == CoroutineStatus_READY) message: (@"new coroutines should start in READY")];
    [AsyncRuntimeTestSupport assertCondition: ([[roundtripCoroutine resume] isEqual: @"yield-1"]) message: (@"Coroutine.resume should return the first yielded value")];
    [AsyncRuntimeTestSupport assertCondition: (roundtripCoroutine.status == CoroutineStatus_SUSPENDED) message: (@"yielding should suspend the coroutine")];
    [AsyncRuntimeTestSupport assertCondition: (roundtripCoroutine.didYieldObject) message: (@"yielding should mark didYieldObject")];
    [AsyncRuntimeTestSupport assertCondition: ([roundtripCoroutine.yieldedObject isEqual: @"yield-1"]) message: (@"yieldedObject should expose the yielded value")];
    [AsyncRuntimeTestSupport assertCondition: ([[roundtripCoroutine resume] isEqual: @"yield-2"]) message: (@"Coroutine.resume should preserve the caller context across multiple yields")];
    [AsyncRuntimeTestSupport assertCondition: ([[roundtripCoroutine resume] isEqual: @"done"]) message: (@"Coroutine.resume should return the final return value")];
    [AsyncRuntimeTestSupport assertCondition: (roundtripCoroutine.status == CoroutineStatus_DEAD) message: (@"returning should transition the coroutine to DEAD")];
    [AsyncRuntimeTestSupport assertCondition: (not roundtripCoroutine.didYieldObject) message: (@"returning should clear didYieldObject")];
    [AsyncRuntimeTestSupport assertCondition: (roundtripCoroutine.didReturnObject) message: (@"returning should mark didReturnObject")];
    [AsyncRuntimeTestSupport assertCondition: ([roundtripCoroutine.returnedObject isEqual: @"done"]) message: (@"returnedObject should expose the final return value")];
}

static void coroutine_return_short_circuits(void)
{
    block_reference bool reachedAfterEarlyReturn = false;
    auto earlyReturnCoroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *co) {
        [co yield: @"before-return"];
        [co return: @"returned-early"];
        reachedAfterEarlyReturn = true;
        return @"unreachable";
    }];

    [AsyncRuntimeTestSupport assertCondition: ([[earlyReturnCoroutine resume] isEqual: @"before-return"]) message: (@"Coroutine.resume should return yielded values before an explicit return")];
    [AsyncRuntimeTestSupport assertCondition: ([[earlyReturnCoroutine resume] isEqual: @"returned-early"]) message: (@"Coroutine.return should immediately finish the coroutine with its return value")];
    [AsyncRuntimeTestSupport assertCondition: (earlyReturnCoroutine.status == CoroutineStatus_DEAD) message: (@"Coroutine.return should transition the coroutine to DEAD")];
    [AsyncRuntimeTestSupport assertCondition: (not reachedAfterEarlyReturn) message: (@"Coroutine.return should not continue executing the block after returning")];
}

static void coroutine_exception_propagation(void)
{
    auto throwingCoroutine = [[Coroutine alloc] initWithBlock: ^id(Coroutine<id> *co) {
        [co yield: @"before-throw"];
        @throw [[TestRejectionException alloc] init];
    }];
    bool caughtCoroutineException = false;

    [AsyncRuntimeTestSupport assertCondition: ([[throwingCoroutine resume] isEqual: @"before-throw"]) message: (@"Coroutine should still yield before throwing from inside the coroutine body")];

    @try {
        (void)[throwingCoroutine resume];
    } @catch (TestRejectionException *) {
        caughtCoroutineException = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtCoroutineException) message: (@"exceptions thrown inside a coroutine should be rethrown to the caller")];
    [AsyncRuntimeTestSupport assertCondition: (throwingCoroutine.status == CoroutineStatus_DEAD) message: (@"an exception escaping the coroutine body should terminate the coroutine")];
    [AsyncRuntimeTestSupport assertCondition: (not throwingCoroutine.didReturnObject) message: (@"an exception escaping the coroutine body should not mark didReturnObject")];
}

static void coroutine_fast_enumeration(void)
{
    auto coroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *co) {
        [co yield: @"one"];
        [co yield: @"two"];
        [co yield: @"three"];
        return @"done";
    }];
    auto values = [OFMutableArray<OFString *> array];

    for (OFString *value in coroutine)
        [values addObject: value];

    [AsyncRuntimeTestSupport assertCondition: (values.count == 3) message: (@"fast enumeration should visit every yielded value")];
    [AsyncRuntimeTestSupport assertCondition: ([[values objectAtIndex: 0] isEqual: @"one"]) message: (@"fast enumeration should preserve the first yielded value")];
    [AsyncRuntimeTestSupport assertCondition: ([[values objectAtIndex: 1] isEqual: @"two"]) message: (@"fast enumeration should preserve the second yielded value")];
    [AsyncRuntimeTestSupport assertCondition: ([[values objectAtIndex: 2] isEqual: @"three"]) message: (@"fast enumeration should preserve the third yielded value")];
    [AsyncRuntimeTestSupport assertCondition: (coroutine.status == CoroutineStatus_DEAD) message: (@"fast enumeration should exhaust the coroutine")];
    [AsyncRuntimeTestSupport assertCondition: ([coroutine.returnedObject isEqual: @"done"]) message: (@"fast enumeration should still preserve the coroutine return value")];
}

static void coroutine_default_stack_size(void)
{
    size_t originalStackSize = Task.defaultStackSize;
    size_t configuredStackSize = originalStackSize + 65536;
    bool caughtZeroStackSize = false;

    @try {
        Task.defaultStackSize = 0;
    } @catch (OFInvalidArgumentException *) {
        caughtZeroStackSize = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtZeroStackSize) message: (@"setting Task.defaultStackSize to zero should throw")];

    @try {
        Task.defaultStackSize = configuredStackSize;
        [AsyncRuntimeTestSupport assertCondition: (Task.defaultStackSize == configuredStackSize) message: (@"Task.defaultStackSize should proxy to Coroutine.defaultStackSize")];
        [AsyncRuntimeTestSupport assertCondition: (Coroutine.defaultStackSize == configuredStackSize) message: (@"Task.defaultStackSize should update the coroutine default stack size")];

        auto coroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *) {
            return @"done";
        }];

        [AsyncRuntimeTestSupport assertCondition: (coroutine.stackSize >= configuredStackSize) message: (@"new coroutines should honour the configured default stack size")];
    } @finally {
        Task.defaultStackSize = originalStackSize;
    }
}

static void task_await_outside_task(void)
{
    auto resolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtAwaitMisuse = false;

    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask == nilptr) message: (@"Task.currentTask should be nilptr outside the runtime")];
    [AsyncRuntimeTestSupport assertCondition: (AsyncTaskGroup.currentTaskGroup == nilptr) message: (@"AsyncTaskGroup.currentTaskGroup should be nilptr outside the runtime")];
    [AsyncRuntimeTestSupport assertCondition: ([Task conformsToProtocol: @protocol(Awaitable)]) message: (@"Task should conform to Awaitable")];

    @try {
        [resolver.task await];
    } @catch (AsyncTaskAwaitOutsideTaskException *exception) {
        caughtAwaitMisuse = (exception.task == resolver.task);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtAwaitMisuse) message: (@"task.await outside a Task should throw AsyncTaskAwaitOutsideTaskException")];
}

static void task_resolution_guards(void)
{
    auto doubleResolveResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto doubleRejectResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtDoubleResolve = false;
    bool caughtRejectAfterResolve = false;
    bool caughtDoubleReject = false;
    bool caughtResolveAfterReject = false;

    [doubleResolveResolver fulfill: @"first"];

    @try {
        [doubleResolveResolver fulfill: @"second"];
    } @catch (AsyncTaskAlreadyResolvedException *exception) {
        caughtDoubleResolve = (exception.task == doubleResolveResolver.task and exception.currentStatus == AsyncTaskStatus_FULFILLED and exception.attemptedStatus == AsyncTaskStatus_FULFILLED);
    }

    @try {
        [doubleResolveResolver reject: [[TestRejectionException alloc] init]];
    } @catch (AsyncTaskAlreadyResolvedException *exception) {
        caughtRejectAfterResolve = (exception.task == doubleResolveResolver.task and exception.currentStatus == AsyncTaskStatus_FULFILLED and exception.attemptedStatus == AsyncTaskStatus_REJECTED);
    }

    [doubleRejectResolver reject: [[TestRejectionException alloc] init]];

    @try {
        [doubleRejectResolver reject: [[TestRejectionException alloc] init]];
    } @catch (AsyncTaskAlreadyResolvedException *exception) {
        caughtDoubleReject = (exception.task == doubleRejectResolver.task and exception.currentStatus == AsyncTaskStatus_REJECTED and exception.attemptedStatus == AsyncTaskStatus_REJECTED);
    }

    @try {
        [doubleRejectResolver fulfill: @"nope"];
    } @catch (AsyncTaskAlreadyResolvedException *exception) {
        caughtResolveAfterReject = (exception.task == doubleRejectResolver.task and exception.currentStatus == AsyncTaskStatus_REJECTED and exception.attemptedStatus == AsyncTaskStatus_FULFILLED);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtDoubleResolve) message: (@"resolving an already fulfilled task should throw AsyncTaskAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRejectAfterResolve) message: (@"rejecting an already fulfilled task should throw AsyncTaskAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDoubleReject) message: (@"rejecting an already rejected task should throw AsyncTaskAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtResolveAfterReject) message: (@"resolving an already rejected task should throw AsyncTaskAlreadyResolvedException")];
}

static void task_state_access_guards(void)
{
    auto pendingResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto fulfilledResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto rejectedResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtPendingValueAccess = false;
    bool caughtPendingRejectionAccess = false;
    bool caughtFulfilledRejectionAccess = false;
    bool caughtRejectedValueAccess = false;

    @try {
        (void)pendingResolver.task.value;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtPendingValueAccess = (exception.task == pendingResolver.task and exception.status == AsyncTaskStatus_PENDING);
    }

    @try {
        (void)pendingResolver.task.failureException;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtPendingRejectionAccess = (exception.task == pendingResolver.task and exception.status == AsyncTaskStatus_PENDING);
    }

    [fulfilledResolver fulfill: @"state-ok"];
    [AsyncRuntimeTestSupport assertCondition: ([fulfilledResolver.task.value isEqual: @"state-ok"]) message: (@"reading value on a fulfilled task should succeed")];

    @try {
        (void)fulfilledResolver.task.failureException;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtFulfilledRejectionAccess = (exception.task == fulfilledResolver.task and exception.status == AsyncTaskStatus_FULFILLED);
    }

    [rejectedResolver reject: [[TestRejectionException alloc] init]];
    [AsyncRuntimeTestSupport assertCondition: ([rejectedResolver.task.failureException isKindOfClass: TestRejectionException.class]) message: (@"reading failureException on a rejected task should succeed")];

    @try {
        (void)rejectedResolver.task.value;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtRejectedValueAccess = (exception.task == rejectedResolver.task and exception.status == AsyncTaskStatus_REJECTED);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtPendingValueAccess) message: (@"reading value on a pending task should throw AsyncTaskInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtPendingRejectionAccess) message: (@"reading failureException on a pending task should throw AsyncTaskInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtFulfilledRejectionAccess) message: (@"reading failureException on a fulfilled task should throw AsyncTaskInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRejectedValueAccess) message: (@"reading value on a rejected task should throw AsyncTaskInvalidStateAccessException")];
}

static void task_nil_resolution_and_rejection(void)
{
    auto resolutionResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto rejectionResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtNilResolution = false;
    bool caughtNilRejection = false;
    bool caughtClassNilResolution = false;
    bool caughtClassNilRejection = false;

    @try {
        [resolutionResolver fulfill: (id)0];
    } @catch (AsyncTaskNilResolutionValueException *exception) {
        caughtNilResolution = (exception.task == resolutionResolver.task);
    }

    @try {
        [rejectionResolver reject: (OFException *)0];
    } @catch (AsyncTaskNilRejectionException *exception) {
        caughtNilRejection = (exception.task == rejectionResolver.task);
    }

    @try {
        (void)[Task resolved: (id)0];
    } @catch (AsyncTaskNilResolutionValueException *) {
        caughtClassNilResolution = true;
    }

    @try {
        (void)[Task rejected: (OFException *)0];
    } @catch (AsyncTaskNilRejectionException *) {
        caughtClassNilRejection = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilResolution) message: (@"fulfilling a completion source with nilptr should throw AsyncTaskNilResolutionValueException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilRejection) message: (@"rejecting a completion source with nilptr should throw AsyncTaskNilRejectionException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtClassNilResolution) message: (@"Task.resolved(nilptr) should throw AsyncTaskNilResolutionValueException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtClassNilRejection) message: (@"Task.rejected(nilptr) should throw AsyncTaskNilRejectionException")];
}

static void async_unit_singleton(void)
{
    AsyncUnit *firstUnit = AsyncUnit.unit;
    AsyncUnit *sameUnit = AsyncUnit.unit;

    [AsyncRuntimeTestSupport assertCondition: (firstUnit == sameUnit) message: (@"AsyncUnit.unit should be memoized")];
    [AsyncRuntimeTestSupport assertCondition: ([[firstUnit description] isEqual: @"AsyncUnit"]) message: (@"AsyncUnit should provide a stable description")];
}

static void async_scheduler_invalid_initialization(void)
{
    auto run_loop = $assert_nonnil(OFRunLoop.currentRunLoop);
    bool caughtNilRunLoop = false;
    bool caughtNilMode = false;
    bool caughtZeroWorkerCount = false;
    bool caughtZeroDrainBatchSize = false;

    @try {
        [AsyncSchedulerValidation validateRunLoop: nilptr mode: OFDefaultRunLoopMode maxWorkerCount: 1 maxDrainBatchSize: 1];
    } @catch (AsyncSchedulerInvalidInitializationException *exception) {
        caughtNilRunLoop = [exception.reason isEqual: @"runLoop must not be nilptr"];
    }

    @try {
        [AsyncSchedulerValidation validateRunLoop: run_loop mode: nilptr maxWorkerCount: 1 maxDrainBatchSize: 1];
    } @catch (AsyncSchedulerInvalidInitializationException *exception) {
        caughtNilMode = [exception.reason isEqual: @"mode must not be nilptr"];
    }

    @try {
        [AsyncSchedulerValidation validateRunLoop: run_loop mode: OFDefaultRunLoopMode maxWorkerCount: 0 maxDrainBatchSize: 1];
    } @catch (AsyncSchedulerInvalidInitializationException *exception) {
        caughtZeroWorkerCount = [exception.reason isEqual: @"maxWorkerCount must be at least 1"];
    }

    @try {
        [AsyncSchedulerValidation validateRunLoop: run_loop mode: OFDefaultRunLoopMode maxWorkerCount: 1 maxDrainBatchSize: 0];
    } @catch (AsyncSchedulerInvalidInitializationException *exception) {
        caughtZeroDrainBatchSize = [exception.reason isEqual: @"maxDrainBatchSize must be at least 1"];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilRunLoop) message: (@"AsyncScheduler should reject a nil run loop")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilMode) message: (@"AsyncScheduler should reject a nil run-loop mode")];
    [AsyncRuntimeTestSupport assertCondition: (caughtZeroWorkerCount) message: (@"AsyncScheduler should reject a zero worker count")];
    [AsyncRuntimeTestSupport assertCondition: (caughtZeroDrainBatchSize) message: (@"AsyncScheduler should reject a zero drain batch size")];
}

static void task_continuation_scheduler_requirements(void)
{
    AsyncScheduler *scheduler = AsyncScheduler.defaultScheduler;
    Task<OFString *> *resolvedTask = [Task resolved: @"outside"];
    Task<OFString *> *rejectedTask = [Task rejected: [[TestRejectionException alloc] init]];
    auto crossThreadResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto resolverThread = [[CrossThreadResolverThread alloc] initWithResolver: crossThreadResolver value: @"cross-thread" delay: 0.01];
    OFThread *expectedThread = $assert_nonnil(OFThread.currentThread);
    block_reference OFThread *continuationThread = nilptr;
    block_reference bool sawNilCurrentTask = false;
    bool caughtMapOutsideTask = false;
    bool caughtFlatMapOutsideTask = false;
    bool caughtRecoverOutsideTask = false;
    bool caughtFlatRecoverOutsideTask = false;
    bool caughtEnsureOutsideTask = false;

    @try {
        (void)[resolvedTask map: ^id(OFString *value) {
            return value;
        }];
    } @catch (AsyncTaskContinuationOutsideTaskException *exception) {
        caughtMapOutsideTask = (exception.task == resolvedTask);
    }

    @try {
        (void)[resolvedTask flatMap: ^Task<OFString *> *(OFString *value) {
            return [Task resolved: value];
        }];
    } @catch (AsyncTaskContinuationOutsideTaskException *exception) {
        caughtFlatMapOutsideTask = (exception.task == resolvedTask);
    }

    @try {
        (void)[rejectedTask recover: ^id(OFException *exception) {
            (void)exception;
            return @"recovered";
        }];
    } @catch (AsyncTaskContinuationOutsideTaskException *exception) {
        caughtRecoverOutsideTask = (exception.task == rejectedTask);
    }

    @try {
        (void)[rejectedTask flatRecover: ^Task<OFString *> *(OFException *exception) {
            (void)exception;
            return [Task resolved: @"recovered"];
        }];
    } @catch (AsyncTaskContinuationOutsideTaskException *exception) {
        caughtFlatRecoverOutsideTask = (exception.task == rejectedTask);
    }

    @try {
        (void)[resolvedTask ensure: ^{
        }];
    } @catch (AsyncTaskContinuationOutsideTaskException *exception) {
        caughtEnsureOutsideTask = (exception.task == resolvedTask);
    }

    auto mapped = [crossThreadResolver.task mapOnScheduler: scheduler transform: ^id(OFString *value) {
        sawNilCurrentTask = (Task.currentTask == nilptr);
        continuationThread = $assert_nonnil(OFThread.currentThread);
        return [value stringByAppendingString: @"-mapped"];
    }];
    auto recovered = [rejectedTask recoverOnScheduler: scheduler handler: ^id(OFException *exception) {
        [AsyncRuntimeTestSupport assertCondition: ([exception isKindOfClass: TestRejectionException.class]) message: (@"recoverOnScheduler should receive the original rejection outside a task")];
        return @"recovered";
    }];

    [resolverThread start];
    drain_scheduler_until_task_resolved(scheduler, mapped);
    drain_scheduler_until_task_resolved(scheduler, recovered);

    [AsyncRuntimeTestSupport assertCondition: (caughtMapOutsideTask) message: (@"map outside a Task should throw AsyncTaskContinuationOutsideTaskException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtFlatMapOutsideTask) message: (@"flatMap outside a Task should throw AsyncTaskContinuationOutsideTaskException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRecoverOutsideTask) message: (@"recover outside a Task should throw AsyncTaskContinuationOutsideTaskException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtFlatRecoverOutsideTask) message: (@"flatRecover outside a Task should throw AsyncTaskContinuationOutsideTaskException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtEnsureOutsideTask) message: (@"ensure outside a Task should throw AsyncTaskContinuationOutsideTaskException")];
    [AsyncRuntimeTestSupport assertCondition: ([mapped.value isEqual: @"cross-thread-mapped"]) message: (@"mapOnScheduler outside a Task should resolve on the supplied scheduler")];
    [AsyncRuntimeTestSupport assertCondition: ([recovered.value isEqual: @"recovered"]) message: (@"recoverOnScheduler outside a Task should resolve on the supplied scheduler")];
    [AsyncRuntimeTestSupport assertCondition: (continuationThread == expectedThread) message: (@"explicit scheduler continuations should execute on the scheduler run-loop thread")];
    [AsyncRuntimeTestSupport assertCondition: (sawNilCurrentTask) message: (@"explicit scheduler continuations outside a Task should not synthesize a current task")];
    (void)[resolverThread join];
}

ASYNC_RUNTIME_SYNC_TEST(default_scheduler_lifecycle)
ASYNC_RUNTIME_SYNC_TEST(coroutine_roundtrip_states)
ASYNC_RUNTIME_SYNC_TEST(coroutine_return_short_circuits)
ASYNC_RUNTIME_SYNC_TEST(coroutine_exception_propagation)
ASYNC_RUNTIME_SYNC_TEST(coroutine_fast_enumeration)
ASYNC_RUNTIME_SYNC_TEST(coroutine_default_stack_size)
ASYNC_RUNTIME_SYNC_TEST(task_await_outside_task)
ASYNC_RUNTIME_SYNC_TEST(task_resolution_guards)
ASYNC_RUNTIME_SYNC_TEST(task_state_access_guards)
ASYNC_RUNTIME_SYNC_TEST(task_nil_resolution_and_rejection)
ASYNC_RUNTIME_SYNC_TEST(task_continuation_scheduler_requirements)
ASYNC_RUNTIME_SYNC_TEST(async_unit_singleton)
ASYNC_RUNTIME_SYNC_TEST(async_scheduler_invalid_initialization)

#pragma clang assume_nonnull end
