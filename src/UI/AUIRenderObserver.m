#import "UI/AUIInternal.h"

#pragma clang assume_nonnull begin

@namespace(AUIRenderObserverSupport)

+ (bool)dependencies: (OFArray *)dependencies containIdentity: (id)dependency;

@end

@namespace_implementation(AUIRenderObserverSupport)

+ (bool)dependencies: (OFArray *)dependencies containIdentity: (id)dependency
{
    for (id currentDependency in dependencies) {
        if (currentDependency == dependency)
            return true;
    }

    return false;
}

@end

@interface AUIRenderObserver ()

- (void)_cleanupTrackedDependencies;

@end

@implementation AUIRenderObserver {
    OFMutex *_lock;
    OFMutableArray<id> *_dependencies;
    OFMutableArray<id> *_cleanupBlocks;
    void (^_invalidationHandler)(void);
}

- (instancetype)initWithInvalidationHandler: (void (^nillable)(void))invalidationHandler
{
    if (invalidationHandler == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _lock = [OFMutex mutex];
    _dependencies = [OFMutableArray array];
    _cleanupBlocks = [OFMutableArray array];
    _invalidationHandler = [invalidationHandler copy];
    return self;
}

- (void)dealloc
{
    [self _cleanupTrackedDependencies];
}

- (void)beginTracking
{
    [self _cleanupTrackedDependencies];
    [DependencyTracking pushObserver: self];
}

- (void)endTracking
{
    [DependencyTracking popObserver];
}

- (void)invalidate
{
    _invalidationHandler();
}

- (void)trackDependency: (id)dependency registration: (DependencyTrackingRegistrationBlock)registration
{
    block_reference bool alreadyTracked = false;
    DependencyTrackingCleanupBlock nillable cleanup = nilptr;

    [_lock lock];
    @try {
        alreadyTracked = [AUIRenderObserverSupport dependencies: _dependencies containIdentity: dependency];
    } @finally {
        [_lock unlock];
    }

    if (alreadyTracked)
        return;

    cleanup = registration(^{
        [self invalidate];
    });

    [_lock lock];
    @try {
        if ([AUIRenderObserverSupport dependencies: _dependencies containIdentity: dependency])
            return;

        [_dependencies addObject: dependency];
        if (cleanup != nilptr)
            [_cleanupBlocks addObject: $assert_nonnil([cleanup copy])];
    } @finally {
        [_lock unlock];
    }
}

- (void)_cleanupTrackedDependencies
{
    OFArray<id> *cleanupBlocks;

    [_lock lock];
    @try {
        cleanupBlocks = [_cleanupBlocks copy];
        [_dependencies removeAllObjects];
        [_cleanupBlocks removeAllObjects];
    } @finally {
        [_lock unlock];
    }

    for (id cleanupObject in cleanupBlocks)
        ((DependencyTrackingCleanupBlock)cleanupObject)();
}

@end

#pragma clang assume_nonnull end
