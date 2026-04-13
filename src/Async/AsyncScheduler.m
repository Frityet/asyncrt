#include <unistd.h>
#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static OFString * const async_default_scheduler_key = @"AsyncScheduler.defaultScheduler";
static size_t const async_default_drain_batch_size = 64;

@protocol AsyncTaskCoroutineLike

@property(readonly, nonatomic) enum CoroutineStatus status;
@property(readonly, nonatomic) id nillable returnedObject;

- (id nillable)resume;

@end

[[gnu::constructor]]
static void async_link_support_categories(void)
{
    async_link_objfw_promise_categories();
}

[[subclassing_restricted]]
@interface AsyncOffloadJob : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) PromiseResolver<id> *resolver;
@property(readonly, nonatomic) id (^block)(void);

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<id> *)resolver block: (id (^)(void))block [[designated_initailiser]];
- (void)perform;

@end

[[subclassing_restricted]]
@interface AsyncWorkerPool : OFObject

@property(readonly, nonatomic) size_t maxWorkerCount;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler maxWorkerCount: (size_t)maxWorkerCount [[designated_initailiser]];
- (void)enqueueBlock: (id (^)(void))block resolver: (PromiseResolver<id> *)resolver;
- (void)shutdown;

@end

[[direct_members]]
@interface AsyncScheduler ()

+ (size_t)_defaultWorkerCount;
- (void)_scheduleDrainTimer;
- (void)_resumeTask: (Task *)task;

@end

@namespace_implementation(AsyncSchedulerValidation)

+ (void)validateRunLoop: (OFRunLoop *nillable)runLoop
                  mode: (OFRunLoopMode nillable)mode
        maxWorkerCount: (size_t)maxWorkerCount
    maxDrainBatchSize: (size_t)maxDrainBatchSize
{
    if (runLoop == nilptr)
        @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"runLoop must not be nilptr"];
    if (mode == nilptr)
        @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"mode must not be nilptr"];
    if (maxWorkerCount == 0)
        @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"maxWorkerCount must be at least 1"];
    if (maxDrainBatchSize == 0)
        @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"maxDrainBatchSize must be at least 1"];
}

@end

@implementation AsyncTaskSnapshot

@synthesize isCancellationRequested = _cancellationRequested;

- (instancetype)initWithTaskID: (uint64_t)taskID name: (OFString *nillable)name executionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason cancellationRequested: (bool)cancellationRequested scopeName: (OFString *nillable)scopeName
{
    self = [super init];
    _taskID = taskID;
    _name = [name copy];
    _executionState = executionState;
    _waitReason = [waitReason copy];
    _cancellationRequested = cancellationRequested;
    _scopeName = [scopeName copy];
    return self;
}

@end

@implementation AsyncSchedulerSnapshot


- (instancetype)initWithQueuedTaskCount: (size_t)queuedTaskCount runningTaskCount: (size_t)runningTaskCount completedTaskCount: (uint64_t)completedTaskCount cancelledTaskCount: (uint64_t)cancelledTaskCount tasks: (OFArray<AsyncTaskSnapshot *> *)tasks
{
    self = [super init];
    _queuedTaskCount = queuedTaskCount;
    _runningTaskCount = runningTaskCount;
    _completedTaskCount = completedTaskCount;
    _cancelledTaskCount = cancelledTaskCount;
    _tasks = [tasks copy];
    return self;
}

@end

@implementation AsyncSchedulerException


- (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler
{
    self = [super init];
    _scheduler = scheduler;
    return self;
}

- (OFString *)description
{
    OFString *schedulerDescription = (self.scheduler == nilptr ? @"<nil>" : self.scheduler.describe);
    return [OFString stringWithFormat: @"AsyncSchedulerException: %@", schedulerDescription];
}

@end

@implementation AsyncSchedulerInvalidInitializationException


- (instancetype)initWithReason: (OFString *)reason
{
    self = [super initWithScheduler: nilptr];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncSchedulerInvalidInitializationException: %@", self.reason];
}

@end

@implementation AsyncSchedulerUnsupportedYieldException


- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task yieldedObject: (id nillable)yieldedObject
{
    self = [super initWithScheduler: scheduler];
    _task = task;
    _yieldedObject = yieldedObject;
    return self;
}

- (OFString *)description
{
    OFString *schedulerDescription = (self.scheduler == nilptr ? @"<nil>" : self.scheduler.describe);
    return [OFString stringWithFormat: @"AsyncSchedulerUnsupportedYieldException: %@ received unsupported yield from %@: %@", schedulerDescription, self.task, self.yieldedObject];
}

@end

@implementation AsyncScheduler {
    OFMutex *_lock;
    OFMutableArray<Task *> *_readyTasks;
    OFMutableSet<Task *> *_queuedTasks;
    OFMutableSet<Task *> *_activeTasks;
    AsyncWorkerPool *_workerPool;
    bool _drainScheduled;
    bool _shutdown;
    size_t _runningTaskCount;
    uint64_t _completedTaskCount;
    uint64_t _cancelledTaskCount;
}


+ (AsyncScheduler *)defaultScheduler
{
    OFMutableDictionary<OFString *, AsyncScheduler *> *threadDictionary = OFThread.threadDictionary;
    AsyncScheduler *scheduler;

    if (threadDictionary == nilptr)
        return [[self alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];

    scheduler = threadDictionary[async_default_scheduler_key];
    if (scheduler == nilptr) {
        scheduler = [[self alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
        threadDictionary[async_default_scheduler_key] = scheduler;
    }

    return scheduler;
}

+ (size_t)_defaultWorkerCount
{
    long cpuCount = sysconf(_SC_NPROCESSORS_ONLN);

    if (cpuCount <= 1)
        return 1;

    return (size_t)(cpuCount - 1);
}

+ (void)shutdownDefaultSchedulerForCurrentThread
{
    OFMutableDictionary<OFString *, AsyncScheduler *> *threadDictionary = OFThread.threadDictionary;
    AsyncScheduler *scheduler = threadDictionary[async_default_scheduler_key];
    if (scheduler == nilptr)
        return;

    [threadDictionary removeObjectForKey: async_default_scheduler_key];
    [scheduler shutdown];
}

- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode maxWorkerCount: (size_t)maxWorkerCount maxDrainBatchSize: (size_t)maxDrainBatchSize
{
    [AsyncSchedulerValidation validateRunLoop: runLoop
                                         mode: mode
                               maxWorkerCount: maxWorkerCount
                           maxDrainBatchSize: maxDrainBatchSize];

    self = [super init];
    _runLoop = runLoop;
    _mode = [mode copy];
    _maxWorkerCount = maxWorkerCount;
    _maxDrainBatchSize = maxDrainBatchSize;
    _lock = [OFMutex mutex];
    _readyTasks = [OFMutableArray array];
    _queuedTasks = [OFMutableSet set];
    _activeTasks = [OFMutableSet set];
    _workerPool = [[AsyncWorkerPool alloc] initWithScheduler: self maxWorkerCount: maxWorkerCount];
    _drainScheduled = false;
    _shutdown = false;
    _runningTaskCount = 0;
    _completedTaskCount = 0;
    _cancelledTaskCount = 0;
    return self;
}

- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode
{
    return [self initWithRunLoop: runLoop mode: mode maxWorkerCount: [AsyncScheduler _defaultWorkerCount] maxDrainBatchSize: async_default_drain_batch_size];
}

- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop
{
    return [self initWithRunLoop: runLoop mode: OFDefaultRunLoopMode];
}

- (void)_scheduleDrainTimer
{
    auto fireDate = [[OFDate alloc] initWithTimeIntervalSinceNow: 0];
    auto timer = [[OFTimer alloc] initWithFireDate: fireDate interval: 0 target: self selector: @selector(_drainReadyTasks) repeats: false];
    [self.runLoop addTimer: timer forMode: self.mode];
}

- (void)_enqueueTask: (Task *)task
{
    block_reference bool shouldScheduleTimer = false;
    block_reference bool shouldEnqueueTask = false;

    if (task.isResolved)
        return;

    [_lock lock];
    @try {
        if (not _shutdown) {
            shouldEnqueueTask = true;
            [_activeTasks addObject: task];
            if (not [_queuedTasks containsObject: task]) {
                [_queuedTasks addObject: task];
                [_readyTasks addObject: task];
            }

            if (not _drainScheduled) {
                _drainScheduled = true;
                shouldScheduleTimer = true;
            }
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldEnqueueTask)
        return;

    if (shouldScheduleTimer)
        [self _scheduleDrainTimer];
}

- (void)_recordTaskResolutionForTask: (Task *)task
{
    [_lock lock];
    @try {
        [_activeTasks removeObject: task];
        [_queuedTasks removeObject: task];
        _completedTaskCount++;
        if (task.status == PromiseStatus_REJECTED and [task.rejectionException isKindOfClass: TaskCancelledException.class])
            _cancelledTaskCount++;
    } @finally {
        [_lock unlock];
    }
}

- (void)_resumeTask: (Task *)task
{
    id coroutineObject;
    id yieldedObject = nilptr;
    id returnedObject = nilptr;
    enum CoroutineStatus coroutineStatus;
    Task *previousTask;
    AsyncScheduler *previousScheduler;
    AsyncScope *previousScope;

    if (task.isResolved)
        return;

    coroutineObject = [task _coroutineObject];
    previousTask = async_current_task;
    previousScheduler = async_current_scheduler;
    previousScope = async_current_scope;
    async_current_task = task;
    async_current_scheduler = self;
    async_current_scope = [task _resumeScopeContext];

    [_lock lock];
    @try {
        _runningTaskCount++;
    } @finally {
        [_lock unlock];
    }

    [task _setExecutionState: AsyncTaskExecutionState_RUNNING waitReason: nilptr];

    @try {
        if ([coroutineObject isKindOfClass: Coroutine.class]) {
            Coroutine<id> *coroutine = (Coroutine<id> *)coroutineObject;
            yieldedObject = [coroutine resume];
            coroutineStatus = coroutine.status;
            returnedObject = coroutine.returnedObject;
        } else {
            id<AsyncTaskCoroutineLike> coroutine = (id<AsyncTaskCoroutineLike>)coroutineObject;
            yieldedObject = [coroutine resume];
            coroutineStatus = coroutine.status;
            returnedObject = coroutine.returnedObject;
        }
    } @catch (OFException *exception) {
        [task _captureCurrentScopeContext];
        [task _rejectTaskWithException: exception];
        return;
    } @finally {
        [task _captureCurrentScopeContext];
        async_current_task = previousTask;
        async_current_scheduler = previousScheduler;
        async_current_scope = previousScope;

        [_lock lock];
        @try {
            _runningTaskCount--;
        } @finally {
            [_lock unlock];
        }
    }

    if (coroutineStatus == CoroutineStatus_DEAD) {
        if (not [returnedObject isKindOfClass: AsyncPromiseCompletion.class]) {
            [task _rejectTaskWithException: [[TaskReturnedNilException alloc] initWithTask: task]];
            return;
        }

        [task _resolveFromCompletion: $as_nonnil((AsyncPromiseCompletion *)returnedObject)];
        return;
    }

    if (not [yieldedObject isKindOfClass: AsyncWaitInstruction.class]) {
        [task _rejectTaskWithException: [[AsyncSchedulerUnsupportedYieldException alloc] initWithScheduler: self task: task yieldedObject: yieldedObject]];
        return;
    }

    AsyncWaitInstruction *instruction = $as_nonnil((AsyncWaitInstruction *)yieldedObject);
    [instruction.registration arm];
}

- (void)_drainReadyTasks
{
    auto batch = [OFMutableArray<Task *> array];
    block_reference bool shouldScheduleAnotherDrain = false;
    block_reference bool hasBatch = false;

    [_lock lock];
    @try {
        size_t taskCount = _readyTasks.count;
        size_t batchCount = taskCount;

        if (batchCount > _maxDrainBatchSize)
            batchCount = _maxDrainBatchSize;

        if (batchCount == 0) {
            _drainScheduled = false;
            return;
        }

        hasBatch = true;

        for (size_t index = 0; index < batchCount; index++) {
            auto task = _readyTasks[0];
            [_readyTasks removeObjectAtIndex: 0];
            [_queuedTasks removeObject: task];
            [batch addObject: task];
        }
    } @finally {
        [_lock unlock];
    }

    if (not hasBatch)
        return;

    for (Task *task in batch)
        [self _resumeTask: task];

    [_lock lock];
    @try {
        shouldScheduleAnotherDrain = (_readyTasks.count > 0);
        _drainScheduled = shouldScheduleAnotherDrain;
    } @finally {
        [_lock unlock];
    }

    if (shouldScheduleAnotherDrain)
        [self _scheduleDrainTimer];
}

- (Promise *)sleepForTimeInterval: (OFTimeInterval)timeInterval
{
    if (timeInterval <= 0)
        return [Promise resolved: AsyncUnit.unit];

    auto resolver = [[PromiseResolver alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: timeInterval] interval: 0 target: resolver selector: @selector(resolve:) object: AsyncUnit.unit repeats: false];
    [self.runLoop addTimer: timer forMode: self.mode];
    return resolver.promise;
}

- (Promise *)sleepUntilDate: (OFDate *)date
{
    if ([date compare: OFDate.date] != OFOrderedDescending)
        return [Promise resolved: AsyncUnit.unit];

    auto resolver = [[PromiseResolver alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: date interval: 0 target: resolver selector: @selector(resolve:) object: AsyncUnit.unit repeats: false];
    [self.runLoop addTimer: timer forMode: self.mode];
    return resolver.promise;
}

- (Promise<id> *)offload: (id (^)(void))block
{
    [_lock lock];
    @try {
        if (_shutdown)
            @throw [OFInvalidArgumentException exception];
    } @finally {
        [_lock unlock];
    }

    auto resolver = [[PromiseResolver alloc] init];
    [_workerPool enqueueBlock: block resolver: resolver];
    return resolver.promise;
}

- (void)shutdown
{
    block_reference AsyncWorkerPool *workerPool = nilptr;
    block_reference bool shouldShutdown = false;

    [_lock lock];
    @try {
        if (not _shutdown) {
            shouldShutdown = true;
            _shutdown = true;
            [_readyTasks removeAllObjects];
            [_queuedTasks removeAllObjects];
            [_activeTasks removeAllObjects];
            workerPool = _workerPool;
            _workerPool = nilptr;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldShutdown)
        return;

    [workerPool shutdown];
}

- (void)dealloc
{
    [self shutdown];
}

- (AsyncSchedulerSnapshot *)snapshot
{
    block_reference OFArray<Task *> *activeTasks;
    block_reference size_t queuedTaskCount;
    block_reference size_t runningTaskCount;
    block_reference uint64_t completedTaskCount;
    block_reference uint64_t cancelledTaskCount;
    auto taskSnapshots = [OFMutableArray<AsyncTaskSnapshot *> array];

    [_lock lock];
    @try {
        activeTasks = _activeTasks.allObjects;
        queuedTaskCount = _readyTasks.count;
        runningTaskCount = _runningTaskCount;
        completedTaskCount = _completedTaskCount;
        cancelledTaskCount = _cancelledTaskCount;
    } @finally {
        [_lock unlock];
    }

    for (Task *task in activeTasks) {
        [taskSnapshots addObject: [[AsyncTaskSnapshot alloc] initWithTaskID: task.taskID name: task.name executionState: task.executionState waitReason: task.waitReason cancellationRequested: task.isCancellationRequested scopeName: task.scope._scopeNameForSnapshots]];
    }

    return [[AsyncSchedulerSnapshot alloc] initWithQueuedTaskCount: queuedTaskCount runningTaskCount: runningTaskCount completedTaskCount: completedTaskCount cancelledTaskCount: cancelledTaskCount tasks: taskSnapshots];
}

- (OFString *)description
{
    return self.describe;
}

- (OFString *)describe
{
    return [OFString stringWithFormat: @"%p (%@)", self, self.mode];
}

@end

@implementation AsyncOffloadJob


- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<id> *)resolver block: (id (^)(void))block
{
    self = [super init];
    _scheduler = scheduler;
    _resolver = resolver;
    _block = [block copy];
    return self;
}

- (void)perform
{
    id nillable value = nilptr;
    OFException *nillable exception = nilptr;
    auto resolver = self.resolver;
    auto scheduler = self.scheduler;

    @try {
        value = self.block();
        if (value == nilptr)
            exception = [OFInvalidArgumentException exception];
    } @catch (OFException *caughtException) {
        exception = caughtException;
    }

    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: 0 repeats: false block: ^(OFTimer *) {
        if (exception != nilptr)
            [resolver reject: $assert_nonnil(exception)];
        else
            [resolver resolve: $assert_nonnil(value)];
    }];

    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
}

@end

@implementation AsyncWorkerPool {
    AsyncScheduler *_scheduler;
    OFCondition *_condition;
    OFMutableArray<AsyncOffloadJob *> *_jobs;
    OFMutableArray<OFThread *> *_threads;
    bool _stopping;
}


- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler maxWorkerCount: (size_t)maxWorkerCount
{
    self = [super init];
    _scheduler = scheduler;
    _maxWorkerCount = maxWorkerCount;
    _condition = [[OFCondition alloc] init];
    _jobs = [OFMutableArray array];
    _threads = [OFMutableArray array];
    _stopping = false;

    for (size_t index = 0; index < maxWorkerCount; index++) {
        auto thread = [[OFThread alloc] initWithBlock: ^{
            while (true) {
                AsyncOffloadJob *job = nilptr;

                [self->_condition lock];
                @try {
                    while (self->_jobs.count == 0 and not self->_stopping)
                        [self->_condition wait];

                    if (self->_stopping and self->_jobs.count == 0)
                        return nilptr;

                    job = self->_jobs[0];
                    [self->_jobs removeObjectAtIndex: 0];
                } @finally {
                    [self->_condition unlock];
                }

                [job perform];
            }
        }];

        thread.name = [OFString stringWithFormat: @"AsyncWorker-%zu", index];
        [thread start];
        [_threads addObject: thread];
    }

    return self;
}

- (void)dealloc
{
    [self shutdown];
}

- (void)enqueueBlock: (id (^)(void))block resolver: (PromiseResolver<id> *)resolver
{
    auto job = [[AsyncOffloadJob alloc] initWithScheduler: _scheduler resolver: resolver block: block];

    [_condition lock];
    @try {
        [_jobs addObject: job];
        [_condition signal];
    } @finally {
        [_condition unlock];
    }
}

- (void)shutdown
{
    OFArray<OFThread *> *threads = nilptr;

    [_condition lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
        /* Worker thread blocks retain the pool, so dealloc alone can't stop them. */
        threads = [_threads copy];
        [_condition broadcast];
    } @finally {
        [_condition unlock];
    }

    for (OFThread *thread in threads)
        [thread join];
}

@end

#pragma clang assume_nonnull end
