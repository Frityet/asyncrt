#include <unistd.h>
#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static OFString * const async_default_scheduler_key = @"AsyncScheduler.defaultScheduler";
static size_t const async_default_drain_batch_size = 64;

[[gnu::constructor]]
static void async_link_support_categories(void)
{
    async_link_scoped_lock_support();
    async_link_objfw_future_categories();
}

@interface AsyncOffloadJob : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) FutureResolver<id> *resolver;
@property(readonly, nonatomic) id (^block)(void);

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler resolver: (FutureResolver<id> *)resolver block: (id (^)(void))block OF_DESIGNATED_INITIALIZER;
- (void)perform;

@end

@interface AsyncWorkerPool : OFObject

@property(readonly, nonatomic) size_t maxWorkerCount;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler maxWorkerCount: (size_t)maxWorkerCount OF_DESIGNATED_INITIALIZER;
- (void)enqueueBlock: (id (^)(void))block resolver: (FutureResolver<id> *)resolver;
- (void)shutdown;

@end

static size_t async_default_worker_count(void)
{
    long cpuCount = sysconf(_SC_NPROCESSORS_ONLN);

    if (cpuCount <= 1)
        return 1;

    return (size_t)(cpuCount - 1);
}

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

@synthesize taskID = _taskID;
@synthesize name = _name;
@synthesize executionState = _executionState;
@synthesize waitReason = _waitReason;
@synthesize scopeName = _scopeName;

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

- (bool)isCancellationRequested
{
    return _cancellationRequested;
}

@end

@implementation AsyncSchedulerSnapshot

@synthesize queuedTaskCount = _queuedTaskCount;
@synthesize runningTaskCount = _runningTaskCount;
@synthesize completedTaskCount = _completedTaskCount;
@synthesize cancelledTaskCount = _cancelledTaskCount;
@synthesize tasks = _tasks;

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
    return [OFString stringWithFormat: @"AsyncSchedulerException: %@", DescribeScheduler(self.scheduler)];
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
    return [OFString stringWithFormat: @"AsyncSchedulerUnsupportedYieldException: %@ received unsupported yield from %@: %@", DescribeScheduler(self.scheduler), self.task, self.yieldedObject];
}

@end

@implementation AsyncScheduler {
    OFRunLoop *_runLoop;
    OFRunLoopMode _mode;
    size_t _maxWorkerCount;
    size_t _maxDrainBatchSize;
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

@synthesize runLoop = _runLoop;
@synthesize mode = _mode;
@synthesize maxWorkerCount = _maxWorkerCount;
@synthesize maxDrainBatchSize = _maxDrainBatchSize;

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
    return [self initWithRunLoop: runLoop mode: mode maxWorkerCount: async_default_worker_count() maxDrainBatchSize: async_default_drain_batch_size];
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

    [_lock scopedLock: ^{
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
    }];

    if (not shouldEnqueueTask)
        return;

    if (shouldScheduleTimer)
        [self _scheduleDrainTimer];
}

- (void)_recordTaskResolutionForTask: (Task *)task
{
    [_lock scopedLock: ^{
        [_activeTasks removeObject: task];
        [_queuedTasks removeObject: task];
        _completedTaskCount++;
        if (task.status == FutureStatus_REJECTED and [task.rejectionException isKindOfClass: TaskCancelledException.class])
            _cancelledTaskCount++;
    }];
}

- (void)_resumeTask: (Task *)task
{
    Coroutine<id> *coroutine;
    id yieldedObject = nilptr;
    Task *previousTask;
    AsyncScheduler *previousScheduler;
    AsyncScope *previousScope;

    if (task.isResolved)
        return;

    coroutine = [task _coroutineObject];
    previousTask = async_current_task;
    previousScheduler = async_current_scheduler;
    previousScope = async_current_scope;
    async_current_task = task;
    async_current_scheduler = self;
    async_current_scope = [task _resumeScopeContext];

    [_lock scopedLock: ^{
        _runningTaskCount++;
    }];

    [task _setExecutionState: AsyncTaskExecutionState_RUNNING waitReason: nilptr];

    @try {
        yieldedObject = [coroutine resume];
    } @catch (OFException *exception) {
        [task _captureCurrentScopeContext];
        [task _rejectTaskWithException: exception];
        return;
    } @finally {
        [task _captureCurrentScopeContext];
        async_current_task = previousTask;
        async_current_scheduler = previousScheduler;
        async_current_scope = previousScope;

        [_lock scopedLock: ^{
            _runningTaskCount--;
        }];
    }

    if (coroutine.status == CoroutineStatus_DEAD) {
        id returnedObject = coroutine.returnedObject;
        if (not [returnedObject isKindOfClass: AsyncPromiseCompletion.class]) {
            [task _rejectTaskWithException: [[TaskReturnedNilException alloc] initWithTask: task]];
            return;
        }

        [task _resolveFromCompletion: $assert_nonnil((AsyncPromiseCompletion *)returnedObject)];
        return;
    }

    if (not [yieldedObject isKindOfClass: AsyncWaitInstruction.class]) {
        [task _rejectTaskWithException: [[AsyncSchedulerUnsupportedYieldException alloc] initWithScheduler: self task: task yieldedObject: yieldedObject]];
        return;
    }

    AsyncWaitInstruction *instruction = $assert_nonnil((AsyncWaitInstruction *)yieldedObject);
    [instruction.registration arm];
}

- (void)_drainReadyTasks
{
    auto batch = [OFMutableArray<Task *> array];
    block_reference bool shouldScheduleAnotherDrain = false;
    block_reference bool hasBatch = false;

    [_lock scopedLock: ^{
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
    }];

    if (not hasBatch)
        return;

    for (Task *task in batch)
        [self _resumeTask: task];

    [_lock scopedLock: ^{
        shouldScheduleAnotherDrain = (_readyTasks.count > 0);
        _drainScheduled = shouldScheduleAnotherDrain;
    }];

    if (shouldScheduleAnotherDrain)
        [self _scheduleDrainTimer];
}

- (Future *)sleepForTimeInterval: (OFTimeInterval)timeInterval
{
    if (timeInterval <= 0)
        return [Future resolved: AsyncUnit.unit];

    auto resolver = [[FutureResolver alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: timeInterval] interval: 0 target: resolver selector: @selector(resolve:) object: AsyncUnit.unit repeats: false];
    [self.runLoop addTimer: timer forMode: self.mode];
    return resolver.future;
}

- (Future *)sleepUntilDate: (OFDate *)date
{
    if ([date compare: OFDate.date] != OFOrderedDescending)
        return [Future resolved: AsyncUnit.unit];

    auto resolver = [[FutureResolver alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: date interval: 0 target: resolver selector: @selector(resolve:) object: AsyncUnit.unit repeats: false];
    [self.runLoop addTimer: timer forMode: self.mode];
    return resolver.future;
}

- (Future<id> *)offload: (id (^)(void))block
{
    [_lock scopedLock: ^{
        if (_shutdown)
            @throw [OFInvalidArgumentException exception];
    }];

    auto resolver = [[FutureResolver alloc] init];
    [_workerPool enqueueBlock: block resolver: resolver];
    return resolver.future;
}

- (void)shutdown
{
    block_reference AsyncWorkerPool *workerPool = nilptr;
    block_reference bool shouldShutdown = false;

    [_lock scopedLock: ^{
        if (not _shutdown) {
            shouldShutdown = true;
            _shutdown = true;
            [_readyTasks removeAllObjects];
            [_queuedTasks removeAllObjects];
            [_activeTasks removeAllObjects];
            workerPool = _workerPool;
            _workerPool = nilptr;
        }
    }];

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

    [_lock scopedLock: ^{
        activeTasks = _activeTasks.allObjects;
        queuedTaskCount = _readyTasks.count;
        runningTaskCount = _runningTaskCount;
        completedTaskCount = _completedTaskCount;
        cancelledTaskCount = _cancelledTaskCount;
    }];

    for (Task *task in activeTasks) {
        [taskSnapshots addObject: [[AsyncTaskSnapshot alloc] initWithTaskID: task.taskID name: task.name executionState: task.executionState waitReason: task.waitReason cancellationRequested: task.cancellationRequested scopeName: task.scope._scopeNameForSnapshots]];
    }

    return [[AsyncSchedulerSnapshot alloc] initWithQueuedTaskCount: queuedTaskCount runningTaskCount: runningTaskCount completedTaskCount: completedTaskCount cancelledTaskCount: cancelledTaskCount tasks: taskSnapshots];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<AsyncScheduler %p %@>", self, self.mode];
}

@end

@implementation AsyncOffloadJob {
    AsyncScheduler *_scheduler;
    FutureResolver<id> *_resolver;
    id (^_block)(void);
}

@synthesize scheduler = _scheduler;
@synthesize resolver = _resolver;
@synthesize block = _block;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler resolver: (FutureResolver<id> *)resolver block: (id (^)(void))block
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

    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: 0 repeats: false block: ^(OFTimer *unusedTimer) {
        (void)unusedTimer;
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
    size_t _maxWorkerCount;
    OFCondition *_condition;
    OFMutableArray<AsyncOffloadJob *> *_jobs;
    OFMutableArray<OFThread *> *_threads;
    bool _stopping;
}

@synthesize maxWorkerCount = _maxWorkerCount;

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

                    job = [self->_jobs objectAtIndex: 0];
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

- (void)enqueueBlock: (id (^)(void))block resolver: (FutureResolver<id> *)resolver
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
