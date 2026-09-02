#include <AsyncExecutor.h>

#include <float.h>
#include <stdlib.h>

#pragma clang assume_nonnull begin

constexpr auto CURRENT_EXECUTOR_TD_KEY = @"AsyncRT.Core.AsyncExecutor.current";

constexpr auto CLEANUP_QUEUE_THRESHOLD = 128UL;

static OFMutableDictionary *nillable mainExecutorThreadDictionary;

@interface AsyncExecutor ()
- (void)_shutdown;
@end

@interface AsyncExecutorThreadState : OFObject {
    @private AsyncExecutor *_executor;
}
@property(readonly, nonatomic) AsyncExecutor *executor;
- (instancetype)initWithExecutor: (AsyncExecutor *)executor;
@end

@implementation AsyncExecutorThreadState

@synthesize executor = _executor;

- (instancetype)initWithExecutor: (AsyncExecutor *)executor
{
    self = [super init];
    _executor = executor;
    return self;
}

- (void)dealloc
{
    [_executor _shutdown];
}

@end

static void
cleanupCurrentExecutor(void)
{
    OFMutableDictionary *nillable threadDictionary =
        mainExecutorThreadDictionary ?: OFThread.threadDictionary;
    [threadDictionary removeObjectForKey: CURRENT_EXECUTOR_TD_KEY];
    mainExecutorThreadDictionary = nilptr;
}

@implementation AsyncExecutor

+ (void)initialize
{
    if (self == AsyncExecutor.class and atexit(cleanupCurrentExecutor) != 0)
        @throw [OFInitializationFailedException exceptionWithClass: self];
}

- (void)setMaxDrainCount:(size_t)maxDrainCount
{
    if (maxDrainCount == 0)
        @throw [OFInvalidArgumentException exception];

    _maxDrainCount = maxDrainCount;
}

+ (instancetype)current
{
    OFMutableDictionary *threadDictionary = $assert_nonnil(OFThread.threadDictionary);
    AsyncExecutorThreadState *state = threadDictionary[CURRENT_EXECUTOR_TD_KEY];

    if (OFThread.isMainThread)
        mainExecutorThreadDictionary = threadDictionary;

    if (state == nilptr) {
        state = [[AsyncExecutorThreadState alloc]
            initWithExecutor: [[self alloc] init]];
        threadDictionary[CURRENT_EXECUTOR_TD_KEY] = state;
    }

    return state.executor;
}

- (instancetype)init
{
    self = [super init];
    _workQueue = [[OFMutableArray alloc] initWithCapacity: 32];
    _lock = [[OFMutex alloc] init];
    _runLoop = $assert_nonnil(OFRunLoop.currentRunLoop);
    _shouldShutdown = false;
    _maxDrainCount = 64;
    _jobIdx = 0;
    return self;
}

- (void)_shutdown
{
    OFTimer *nillable timer;

    [_lock lock];
    @try {
        if (_shouldShutdown)
            return;

        _shouldShutdown = true;
        _drainScheduled = false;
        [_workQueue removeAllObjects];
        _jobIdx = 0;

        timer = _drainTimer;
        _drainTimer = nilptr;
        _runLoop = nilptr;
    } @finally {
        [_lock unlock];
    }

    if (timer != nilptr)
        [$assert_nonnil(timer) invalidate];
}

- (void)_cleanWorkQueue
{
    if (_jobIdx == 0)
        return;

    if (_jobIdx >= _workQueue.count) {
        [_workQueue removeAllObjects];
        _jobIdx = 0;
        return;
    }

    if (_jobIdx < CLEANUP_QUEUE_THRESHOLD or _jobIdx * 2 < _workQueue.count)
        return;
    
    _workQueue = [[_workQueue objectsInRange: (OFRange){ .location = _jobIdx, .length = _workQueue.count - _jobIdx }] mutableCopy];
    _jobIdx = 0;
}

- (void)_drain
{
    bool schedAnother = false;

    [_lock lock];
    @try {
        if (_shouldShutdown) {
            _drainScheduled = false;
            [_workQueue removeAllObjects];
            _jobIdx = 0;
            return;
        }

        if (_isDraining)
            return;
        
        _isDraining = true;
    } @finally {
        [_lock unlock];
    }

    size_t execN = 0;
    @try {
        while (execN < _maxDrainCount) {
            AsyncExecutorBlock blk;
            [_lock lock];
            @try {
                if (_shouldShutdown)
                    break;

                if (_jobIdx >= _workQueue.count)
                    break;

                blk = _workQueue[_jobIdx++];
            } @finally {
                [_lock unlock];
            }

            @autoreleasepool {
                blk();
            }
            execN++;
        }
    } @finally {
        [_lock lock];
        @try {
            [self _cleanWorkQueue];
            _isDraining = false;

            if (not _shouldShutdown and not _drainScheduled
                and _jobIdx < _workQueue.count) {
                schedAnother = true;
                _drainScheduled = true;
            }
        } @finally {
            [_lock unlock];
        }
    }

    if (schedAnother)
        [self scheduleDrain];
}

- (void)scheduleDrain
{
    OFTimer *timer = [OFTimer timerWithTimeInterval: 0.0
        target: self
        selector: @selector(_drainTimerDidFire)
        repeats: false];

    [_lock lock];
    @try {
        if (_shouldShutdown)
            return;

        if (_drainTimer != nilptr)
            return;

        _drainTimer = timer;
        [_runLoop addTimer: timer];
    } @finally {
        [_lock unlock];
    }
}

- (void)_drainTimerDidFire
{
    [_lock lock];
    @try {
        _drainTimer = nilptr;
        _drainScheduled = false;
    } @finally {
        [_lock unlock];
    }

    [self _drain];
}

- (bool)_isIdle
{ return not _isDraining and not _drainScheduled; }

- (void)enqueue: (AsyncExecutorBlock)block
{
    auto shouldDrain = false;
    [_lock lock];
    @try {
        if (_shouldShutdown)
            @throw [OFInvalidArgumentException exception];

        [_workQueue addObject: [block copy]];

        if (self._isIdle) {
            _drainScheduled = true;
            shouldDrain = true;
        }
    } @finally {
        [_lock unlock];
    }
    
    if (shouldDrain)
        [self scheduleDrain];
}

- (void)runUntil: (bool (^)(void))condition
{
    while (not condition()) {
        [self _drain];
        [_runLoop runMode: OFDefaultRunLoopMode beforeDate: nilptr];
    }
}

- (void)runUntil: (bool (^)(void))condition timeout: (OFTimeInterval)timeout
{
    OFTimeInterval startTime = OFDate.date.timeIntervalSinceNow;
    while (not condition()) {
        if (OFDate.date.timeIntervalSinceNow - startTime > timeout)
            @throw [OFException exception];

        [self _drain];
        [_runLoop runMode: OFDefaultRunLoopMode beforeDate: nilptr];
    }
}

@end

#pragma clang assume_nonnull end
