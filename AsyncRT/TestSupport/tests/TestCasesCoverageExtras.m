#import "TestSupport.h"

#pragma clang assume_nonnull begin

@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;

@interface AsyncScheduler (CoverageExtras)
- (void)_drainReadyQueue;
- (void)_resumeTask: (Task *)task [[direct]];
@end

@interface AsyncTaskGroup (CoverageExtras)
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

- (id nillable)resume
{
    return _yieldedObject;
}

@end

[[subclassing_restricted]]
@interface CoverageSchedulerTaskHarness : OFObject

@property(nonatomic) bool isCompleted;
@property(retain, nonatomic) id coroutine;
@property(retain, nonatomic) AsyncTaskGroup *nillable resumedTaskGroup;
@property(nonatomic) enum AsyncTaskStatus status;
@property(retain, nonatomic) OFException *nillable failureException;
@property(nonatomic) enum AsyncTaskExecutionState executionState;
@property(copy, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) size_t captureCount;
@property(readonly, nonatomic) size_t rejectCount;
@property(readonly, nonatomic) size_t resolveCount;

- (id)_coroutineObject;
- (AsyncTaskGroup *nillable)_resumeTaskGroupContext;
- (void)_setExecutionState: (enum AsyncTaskExecutionState)executionState
                 waitReason: (OFString *nillable)waitReason;
- (void)_captureCurrentScopeContext;
- (void)_rejectTaskWithException: (OFException *)exception;
- (void)_resolveFromCompletion: (AsyncTaskExecutionCompletion *)completion;
- (bool)_markReadyQueued;
- (void)_clearReadyQueued;

@end

@implementation CoverageSchedulerTaskHarness {
    bool _isCompleted;
    id _coroutine;
    AsyncTaskGroup *_resumedTaskGroup;
    enum AsyncTaskStatus _status;
    OFException *_failureException;
    enum AsyncTaskExecutionState _executionState;
    OFString *_waitReason;
    size_t _captureCount;
    size_t _rejectCount;
    size_t _resolveCount;
    bool _readyQueued;
}

- (id)_coroutineObject
{
    return _coroutine;
}

- (AsyncTaskGroup *nillable)_resumeTaskGroupContext
{
    return _resumedTaskGroup;
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
    _isCompleted = true;
    _status = AsyncTaskStatus_REJECTED;
    _failureException = exception;
}

- (void)_resolveFromCompletion: (AsyncTaskExecutionCompletion *)completion
{
    _resolveCount++;
    _isCompleted = true;
    if (completion.exception != nilptr) {
        _status = AsyncTaskStatus_REJECTED;
        _failureException = completion.exception;
    } else {
        _status = AsyncTaskStatus_FULFILLED;
    }
}

- (bool)_markReadyQueued
{
    if (_readyQueued)
        return false;

    _readyQueued = true;
    return true;
}

- (void)_clearReadyQueued
{
    _readyQueued = false;
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
    bool _isClosed;
    size_t _deliveredCount;
    size_t _closedCount;
}

- (void)signalDelivered
{
    _deliveredCount++;
}

- (void)signalClosed
{
    _isClosed = true;
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
    bool _isClosed;
    size_t _closedCount;
}

- (void)signalReceivedValue: (id)value
{
    _receivedValue = value;
    _hasReceivedValue = true;
}

- (void)signalClosed
{
    _isClosed = true;
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

[[subclassing_restricted]]
@interface AsyncRuntimeCoverageExtrasTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeCoverageExtrasTests

- (void)test_runtime_internal_description_coverage
{
    auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    auto ownerTask = [[CoverageScopeOwnerTaskHarness alloc] init];
    ownerTask.scheduler = scheduler;
    auto channel = [[AsyncChannel alloc] initWithCapacity: 1];
    auto unnamedTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler
                                                            ownerTask: (Task *)ownerTask
                                                      parentTaskGroup: nilptr
                                                                 name: nilptr
                                                             deadline: nilptr];
    auto namedTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler
                                                          ownerTask: (Task *)ownerTask
                                                    parentTaskGroup: nilptr
                                                               name: @"named-scope"
                                                           deadline: nilptr];
    auto namedTask = [[Task alloc] initWithScheduler: scheduler
                                           taskGroup: nilptr
                                                name: @"named-task"
                                               block: ^id {
                                                   return @"unused";
                                               }];
    auto unnamedTask = [[Task alloc] initWithScheduler: scheduler
                                             taskGroup: nilptr
                                                  name: nilptr
                                                 block: ^id {
                                                     return @"unused";
                                                 }];
    auto task = [Task resolved: @"ready"];
    auto runtimeTask = [AsyncRuntime run: ^id(AsyncTaskGroup *) {
        return @"runtime-run";
    }];
    auto waitRegistration = [[AsyncTaskWaitRegistration alloc]
        initWithScheduler: scheduler
                     task: (Task *)ownerTask];
    auto taskException = [[AsyncTaskException alloc] initWithTask: task];
    auto alreadyResolvedException = [[AsyncTaskAlreadyResolvedException alloc]
        initWithTask: task
          currentStatus: AsyncTaskStatus_FULFILLED
        attemptedStatus: AsyncTaskStatus_REJECTED];
    auto nilResolutionException = [[AsyncTaskNilResolutionValueException alloc] initWithTask: task];
    auto nilRejectionException = [[AsyncTaskNilRejectionException alloc] initWithTask: task];
    auto invalidStateException = [[AsyncTaskInvalidStateAccessException alloc]
        initWithTask: task
              operation: @"read value"
                  status: AsyncTaskStatus_PENDING];
    auto awaitOutsideTaskException = [[AsyncTaskAwaitOutsideTaskException alloc] initWithTask: task];
    auto selfAwaitException = [[AsyncTaskSelfAwaitException alloc] initWithTask: task];
    auto continuationOutsideTaskException = [[AsyncTaskContinuationOutsideTaskException alloc] initWithTask: task];
    auto schedulerException = [[AsyncSchedulerException alloc] initWithScheduler: scheduler];
    auto schedulerInitException = [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"invalid"];
    auto unsupportedYieldException = [[AsyncSchedulerUnsupportedYieldException alloc]
        initWithScheduler: scheduler
                      task: namedTask
             yieldedObject: @"yielded"];
    auto timeoutException = [[AsyncTaskGroupTimeoutException alloc]
        initWithTaskGroup: namedTaskGroup
                  deadline: [OFDate dateWithTimeIntervalSinceNow: 0.05]];
    auto taskReturnedNilException = [[TaskReturnedNilException alloc] initWithTask: namedTask];
    auto taskCancelledException = [[TaskCancelledException alloc] initWithTask: namedTask];
    auto channelClosedException = [[AsyncChannelClosedException alloc]
        initWithChannel: channel
              operation: @"send"];
    bool caughtArm = false;
    bool caughtCancel = false;
    bool caughtTaskSuppressionUnderflow = false;

    [Task checkCancellation];
    [namedTask _setExecutionState: AsyncTaskExecutionState_WAITING waitReason: @"waiting"];
    [unnamedTask _setExecutionState: AsyncTaskExecutionState_READY waitReason: nilptr];

    pump_scheduler_until(AsyncScheduler.defaultScheduler, ^bool {
        return runtimeTask.isCompleted;
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
        [unnamedTask _popCancellationSuppression];
    } @catch (OFOutOfRangeException *) {
        caughtTaskSuppressionUnderflow = true;
    }

    OTAssert((caughtArm and caughtCancel), @"Base wait registrations should throw until subclasses override arm/cancel");
    OTAssert((caughtTaskSuppressionUnderflow), @"Tasks should reject cancellation suppression underflow");
    block_reference OFString *runtimeTaskResult = nilptr;
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
        (void)rootScope;
        runtimeTaskResult = [runtimeTask await];
    }];
    OTAssert(([runtimeTaskResult isEqual: @"runtime-run"]), @"AsyncRuntime +run: should schedule work on the default scheduler");

    OTAssert(([[Task describeStatus: AsyncTaskStatus_REJECTED] isEqual: @"REJECTED"]), @"Tasks should describe rejected state explicitly");
    OTAssert(([[Task describeExecutionState: AsyncTaskExecutionState_READY] isEqual: @"READY"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_RUNNING] isEqual: @"RUNNING"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_WAITING] isEqual: @"WAITING"]
        and [[Task describeExecutionState: AsyncTaskExecutionState_RESOLVED] isEqual: @"RESOLVED"]), @"Tasks should describe every execution state explicitly");

    OTAssert(([task.description containsString: @"FULFILLED"]), @"Tasks should describe their current status");
    OTAssert(([taskException.description containsString: @"AsyncTaskException"]), @"AsyncTaskException should describe the wrapped task");
    OTAssert(([alreadyResolvedException.description containsString: @"cannot transition"]), @"AsyncTaskAlreadyResolvedException should mention the attempted transition");
    OTAssert(([nilResolutionException.description containsString: @"fulfilled with nilptr"]), @"AsyncTaskNilResolutionValueException should describe nil resolution failures");
    OTAssert(([nilRejectionException.description containsString: @"rejected with nilptr"]), @"AsyncTaskNilRejectionException should describe nil rejection failures");
    OTAssert(([invalidStateException.description containsString: @"read value"]), @"AsyncTaskInvalidStateAccessException should describe the invalid operation");
    OTAssert(([awaitOutsideTaskException.description containsString: @"outside a Task"]), @"AsyncTaskAwaitOutsideTaskException should describe the task requirement");
    OTAssert(([selfAwaitException.description containsString: @"await itself"]), @"AsyncTaskSelfAwaitException should describe the self-await guard");
    OTAssert(([continuationOutsideTaskException.description containsString: @"explicit scheduler"]), @"AsyncTaskContinuationOutsideTaskException should describe the scheduler requirement");

    OTAssert(([schedulerException.description containsString: @"AsyncSchedulerException"]), @"AsyncSchedulerException should describe the offending scheduler");
    OTAssert(([schedulerInitException.description containsString: @"invalid"]), @"AsyncSchedulerInvalidInitializationException should include its reason");
    OTAssert(([unsupportedYieldException.description containsString: @"unsupported yield"]), @"AsyncSchedulerUnsupportedYieldException should describe the yielded object");
    OTAssert(([scheduler.description containsString: scheduler.mode]
        and [scheduler.describe containsString: scheduler.mode]), @"Schedulers should describe their current run loop mode");

    OTAssert(([timeoutException.description containsString: @"exceeded deadline"]), @"AsyncTaskGroupTimeoutException should describe the expired deadline");
    OTAssert(([namedTaskGroup.description containsString: @"named-scope"]), @"Named task groups should include their debug name in descriptions");
    OTAssert(([unnamedTaskGroup.description containsString: @"AsyncTaskGroup"]
        and unnamedTaskGroup._taskGroupNameForSnapshots == nilptr), @"Unnamed task groups should still render a stable description");

    OTAssert(([taskReturnedNilException.description containsString: @"returned nilptr"]), @"TaskReturnedNilException should describe nil return failures");
    OTAssert(([taskCancelledException.description containsString: @"cancellation checkpoint"]), @"TaskCancelledException should describe cancellation checkpoints");
    OTAssert((not [namedTask _isCancellationRequested]), @"Fresh tasks should report that cancellation was not requested");
    OTAssert(([namedTask.description containsString: @"named-task"]
        and [unnamedTask.description containsString: @"<Task"]), @"Task descriptions should render both named and unnamed tasks");

    OTAssert(([channelClosedException.description containsString: @"after close"]), @"AsyncChannelClosedException should describe the rejected operation");
    OTAssert(([channel.description containsString: @"capacity=1"]
        and not channel.isClosed), @"Channels should describe their capacity and closed state");
    OTAssert(([AsyncUnit.unit.description isEqual: @"AsyncUnit"]), @"AsyncUnit should preserve its singleton description");

    [scheduler shutdown];
}

- (void)test_task_continuation_and_scope_internal_branches
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            AsyncScheduler *scheduler = rootScope.scheduler;
            OFDate *earlierDeadline = [OFDate dateWithTimeIntervalSinceNow: 0.10];
            OFDate *laterDeadline = [OFDate dateWithTimeIntervalSinceNow: 0.20];
            bool caughtMappedReject = false;
            bool caughtFlatMappedReject = false;
            bool caughtInvalidAll = false;
            bool caughtInvalidRace = false;
            bool caughtThrownTask = false;
            bool caughtTaskGroupFailure = false;
            block_reference bool inheritedParentDeadline = false;
            auto mappedRejected = [[Task rejected: [[TestRejectionException alloc] init]]
                mapOnScheduler: scheduler
                      transform: ^id(id) {
                          return @"unreachable";
                      }];
            auto flatMappedRejected = [[Task rejected: [[TestRejectionException alloc] init]]
                flatMapOnScheduler: scheduler
                             transform: ^Task *(id) {
                                 return [Task resolved: @"unreachable"];
                             }];
            auto recoveredResolved = [[Task resolved: @"kept"]
                recoverOnScheduler: scheduler
                           handler: ^id(OFException *) {
                               return @"changed";
                           }];
            auto flatRecoveredResolved = [[Task resolved: @"still-kept"]
                flatRecoverOnScheduler: scheduler
                               handler: ^Task *(OFException *) {
                                   return [Task resolved: @"changed"];
                               }];
            auto spawnedWithoutName = [rootScope spawnTask: ^id {
                return @"spawned";
            }];
            auto throwingTask = [[Task alloc] initWithScheduler: scheduler
                                                      taskGroup: nilptr
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
                (void)[Task all: (OFArray<Task *> *)@[@"bad"]];
            } @catch (OFInvalidArgumentException *) {
                caughtInvalidAll = true;
            }

            @try {
                (void)[Task race: (OFArray<Task *> *)@[@"bad"]];
            } @catch (OFInvalidArgumentException *) {
                caughtInvalidRace = true;
            }

            @try {
                (void)throwingTask.await;
            } @catch (TestRejectionException *) {
                caughtThrownTask = true;
            }

            @try {
                (void)[rootScope performInChildTaskGroupNamed: @"body-failure" block: ^id(AsyncTaskGroup *) {
                    @throw [[TestRejectionException alloc] init];
                }];
            } @catch (TestRejectionException *) {
                caughtTaskGroupFailure = true;
            }

            (void)[rootScope performWithDeadline: earlierDeadline block: ^id(AsyncTaskGroup *deadlineTaskGroup) {
                (void)[deadlineTaskGroup performWithDeadline: laterDeadline block: ^id(AsyncTaskGroup *childTaskGroup) {
                    inheritedParentDeadline = ([childTaskGroup.deadline compare: $assert_nonnil(deadlineTaskGroup.deadline)] == OFOrderedSame);
                    return AsyncUnit.unit;
                }];
                return AsyncUnit.unit;
            }];

            OTAssert((caughtMappedReject and caughtFlatMappedReject), @"Task continuations should propagate rejected inputs across map and flatMap");
            OTAssert(([[recoveredResolved await] isEqual: @"kept"]
                and [[flatRecoveredResolved await] isEqual: @"still-kept"]), @"Recover continuations should leave fulfilled tasks unchanged");
            OTAssert((caughtInvalidAll and caughtInvalidRace), @"Task collection helpers should reject non-task inputs");
            OTAssert(([[spawnedWithoutName await] isEqual: @"spawned"]), @"Task groups should support the spawnTask: convenience overload");
            OTAssert(([[rootScope performInChildTaskGroup: ^id(AsyncTaskGroup *) {
                return @"child-result";
            }] isEqual: @"child-result"]), @"Task groups should support the performInChildTaskGroup: convenience overload");
            OTAssert((caughtThrownTask), @"Thrown task bodies should reject through task completion handling");
            OTAssert((caughtTaskGroupFailure), @"Thrown child task-group bodies should surface the primary exception directly");
            OTAssert((inheritedParentDeadline), @"Nested task groups should inherit an earlier parent deadline");
            OTAssert(([scheduler sleepUntilDate: [OFDate dateWithTimeIntervalSinceNow: 0.01]].await == AsyncUnit.unit), @"Schedulers should wait until future dates instead of taking the immediate shortcut");
    }];
}

- (void)test_scheduler_channel_private_branches
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
    auto cancelledTaskGroupOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto finishedTaskGroupOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto deadlineTaskGroupOwner = [[CoverageScopeOwnerTaskHarness alloc] init];
    auto cancelledTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler ownerTask: (Task *)cancelledTaskGroupOwner parentTaskGroup: nilptr name: @"cancelled" deadline: nilptr];
    auto finishedTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler ownerTask: (Task *)finishedTaskGroupOwner parentTaskGroup: nilptr name: @"finished" deadline: nilptr];
    auto deadlineTaskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler ownerTask: (Task *)deadlineTaskGroupOwner parentTaskGroup: nilptr name: @"deadline" deadline: [OFDate dateWithTimeIntervalSinceNow: 1]];
    auto taskGroup = [[AsyncTaskGroup alloc] initWithScheduler: scheduler ownerTask: (Task *)ownerTask parentTaskGroup: nilptr name: @"scope" deadline: nilptr];
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
    bool caughtChildTaskGroupOutsideTask = false;
    bool caughtChildTaskGroupSchedulerMismatch = false;
    bool caughtDeadlineOutsideTask = false;
    bool caughtDeadlineSchedulerMismatch = false;
    bool caughtRegisterAfterCancel = false;
    bool caughtRegisterAfterBody = false;
    Task *previousTask = async_current_task;

    ownerTask.scheduler = scheduler;
    otherOwnerTask.scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    cancelledTaskGroupOwner.scheduler = scheduler;
    finishedTaskGroupOwner.scheduler = scheduler;
    deadlineTaskGroupOwner.scheduler = scheduler;

    resolvedTask.isCompleted = true;
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

    [scheduler _drainReadyQueue];
    [scheduler _enqueueTask: (Task *)resolvedTask];
    [scheduler _resumeTask: (Task *)resolvedTask];

    [scheduler shutdown];
    [scheduler _enqueueTask: (Task *)shutDownTask];

    scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    ownerTask.scheduler = scheduler;
    cancelledTaskGroupOwner.scheduler = scheduler;
    finishedTaskGroupOwner.scheduler = scheduler;
    deadlineTaskGroupOwner.scheduler = scheduler;

    [scheduler _resumeTask: (Task *)invalidCompletionTask];
    [scheduler _resumeTask: (Task *)unsupportedYieldTask];

    [deadlineTaskGroup _installDeadlineTimerIfNeeded];
    [deadlineTaskGroup _invalidateDeadlineTimerIfNeeded];
    [deadlineTaskGroup _cancelFromTimeoutWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01]];
    [deadlineTaskGroup _cancelFromTimeoutWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01]];

    [cancelledTaskGroup cancel];

    (void)[finishedTaskGroup _runTaskGroupBody: ^id(AsyncTaskGroup *) {
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
        [taskGroup spawnTask: ^id {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtSpawnOutsideTask = true;
    }

    @try {
        (void)[taskGroup performInChildTaskGroup: ^id(AsyncTaskGroup *) {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtChildTaskGroupOutsideTask = true;
    }

    @try {
        (void)[taskGroup performWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01] block: ^id(AsyncTaskGroup *) {
            return @"outside";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtDeadlineOutsideTask = true;
    }

    async_current_task = (Task *)otherOwnerTask;
    @try {
        [taskGroup spawnTask: ^id {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtSpawnSchedulerMismatch = true;
    }

    @try {
        (void)[taskGroup performInChildTaskGroupNamed: @"mismatch" block: ^id(AsyncTaskGroup *) {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtChildTaskGroupSchedulerMismatch = true;
    }

    @try {
        (void)[taskGroup performWithDeadline: [OFDate dateWithTimeIntervalSinceNow: 0.01] block: ^id(AsyncTaskGroup *) {
            return @"mismatch";
        }];
    } @catch (OFInvalidArgumentException *) {
        caughtDeadlineSchedulerMismatch = true;
    } @finally {
        async_current_task = previousTask;
    }

    @try {
        [cancelledTaskGroup _registerChildTask: (Task *)ownerTask];
    } @catch (OFInvalidArgumentException *) {
        caughtRegisterAfterCancel = true;
    }

    @try {
        [finishedTaskGroup _registerChildTask: (Task *)ownerTask];
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

    OTAssert((invalidCompletionTask.rejectCount == 1
        and [invalidCompletionTask.failureException isKindOfClass: TaskReturnedNilException.class]), @"Schedulers should reject dead coroutines that return invalid completion objects");
    OTAssert((unsupportedYieldTask.rejectCount == 1
        and [unsupportedYieldTask.failureException isKindOfClass: AsyncSchedulerUnsupportedYieldException.class]), @"Schedulers should reject unsupported yielded objects");
    OTAssert((deadlineTaskGroupOwner.interruptCount == 1), @"Timeout cancellation should only interrupt the owner task once");
    OTAssert((caughtSendOutsideTask and caughtReceiveOutsideTask), @"Channels should reject send and receive outside a task context");
    OTAssert((caughtSpawnOutsideTask
        and caughtSpawnSchedulerMismatch
        and caughtChildTaskGroupOutsideTask
        and caughtChildTaskGroupSchedulerMismatch
        and caughtDeadlineOutsideTask
        and caughtDeadlineSchedulerMismatch), @"Task groups should reject spawn, child-task-group, and deadline helpers outside the owning task scheduler");
    OTAssert((caughtRegisterAfterCancel and caughtRegisterAfterBody), @"Scopes should reject registering child tasks after cancellation or after the body finishes");
    OTAssert((waitingReceiver.hasReceivedValue
        and [waitingReceiver.receivedValue isEqual: @"delivered"]
        and sendToWaitingReceiver.deliveredCount == 1), @"Channel send arm logic should hand values directly to waiting receivers");
    OTAssert((bufferedSend.deliveredCount == 1
        and bufferedReceive.hasReceivedValue
        and [bufferedReceive.receivedValue isEqual: @"buffered"]), @"Buffered channels should deliver buffered registrations through private arm helpers");
    OTAssert((rendezvousSend.deliveredCount == 1
        and rendezvousReceive.hasReceivedValue
        and [rendezvousReceive.receivedValue isEqual: @"rendezvous"]), @"Receive arm logic should drain waiting senders in rendezvous channels");
    OTAssert((closedSend.closedCount == 1
        and closedSend.isClosed
        and closedReceive.closedCount == 1
        and closedReceive.isClosed), @"Closed channels should close both send and receive registrations immediately");

    [scheduler shutdown];
    [otherOwnerTask.scheduler shutdown];
}

- (void)test_utility_internal_branch_coverage
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
        (void)[some valueOr: nilptr];
#pragma clang diagnostic pop
    } @catch (OFInvalidArgumentException *) {
        caughtNilOptionalFallback = true;
    }

    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
        (void)[Optional some: nilptr];
#pragma clang diagnostic pop
    } @catch (OFInvalidArgumentException *) {
        caughtNilSome = true;
    }

    OTAssert((caughtNilOptionalValue and caughtNilOptionalFallback and caughtNilSome), @"Optional should reject nil payloads, nil fallbacks, and reading missing values");
    OTAssert(([[some valueOr: @"fallback"] isEqual: @"payload"]
        and [[none valueOr: @"fallback"] isEqual: @"fallback"]), @"Optional should return either its stored value or the provided fallback");
    OTAssert(([some isEqual: some]
        and [some isEqual: @"payload"]
        and not [some isEqual: other]
        and not [none isEqual: some]
        and not [some isEqual: @42]), @"Optional equality should cover self, raw-value, nil, and type-mismatch comparisons");
    OTAssert(([none.description containsString: @"<none>"]), @"Optional descriptions should spell out the empty state");

    OTAssert(([highPointer compare: lowPointer] == OFOrderedDescending
        and [highPointer compare: sameAsHighPointer] == OFOrderedSame), @"Pointer comparisons should cover both descending and equal orderings");
    OTAssert(([highPointer isEqual: highPointer]
        and not [highPointer isEqual: @"not-data"]), @"Pointer equality should handle self-comparisons and non-data values");
}

@end
#pragma clang assume_nonnull end
