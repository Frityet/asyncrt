#import "Async/AsyncRuntimeInternal.h"
#import "Utilities/DependencyTracking.h"

#pragma clang assume_nonnull begin

typedef void (^AsyncSignalCleanupBlock)(void);

@protocol AsyncSignalTrackingContext

- (void)markDirty;
- (void)addSourceCleanup: (AsyncSignalCleanupBlock)cleanup;
- (void)invalidate;

@end

@class AsyncSignalWaitRegistration;

[[clang::objc_direct_members]]
@interface AsyncSignalSubscriber : OFObject

@property(readonly, nonatomic) id nillable owner;

- (instancetype)initWithOwner: (id nillable)owner
                       notify: (void (^)(id _Null_unspecified value))notify OF_DESIGNATED_INITIALIZER;
- (void)notifyWithValue: (id _Null_unspecified)value;
- (instancetype)init OF_UNAVAILABLE;

@end

[[clang::objc_direct_members]]
@interface AsyncComputedTrackingContext : OFObject<AsyncSignalTrackingContext>

- (instancetype)initWithOwner: (AsyncComputed *)owner OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncSignalWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) AsyncSignal *signal;
@property(readonly, nonatomic) uint64_t observedVersion;
@property(readonly, nonatomic) id nillable receivedValue;
@property(readonly, nonatomic) bool hasReceivedValue;

- (instancetype)initWithSignal: (AsyncSignal *)signal
               observedVersion: (uint64_t)observedVersion
                     scheduler: (AsyncScheduler *)scheduler
                          task: (Task *)task OF_DESIGNATED_INITIALIZER [[clang::objc_direct]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (bool)_finishOnce [[clang::objc_direct]];
- (void)signalValue: (id _Null_unspecified)value;

@end

@namespace(AsyncSignalSupport)

+ (OFString *)contextStackKey;
+ (bool)valuesEqual: (id nillable)previousValue nextValue: (id nillable)nextValue;
+ (OFMutableArray<id<AsyncSignalTrackingContext>> *)contextStack;
+ (id<AsyncSignalTrackingContext> nillable)currentContext;
+ (void)pushContext: (id<AsyncSignalTrackingContext>)context;
+ (void)popContext;
+ (AsyncSignalSubscriber *nillable)subscriberForOwner: (id)owner
                                         inSubscribers: (OFArray<AsyncSignalSubscriber *> *)subscribers;
+ (void)registerCurrentContextWithSubscribers: (OFMutableArray<AsyncSignalSubscriber *> *)subscribers;

@end

[[clang::objc_direct_members]]
@interface AsyncSignal ()

- (void)_registerCurrentContext;
- (void)_armWaitRegistration: (AsyncSignalWaitRegistration *)registration;
- (void)_cancelWaitRegistration: (AsyncSignalWaitRegistration *)registration;

@end

[[clang::objc_direct_members]]
@interface AsyncComputed ()

- (void)_cleanupSources;
- (void)_computeValue;
- (void)_contextMarkDirty;
- (void)_contextAddSourceCleanup: (AsyncSignalCleanupBlock)cleanup;

@end

@namespace_implementation(AsyncSignalSupport)

+ (OFString *)contextStackKey
{
    return @"AsyncSignal.contextStack";
}

+ (bool)valuesEqual: (id nillable)previousValue nextValue: (id nillable)nextValue
{
    if (previousValue == nextValue)
        return true;
    if (previousValue != nilptr and [previousValue isEqual: nextValue])
        return true;

    return false;
}

+ (OFMutableArray<id<AsyncSignalTrackingContext>> *)contextStack
{
    OFMutableDictionary<OFString *, OFMutableArray<id<AsyncSignalTrackingContext>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<AsyncSignalTrackingContext>> *stack;

    if (threadDictionary == nilptr)
        @throw [OFInvalidArgumentException exception];

    stack = threadDictionary[self.contextStackKey];
    if (stack == nilptr) {
        stack = [OFMutableArray array];
        threadDictionary[self.contextStackKey] = stack;
    }

    return stack;
}

+ (id<AsyncSignalTrackingContext> nillable)currentContext
{
    OFMutableDictionary<OFString *, OFMutableArray<id<AsyncSignalTrackingContext>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<AsyncSignalTrackingContext>> *stack;

    if (threadDictionary == nilptr)
        return nilptr;

    stack = threadDictionary[self.contextStackKey];
    if (stack == nilptr or stack.count == 0)
        return nilptr;

    return [stack objectAtIndex: stack.count - 1];
}

+ (void)pushContext: (id<AsyncSignalTrackingContext>)context
{
    [[self contextStack] addObject: context];
}

+ (void)popContext
{
    auto stack = [self contextStack];

    if (stack.count == 0)
        @throw [OFOutOfRangeException exception];

    [stack removeObjectAtIndex: stack.count - 1];
}

+ (AsyncSignalSubscriber *nillable)subscriberForOwner: (id)owner
                                         inSubscribers: (OFArray<AsyncSignalSubscriber *> *)subscribers
{
    for (AsyncSignalSubscriber *subscriber in subscribers) {
        if (subscriber.owner == owner)
            return subscriber;
    }

    return nilptr;
}

+ (void)registerCurrentContextWithSubscribers: (OFMutableArray<AsyncSignalSubscriber *> *)subscribers
{
    id<AsyncSignalTrackingContext> currentContext = self.currentContext;
    AsyncSignalSubscriber *nillable subscriber;

    if (currentContext == nilptr)
        return;

    subscriber = [self subscriberForOwner: (id)currentContext inSubscribers: subscribers];
    if (subscriber == nilptr) {
        subscriber = [[AsyncSignalSubscriber alloc]
            initWithOwner: (id)currentContext
                   notify: ^(id _Null_unspecified value) {
                       (void)value;
                       [currentContext markDirty];
                   }];
        [subscribers addObject: $assert_nonnil(subscriber)];
    }

    [currentContext addSourceCleanup: ^{
        [subscribers removeObjectIdenticalTo: $assert_nonnil(subscriber)];
    }];
}

@end

@implementation AsyncSignalSubscriber {
    id nillable _owner;
    void (^_notify)(id _Null_unspecified value);
}

@synthesize owner = _owner;

- (instancetype)initWithOwner: (id nillable)owner
                       notify: (void (^)(id _Null_unspecified value))notify
{
    self = [super init];
    _owner = owner;
    _notify = [notify copy];
    return self;
}

- (void)notifyWithValue: (id _Null_unspecified)value
{
    _notify(value);
}

@end

@implementation AsyncSignal {
    OFMutex *_lock;
    id nillable _value;
    uint64_t _version;
    OFMutableArray<AsyncSignalSubscriber *> *_subscribers;
    OFMutableArray<AsyncSignalWaitRegistration *> *_waitRegistrations;
}

@synthesize value = _value;

+ (instancetype)withValue: (id _Null_unspecified)value
{
    return [[self alloc] initWithValue: value];
}

- (instancetype)initWithValue: (id _Null_unspecified)value
{
    self = [super init];
    _lock = [OFMutex mutex];
    _value = value;
    _version = 0;
    _subscribers = [OFMutableArray array];
    _waitRegistrations = [OFMutableArray array];
    return self;
}

- (id _Null_unspecified)value
{
    block_reference id value = nilptr;

    [self _registerCurrentContext];
    [DependencyTracking registerDependency: self registration: ^DependencyTrackingCleanupBlock(void (^notify)(void)) {
        return [self subscribe: ^(id _Null_unspecified nextValue) {
            (void)nextValue;
            notify();
        }];
    }];

    [_lock lock];
    @try {
        value = _value;
    } @finally {
        [_lock unlock];
    }

    return value;
}

- (void)setValue: (id _Null_unspecified)value
{
    block_reference OFArray<AsyncSignalSubscriber *> *subscribers = nilptr;
    block_reference OFArray<AsyncSignalWaitRegistration *> *waitRegistrations = nilptr;
    block_reference bool didChange = false;

    [_lock lock];
    @try {
        if ([AsyncSignalSupport valuesEqual: _value nextValue: value])
            return;

        _value = value;
        _version++;
        subscribers = [_subscribers copy];
        waitRegistrations = [_waitRegistrations copy];
        [_waitRegistrations removeAllObjects];
        didChange = true;
    } @finally {
        [_lock unlock];
    }

    if (not didChange)
        return;

    for (AsyncSignalSubscriber *subscriber in subscribers)
        [subscriber notifyWithValue: value];
    for (AsyncSignalWaitRegistration *registration in waitRegistrations)
        [registration signalValue: value];
}

- (void (^)(void))subscribe: (void (^)(id _Null_unspecified))subscriber
{
    auto entry = [[AsyncSignalSubscriber alloc]
        initWithOwner: nilptr
               notify: ^(id _Null_unspecified value) {
                   subscriber(value);
               }];

    if (subscriber == nilptr)
        @throw [OFInvalidArgumentException exception];

    [_lock lock];
    @try {
        [_subscribers addObject: entry];
    } @finally {
        [_lock unlock];
    }

    return [^{
        [_lock lock];
        @try {
            [_subscribers removeObjectIdenticalTo: entry];
        } @finally {
            [_lock unlock];
        }
    } copy];
}

- (id _Null_unspecified)next
{
    Task *currentTask = Task.currentTask;
    block_reference uint64_t observedVersion = 0;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock lock];
    @try {
        observedVersion = _version;
    } @finally {
        [_lock unlock];
    }

    auto registration = [[AsyncSignalWaitRegistration alloc]
        initWithSignal: self
        observedVersion: observedVersion
              scheduler: currentTask.scheduler
                   task: currentTask];

    [currentTask _yieldWithRegistration: registration waitReason: @"signal next"];
    [Task checkCancellation];

    if (not registration.hasReceivedValue)
        @throw [OFInvalidArgumentException exception];

    return registration.receivedValue;
}

- (void)_registerCurrentContext
{
    id<AsyncSignalTrackingContext> currentContext = [AsyncSignalSupport currentContext];
    AsyncSignalSubscriber *nillable subscriber = nilptr;

    if (currentContext == nilptr)
        return;

    [_lock lock];
    @try {
        subscriber = [AsyncSignalSupport subscriberForOwner: (id)currentContext
                                             inSubscribers: _subscribers];
        if (subscriber == nilptr) {
            subscriber = [[AsyncSignalSubscriber alloc]
                initWithOwner: (id)currentContext
                       notify: ^(id _Null_unspecified value) {
                           (void)value;
                           [currentContext markDirty];
                       }];
            [_subscribers addObject: $assert_nonnil(subscriber)];
        }
    } @finally {
        [_lock unlock];
    }

    [currentContext addSourceCleanup: ^{
        [_lock lock];
        @try {
            [_subscribers removeObjectIdenticalTo: $assert_nonnil(subscriber)];
        } @finally {
            [_lock unlock];
        }
    }];
}

- (void)_armWaitRegistration: (AsyncSignalWaitRegistration *)registration
{
    block_reference bool shouldSignalImmediately = false;
    block_reference id value = nilptr;

    [_lock lock];
    @try {
        if (_version > registration.observedVersion) {
            shouldSignalImmediately = true;
            value = _value;
        } else
            [_waitRegistrations addObject: registration];
    } @finally {
        [_lock unlock];
    }

    if (shouldSignalImmediately)
        [registration signalValue: value];
}

- (void)_cancelWaitRegistration: (AsyncSignalWaitRegistration *)registration
{
    [_lock lock];
    @try {
        [_waitRegistrations removeObjectIdenticalTo: registration];
    } @finally {
        [_lock unlock];
    }
}

- (OFString *)description
{
    block_reference uint64_t version = 0;
    block_reference size_t waitRegistrationCount = 0;

    [_lock lock];
    @try {
        version = _version;
        waitRegistrationCount = _waitRegistrations.count;
    } @finally {
        [_lock unlock];
    }

    return [OFString stringWithFormat: @"<AsyncSignal %p version=%llu waiters=%zu>",
                                          self,
                                          (unsigned long long)version,
                                          waitRegistrationCount];
}

@end

@implementation AsyncComputed {
    id nillable _cached;
    id (^_computeBlock)(void);
    OFMutableArray<id> *_sources;
    OFMutableArray<AsyncSignalSubscriber *> *_subscribers;
    id<AsyncSignalTrackingContext> _context;
    bool _dirty;
}

+ (instancetype)withBlock: (id _Null_unspecified (^)(void))computeBlock
{
    return [[self alloc] initWithBlock: computeBlock];
}

- (instancetype)initWithBlock: (id _Null_unspecified (^)(void))computeBlock
{
    if (computeBlock == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _computeBlock = [computeBlock copy];
    _sources = [OFMutableArray array];
    _subscribers = [OFMutableArray array];
    _context = [[AsyncComputedTrackingContext alloc] initWithOwner: self];
    _dirty = true;
    return self;
}

- (void)dealloc
{
    [self _cleanupSources];
    [_context invalidate];
}

- (void)_cleanupSources
{
    OFArray<id> *sources = [_sources copy];

    [_sources removeAllObjects];
    for (id cleanupObject in sources)
        ((AsyncSignalCleanupBlock)cleanupObject)();
}

- (void)_computeValue
{
    [self _cleanupSources];
    [AsyncSignalSupport pushContext: $assert_nonnil(_context)];

    @try {
        _cached = _computeBlock();
        _dirty = false;
    } @finally {
        [AsyncSignalSupport popContext];
    }
}

- (void)_contextMarkDirty
{
    OFArray<AsyncSignalSubscriber *> *subscribers;

    if (_dirty)
        return;

    _dirty = true;
    subscribers = [_subscribers copy];

    for (AsyncSignalSubscriber *subscriber in subscribers)
        [subscriber notifyWithValue: nilptr];
}

- (void)_contextAddSourceCleanup: (AsyncSignalCleanupBlock)cleanup
{
    if (cleanup == nilptr)
        return;

    [_sources addObject: [cleanup copy]];
}

- (id _Null_unspecified)value
{
    [AsyncSignalSupport registerCurrentContextWithSubscribers: _subscribers];

    if (_dirty)
        [self _computeValue];

    return _cached;
}

@end

@implementation AsyncComputedTrackingContext {
    unretained AsyncComputed *_owner;
    bool _active;
}

- (instancetype)initWithOwner: (AsyncComputed *)owner
{
    self = [super init];
    _owner = owner;
    _active = true;
    return self;
}

- (void)markDirty
{
    AsyncComputed *owner = _owner;

    if (not _active or owner == nilptr)
        return;

    [owner _contextMarkDirty];
}

- (void)addSourceCleanup: (AsyncSignalCleanupBlock)cleanup
{
    AsyncComputed *owner = _owner;

    if (not _active or owner == nilptr or cleanup == nilptr)
        return;

    [owner _contextAddSourceCleanup: cleanup];
}

- (void)invalidate
{
    _active = false;
    _owner = nilptr;
}

@end

@implementation AsyncSignalWaitRegistration {
    OFMutex *_lock;
    bool _completed;
    bool _hasReceivedValue;
    id nillable _receivedValue;
}

@synthesize signal = _signal;
@synthesize observedVersion = _observedVersion;
@synthesize hasReceivedValue = _hasReceivedValue;

- (instancetype)initWithSignal: (AsyncSignal *)signal
               observedVersion: (uint64_t)observedVersion
                     scheduler: (AsyncScheduler *)scheduler
                          task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _signal = signal;
    _observedVersion = observedVersion;
    _lock = [OFMutex mutex];
    _completed = false;
    _hasReceivedValue = false;
    return self;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish;

    [_lock lock];
    @try {
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (id nillable)receivedValue
{
    block_reference id value = nilptr;

    [_lock lock];
    @try {
        value = _receivedValue;
    } @finally {
        [_lock unlock];
    }

    return value;
}

- (void)arm
{
    [self.signal _armWaitRegistration: self];
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    [self.signal _cancelWaitRegistration: self];
    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalValue: (id _Null_unspecified)value
{
    [_lock lock];
    @try {
        _receivedValue = value;
        _hasReceivedValue = true;
    } @finally {
        [_lock unlock];
    }

    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

@end

#pragma clang assume_nonnull end
