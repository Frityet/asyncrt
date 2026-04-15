#import "TestSupport.h"

#pragma clang assume_nonnull begin

static void drain_scheduler_until_task_resolved(id self, SEL _cmd, AsyncScheduler *scheduler, Task *task)
{
    for (size_t iteration = 0; iteration < 200 and not task.isCompleted; iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }

    OTAssert((task.isCompleted), @"scheduler run loop should eventually resolve the task");
}

[[subclassing_restricted]]
@interface AsyncRuntimeSyncTests : OTTestCase @end

@implementation AsyncRuntimeSyncTests

- (void)test_default_scheduler_lifecycle
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

    OTAssert((firstScheduler == sameScheduler), @"defaultScheduler should be memoized per thread");
    OTAssert((otherThreadScheduler != nilptr), @"defaultScheduler should be available on worker threads");
    OTAssert((otherThreadScheduler != firstScheduler), @"defaultScheduler should be thread-local");

    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];

    AsyncScheduler *replacementScheduler = AsyncScheduler.defaultScheduler;
    OTAssert((replacementScheduler != firstScheduler), @"shutdownDefaultSchedulerForCurrentThread should replace the scheduler for task callers");
    OTAssert((replacementScheduler == AsyncScheduler.defaultScheduler), @"replacement defaultScheduler should also be memoized");

    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
}

- (void)test_coroutine_roundtrip_states
{
    auto roundtripCoroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *co) {
        [co yield: @"yield-1"];
        [co yield: @"yield-2"];
        return @"done";
    }];

    OTAssert((roundtripCoroutine.status == CoroutineStatus_READY), @"new coroutines should start in READY");
    OTAssert(([[roundtripCoroutine resume] isEqual: @"yield-1"]), @"Coroutine.resume should return the first yielded value");
    OTAssert((roundtripCoroutine.status == CoroutineStatus_SUSPENDED), @"yielding should suspend the coroutine");
    OTAssert((roundtripCoroutine.didYieldObject), @"yielding should mark didYieldObject");
    OTAssert(([roundtripCoroutine.yieldedObject isEqual: @"yield-1"]), @"yieldedObject should expose the yielded value");
    OTAssert(([[roundtripCoroutine resume] isEqual: @"yield-2"]), @"Coroutine.resume should preserve the caller context across multiple yields");
    OTAssert(([[roundtripCoroutine resume] isEqual: @"done"]), @"Coroutine.resume should return the final return value");
    OTAssert((roundtripCoroutine.status == CoroutineStatus_DEAD), @"returning should transition the coroutine to DEAD");
    OTAssert((not roundtripCoroutine.didYieldObject), @"returning should clear didYieldObject");
    OTAssert((roundtripCoroutine.didReturnObject), @"returning should mark didReturnObject");
    OTAssert(([roundtripCoroutine.returnedObject isEqual: @"done"]), @"returnedObject should expose the final return value");
}

- (void)test_coroutine_return_short_circuits
{
    block_reference bool reachedAfterEarlyReturn = false;
    auto earlyReturnCoroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *co) {
        [co yield: @"before-return"];
        [co return: @"returned-early"];
        reachedAfterEarlyReturn = true;
        return @"unreachable";
    }];

    OTAssert(([[earlyReturnCoroutine resume] isEqual: @"before-return"]), @"Coroutine.resume should return yielded values before an explicit return");
    OTAssert(([[earlyReturnCoroutine resume] isEqual: @"returned-early"]), @"Coroutine.return should immediately finish the coroutine with its return value");
    OTAssert((earlyReturnCoroutine.status == CoroutineStatus_DEAD), @"Coroutine.return should transition the coroutine to DEAD");
    OTAssert((not reachedAfterEarlyReturn), @"Coroutine.return should not continue executing the block after returning");
}

- (void)test_coroutine_exception_propagation
{
    auto throwingCoroutine = [[Coroutine alloc] initWithBlock: ^id(Coroutine<id> *co) {
        [co yield: @"before-throw"];
        @throw [[TestRejectionException alloc] init];
    }];
    bool caughtCoroutineException = false;

    OTAssert(([[throwingCoroutine resume] isEqual: @"before-throw"]), @"Coroutine should still yield before throwing from inside the coroutine body");

    @try {
        (void)[throwingCoroutine resume];
    } @catch (TestRejectionException *) {
        caughtCoroutineException = true;
    }

    OTAssert((caughtCoroutineException), @"exceptions thrown inside a coroutine should be rethrown to the caller");
    OTAssert((throwingCoroutine.status == CoroutineStatus_DEAD), @"an exception escaping the coroutine body should terminate the coroutine");
    OTAssert((not throwingCoroutine.didReturnObject), @"an exception escaping the coroutine body should not mark didReturnObject");
}

- (void)test_coroutine_fast_enumeration
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

    OTAssert((values.count == 3), @"fast enumeration should visit every yielded value");
    OTAssert(([[values objectAtIndex: 0] isEqual: @"one"]), @"fast enumeration should preserve the first yielded value");
    OTAssert(([[values objectAtIndex: 1] isEqual: @"two"]), @"fast enumeration should preserve the second yielded value");
    OTAssert(([[values objectAtIndex: 2] isEqual: @"three"]), @"fast enumeration should preserve the third yielded value");
    OTAssert((coroutine.status == CoroutineStatus_DEAD), @"fast enumeration should exhaust the coroutine");
    OTAssert(([coroutine.returnedObject isEqual: @"done"]), @"fast enumeration should still preserve the coroutine return value");
}

- (void)test_coroutine_default_stack_size
{
    size_t originalStackSize = Task.defaultStackSize;
    size_t configuredStackSize = originalStackSize + 65536;
    bool caughtZeroStackSize = false;

    @try {
        Task.defaultStackSize = 0;
    } @catch (OFInvalidArgumentException *) {
        caughtZeroStackSize = true;
    }

    OTAssert((caughtZeroStackSize), @"setting Task.defaultStackSize to zero should throw");

    @try {
        Task.defaultStackSize = configuredStackSize;
        OTAssert((Task.defaultStackSize == configuredStackSize), @"Task.defaultStackSize should proxy to Coroutine.defaultStackSize");
        OTAssert((Coroutine.defaultStackSize == configuredStackSize), @"Task.defaultStackSize should update the coroutine default stack size");

        auto coroutine = [[Coroutine<OFString *> alloc] initWithBlock: ^OFString *(Coroutine<OFString *> *) {
            return @"done";
        }];

        OTAssert((coroutine.stackSize >= configuredStackSize), @"new coroutines should honour the configured default stack size");
    } @finally {
        Task.defaultStackSize = originalStackSize;
    }
}

- (void)test_task_await_outside_task
{
    auto resolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtAwaitMisuse = false;

    OTAssert((Task.currentTask == nilptr), @"Task.currentTask should be nilptr outside the runtime");
    OTAssert((AsyncTaskGroup.currentTaskGroup == nilptr), @"AsyncTaskGroup.currentTaskGroup should be nilptr outside the runtime");

    @try {
        [resolver.task await];
    } @catch (AsyncTaskAwaitOutsideTaskException *exception) {
        caughtAwaitMisuse = (exception.task == resolver.task);
    }

    OTAssert((caughtAwaitMisuse), @"task.await outside a Task should throw AsyncTaskAwaitOutsideTaskException");
}

- (void)test_task_resolution_guards
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

    OTAssert((caughtDoubleResolve), @"resolving an already fulfilled task should throw AsyncTaskAlreadyResolvedException");
    OTAssert((caughtRejectAfterResolve), @"rejecting an already fulfilled task should throw AsyncTaskAlreadyResolvedException");
    OTAssert((caughtDoubleReject), @"rejecting an already rejected task should throw AsyncTaskAlreadyResolvedException");
    OTAssert((caughtResolveAfterReject), @"resolving an already rejected task should throw AsyncTaskAlreadyResolvedException");
}

- (void)test_task_state_access_guards
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
    OTAssert(([fulfilledResolver.task.value isEqual: @"state-ok"]), @"reading value on a fulfilled task should succeed");

    @try {
        (void)fulfilledResolver.task.failureException;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtFulfilledRejectionAccess = (exception.task == fulfilledResolver.task and exception.status == AsyncTaskStatus_FULFILLED);
    }

    [rejectedResolver reject: [[TestRejectionException alloc] init]];
    OTAssert(([rejectedResolver.task.failureException isKindOfClass: TestRejectionException.class]), @"reading failureException on a rejected task should succeed");

    @try {
        (void)rejectedResolver.task.value;
    } @catch (AsyncTaskInvalidStateAccessException *exception) {
        caughtRejectedValueAccess = (exception.task == rejectedResolver.task and exception.status == AsyncTaskStatus_REJECTED);
    }

    OTAssert((caughtPendingValueAccess), @"reading value on a pending task should throw AsyncTaskInvalidStateAccessException");
    OTAssert((caughtPendingRejectionAccess), @"reading failureException on a pending task should throw AsyncTaskInvalidStateAccessException");
    OTAssert((caughtFulfilledRejectionAccess), @"reading failureException on a fulfilled task should throw AsyncTaskInvalidStateAccessException");
    OTAssert((caughtRejectedValueAccess), @"reading value on a rejected task should throw AsyncTaskInvalidStateAccessException");
}

- (void)test_task_nil_resolution_and_rejection
{
    auto resolutionResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    auto rejectionResolver = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtNilResolution = false;
    bool caughtNilRejection = false;
    bool caughtClassNilResolution = false;
    bool caughtClassNilRejection = false;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
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
#pragma clang diagnostic pop

    OTAssert((caughtNilResolution), @"fulfilling a completion source with nilptr should throw AsyncTaskNilResolutionValueException");
    OTAssert((caughtNilRejection), @"rejecting a completion source with nilptr should throw AsyncTaskNilRejectionException");
    OTAssert((caughtClassNilResolution), @"Task.resolved(nilptr) should throw AsyncTaskNilResolutionValueException");
    OTAssert((caughtClassNilRejection), @"Task.rejected(nilptr) should throw AsyncTaskNilRejectionException");
}

- (void)test_async_completion_source_lifecycle
{
    auto resolvedCompletionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    auto rejectedCompletionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    auto cancellationCompletionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    __block size_t pendingCancellationCallCount = 0;
    __block bool cancellationObserved = false;

    OTAssert((resolvedCompletionSource.task != nilptr), @"AsyncCompletionSource should eagerly create its task");
    OTAssert((resolvedCompletionSource.task == resolvedCompletionSource.task), @"AsyncCompletionSource.task should be stable across reads");
    OTAssert((resolvedCompletionSource.task.status == AsyncTaskStatus_PENDING), @"a new AsyncCompletionSource task should start pending");

    [resolvedCompletionSource fulfill: @"fulfilled"];

    OTAssert((resolvedCompletionSource.task.isCompleted), @"fulfilling an AsyncCompletionSource should resolve its task");
    OTAssert((resolvedCompletionSource.task.status == AsyncTaskStatus_FULFILLED), @"fulfilled AsyncCompletionSource tasks should report FULFILLED");
    OTAssert(([resolvedCompletionSource.task.value isEqual: @"fulfilled"]), @"fulfilling an AsyncCompletionSource should preserve the value");

    [rejectedCompletionSource reject: [[TestRejectionException alloc] init]];

    OTAssert((rejectedCompletionSource.task.isCompleted), @"rejecting an AsyncCompletionSource should resolve its task");
    OTAssert((rejectedCompletionSource.task.status == AsyncTaskStatus_REJECTED), @"rejected AsyncCompletionSource tasks should report REJECTED");
    OTAssert(([rejectedCompletionSource.task.failureException isKindOfClass: TestRejectionException.class]), @"rejecting an AsyncCompletionSource should preserve the failure exception");

    [cancellationCompletionSource setPendingTaskCancellationHandler: ^{
        pendingCancellationCallCount++;
    }];

    auto scheduler = AsyncScheduler.defaultScheduler;
    auto waitingTask = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;

        @try {
            return [cancellationCompletionSource.task await];
        } @catch (TaskCancelledException *) {
            cancellationObserved = true;
            return @"cancelled";
        }
    }];

    for (size_t iteration = 0; iteration < 200 and waitingTask.executionState != AsyncTaskExecutionState_WAITING; iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }

    OTAssert((waitingTask.executionState == AsyncTaskExecutionState_WAITING), @"awaiting an AsyncCompletionSource task should suspend the consumer task while pending");
    [waitingTask cancel];
    drain_scheduler_until_task_resolved(self, _cmd, scheduler, waitingTask);

    OTAssert((cancellationObserved), @"cancelling a task awaiting an AsyncCompletionSource should surface TaskCancelledException");
    OTAssert((pendingCancellationCallCount == 1), @"pending AsyncCompletionSource cancellation handlers should fire exactly once when the last waiter is removed");

    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
}

- (void)test_task_continuation_scheduler_requirements
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
        OTAssert(([exception isKindOfClass: TestRejectionException.class]), @"recoverOnScheduler should receive the original rejection outside a task");
        return @"recovered";
    }];

    [resolverThread start];
    drain_scheduler_until_task_resolved(self, _cmd, scheduler, mapped);
    drain_scheduler_until_task_resolved(self, _cmd, scheduler, recovered);

    OTAssert((caughtMapOutsideTask), @"map outside a Task should throw AsyncTaskContinuationOutsideTaskException");
    OTAssert((caughtFlatMapOutsideTask), @"flatMap outside a Task should throw AsyncTaskContinuationOutsideTaskException");
    OTAssert((caughtRecoverOutsideTask), @"recover outside a Task should throw AsyncTaskContinuationOutsideTaskException");
    OTAssert((caughtFlatRecoverOutsideTask), @"flatRecover outside a Task should throw AsyncTaskContinuationOutsideTaskException");
    OTAssert((caughtEnsureOutsideTask), @"ensure outside a Task should throw AsyncTaskContinuationOutsideTaskException");
    OTAssert(([mapped.value isEqual: @"cross-thread-mapped"]), @"mapOnScheduler outside a Task should resolve on the supplied scheduler");
    OTAssert(([recovered.value isEqual: @"recovered"]), @"recoverOnScheduler outside a Task should resolve on the supplied scheduler");
    OTAssert((continuationThread == expectedThread), @"explicit scheduler continuations should execute on the scheduler run-loop thread");
    OTAssert((sawNilCurrentTask), @"explicit scheduler continuations outside a Task should not synthesize a current task");
    (void)[resolverThread join];
}

- (void)test_async_unit_singleton
{
    AsyncUnit *firstUnit = AsyncUnit.unit;
    AsyncUnit *sameUnit = AsyncUnit.unit;

    OTAssert((firstUnit == sameUnit), @"AsyncUnit.unit should be memoized");
    OTAssert(([[firstUnit description] isEqual: @"AsyncUnit"]), @"AsyncUnit should provide a stable description");
}

- (void)test_async_scheduler_invalid_initialization
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

    OTAssert((caughtNilRunLoop), @"AsyncScheduler should reject a nil run loop");
    OTAssert((caughtNilMode), @"AsyncScheduler should reject a nil run-loop mode");
    OTAssert((caughtZeroWorkerCount), @"AsyncScheduler should reject a zero worker count");
    OTAssert((caughtZeroDrainBatchSize), @"AsyncScheduler should reject a zero drain batch size");
}

@end
#pragma clang assume_nonnull end
