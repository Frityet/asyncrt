#import <ThreadPool.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncRTThreadPoolState: OFObject

- (void)enqueueTask: (void (^)(void))task;
- (void (^nillable)(void))dequeueTask;
- (void)invalidate;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncRTThreadPoolWorker: OFThread

- (instancetype)initWithState: (AsyncRTThreadPoolState *)state;
- (instancetype)init [[clang::unavailable]];

@end

@implementation AsyncRTThreadPoolState {
    OFMutableArray<void (^)(void)> *_tasks;
    OFCondition *_condition;
    bool _isInvalidated;
}

- (instancetype)init
{
    self = [super init];
    _tasks = [[OFMutableArray alloc] init];
    _condition = [[OFCondition alloc] init];
    return self;
}

- (void)enqueueTask: (void (^)(void))task
{
    [_condition lock];
    @try {
        if (_isInvalidated)
            @throw [OFInvalidArgumentException exception];
        [_tasks addObject: [task copy]];
        [_condition signal];
    } @finally {
        [_condition unlock];
    }
}

- (void (^nillable)(void))dequeueTask
{
    [_condition lock];
    @try {
        while (_tasks.count == 0 && !_isInvalidated)
            [_condition wait];
        if (_tasks.count == 0)
            return nilptr;
        auto task = [_tasks.firstObject copy];
        [_tasks removeObjectAtIndex: 0];
        return task;
    } @finally {
        [_condition unlock];
    }
}

- (void)invalidate
{
    [_condition lock];
    @try {
        if (_isInvalidated)
            return;
        _isInvalidated = true;
        [_condition broadcast];
    } @finally {
        [_condition unlock];
    }
}

@end

@implementation AsyncRTThreadPoolWorker {
    AsyncRTThreadPoolState *_state;
}

- (instancetype)initWithState: (AsyncRTThreadPoolState *)state
{
    self = [super init];
    _state = state;
    return self;
}

- (id nillable)main
{
    while (true) {
        void (^nillable task)(void) = [_state dequeueTask];
        if (task == nilptr)
            break;
        @autoreleasepool {
            /*
             * AsyncTask converts failures into task rejection, but enqueueTask:
             * is public and a malformed caller may throw any Objective-C
             * object. Keep one bad queue item from permanently consuming a
             * worker and eventually exhausting the pool.
             */
            @try {
                task();
            } @catch (id exception) {
                (void)exception;
            }
        }
    }
    return nilptr;
}

@end

@interface ThreadPool ()

- (bool)isCurrentThreadWorker;

@end

@implementation ThreadPool {
    AsyncRTThreadPoolState *_state;
    OFMutableArray<AsyncRTThreadPoolWorker *> *_threads;
    bool _didJoin;
}

- (instancetype)initWithThreadCount: (size_t)threadCount
{
    if (threadCount == 0 || threadCount > 256)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _threadCount = threadCount;
    _state = [[AsyncRTThreadPoolState alloc] init];
    _threads = [[OFMutableArray alloc] initWithCapacity: threadCount];
    for (size_t index = 0; index < threadCount; index++) {
        auto thread = [[AsyncRTThreadPoolWorker alloc]
            initWithState: _state];
        /* Offloaded work may initialize a run loop, DNS resolver or socket. */
        thread.supportsSockets = true;
        [_threads addObject: thread];
        [thread start];
    }
    return self;
}

- (void)enqueueTask: (void (^)(void))task
{
    [_state enqueueTask: task];
}

- (void)invalidate
{
    if ([self isCurrentThreadWorker])
        @throw [OFInvalidArgumentException exception];

    [_state invalidate];
    @synchronized (self) {
        if (_didJoin)
            return;
        for (AsyncRTThreadPoolWorker *thread in _threads)
            [thread join];
        _didJoin = true;
    }
}

- (void)runOnRunLoop: (OFRunLoop *)runLoop
{
    (void)runLoop;
}

- (bool)isCurrentThreadWorker
{
    OFThread *nillable current = OFThread.currentThread;
    for (AsyncRTThreadPoolWorker *thread in _threads)
        if (thread == current)
            return true;
    return false;
}

- (void)dealloc
{
    if ([self isCurrentThreadWorker])
        [_state invalidate];
    else
        [self invalidate];
}

@end

#pragma clang assume_nonnull end
