#import "TestSupport.h"

#pragma clang assume_nonnull begin

static void default_scheduler_lifecycle(void)
{
    AsyncScheduler *firstScheduler = AsyncScheduler.defaultScheduler;
    AsyncScheduler *sameScheduler = AsyncScheduler.defaultScheduler;
    block_reference AsyncScheduler *otherThreadScheduler = nilptr;

    auto thread = [[OFThread alloc] initWithBlock: ^id {
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
    [AsyncRuntimeTestSupport assertCondition: (replacementScheduler != firstScheduler) message: (@"shutdownDefaultSchedulerForCurrentThread should replace the scheduler for future callers")];
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

static void future_await_outside_task(void)
{
    auto resolver = [[PromiseResolver<OFString *> alloc] init];
    bool caughtAwaitMisuse = false;

    [AsyncRuntimeTestSupport assertCondition: (Task.currentTask == nilptr) message: (@"Task.currentTask should be nilptr outside the runtime")];
    [AsyncRuntimeTestSupport assertCondition: (AsyncScope.currentScope == nilptr) message: (@"AsyncScope.currentScope should be nilptr outside the runtime")];
    [AsyncRuntimeTestSupport assertCondition: ([Promise conformsToProtocol: @protocol(Awaitable)]) message: (@"Promise should conform to Awaitable")];

    @try {
        (void)resolver.future.await;
    } @catch (PromiseAwaitOutsideTaskException *exception) {
        caughtAwaitMisuse = (exception.future == resolver.future);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtAwaitMisuse) message: (@"future.await outside a Task should throw PromiseAwaitOutsideTaskException")];
}

static void future_resolution_guards(void)
{
    auto doubleResolveResolver = [[PromiseResolver<OFString *> alloc] init];
    auto doubleRejectResolver = [[PromiseResolver<OFString *> alloc] init];
    bool caughtDoubleResolve = false;
    bool caughtRejectAfterResolve = false;
    bool caughtDoubleReject = false;
    bool caughtResolveAfterReject = false;

    [doubleResolveResolver resolve: @"first"];

    @try {
        [doubleResolveResolver resolve: @"second"];
    } @catch (PromiseAlreadyResolvedException *exception) {
        caughtDoubleResolve = (exception.future == doubleResolveResolver.future and exception.currentStatus == PromiseStatus_FULFILLED and exception.attemptedStatus == PromiseStatus_FULFILLED);
    }

    @try {
        [doubleResolveResolver reject: [[TestRejectionException alloc] init]];
    } @catch (PromiseAlreadyResolvedException *exception) {
        caughtRejectAfterResolve = (exception.future == doubleResolveResolver.future and exception.currentStatus == PromiseStatus_FULFILLED and exception.attemptedStatus == PromiseStatus_REJECTED);
    }

    [doubleRejectResolver reject: [[TestRejectionException alloc] init]];

    @try {
        [doubleRejectResolver reject: [[TestRejectionException alloc] init]];
    } @catch (PromiseAlreadyResolvedException *exception) {
        caughtDoubleReject = (exception.future == doubleRejectResolver.future and exception.currentStatus == PromiseStatus_REJECTED and exception.attemptedStatus == PromiseStatus_REJECTED);
    }

    @try {
        [doubleRejectResolver resolve: @"nope"];
    } @catch (PromiseAlreadyResolvedException *exception) {
        caughtResolveAfterReject = (exception.future == doubleRejectResolver.future and exception.currentStatus == PromiseStatus_REJECTED and exception.attemptedStatus == PromiseStatus_FULFILLED);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtDoubleResolve) message: (@"resolving an already fulfilled future should throw PromiseAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRejectAfterResolve) message: (@"rejecting an already fulfilled future should throw PromiseAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDoubleReject) message: (@"rejecting an already rejected future should throw PromiseAlreadyResolvedException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtResolveAfterReject) message: (@"resolving an already rejected future should throw PromiseAlreadyResolvedException")];
}

static void future_state_access_guards(void)
{
    auto pendingResolver = [[PromiseResolver<OFString *> alloc] init];
    auto fulfilledResolver = [[PromiseResolver<OFString *> alloc] init];
    auto rejectedResolver = [[PromiseResolver<OFString *> alloc] init];
    bool caughtPendingValueAccess = false;
    bool caughtPendingRejectionAccess = false;
    bool caughtFulfilledRejectionAccess = false;
    bool caughtRejectedValueAccess = false;

    @try {
        (void)pendingResolver.future.value;
    } @catch (PromiseInvalidStateAccessException *exception) {
        caughtPendingValueAccess = (exception.future == pendingResolver.future and exception.status == PromiseStatus_PENDING);
    }

    @try {
        (void)pendingResolver.future.rejectionException;
    } @catch (PromiseInvalidStateAccessException *exception) {
        caughtPendingRejectionAccess = (exception.future == pendingResolver.future and exception.status == PromiseStatus_PENDING);
    }

    [fulfilledResolver resolve: @"state-ok"];
    [AsyncRuntimeTestSupport assertCondition: ([fulfilledResolver.future.value isEqual: @"state-ok"]) message: (@"reading value on a fulfilled future should succeed")];

    @try {
        (void)fulfilledResolver.future.rejectionException;
    } @catch (PromiseInvalidStateAccessException *exception) {
        caughtFulfilledRejectionAccess = (exception.future == fulfilledResolver.future and exception.status == PromiseStatus_FULFILLED);
    }

    [rejectedResolver reject: [[TestRejectionException alloc] init]];
    [AsyncRuntimeTestSupport assertCondition: ([rejectedResolver.future.rejectionException isKindOfClass: TestRejectionException.class]) message: (@"reading rejectionException on a rejected future should succeed")];

    @try {
        (void)rejectedResolver.future.value;
    } @catch (PromiseInvalidStateAccessException *exception) {
        caughtRejectedValueAccess = (exception.future == rejectedResolver.future and exception.status == PromiseStatus_REJECTED);
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtPendingValueAccess) message: (@"reading value on a pending future should throw PromiseInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtPendingRejectionAccess) message: (@"reading rejectionException on a pending future should throw PromiseInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtFulfilledRejectionAccess) message: (@"reading rejectionException on a fulfilled future should throw PromiseInvalidStateAccessException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRejectedValueAccess) message: (@"reading value on a rejected future should throw PromiseInvalidStateAccessException")];
}

static void future_nil_resolution_and_rejection(void)
{
    auto resolutionResolver = [[PromiseResolver<OFString *> alloc] init];
    auto rejectionResolver = [[PromiseResolver<OFString *> alloc] init];
    bool caughtNilResolution = false;
    bool caughtNilRejection = false;
    bool caughtClassNilResolution = false;
    bool caughtClassNilRejection = false;

    @try {
        [resolutionResolver resolve: (id)0];
    } @catch (PromiseNilResolutionValueException *exception) {
        caughtNilResolution = (exception.future == resolutionResolver.future);
    }

    @try {
        [rejectionResolver reject: (OFException *)0];
    } @catch (PromiseNilRejectionException *exception) {
        caughtNilRejection = (exception.future == rejectionResolver.future);
    }

    @try {
        (void)[Promise resolved: (id)0];
    } @catch (PromiseNilResolutionValueException *) {
        caughtClassNilResolution = true;
    }

    @try {
        (void)[Promise rejected: (OFException *)0];
    } @catch (PromiseNilRejectionException *) {
        caughtClassNilRejection = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilResolution) message: (@"resolving a future with nilptr should throw PromiseNilResolutionValueException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilRejection) message: (@"rejecting a future with nilptr should throw PromiseNilRejectionException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtClassNilResolution) message: (@"Promise.resolved(nilptr) should throw PromiseNilResolutionValueException")];
    [AsyncRuntimeTestSupport assertCondition: (caughtClassNilRejection) message: (@"Promise.rejected(nilptr) should throw PromiseNilRejectionException")];
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

ASYNC_RUNTIME_SYNC_TEST(default_scheduler_lifecycle)
ASYNC_RUNTIME_SYNC_TEST(coroutine_roundtrip_states)
ASYNC_RUNTIME_SYNC_TEST(coroutine_return_short_circuits)
ASYNC_RUNTIME_SYNC_TEST(coroutine_exception_propagation)
ASYNC_RUNTIME_SYNC_TEST(coroutine_fast_enumeration)
ASYNC_RUNTIME_SYNC_TEST(coroutine_default_stack_size)
ASYNC_RUNTIME_SYNC_TEST(future_await_outside_task)
ASYNC_RUNTIME_SYNC_TEST(future_resolution_guards)
ASYNC_RUNTIME_SYNC_TEST(future_state_access_guards)
ASYNC_RUNTIME_SYNC_TEST(future_nil_resolution_and_rejection)
ASYNC_RUNTIME_SYNC_TEST(async_unit_singleton)
ASYNC_RUNTIME_SYNC_TEST(async_scheduler_invalid_initialization)

#pragma clang assume_nonnull end
