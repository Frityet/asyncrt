#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#import <AsyncRT/Core/AsyncRuntimeInternal.h>

#pragma clang assume_nonnull begin

@class AsyncWorkerPool;

static OFString * const async_default_scheduler_key = @"AsyncScheduler.defaultScheduler";
static size_t const async_default_drain_batch_size = 64;
static OFTimeInterval const async_scheduler_run_interval = 0.01;
static OFOnceControl async_shared_worker_pool_once = OFOnceControlInitValue;
static OFMutex *nillable async_shared_worker_pool_lock;
static AsyncWorkerPool *nillable async_shared_worker_pool;

@protocol AsyncTaskCoroutineLike

@property(readonly, nonatomic) enum AsyncCoroutineStatus status;
@property(readonly, nonatomic) id nillable returnedObject;

- (id nillable)resume;

@end

@protocol AsyncSchedulerRunnable

- (void)runOnScheduler: (AsyncScheduler *)scheduler;

@end

[[subclassing_restricted]]
@interface AsyncSchedulerTaskRunnable : OFObject<AsyncSchedulerRunnable>

@property(readonly, nonatomic) AsyncTask *task;

- (instancetype)initWithTask: (AsyncTask *)task [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncSchedulerBlockRunnable : OFObject<AsyncSchedulerRunnable>

@property(readonly, nonatomic) void (^block)(void);

- (instancetype)initWithBlock: (void (^)(void))block [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncOffloadJob : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncCompletionSource<id> *completionSource;
@property(readonly, nonatomic) id (^block)(void);

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler completionSource: (AsyncCompletionSource<id> *)completionSource block: (id (^)(void))block [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)perform;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWorkerPool : OFObject

@property(readonly, nonatomic) size_t maxWorkerCount;

+ (AsyncWorkerPool *)sharedPoolWithMaxWorkerCount: (size_t)maxWorkerCount;
- (instancetype)initWithMaxWorkerCount: (size_t)maxWorkerCount [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (bool)enqueueBlock: (id (^)(void))block
           scheduler: (AsyncScheduler *)scheduler
    completionSource: (AsyncCompletionSource<id> *)completionSource;
- (void)shutdown;

@end

static void AsyncSchedulerInitialiseSharedWorkerPoolState(void)
{
    async_shared_worker_pool_lock = [OFMutex mutex];
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

[[direct_members]]
@implementation AsyncTaskSnapshot

- (instancetype)initWithTaskID: (uint64_t)taskID name: (OFString *nillable)name executionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason cancellationRequested: (bool)cancellationRequested taskGroupName: (OFString *nillable)taskGroupName
{
    self = [super init];
    _taskID = taskID;
    _name = [name copy];
    _executionState = executionState;
    _waitReason = [waitReason copy];
    _isCancellationRequested = cancellationRequested;
    _taskGroupName = [taskGroupName copy];
    return self;
}

@end

[[direct_members]]
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

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (AsyncTask *)task yieldedObject: (id nillable)yieldedObject
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

[[direct_members]]
@implementation AsyncScheduler {
    OFMutex *_lock;
    OFMutableArray<id<AsyncSchedulerRunnable>> *_readyRunnables;
    size_t _readyRunnableHeadIndex;
    OFMutableSet<AsyncTask *> *_activeTasks;
    AsyncWorkerPool *_workerPool;
    OFFile *nillable _wakeReadFile;
    int _wakeReadFileDescriptor;
    int _wakeWriteFileDescriptor;
    char _wakeBuffer[64];
    bool _wakeSignalPending;
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
    _readyRunnables = [OFMutableArray array];
    _readyRunnableHeadIndex = 0;
    _activeTasks = [OFMutableSet set];
    _wakeReadFileDescriptor = -1;
    _wakeWriteFileDescriptor = -1;
    _wakeSignalPending = false;
    _shutdown = false;
    _runningTaskCount = 0;
    _completedTaskCount = 0;
    _cancelledTaskCount = 0;

    [self _initializeWakePipe];
    _workerPool = nilptr;
    [self _armWakeReadHandler];
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

- (void)_initializeWakePipe
{
    int pipeFileDescriptors[2];

    if (pipe(pipeFileDescriptors) != 0)
        @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"failed to create scheduler wake pipe"];

    for (size_t index = 0; index < 2; index++) {
        int descriptor = pipeFileDescriptors[index];
        int flags = fcntl(descriptor, F_GETFL, 0);
        int descriptorFlags = fcntl(descriptor, F_GETFD, 0);

        if (flags < 0 or descriptorFlags < 0
            or fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) != 0
            or fcntl(descriptor, F_SETFD, descriptorFlags | FD_CLOEXEC) != 0) {
            close(pipeFileDescriptors[0]);
            close(pipeFileDescriptors[1]);
            @throw [[AsyncSchedulerInvalidInitializationException alloc] initWithReason: @"failed to configure scheduler wake pipe"];
        }
    }

    _wakeReadFileDescriptor = pipeFileDescriptors[0];
    _wakeWriteFileDescriptor = pipeFileDescriptors[1];
    _wakeReadFile = [[OFFile alloc] initWithHandle: _wakeReadFileDescriptor];
}

- (void)_clearPendingWakeSignal
{
    [_lock lock];
    @try {
        _wakeSignalPending = false;
    } @finally {
        [_lock unlock];
    }
}

- (bool)_hasReadyRunnables
{
    [_lock lock];
    @try {
        return (_readyRunnables.count > _readyRunnableHeadIndex);
    } @finally {
        [_lock unlock];
    }
}

- (bool)_writeWakeByte
{
    if (_wakeWriteFileDescriptor < 0)
        return false;

    char wakeByte = 1;

    while (true) {
        ssize_t writeCount = write(_wakeWriteFileDescriptor, &wakeByte, sizeof(wakeByte));

        if (writeCount == (ssize_t)sizeof(wakeByte))
            return true;
        if (writeCount >= 0)
            continue;
        if (errno == EINTR)
            continue;
        if (errno == EAGAIN or errno == EWOULDBLOCK)
            return true;

        return false;
    }
}

- (void)_armWakeReadHandler
{
    if (_wakeReadFile == nilptr)
        return;

    unretained AsyncScheduler *unsafeSelf = self;
    [_wakeReadFile asyncReadIntoBuffer: _wakeBuffer
                                length: sizeof(_wakeBuffer)
                           runLoopMode: self.mode
                               handler: ^bool(OFStream *, void *, size_t, id nillable exception) {

        if (exception != nilptr)
            return not unsafeSelf->_shutdown;

        [unsafeSelf _drainWakePipe];
        [unsafeSelf _drainReadyQueue];
        return not unsafeSelf->_shutdown;
    }];
}

- (void)_signalWakePipeIfNeeded
{
    bool shouldWrite = false;

    [_lock lock];
    @try {
        if (not _shutdown and not _wakeSignalPending) {
            _wakeSignalPending = true;
            shouldWrite = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldWrite)
        return;

    if (not [self _writeWakeByte])
        [self _clearPendingWakeSignal];
}

- (void)_drainWakePipe
{
    if (_wakeReadFileDescriptor >= 0) {
        while (true) {
            ssize_t readCount = read(_wakeReadFileDescriptor, _wakeBuffer, sizeof(_wakeBuffer));

            if (readCount > 0)
                continue;
            if (readCount == 0)
                break;
            if (errno == EINTR)
                continue;
            if (errno == EAGAIN or errno == EWOULDBLOCK)
                break;
            break;
        }
    }

    [self _clearPendingWakeSignal];
}

- (void)_compactReadyQueueIfNeeded
{
    if (_readyRunnableHeadIndex == 0)
        return;
    if (_readyRunnableHeadIndex < 128 and _readyRunnableHeadIndex * 2 < _readyRunnables.count)
        return;

    auto compactedQueue = [OFMutableArray<id<AsyncSchedulerRunnable>> arrayWithCapacity: (_readyRunnables.count - _readyRunnableHeadIndex)];
    for (size_t index = _readyRunnableHeadIndex; index < _readyRunnables.count; index++)
        [compactedQueue addObject: _readyRunnables[index]];

    _readyRunnables = compactedQueue;
    _readyRunnableHeadIndex = 0;
}

- (OFArray<id<AsyncSchedulerRunnable>> *)_dequeueReadyBatch
{
    auto batch = [OFMutableArray<id<AsyncSchedulerRunnable>> array];

    [_lock lock];
    @try {
        size_t queuedCount = (_readyRunnables.count - _readyRunnableHeadIndex);
        size_t batchCount = queuedCount;

        if (batchCount > _maxDrainBatchSize)
            batchCount = _maxDrainBatchSize;

        for (size_t index = 0; index < batchCount; index++) {
            [batch addObject: _readyRunnables[_readyRunnableHeadIndex]];
            _readyRunnableHeadIndex++;
        }

        [self _compactReadyQueueIfNeeded];
    } @finally {
        [_lock unlock];
    }

    return batch;
}

- (void)_enqueueTask: (AsyncTask *)task
{
    bool shouldWake = false;

    if (task.isCompleted or not [task _markReadyQueued])
        return;

    [_lock lock];
    @try {
        if (not _shutdown) {
            [_activeTasks addObject: task];
            [_readyRunnables addObject: [[AsyncSchedulerTaskRunnable alloc] initWithTask: task]];
            shouldWake = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (shouldWake)
        [self _signalWakePipeIfNeeded];
    else
        [task _clearReadyQueued];
}

- (bool)_tryEnqueueBlock: (void (^)(void))block
{
    bool shouldWake = false;

    [_lock lock];
    @try {
        if (not _shutdown) {
            [_readyRunnables addObject: [[AsyncSchedulerBlockRunnable alloc] initWithBlock: block]];
            shouldWake = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (shouldWake)
        [self _signalWakePipeIfNeeded];

    return shouldWake;
}

- (void)_enqueueBlock: (void (^)(void))block
{
    (void)[self _tryEnqueueBlock: block];
}

- (void)_recordTaskResolutionForTask: (AsyncTask *)task
{
    [_lock lock];
    @try {
        [_activeTasks removeObject: task];
        _completedTaskCount++;
        if (task.status == AsyncTaskStatus_REJECTED and [task.failureException isKindOfClass: AsyncTaskCancelledException.class])
            _cancelledTaskCount++;
    } @finally {
        [_lock unlock];
    }
}

- (void)_resumeTask: (AsyncTask *)task
{
    id yieldedObject = nilptr;
    id returnedObject = nilptr;

    if (task.isCompleted)
        return;

    id coroutineObject = [task _coroutineObject];
    enum AsyncCoroutineStatus coroutineStatus = AsyncCoroutineStatus_READY;
    AsyncTask *previousTask = async_current_task;
    AsyncScheduler *previousScheduler = async_current_scheduler;
    AsyncTaskGroup *previousTaskGroup = async_current_task_group;
    async_current_task = task;
    async_current_scheduler = self;
    async_current_task_group = [task _resumeTaskGroupContext];

    [_lock lock];
    @try {
        _runningTaskCount++;
    } @finally {
        [_lock unlock];
    }

    [task _setExecutionState: AsyncTaskExecutionState_RUNNING waitReason: nilptr];

    @try {
        if ([coroutineObject isKindOfClass: AsyncCoroutine.class]) {
            AsyncCoroutine<id> *coroutine = (AsyncCoroutine<id> *)coroutineObject;
            yieldedObject = [coroutine resume];
            coroutineStatus = coroutine.status;
            returnedObject = coroutine.returnedObject;
        } else {
            id<AsyncTaskCoroutineLike> coroutine = (id<AsyncTaskCoroutineLike>)coroutineObject;
            yieldedObject = [coroutine resume];
            coroutineStatus = coroutine.status;
            returnedObject = coroutine.returnedObject;
        }
    } @catch (id exception) {
        [task _captureCurrentScopeContext];
        if ([$assert_nonnil(exception) isKindOfClass: OFException.class])
            [task _rejectTaskWithException: (OFException *)$assert_nonnil(exception)];
        else
            [task _rejectTaskWithException: [OFInvalidArgumentException exception]];
        return;
    } @finally {
        [task _captureCurrentScopeContext];
        async_current_task = previousTask;
        async_current_scheduler = previousScheduler;
        async_current_task_group = previousTaskGroup;

        [_lock lock];
        @try {
            _runningTaskCount--;
        } @finally {
            [_lock unlock];
        }
    }

    if (coroutineStatus == AsyncCoroutineStatus_DEAD) {
        if (not [returnedObject isKindOfClass: AsyncTaskExecutionCompletion.class]) {
            [task _rejectTaskWithException: [[AsyncTaskReturnedNilException alloc] initWithTask: task]];
            return;
        }

        [task _resolveFromCompletion: $as_nonnil((AsyncTaskExecutionCompletion *)returnedObject)];
        return;
    }

    if (not [yieldedObject isKindOfClass: AsyncWaitInstruction.class]) {
        [task _rejectTaskWithException: [[AsyncSchedulerUnsupportedYieldException alloc] initWithScheduler: self task: task yieldedObject: yieldedObject]];
        return;
    }

    AsyncWaitInstruction *instruction = $as_nonnil((AsyncWaitInstruction *)yieldedObject);
    [instruction.registration arm];
}

- (bool)_drainReadyQueueOnce
{
    OFArray<id<AsyncSchedulerRunnable>> *batch = [self _dequeueReadyBatch];

    if (batch.count == 0)
        return false;

    for (id<AsyncSchedulerRunnable> runnable in batch)
        [runnable runOnScheduler: self];

    return true;
}

- (void)_drainReadyQueue
{
    if ([self _drainReadyQueueOnce] and [self _hasReadyRunnables])
        [self _signalWakePipeIfNeeded];
}

- (AsyncTask *)sleepForTimeInterval: (OFTimeInterval)timeInterval
{
    if (timeInterval <= 0)
        return [AsyncTask resolved: AsyncUnit.unit];

    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: timeInterval] interval: 0 repeats: false block: ^(OFTimer *) {
        [completionSource fulfill: AsyncUnit.unit];
    }];
    [self.runLoop addTimer: timer forMode: self.mode];
    return completionSource.task;
}

- (AsyncTask *)sleepUntilDate: (OFDate *)date
{
    if ([date compare: OFDate.date] != OFOrderedDescending)
        return [AsyncTask resolved: AsyncUnit.unit];

    auto completionSource = [[AsyncCompletionSource alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: date interval: 0 repeats: false block: ^(OFTimer *) {
        [completionSource fulfill: AsyncUnit.unit];
    }];
    [self.runLoop addTimer: timer forMode: self.mode];
    return completionSource.task;
}

- (AsyncTask<id> *)offload: (id (^)(void))block
{
    AsyncWorkerPool *workerPool = nilptr;

    [_lock lock];
    @try {
        if (_shutdown)
            @throw [OFInvalidArgumentException exception];

        if (_workerPool == nilptr)
            _workerPool = [AsyncWorkerPool sharedPoolWithMaxWorkerCount: self.maxWorkerCount];

        workerPool = _workerPool;
    } @finally {
        [_lock unlock];
    }

    auto completionSource = [[AsyncCompletionSource alloc] init];
    if (not [$assert_nonnil(workerPool) enqueueBlock: block scheduler: self completionSource: completionSource])
        [completionSource reject: [OFInvalidArgumentException exception]];

    return completionSource.task;
}

- (void)runUntilTaskCompletes: (AsyncTask *)task
{
    while (not task.isCompleted) {
        if ([self _drainReadyQueueOnce])
            continue;

        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: async_scheduler_run_interval];
        [self.runLoop runMode: self.mode beforeDate: deadline];
    }
}

- (bool)runUntilTaskCompletes: (AsyncTask *)task timeout: (OFTimeInterval)timeout
{
    OFDate *deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: timeout];

    while (not task.isCompleted) {
        if ([self _drainReadyQueueOnce])
            continue;

        OFDate *sliceDeadline = [[OFDate alloc] initWithTimeIntervalSinceNow: async_scheduler_run_interval];

        if ([sliceDeadline compare: deadline] == OFOrderedDescending)
            sliceDeadline = deadline;

        [self.runLoop runMode: self.mode beforeDate: sliceDeadline];

        if ([deadline compare: OFDate.date] != OFOrderedDescending)
            return task.isCompleted;
    }

    return true;
}

- (void)runUntilIdle
{
    while ([self _drainReadyQueueOnce])
        ;
}

- (void)shutdown
{
    OFFile *nillable wakeReadFile = nilptr;
    int wakeWriteFileDescriptor = -1;
    bool shouldShutdown = false;

    [_lock lock];
    @try {
        if (not _shutdown) {
            shouldShutdown = true;
            _shutdown = true;
            [_readyRunnables removeAllObjects];
            _readyRunnableHeadIndex = 0;
            [_activeTasks removeAllObjects];
            _workerPool = nilptr;
            wakeReadFile = _wakeReadFile;
            _wakeReadFile = nilptr;
            _wakeReadFileDescriptor = -1;
            wakeWriteFileDescriptor = _wakeWriteFileDescriptor;
            _wakeWriteFileDescriptor = -1;
            _wakeSignalPending = false;
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldShutdown)
        return;

    if (wakeReadFile != nilptr)
        [wakeReadFile cancelAsyncRequests];
    if (wakeWriteFileDescriptor >= 0)
        close(wakeWriteFileDescriptor);
    if (wakeReadFile != nilptr)
        @try {
            [wakeReadFile close];
        } @catch (OFException *) {
        }
}

- (void)dealloc
{
    [self shutdown];
}

- (AsyncSchedulerSnapshot *)snapshot
{
    auto taskSnapshots = [OFMutableArray<AsyncTaskSnapshot *> array];

    [_lock lock];
    OFArray<AsyncTask *> *activeTasks = nilptr;
    size_t queuedTaskCount = 0;
    size_t runningTaskCount = 0;
    uint64_t completedTaskCount = 0;
    uint64_t cancelledTaskCount = 0;
    @try {
        activeTasks = _activeTasks.allObjects;
        queuedTaskCount = (_readyRunnables.count - _readyRunnableHeadIndex);
        runningTaskCount = _runningTaskCount;
        completedTaskCount = _completedTaskCount;
        cancelledTaskCount = _cancelledTaskCount;
    } @finally {
        [_lock unlock];
    }

    for (AsyncTask *task in activeTasks) {
        [taskSnapshots addObject: [[AsyncTaskSnapshot alloc] initWithTaskID: task.taskID
                                                                       name: task.name
                                                             executionState: task.executionState
                                                                 waitReason: task.waitReason
                                                      cancellationRequested: task.isCancellationRequested
                                                              taskGroupName: task.taskGroup._taskGroupNameForSnapshots]];
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

[[direct_members]]
@implementation AsyncSchedulerTaskRunnable

- (instancetype)initWithTask: (AsyncTask *)task
{
    self = [super init];
    _task = task;
    return self;
}

- (void)runOnScheduler: (AsyncScheduler *)scheduler
{
    [self.task _clearReadyQueued];
    [scheduler _resumeTask: self.task];
}

@end

[[direct_members]]
@implementation AsyncSchedulerBlockRunnable

- (instancetype)initWithBlock: (void (^)(void))block
{
    self = [super init];
    _block = [block copy];
    return self;
}

- (void)runOnScheduler: (AsyncScheduler *)scheduler
{
    (void)scheduler;
    self.block();
}

@end

[[direct_members]]
@implementation AsyncOffloadJob

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler completionSource: (AsyncCompletionSource<id> *)completionSource block: (id (^)(void))block
{
    self = [super init];
    _scheduler = scheduler;
    _completionSource = completionSource;
    _block = [block copy];
    return self;
}

- (void)perform
{
    id nillable value = nilptr;
    OFException *nillable exception = nilptr;
    auto completionSource = self.completionSource;
    auto scheduler = self.scheduler;

    @try {
        value = self.block();
        if (value == nilptr)
            exception = [OFInvalidArgumentException exception];
    } @catch (id caughtException) {
        if ([$assert_nonnil(caughtException) isKindOfClass: OFException.class])
            exception = (OFException *)$assert_nonnil(caughtException);
        else
            exception = [OFInvalidArgumentException exception];
    }

    if (not [scheduler _tryEnqueueBlock: ^{
        if (exception != nilptr)
            [completionSource reject: $assert_nonnil(exception)];
        else
            [completionSource fulfill: $assert_nonnil(value)];
    }]) {
        [completionSource reject: [OFInvalidArgumentException exception]];
    }
}

@end

[[direct_members]]
@implementation AsyncWorkerPool {
    OFCondition *_condition;
    OFMutableArray<AsyncOffloadJob *> *_jobs;
    size_t _jobHeadIndex;
    OFMutableArray<OFThread *> *_threads;
    bool _stopping;
}

+ (AsyncWorkerPool *)sharedPoolWithMaxWorkerCount: (size_t)maxWorkerCount
{
    OFOnce(&async_shared_worker_pool_once, AsyncSchedulerInitialiseSharedWorkerPoolState);

    [async_shared_worker_pool_lock lock];
    @try {
        if (async_shared_worker_pool == nilptr)
            async_shared_worker_pool = [[AsyncWorkerPool alloc] initWithMaxWorkerCount: maxWorkerCount];

        return $assert_nonnil(async_shared_worker_pool);
    } @finally {
        [async_shared_worker_pool_lock unlock];
    }
}

- (instancetype)initWithMaxWorkerCount: (size_t)maxWorkerCount
{
    self = [super init];
    _maxWorkerCount = maxWorkerCount;
    _condition = [[OFCondition alloc] init];
    _jobs = [OFMutableArray array];
    _jobHeadIndex = 0;
    _threads = [OFMutableArray array];
    _stopping = false;

    for (size_t index = 0; index < maxWorkerCount; index++) {
        auto thread = [[OFThread alloc] initWithBlock: ^{
            while (true) {
                AsyncOffloadJob *nillable job = nilptr;

                [self->_condition lock];
                @try {
                    while ((self->_jobs.count - self->_jobHeadIndex) == 0 and not self->_stopping)
                        [self->_condition wait];

                    if (self->_stopping)
                        return nilptr;

                    job = self->_jobs[self->_jobHeadIndex];
                    self->_jobHeadIndex++;

                    if (self->_jobHeadIndex >= 128 and self->_jobHeadIndex * 2 >= self->_jobs.count) {
                        auto compactedQueue = [OFMutableArray<AsyncOffloadJob *> arrayWithCapacity: (self->_jobs.count - self->_jobHeadIndex)];
                        for (size_t jobIndex = self->_jobHeadIndex; jobIndex < self->_jobs.count; jobIndex++)
                            [compactedQueue addObject: self->_jobs[jobIndex]];
                        self->_jobs = compactedQueue;
                        self->_jobHeadIndex = 0;
                    }
                } @finally {
                    [self->_condition unlock];
                }

                [$assert_nonnil(job) perform];
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

- (bool)enqueueBlock: (id (^)(void))block
           scheduler: (AsyncScheduler *)scheduler
    completionSource: (AsyncCompletionSource<id> *)completionSource
{
    auto job = [[AsyncOffloadJob alloc] initWithScheduler: scheduler completionSource: completionSource block: block];

    [_condition lock];
    @try {
        if (_stopping)
            return false;

        [_jobs addObject: job];
        [_condition signal];
    } @finally {
        [_condition unlock];
    }

    return true;
}

- (void)shutdown
{
    OFArray<OFThread *> *threads = nilptr;

    [_condition lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
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
