#include "Utilities/Signal.h"
#include "Utilities/DependencyTracking.h"

#pragma clang assume_nonnull begin

@protocol SignalTrackingContext

- (void)markDirty;
- (void)addSourceCleanup: (SignalCleanupBlock)cleanup;
- (void)invalidate;

@end

[[subclassing_restricted]]
@interface SignalObserverEntry : OFObject

@property(readonly, nonatomic) id nillable owner;

- (instancetype)initWithOwner: (id nillable)owner
                       notify: (void (^)(id _Null_unspecified value))notify [[designated_initailiser]];
- (void)notifyWithValue: (id _Null_unspecified)value;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface ComputedTrackingContext : OFObject<SignalTrackingContext>

- (instancetype)initWithOwner: (Computed *)owner [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface EffectTrackingContext : OFObject<SignalTrackingContext>

- (instancetype)initWithOwner: (Effect *)owner [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[direct_members]]
@interface Computed ()

- (void)_cleanupSources;
- (void)_computeValue;
- (void)_contextMarkDirty;
- (void)_contextAddSourceCleanup: (SignalCleanupBlock)cleanup;

@end

[[direct_members]]
@interface Effect ()

- (void)_cleanupSources;
- (void)_run;
- (void)_contextMarkDirty;
- (void)_contextAddSourceCleanup: (SignalCleanupBlock)cleanup;

@end

@namespace(SignalSupport)

+ (OFConstantString *)contextStackKey;
+ (bool)valuesEqual: (id nillable)previousValue nextValue: (id nillable)nextValue;
+ (OFMutableArray<id<SignalTrackingContext>> *)contextStack;
+ (id<SignalTrackingContext> nillable)currentContext;
+ (void)pushContext: (id<SignalTrackingContext>)context;
+ (void)popContext;
+ (SignalObserverEntry *nillable)observerForOwner: (id)owner
                                      inObservers: (OFArray<SignalObserverEntry *> *)observers;
+ (void)registerCurrentContextWithObservers: (OFMutableArray<SignalObserverEntry *> *)observers;

@end

@namespace_implementation(SignalSupport)

+ (OFConstantString *)contextStackKey
{
    return @"Signal.contextStack";
}

+ (bool)valuesEqual: (id nillable)previousValue nextValue: (id nillable)nextValue
{
    if (previousValue == nextValue)
        return true;
    if (previousValue != nilptr and [previousValue isEqual: nextValue])
        return true;

    return false;
}

+ (OFMutableArray<id<SignalTrackingContext>> *)contextStack
{
    OFMutableDictionary<OFString *, OFMutableArray<id<SignalTrackingContext>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<SignalTrackingContext>> *stack;

    if (threadDictionary == nilptr)
        @throw [OFInvalidArgumentException exception];

    stack = threadDictionary[self.contextStackKey];
    if (stack == nilptr) {
        stack = [OFMutableArray array];
        threadDictionary[self.contextStackKey] = stack;
    }

    return stack;
}

+ (id<SignalTrackingContext> nillable)currentContext
{
    OFMutableDictionary<OFString *, OFMutableArray<id<SignalTrackingContext>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<SignalTrackingContext>> *stack;

    if (threadDictionary == nilptr)
        return nilptr;

    stack = threadDictionary[self.contextStackKey];
    if (stack == nilptr or stack.count == 0)
        return nilptr;

    return [stack objectAtIndex: stack.count - 1];
}

+ (void)pushContext: (id<SignalTrackingContext>)context
{
    [[self contextStack] addObject: context];
}

+ (void)popContext
{
    auto stack = self.contextStack;

    if (stack.count == 0)
        @throw [OFOutOfRangeException exception];

    [stack removeObjectAtIndex: stack.count - 1];
}

+ (SignalObserverEntry *nillable)observerForOwner: (id)owner
                                      inObservers: (OFArray<SignalObserverEntry *> *)observers
{
    for (SignalObserverEntry *entry in observers) {
        if (entry.owner == owner)
            return entry;
    }

    return nilptr;
}

+ (void)registerCurrentContextWithObservers: (OFMutableArray<SignalObserverEntry *> *)observers
{
    id<SignalTrackingContext> currentContext = self.currentContext;
    SignalObserverEntry *nillable entry;

    if (currentContext == nilptr)
        return;

    entry = [self observerForOwner: (id)currentContext inObservers: observers];
    if (entry == nilptr) {
        entry = [[SignalObserverEntry alloc]
            initWithOwner: (id)currentContext
                   notify: ^(id nillable value) {
                       (void)value;
                       [currentContext markDirty];
                   }];
        [observers addObject: $assert_nonnil(entry)];
    }

    [currentContext addSourceCleanup: ^{
        [observers removeObjectIdenticalTo: $assert_nonnil(entry)];
    }];
}

@end

@implementation SignalObserverEntry {
    id nillable _owner;
    void (^_notify)(id _Null_unspecified value);
}


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

@implementation Signal {
    id nillable _value;
    OFMutableArray<SignalObserverEntry *> *_subscribers;
}


+ (instancetype)withValue: (id _Null_unspecified)value
{
    return [[self alloc] initWithValue: value];
}

- (instancetype)initWithValue: (id _Null_unspecified)value
{
    self = [super init];
    _value = value;
    _subscribers = [OFMutableArray array];
    return self;
}

- (id _Null_unspecified)value
{
    [SignalSupport registerCurrentContextWithObservers: _subscribers];
    [DependencyTracking registerDependency: self registration: ^(void (^notify)(void)) {
        return [self subscribe: ^(id _Null_unspecified value) {
            (void)value;
            notify();
        }];
    }];
    return _value;
}

- (void)setValue: (id _Null_unspecified)value
{
    OFArray<SignalObserverEntry *> *subscribers;

    if ([SignalSupport valuesEqual: _value nextValue: value])
        return;

    _value = value;
    subscribers = [_subscribers copy];

    for (SignalObserverEntry *entry in subscribers)
        [entry notifyWithValue: value];
}

- (SignalCleanupBlock)subscribe: (void (^)(id _Null_unspecified))subscriber
{
    auto entry = [[SignalObserverEntry alloc]
        initWithOwner: nilptr
               notify: ^(id _Null_unspecified value) {
                   subscriber(value);
               }];

    if (subscriber == nilptr)
        @throw [OFInvalidArgumentException exception];

    [_subscribers addObject: entry];
    return [^{
        [_subscribers removeObjectIdenticalTo: entry];
    } copy];
}

@end

@implementation Computed {
    id nillable _cached;
    id (^_computeBlock)(void);
    OFMutableArray<id> *_sources;
    OFMutableArray<SignalObserverEntry *> *_subscribers;
    id<SignalTrackingContext> _context;
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
    _context = [[ComputedTrackingContext alloc] initWithOwner: self];
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
        ((SignalCleanupBlock)cleanupObject)();
}

- (void)_computeValue
{
    [self _cleanupSources];
    [SignalSupport pushContext: $assert_nonnil(_context)];

    @try {
        _cached = _computeBlock();
        _dirty = false;
    } @finally {
        [SignalSupport popContext];
    }
}

- (void)_contextMarkDirty
{
    OFArray<SignalObserverEntry *> *subscribers;

    if (_dirty)
        return;

    _dirty = true;
    subscribers = [_subscribers copy];

    for (SignalObserverEntry *entry in subscribers)
        [entry notifyWithValue: nilptr];
}

- (void)_contextAddSourceCleanup: (SignalCleanupBlock)cleanup
{
    if (cleanup == nilptr)
        return;

    [_sources addObject: [cleanup copy]];
}

- (id _Null_unspecified)value
{
    [SignalSupport registerCurrentContextWithObservers: _subscribers];

    if (_dirty)
        [self _computeValue];

    return _cached;
}

@end

@implementation Effect {
    void (^_effectBlock)(void);
    OFMutableArray<id> *_sources;
    id<SignalTrackingContext> _context;
    bool _active;
}

+ (instancetype)withBlock: (void (^)(void))effectBlock
{
    return [[self alloc] initWithBlock: effectBlock];
}

- (instancetype)initWithBlock: (void (^)(void))effectBlock
{
    if (effectBlock == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _effectBlock = [effectBlock copy];
    _sources = [OFMutableArray array];
    _context = [[EffectTrackingContext alloc] initWithOwner: self];
    _active = true;

    @try {
        [self _run];
    } @catch (OFException *exception) {
        [self invalidate];
        @throw exception;
    }

    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)_cleanupSources
{
    OFArray<id> *sources = [_sources copy];

    [_sources removeAllObjects];
    for (id cleanupObject in sources)
        ((SignalCleanupBlock)cleanupObject)();
}

- (void)_run
{
    if (not _active)
        return;

    [self _cleanupSources];
    [SignalSupport pushContext: $assert_nonnil(_context)];

    @try {
        _effectBlock();
    } @finally {
        [SignalSupport popContext];
    }
}

- (void)_contextMarkDirty
{
    [self _run];
}

- (void)_contextAddSourceCleanup: (SignalCleanupBlock)cleanup
{
    if (cleanup == nilptr)
        return;

    [_sources addObject: [cleanup copy]];
}

- (void)invalidate
{
    if (not _active)
        return;

    _active = false;
    [self _cleanupSources];
    [_context invalidate];
}

@end

@implementation ComputedTrackingContext {
    unretained Computed *_owner;
    bool _active;
}

- (instancetype)initWithOwner: (Computed *)owner
{
    self = [super init];
    _owner = owner;
    _active = true;
    return self;
}

- (void)markDirty
{
    Computed *owner = _owner;

    if (not _active or owner == nilptr)
        return;

    [owner _contextMarkDirty];
}

- (void)addSourceCleanup: (SignalCleanupBlock)cleanup
{
    Computed *owner = _owner;

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

@implementation EffectTrackingContext {
    unretained Effect *_owner;
    bool _active;
}

- (instancetype)initWithOwner: (Effect *)owner
{
    self = [super init];
    _owner = owner;
    _active = true;
    return self;
}

- (void)markDirty
{
    Effect *owner = _owner;

    if (not _active or owner == nilptr)
        return;

    [owner _run];
}

- (void)addSourceCleanup: (SignalCleanupBlock)cleanup
{
    Effect *owner = _owner;

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

#pragma clang assume_nonnull end
