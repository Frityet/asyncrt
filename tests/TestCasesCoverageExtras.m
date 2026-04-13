#import "TestSupport.h"

#pragma clang assume_nonnull begin

@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;

@interface AsyncScheduler (CoverageExtras)
- (void)_drainReadyTasks;
- (void)_resumeTask: (Task *)task [[direct]];
@end

@interface AsyncScope (CoverageExtras)
- (void)_installDeadlineTimerIfNeeded [[direct]];
- (void)_invalidateDeadlineTimerIfNeeded [[direct]];
@end

[[subclassing_restricted]]
@interface CoverageCoroutineHarness : OFObject

@property(nonatomic) enum CoroutineStatus status;
@property(retain, nonatomic) id nillable returnedObject;
@property(retain, nonatomic) id nillable yieldedObject;

- (id nillable)resume;

@end

@implementation CoverageCoroutineHarness {
    enum CoroutineStatus _status;
    id _returnedObject;
    id _yieldedObject;
}

@synthesize status = _status;
@synthesize returnedObject = _returnedObject;
@synthesize yieldedObject = _yieldedObject;

- (id nillable)resume
{
    return _yieldedObject;
}

@end

[[subclassing_restricted]]
@interface CoverageSchedulerTaskHarness : OFObject

@property(nonatomic) bool isResolved;
@property(retain, nonatomic) id coroutine;
@property(retain, nonatomic) AsyncScope *nillable resumedScope;
@property(nonatomic) enum PromiseStatus status;
@property(retain, nonatomic) OFException *nillable rejectionException;
@property(nonatomic) enum AsyncTaskExecutionState executionState;
@property(copy, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) size_t captureCount;
@property(readonly, nonatomic) size_t rejectCount;
@property(readonly, nonatomic) size_t resolveCount;

- (id)_coroutineObject;
- (AsyncScope *nillable)_resumeScopeContext;
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState
                 waitReason: (OFString *nillable)waitReason;
- (void)_captureCurrentScopeContext;
- (void)_rejectTaskWithException: (OFException *)exception;
- (void)_resolveFromCompletion: (AsyncPromiseCompletion *)completion;

@end

@implementation CoverageSchedulerTaskHarness {
    bool _resolved;
    id _coroutine;
    AsyncScope *_resumedScope;
    enum PromiseStatus _status;
    OFException *_rejectionException;
    enum AsyncTaskExecutionState _executionState;
    OFString *_waitReason;
    size_t _captureCount;
    size_t _rejectCount;
    size_t _resolveCount;
}

@synthesize isResolved = _resolved;
@synthesize coroutine = _coroutine;
@synthesize resumedScope = _resumedScope;
@synthesize status = _status;
@synthesize rejectionException = _rejectionException;
@synthesize executionState = _executionState;
@synthesize waitReason = _waitReason;
@synthesize captureCount = _captureCount;
@synthesize rejectCount = _rejectCount;
@synthesize resolveCount = _resolveCount;

- (id)_coroutineObject
{
    return _coroutine;
}

- (AsyncScope *nillable)_resumeScopeContext
{
    return _resumedScope;
}

- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState
                 waitReason: (OFString *nillable)waitReason
{
    _executionState = executionState;
    _waitReason = [waitReason copy];
}

- (void)_captureCurrentScopeContext
{
    _captureCount++;
}

- (void)_rejectTaskWithException: (OFException *)exception
{
    _rejectCount++;
    _resolved = true;
    _status = PromiseStatus_REJECTED;
    _rejectionException = exception;
}

- (void)_resolveFromCompletion: (AsyncPromiseCompletion *)completion
{
    _resolveCount++;
    _resolved = true;
    if (completion.exception != nilptr) {
        _status = PromiseStatus_REJECTED;
        _rejectionException = completion.exception;
    } else {
        _status = PromiseStatus_FULFILLED;
    }
}

@end

[[subclassing_restricted]]
@interface CoverageScopeOwnerTaskHarness : OFObject

@property(retain, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) size_t interruptCount;
@property(readonly, nonatomic) size_t pushCount;
@property(readonly, nonatomic) size_t popCount;
@property(readonly, nonatomic) size_t captureCount;

- (void)_interruptForScopeCancellation;
- (void)_pushCancellationSuppression;
- (void)_popCancellationSuppression;
- (void)_captureCurrentScopeContext;

@end

@implementation CoverageScopeOwnerTaskHarness {
    AsyncScheduler *_scheduler;
    size_t _interruptCount;
    size_t _pushCount;
    size_t _popCount;
    size_t _captureCount;
}

@synthesize scheduler = _scheduler;
@synthesize interruptCount = _interruptCount;
@synthesize pushCount = _pushCount;
@synthesize popCount = _popCount;
@synthesize captureCount = _captureCount;

- (void)_interruptForScopeCancellation
{
    _interruptCount++;
}

- (void)_pushCancellationSuppression
{
    _pushCount++;
}

- (void)_popCancellationSuppression
{
    _popCount++;
}

- (void)_captureCurrentScopeContext
{
    _captureCount++;
}

@end

[[subclassing_restricted]]
@interface CoverageChannelSendRegistrationHarness : OFObject

@property(retain, nonatomic) id value;
@property(nonatomic) bool isClosed;
@property(readonly, nonatomic) size_t deliveredCount;
@property(readonly, nonatomic) size_t closedCount;

- (void)signalDelivered;
- (void)signalClosed;

@end

@implementation CoverageChannelSendRegistrationHarness {
    id _value;
    bool _closed;
    size_t _deliveredCount;
    size_t _closedCount;
}

@synthesize value = _value;
@synthesize isClosed = _closed;
@synthesize deliveredCount = _deliveredCount;
@synthesize closedCount = _closedCount;

- (void)signalDelivered
{
    _deliveredCount++;
}

- (void)signalClosed
{
    _closed = true;
    _closedCount++;
}

@end

[[subclassing_restricted]]
@interface CoverageChannelReceiveRegistrationHarness : OFObject

@property(retain, nonatomic) id nillable receivedValue;
@property(nonatomic) bool hasReceivedValue;
@property(nonatomic) bool isClosed;
@property(readonly, nonatomic) size_t closedCount;

- (void)signalReceivedValue: (id)value;
- (void)signalClosed;

@end

@implementation CoverageChannelReceiveRegistrationHarness {
    id _receivedValue;
    bool _hasReceivedValue;
    bool _closed;
    size_t _closedCount;
}

@synthesize receivedValue = _receivedValue;
@synthesize hasReceivedValue = _hasReceivedValue;
@synthesize isClosed = _closed;
@synthesize closedCount = _closedCount;

- (void)signalReceivedValue: (id)value
{
    _receivedValue = value;
    _hasReceivedValue = true;
}

- (void)signalClosed
{
    _closed = true;
    _closedCount++;
}

@end

static void pump_scheduler_until(AsyncScheduler *scheduler, bool (^condition)(void))
{
    for (size_t iteration = 0; iteration < 200 and not condition(); iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }
}

static void runtime_internal_description_coverage(void)
{
    auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    auto ownerTask = [[CoverageScopeOwnerTaskHarness alloc] init];
    ownerTask.scheduler = scheduler;
    auto channel = [[AsyncChannel alloc] initWithCapacity: 1];
    auto unnamedScope = [[AsyncScope alloc] initWithScheduler: scheduler
                                                    ownerTask: (Task *)ownerTask
                                                  parentScope: nilptr
                                                         name: nilptr
                                                     deadline: nilptr];
    auto namedScope = [[AsyncScope alloc] initWithScheduler: scheduler
                                                  ownerTask: (Task *)ownerTask
                                                parentScope: nilptr
                                                       name: @"named-scope"
                                                   deadline: nilptr];
    auto namedTask = [[Task alloc] initWithScheduler: scheduler
                                               scope: nilptr
                                                name: @"named-task"
                                               block: ^id {
                                                   return @"unused";
                                               }];
    auto unnamedTask = [[Task alloc] initWithScheduler: scheduler
                                                 scope: nilptr
                                                  name: nilptr
                                                 block: ^id {
                                                     return @"unused";
                                                 }];
    auto promise = [Promise resolved: @"ready"];
    auto runtimeTask = [AsyncRuntime run: ^id(AsyncScope *) {
        return @"runtime-run";
    }];
    auto waitRegistration = [[AsyncTaskWaitRegistration alloc]
        initWithScheduler: scheduler
                     task: (Task *)ownerTask];
    auto promiseException = [[PromiseException alloc] initWithPromise: promise];
    auto alreadyResolvedException = [[PromiseAlreadyResolvedException alloc]
        initWithPromise: promise
          currentStatus: PromiseStatus_FULFILLED
        attemptedStatus: PromiseStatus_REJECTED];
    auto nilResolutionException = [[PromiseNilResolutionValueException alloc] initWithPromise: promise];
    auto nilRejectionException = [[PromiseNilRejectionException alloc] initWithPromise: promise];
    auto invalidStateException = [[PromiseInvalidStateAccessException alloc]
        initWithPromise: promise
              operation: @"read value"
                  status: PromiseStatus_PENDING];
    auto awaitOutsideTaskException = [[PromiseAwaitOutsideTaskException alloc] initWithPromise: promise];
    auto selfAwaitException = [[PromiseSelfAwaitException alloc] initWithPromise: promise];
    auto continuationOutsideTaskException = [[PromiseContinuationOutsideTaskException alloc] initWithPromise: promise];
    auto schedulerException = [[AsyncSchedulerException alloc] initWithScheduler: scheduler];
    auto schedulerInitException = [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"invalid"];
    auto unsupportedYieldException = [[AsyncSchedulerUnsupportedYieldException alloc]
        initWithScheduler: scheduler
                      task: namedTask
             yieldedObject: @"yielded"];
    auto scopeException = [[AsyncScopeException alloc]
        initWithScope: namedScope
           exceptions: @[[[TestRejectionException alloc] init]]];
    auto timeoutException = [[AsyncTimeoutException alloc]
        initWithScope: namedScope
                  deadline: [OFDate dateWithTimeIntervalSinceNow: 0.05]];
    auto taskReturnedNilException = [[TaskReturnedNilException alloc] initWithTask: namedTask];
    auto taskCancelledException = [[TaskCancelledException alloc] initWithTask: namedTask];
    auto channelClosedException = [[AsyncChannelClosedException alloc]
        initWithChannel: channel
              operation: @"send"];
    bool caughtArm = false;
    bool caughtCancel = false;
    bool caughtScopeInit = false;
    bool caughtTaskSuppressionUnderflow = false;

    [Task checkCancellation];
    [namedTask _setExecutionState: AsyncTaskExecutionState_WAITING waitReason: @"waiting"];
    [unnamedTask _setExecutionState: AsyncTaskExecutionState_READY waitReason: nilptr];

    pump_scheduler_until(AsyncScheduler.defaultScheduler, ^bool {
        return runtimeTask.isResolved;
    });

    @try {
        [waitRegistration arm];
    } @catch (OFNotImplementedException *) {
        caughtArm = true;
    }

    @try {
        [waitRegistration cancel];
    } @catch (OFNotImplementedException *) {
        caughtCancel = true;
    }

    @try {
        (void)[[AsyncScopeException alloc] initWithScope: unnamedScope exceptions: @[]];
    } @catch (OFInvalidArgumentException *) {
        caughtScopeInit = true;
    }

    @try {
        [unnamedTask _popCancellationSuppression];
    } @catch (OFOutOfRangeException *) {
        caughtTaskSuppressionUnderflow = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtArm and caughtCancel)
                                     message: (@"Base wait registrations should throw until subclasses override arm/cancel")];
    [AsyncRuntimeTestSupport assertCondition: (caughtScopeInit)
                                     message: (@"AsyncScopeException should reject empty exception lists")];
    [AsyncRuntimeTestSupport assertCondition: (caughtTaskSuppressionUnderflow)
                                     message: (@"Tasks should reject cancellation suppression underflow")];
    [AsyncRuntimeTestSupport assertCondition: ([runtimeTask.value isEqual: @"runtime-run"])
                                     message: (@"AsyncRuntime +run: should schedule work on the default scheduler")];

    [AsyncRuntimeTestSupport assertCondition: ([[Promise describeStatus: PromiseStatus_REJECTED] isEqual: @"REJECTED"])
                                     message: (@"Promises should describe rejected state explicitly")];
    [AsyncRuntimeTestSupport assertCondition: ([[Task describeExecutionState: AsyncTaskExecutionState_READY] isEqual: @"READY"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_RUNNING] isEqual: @"RUNNING"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_WAITING] isEqual: @"WAITING"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_RESOLVED] isEqual: @"RESOLVED"])
                                     message: (@"Tasks should describe every execution state explicitly")];

    [AsyncRuntimeTestSupport assertCondition: ([promise.description containsString: @"FULFILLED"])
                                     message: (@"Promises should describe their current status")];
    [AsyncRuntimeTestSupport assertCondition: ([promiseException.description containsString: @"PromiseException"])
                                     message: (@"PromiseException should describe the wrapped promise")];
    [AsyncRuntimeTestSupport assertCondition: ([alreadyResolvedException.description containsString: @"cannot transition"])
                                     message: (@"PromiseAlreadyResolvedException should mention the attempted transition")];
    [AsyncRuntimeTestSupport assertCondition: ([nilResolutionException.description containsString: @"fulfilled with nilptr"])
                                     message: (@"PromiseNilResolutionValueException should describe nil resolution failures")];
    [AsyncRuntimeTestSupport assertCondition: ([nilRejectionException.description containsString: @"rejected with nilptr"])
                                     message: (@"PromiseNilRejectionException should describe nil rejection failures")];
    [AsyncRuntimeTestSupport assertCondition: ([invalidStateException.description containsString: @"read value"])
                                     message: (@"PromiseInvalidStateAccessException should describe the invalid operation")];
    [AsyncRuntimeTestSupport assertCondition: ([awaitOutsideTaskException.description containsString: @"outside a Task"])
                                     message: (@"PromiseAwaitOutsideTaskException should describe the task requirement")];
    [AsyncRuntimeTestSupport assertCondition: ([selfAwaitException.description containsString: @"await itself"])
                                     message: (@"PromiseSelfAwaitException should describe the self-await guard")];
    [AsyncRuntimeTestSupport assertCondition: ([continuationOutsideTaskException.description containsString: @"explicit scheduler"])
                                     message: (@"PromiseContinuationOutsideTaskException should describe the scheduler requirement")];

    [AsyncRuntimeTestSupport assertCondition: ([schedulerException.description containsString: @"AsyncSchedulerException"])
                                     message: (@"AsyncSchedulerException should describe the offending scheduler")];
    [AsyncRuntimeTestSupport assertCondition: ([schedulerInitException.description containsString: @"invalid"])
                                     message: (@"AsyncSchedulerInvalidInitializationException should include its reason")];
    [AsyncRuntimeTestSupport assertCondition: ([unsupportedYieldException.description containsString: @"unsupported yield"])
                                     message: (@"AsyncSchedulerUnsupportedYieldException should describe the yielded object")];
    [AsyncRuntimeTestSupport assertCondition: ([scheduler.description containsString: scheduler.mode]
        and [scheduler.describe containsString: scheduler.mode])
                                     message: (@"Schedulers should describe their current run loop mode")];

    [AsyncRuntimeTestSupport assertCondition: ([scopeException.description containsString: @"primary"])
                                     message: (@"AsyncScopeException should describe the primary failure")];
    [AsyncRuntimeTestSupport assertCondition: ([timeoutException.description containsString: @"exceeded deadline"])
                                     message: (@"AsyncTimeoutException should describe the expired deadline")];
    [AsyncRuntimeTestSupport assertCondition: ([namedScope.description containsString: @"named-scope"])
                                     message: (@"Named scopes should include their debug name in descriptions")];
    [AsyncRuntimeTestSupport assertCondition: ([unnamedScope.description containsString: @"AsyncScope"]
        and unnamedScope._debugName == nilptr)
                                     message: (@"Unnamed scopes should still render a stable description")];

    [AsyncRuntimeTestSupport assertCondition: ([taskReturnedNilException.description containsString: @"returned nilptr"])
                                     message: (@"TaskReturnedNilException should describe nil return failures")];
    [AsyncRuntimeTestSupport assertCondition: ([taskCancelledException.description containsString: @"cancellation checkpoint"])
                                     message: (@"TaskCancelledException should describe cancellation checkpoints")];
    [AsyncRuntimeTestSupport assertCondition: (not [namedTask _isCancellationRequested])
                                     message: (@"Fresh tasks should report that cancellation was not requested")];
    [AsyncRuntimeTestSupport assertCondition: ([namedTask.description containsString: @"named-task"]
        and [unnamedTask.description containsString: @"<Task"])
                                     message: (@"Task descriptions should render both named and unnamed tasks")];

    [AsyncRuntimeTestSupport assertCondition: ([channelClosedException.description containsString: @"after close"])
                                     message: (@"AsyncChannelClosedException should describe the rejected operation")];
    [AsyncRuntimeTestSupport assertCondition: ([channel.description containsString: @"capacity=1"]
        and not channel.isClosed)
                                     message: (@"Channels should describe their capacity and closed state")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncUnit.unit.description isEqual: @"AsyncUnit"])
                                     message: (@"AsyncUnit should preserve its singleton description")];

    [scheduler shutdown];
}

static void promise_continuation_and_scope_internal_branches(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFDate *earlierDeadline = [OFDate dateWithTimeIntervalSinceNow: 0.10];
    OFDate *laterDeadline = [OFDate dateWithTimeIntervalSinceNow: 0.20];
    bool caughtMappedReject = false;
    bool caughtFlatMappedReject = false;
    bool caughtInvalidAll = false;
    bool caughtInvalidRace = false;
    bool caughtThrownTask = false;
    bool caughtScopeFailure = false;
    block_reference bool inheritedParentDeadline = false;
    auto mappedRejected = [[Promise rejected: [[TestRejectionException alloc] init]]
        mapOnScheduler: scheduler
              transform: ^id(id) {
                  return @"unreachable";
              }];
    auto flatMappedRejected = [[Promise rejected: [[TestRejectionException alloc] init]]
        flatMapOnScheduler: scheduler
                     transform: ^id<PromiseLike>(id) {
                         return [Promise resolved: @"unreachable"];
                     }];
    auto recoveredResolved = [[Promise resolved: @"kept"]
        recoverOnScheduler: scheduler
                   handler: ^id(OFException *) {
                       return @"changed";
                   }];
    auto flatRecoveredResolved = [[Promise resolved: @"still-kept"]
        flatRecoverOnScheduler: scheduler
                       handler: ^id<PromiseLike>(OFException *) {
                           return [Promise resolved: @"changed"];
                       }];
    auto spawnedWithoutName = [rootScope spawn: ^id {
        return @"spawned";
    }];
    auto throwingTask = [[Task alloc] initWithScheduler: scheduler
                                                  scope: nilptr
                                                   name: @"throws"
                                                  block: ^id {
        @throw [[TestRejectionException alloc] init];
        return AsyncUnit.unit;
    }];

    @try {
        (void)mappedRejected.await;
    } @catch (TestRejectionException *) {
        caughtMappedReject = true;
    }

    @try {
        (void)flatMappedRejected.await;
    } @catch (TestRejectionException *) {
        caughtFlatMappedReject = true;
    }

    @try {
        (void)[Promise all: (OFArray<id<PromiseLike>> *)@[@"bad"]];
    } @catch (OFInvalidArgumentException *) {
        caughtInvalidAll = true;
    }

    @try {
        (void)[Promise race: (OFArray<id<PromiseLike>> *)@[@"bad"]];
    } @catch (OFInvalidArgumentException *) {
        caughtInvalidRace = true;
    }

    @try {
        (void)throwingTask.await;
    } @catch (TestRejectionException *) {
        caughtThrownTask = true;
    }

    @try {
        (void)[rootScope withChildScopeNamed: @"body-failure" block: ^id(AsyncScope *) {
            @throw [[TestRejectionException alloc] init];
        }];
    } @catch (AsyncScopeException *exception) {
        caughtScopeFailure = [exception.primaryException isKindOfClass: TestRejectionException.class];
    }

    (void)[rootScope withDeadline: earlierDeadline block: ^id(AsyncScope *deadlineScope) {
        (void)[deadlineScope withDeadline: laterDeadline block: ^id(AsyncScope *childScope) {
            inheritedParentDeadline = ([childScope.deadline compare: $assert_nonnil(deadlineScope.deadline)] == OFOrderedSame);
            return AsyncUnit.unit;
        }];
        return AsyncUnit.unit;
    }];

    [AsyncRuntimeTestSupport assertCondition: (caughtMappedReject and caughtFlatMappedReject)
                                     message: (@"Promise continuations should propagate rejected inputs across map and flatMap")];
    [AsyncRuntimeTestSupport assertCondition: ([[recoveredResolved await] isEqual: @"kept"]
        and [[flatRecoveredResolved await] isEqual: @"still-kept"])
                                     message: (@"Recover continuations should leave fulfilled promises unchanged")];
    [AsyncRuntimeTestSupport assertCondition: (caughtInvalidAll and caughtInvalidRace)
                                     message: (@"Promise collection helpers should reject non-promise inputs")];
    [AsyncRuntimeTestSupport assertCondition: ([[spawnedWithoutName await] isEqual: @"spawned"])
                                     message: (@"Scopes should support the spawn: convenience overload")];
    [AsyncRuntimeTestSupport assertCondition: ([[rootScope withChildScope: ^id(AsyncScope *) {
        return @"child-result";
    }] isEqual: @"child-result"])
                                     message: (@"Scopes should support the withChildScope: convenience overload")];
    [AsyncRuntimeTestSupport assertCondition: (caughtThrownTask)
                                     message: (@"Thrown task bodies should reject through task completion handling")];
    [AsyncRuntimeTestSupport assertCondition: (caughtScopeFailure)
                                     message: (@"Thrown child-scope bodies should aggregate into AsyncScopeException")];
    [AsyncRuntimeTestSupport assertCondition: (inheritedParentDeadline)
                                     message: (@"Nested scopes should inherit an earlier parent deadline")];
    [AsyncRuntimeTestSupport assertCondition: ([scheduler sleepUntilDate: [OFDate dateWithTimeIntervalSinceNow: 0.01]].await == AsyncUnit.unit)
                                     message: (@"Schedulers should wait until future dates instead of taking the immediate shortcut")];
}

static void scheduler_channel_private_branches(void)
{
    auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    auto resolvedTask = [[CoverageSchedulerTaskHarness alloc] init];
    auto shutDownTask = [[CoverageSchedulerTaskHarness alloc] init];
    auto invalidCompletionCoroutine = [[CoverageCoroutineHarness alloc] init];
    auto invalidCompletionTask = [[CoverageSchedulerTaskHarness alloc] init];
    auto unsupportedYieldCoroutine = [[CoverageCoroutineHarness alloc] init];
    auto unsupportedYieldTask = [[CoverageSchedulerTaskHarness alloc] init];
    auto ownerTask = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto otherOwnerTask = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto cancelledScopeOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto finishedScopeOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto deadlineScopeOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto cancelledScope = [[AsyncScope alloc] initWithScheduler: scheduler ownerTask: (Task *)cancelledScopeOwner parentScope: nilptr name: @"cancelled" deadline: nilptr];
    auto finishedScope = [[AsyncScope alloc] initWithScheduler: scheduler ownerTask: (Task *)finishedScopeOwner parentScope: nilptr name: @"finished" deadline: nilptr];
    auto deadlineScope = [[AsyncScope alloc] initWithScheduler: scheduler ownerTask: (Task *)deadlineScopeOwner parentScope: nilptr name: @"deadline" deadline: [OFDate dateWithTimeIntervalSinceNow: 1]];
    auto scope = [[AsyncScope alloc] initWithScheduler: scheduler ownerTask: (Task *)ownerTask parentScope: nilptr name: @"scope" deadline: nilptr];
    auto channel = [[AsyncChannel alloc] initWithCapacity: 1];
    auto rendezvousChannel = [[AsyncChannel alloc] initWithCapacity: 0];
    auto closedChannel = [[AsyncChannel alloc] initWithCapacity: 1];
    auto waitingReceiver = [[CoverageChannelReceiveRegistrationHarness alloc] init];
    auto sendToWaitingReceiver = [[CoverageChannelSendRegistrationHarness alloc] init];
    auto bufferedSend = [[CoverageChannelSendRegistrationHarness alloc] init];
    auto bufferedReceive = [[CoverageChannelReceiveRegistrationHarness alloc] init];
    auto rendezvousSend = [[CoverageChannelSendRegistrationHarness alloc] init];
    auto rendezvousReceive = [[CoverageChannelReceiveRegistrationHarness alloc] init];
    auto closedSend = [[CoverageChannelSendRegistrationHarness alloc] init];
    auto closedReceive = [[CoverageChannelReceiveRegistrationHarness alloc] init];
    bool caughtSendOutsideTask = false;
    bool caughtReceiveOutsideTask = false;
    bool caughtSpawnOutsideTask = false;
    bool caughtSpawnSchedulerMismatch = false;
    bool caughtChildScopeOutsideTask = false;
    bool caughtChildScopeSchedulerMismatch = false;
    bool caughtDeadlineOutsideTask = false;
    bool caughtDeadlineSchedulerMismatch = false;
    bool caughtRegisterAfterCancel = false;
    bool caughtRegisterAfterBody = false;
    Task *previousTask = async_current_task;

    ownerTask.scheduler = scheduler;
    otherOwnerTask.scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    cancelledScopeOwner.scheduler = scheduler;
    finishedScopeOwner.scheduler = scheduler;
    deadlineScopeOwner.scheduler = scheduler;

    resolvedTask.isResolved = true;
    invalidCompletionCoroutine.status = CoroutineStatus_DEAD;
    invalidCompletionCoroutine.returnedObject = @"bad-completion";
    invalidCompletionTask.coroutine = invalidCompletionCoroutine;
    unsupportedYieldCoroutine.status = CoroutineStatus_SUSPENDED;
    unsupportedYieldCoroutine.yieldedObject = @"invalid-yield";
    unsupportedYieldTask.coroutine = unsupportedYieldCoroutine;

    sendToWaitingReceiver.value = @"delivered";
    bufferedSend.value = @"buffered";
    rendezvousSend.value = @"rendezvous";
    closedSend.value = @"closed";

    [scheduler _drainReadyTasks];
    [scheduler _enqueueTask: (Task *)resolvedTask];
    [scheduler _resumeTask: (Task *)resolvedTask];

    [scheduler shutdown];
    [scheduler _enqueueTask: (Task *)shutDownTask];

    scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    ownerTask.scheduler = scheduler;
    cancelledScopeOwner.scheduler = scheduler;
    finishedScopeOwner.scheduler = scheduler;
    deadlineScopeOwner.scheduler = scheduler;

    [scheduler _resumeTask: (Task *)invalidCompletionTask];
    [scheduler _resumeTask: (Task *)unsupportedYieldTask];

    [deadlineScope _installDeadlineTimerIfNeeded];
    [deadlineScope _invalidateDeadlineTimerIfNeeded];
    [deadlineScope _cancelFromTimeoutWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01]];
    [deadlineScope _cancelFromTimeoutWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01]];

    [cancelledScope cancel];

    (void)[finishedScope _runScopeBody: ^id(AsyncScope *) {
        return AsyncUnit.unit;
    }];

    @try {
        [channel send: @"outside-task"];
    } @catch (OFInvalidArgumentException *) {
        caughtSendOutsideTask = true;
    }

    @try {
        (void)[channel receive];
    } @catch (OFInvalidArgumentException *) {
        caughtReceiveOutsideTask = true;
    }

    @try {
        [scope spawn: ^id {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtSpawnOutsideTask = true;
    }

    @try {
        (void)[scope withChildScope: ^id(AsyncScope *) {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtChildScopeOutsideTask = true;
    }

    @try {
        (void)[scope withDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01] block: ^id(AsyncScope *) {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtDeadlineOutsideTask = true;
    }

    async_current_task = (Task *)otherOwnerTask;
    @try {
        [scope spawn: ^id {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtSpawnSchedulerMismatch = true;
    }

    @try {
        (void)[scope withChildScopeNamed: @"mismatch" block: ^id(AsyncScope *) {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtChildScopeSchedulerMismatch = true;
    }

    @try {
        (void)[scope withDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01] block: ^id(AsyncScope *) {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtDeadlineSchedulerMismatch = true;
    } @finally {
        async_current_task = previousTask;
    }

    @try {
        [cancelledScope _registerChildTask: (Task *)ownerTask];
    } @catch (OFInvalidArgumentException *) {
        caughtRegisterAfterCancel = true;
    }

    @try {
        [finishedScope _registerChildTask: (Task *)ownerTask];
    } @catch (OFInvalidArgumentException *) {
        caughtRegisterAfterBody = true;
    }

    [channel _armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)waitingReceiver];
    [channel _armSendRegistration: (AsyncChannelSendWaitRegistration *)sendToWaitingReceiver];

    [channel _armSendRegistration: (AsyncChannelSendWaitRegistration *)bufferedSend];
    [channel _armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)bufferedReceive];

    [rendezvousChannel _armSendRegistration: (AsyncChannelSendWaitRegistration *)rendezvousSend];
    [rendezvousChannel _armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)rendezvousReceive];

    [closedChannel close];
    [closedChannel close];
    [closedChannel _armSendRegistration: (AsyncChannelSendWaitRegistration *)closedSend];
    [closedChannel _armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)closedReceive];

    [AsyncRuntimeTestSupport assertCondition: (invalidCompletionTask.rejectCount == 1
        and [invalidCompletionTask.rejectionException isKindOfClass: TaskReturnedNilException.class])
                                     message: (@"Schedulers should reject dead coroutines that return invalid completion objects")];
    [AsyncRuntimeTestSupport assertCondition: (unsupportedYieldTask.rejectCount == 1
        and [unsupportedYieldTask.rejectionException isKindOfClass: AsyncSchedulerUnsupportedYieldException.class])
                                     message: (@"Schedulers should reject unsupported yielded objects")];
    [AsyncRuntimeTestSupport assertCondition: (deadlineScopeOwner.interruptCount == 1)
                                     message: (@"Timeout cancellation should only interrupt the owner task once")];
    [AsyncRuntimeTestSupport assertCondition: (caughtSendOutsideTask and caughtReceiveOutsideTask)
                                     message: (@"Channels should reject send and receive outside a task context")];
    [AsyncRuntimeTestSupport assertCondition: (caughtSpawnOutsideTask
        and caughtSpawnSchedulerMismatch
        and caughtChildScopeOutsideTask
        and caughtChildScopeSchedulerMismatch
        and caughtDeadlineOutsideTask
        and caughtDeadlineSchedulerMismatch)
                                     message: (@"Scopes should reject spawn, child-scope, and deadline helpers outside the owning task scheduler")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRegisterAfterCancel and caughtRegisterAfterBody)
                                     message: (@"Scopes should reject registering child tasks after cancellation or after the body finishes")];
    [AsyncRuntimeTestSupport assertCondition: (waitingReceiver.hasReceivedValue
        and [waitingReceiver.receivedValue isEqual: @"delivered"]
        and sendToWaitingReceiver.deliveredCount == 1)
                                     message: (@"Channel send arm logic should hand values directly to waiting receivers")];
    [AsyncRuntimeTestSupport assertCondition: (bufferedSend.deliveredCount == 1
        and bufferedReceive.hasReceivedValue
        and [bufferedReceive.receivedValue isEqual: @"buffered"])
                                     message: (@"Buffered channels should deliver buffered registrations through private arm helpers")];
    [AsyncRuntimeTestSupport assertCondition: (rendezvousSend.deliveredCount == 1
        and rendezvousReceive.hasReceivedValue
        and [rendezvousReceive.receivedValue isEqual: @"rendezvous"])
                                     message: (@"Receive arm logic should drain waiting senders in rendezvous channels")];
    [AsyncRuntimeTestSupport assertCondition: (closedSend.closedCount == 1
        and closedSend.isClosed
        and closedReceive.closedCount == 1
        and closedReceive.isClosed)
                                     message: (@"Closed channels should close both send and receive registrations immediately")];

    [scheduler shutdown];
    [otherOwnerTask.scheduler shutdown];
}

static void utility_internal_branch_coverage(void)
{
    auto none = Optional.none;
    auto some = [Optional some: @"payload"];
    auto other = [Optional some: @"other"];
    auto lowPointer = [Pointer from: (const void *)0x10];
    auto highPointer = [Pointer from: (const void *)0x20];
    auto sameAsHighPointer = [Pointer from: (const void *)0x20];
    bool caughtNilOptionalValue = false;
    bool caughtNilOptionalFallback = false;
    bool caughtNilSome = false;

    @try {
        (void)none.value;
    } @catch (OFOutOfRangeException *) {
        caughtNilOptionalValue = true;
    }

    @try {
        (void)[some valueOr: nilptr];
    } @catch (OFInvalidArgumentException *) {
        caughtNilOptionalFallback = true;
    }

    @try {
        (void)[Optional some: nilptr];
    } @catch (OFInvalidArgumentException *) {
        caughtNilSome = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilOptionalValue and caughtNilOptionalFallback and caughtNilSome)
                                     message: (@"Optional should reject nil payloads, nil fallbacks, and reading missing values")];
    [AsyncRuntimeTestSupport assertCondition: ([[some valueOr: @"fallback"] isEqual: @"payload"]
        and [[none valueOr: @"fallback"] isEqual: @"fallback"])
                                     message: (@"Optional should return either its stored value or the provided fallback")];
    [AsyncRuntimeTestSupport assertCondition: ([some isEqual: some]
        and [some isEqual: @"payload"]
        and not [some isEqual: other]
        and not [none isEqual: some]
        and not [some isEqual: @42])
                                     message: (@"Optional equality should cover self, raw-value, nil, and type-mismatch comparisons")];
    [AsyncRuntimeTestSupport assertCondition: ([none.description containsString: @"<none>"])
                                     message: (@"Optional descriptions should spell out the empty state")];

    [AsyncRuntimeTestSupport assertCondition: ([highPointer compare: lowPointer] == OFOrderedDescending
        and [highPointer compare: sameAsHighPointer] == OFOrderedSame)
                                     message: (@"Pointer comparisons should cover both descending and equal orderings")];
    [AsyncRuntimeTestSupport assertCondition: ([highPointer isEqual: highPointer]
        and not [highPointer isEqual: @"not-data"])
                                     message: (@"Pointer equality should handle self-comparisons and non-data values")];
}

ASYNC_RUNTIME_SYNC_TEST(runtime_internal_description_coverage)
ASYNC_RUNTIME_ASYNC_TEST(promise_continuation_and_scope_internal_branches)
ASYNC_RUNTIME_SYNC_TEST(scheduler_channel_private_branches)
ASYNC_RUNTIME_SYNC_TEST(utility_internal_branch_coverage)

#pragma clang assume_nonnull end
