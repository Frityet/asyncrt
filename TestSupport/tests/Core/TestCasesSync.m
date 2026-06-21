#import <TestSupport/TestSupport.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeSyncTests : OTTestCase @end

@implementation AsyncRuntimeSyncTests

- (void)test_shared_scheduler_is_process_managed
{
    AsyncScheduler *firstScheduler = [AsyncScheduler sharedScheduler];
    AsyncScheduler *sameScheduler = [AsyncScheduler sharedScheduler];
    block_reference AsyncScheduler *threadScheduler = nilptr;

    auto thread = [[OFThread alloc] initWithBlock: ^{
        threadScheduler = [AsyncScheduler sharedScheduler];
        return nilptr;
    }];

    [thread start];
    (void)[thread join];

    OTAssert((firstScheduler == sameScheduler), @"The managed scheduler should be memoized");
    OTAssert((threadScheduler == firstScheduler), @"Worker threads should see the same managed scheduler");

    [AsyncRuntime shutdown];

    AsyncScheduler *replacementScheduler = [AsyncScheduler sharedScheduler];
    OTAssert((replacementScheduler != nilptr), @"Shutdown should leave the managed scheduler recreatable");
    OTAssert((replacementScheduler == [AsyncScheduler sharedScheduler]), @"Recreated managed schedulers should still be memoized");

    [AsyncRuntime shutdown];
}

- (void)test_runtime_run_until_task_completes_drives_shared_scheduler
{
    block_reference bool ran = false;
    auto task = [AsyncRuntime run: ^id {
        ran = true;
        return @"done";
    }];

    [AsyncRuntime runUntilTaskCompletes: task];

    OTAssert(ran, @"AsyncRuntime should run tasks on the managed scheduler");
    OTAssert((task.status == AsyncTaskStatus_FULFILLED), @"Completed runtime tasks should fulfill");
    OTAssert(([[task _internalTaskState].value isEqual: @"done"]), @"Completed runtime task values should remain readable");

    [AsyncRuntime shutdown];
}

- (void)test_coroutine_roundtrip_states
{
    auto coroutine = [[AsyncCoroutine<OFString *> alloc] initWithBlock: ^OFString *(AsyncCoroutine<OFString *> *co) {
        [co yield: @"first"];
        [co yield: @"second"];
        return @"done";
    }];

    OTAssert((coroutine.status == AsyncCoroutineStatus_READY), @"New coroutines should start ready");
    OTAssert(([[coroutine resume] isEqual: @"first"]), @"Coroutine resume should return the first yield");
    OTAssert((coroutine.status == AsyncCoroutineStatus_SUSPENDED), @"Yielding should suspend the coroutine");
    OTAssert(([[coroutine resume] isEqual: @"second"]), @"Coroutine resume should preserve state");
    OTAssert(([[coroutine resume] isEqual: @"done"]), @"Coroutine resume should return final values");
    OTAssert((coroutine.status == AsyncCoroutineStatus_DEAD), @"Finished coroutines should be dead");
    OTAssert(([coroutine.returnedObject isEqual: @"done"]), @"Returned objects should be retained for diagnostics");
}

- (void)test_coroutine_exception_propagates_to_resumer
{
    bool caught = false;
    auto coroutine = [[AsyncCoroutine alloc] initWithBlock: ^id(AsyncCoroutine<id> *co) {
        [co yield: @"before-throw"];
        @throw [[TestRejectionException alloc] init];
    }];

    OTAssert(([[coroutine resume] isEqual: @"before-throw"]), @"Coroutines should yield before throwing");

    @try {
        (void)[coroutine resume];
    } @catch (TestRejectionException *) {
        caught = true;
    }

    OTAssert(caught, @"Coroutine exceptions should propagate to the caller");
    OTAssert((coroutine.status == AsyncCoroutineStatus_DEAD), @"Thrown coroutine bodies should terminate the coroutine");
}

- (void)test_completion_source_state_guards
{
    auto completionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caughtSecondFulfill = false;
    bool caughtNilFulfill = false;
    bool caughtNilReject = false;

    [completionSource fulfill: @"ready"];

    @try {
        [completionSource fulfill: @"again"];
    } @catch (AsyncTaskAlreadyResolvedException *) {
        caughtSecondFulfill = true;
    }

    @try {
        [[[AsyncCompletionSource alloc] init] fulfill: nilptr];
    } @catch (AsyncTaskNilResolutionValueException *) {
        caughtNilFulfill = true;
    }

    @try {
        [[[AsyncCompletionSource alloc] init] reject: nilptr];
    } @catch (AsyncTaskNilRejectionException *) {
        caughtNilReject = true;
    }

    OTAssert((completionSource.task.status == AsyncTaskStatus_FULFILLED), @"Completion sources should expose fulfilled tasks");
    OTAssert(([[completionSource.task _internalTaskState].value isEqual: @"ready"]), @"Fulfilled values should be readable");
    OTAssert(caughtSecondFulfill, @"Completion sources should reject double resolution");
    OTAssert(caughtNilFulfill, @"Completion sources should reject nil fulfillment");
    OTAssert(caughtNilReject, @"Completion sources should reject nil rejection exceptions");
}

- (void)test_await_outside_runtime_is_rejected_for_pending_tasks
{
    auto completionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    bool caught = false;

    @try {
        (void)[completionSource.task await];
    } @catch (AsyncTaskAwaitOutsideTaskException *) {
        caught = true;
    }

    OTAssert(caught, @"Pending tasks should not be awaited outside a runtime task");
}

@end

#pragma clang assume_nonnull end
