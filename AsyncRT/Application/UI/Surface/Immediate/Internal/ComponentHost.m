#import <AsyncRT/Application/UI/Surface/Immediate/Internal/ComponentHost.h>

#import <AsyncRT/Application/UI/Application.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Renderer.h>

#pragma clang assume_nonnull begin

@class AsyncUIRenderException;

@interface AsyncUIHookSlot : OFObject @end

[[subclassing_restricted, direct_members]]
@interface AsyncUIStateHookSlot : AsyncUIHookSlot

@property(readonly, nonatomic) AsyncUIState *state;

- (instancetype)initWithHost: (AsyncUIComponentHost *nonnil)host
                initialValue: (id nillable)initialValue [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncUIEffectHookSlot : AsyncUIHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(copy, nonatomic) AsyncUIEffectHandler nillable effectHandler;
@property(copy, nonatomic) AsyncUIEffectCleanupHandler nillable cleanupHandler;
@property(nonatomic) bool needsCommit;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncUITaskHookSlot : AsyncUIHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(retain, nonatomic) AsyncTask<id> *nillable task;

@end

[[direct_members]]
@implementation AsyncUIState {
    unretained AsyncUIComponentHost *_host;
    id nillable _value;
}

- (instancetype)initWithHost: (AsyncUIComponentHost *nillable)host
                initialValue: (id nillable)initialValue
{
    self = [super init];
    _host = host;
    _value = initialValue;
    return self;
}

- (void)_setHost: (AsyncUIComponentHost *nillable)host
{
    _host = host;
}

- (void)setValue: (id nillable)value
{
    bool isSameValue = false;

    if (_value == value)
        isSameValue = true;
    else if (_value != nilptr and value != nilptr and [_value respondsToSelector: @selector(isEqual:)] and [_value isEqual: value])
        isSameValue = true;

    if (isSameValue)
        return;

    _value = value;
    if (_host != nilptr)
        [_host setNeedsRender];
}

- (void)update: (id _Nullable (^nonnil)(id nillable currentValue))updateBlock
{
    self.value = updateBlock(_value);
}

@end

@implementation AsyncUIHookSlot @end

[[direct_members]]
@implementation AsyncUIStateHookSlot {
    AsyncUIState *_state;
}

- (instancetype)initWithHost: (AsyncUIComponentHost *nonnil)host
                initialValue: (id nillable)initialValue
{
    self = [super init];
    _state = [[AsyncUIState alloc] initWithHost: host initialValue: initialValue];
    return self;
}

@end

[[direct_members]]
@implementation AsyncUIEffectHookSlot
@end

[[direct_members]]
@implementation AsyncUITaskHookSlot
@end

[[direct_members]]
@implementation AsyncUIComponentHost {
    unretained AsyncUIComponent *nillable _owner;
    AsyncUIApplication *nillable _application;
    AsyncUIComponentHost *nillable _parentHost;
    AsyncTaskGroup *nillable _mountedTaskGroup;
    bool _isMounted;
    bool _needsContentUpdate;
    bool _isRenderingContent;
    id<AsyncUIContent> nillable _cachedRenderedContent;
    OFMutableDictionary<OFString *, AsyncUIComponentHost *> *_childHostsByKey;
    OFMutableSet<OFString *> *nillable _renderedChildKeys;
    OFMutableArray<AsyncUIHookSlot *> *_hookSlots;
    size_t _currentHookIndex;
}

- (instancetype)initWithOwner: (AsyncUIComponent *nillable)owner
{
    self = [super init];
    _owner = owner;
    _needsContentUpdate = true;
    _childHostsByKey = [OFMutableDictionary dictionary];
    _hookSlots = [OFMutableArray array];
    return self;
}

- (void)attachToApplication: (AsyncUIApplication *nillable)application
                  parentHost: (AsyncUIComponentHost *nillable)parentHost
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    _application = application;
    _parentHost = parentHost;
    _mountedTaskGroup = taskGroup;

    for (AsyncUIComponentHost *childHost in _childHostsByKey.objectEnumerator)
        [childHost attachToApplication: application parentHost: self taskGroup: taskGroup];
}

- (void)detachFromApplication
{
    for (AsyncUIComponentHost *childHost in _childHostsByKey.objectEnumerator)
        [childHost detachFromApplication];

    _application = nilptr;
    _parentHost = nilptr;
    _mountedTaskGroup = nilptr;
}

- (void)ensureMountedInTaskGroup: (AsyncTaskGroup *nonnil)taskGroup
{
    if (_isMounted)
        return;

    _mountedTaskGroup = taskGroup;
    _isMounted = true;
    if (_owner != nilptr)
        [_owner componentDidMount];
    [self setNeedsRender];
}

- (void)unmountRecursively
{
    if (not _isMounted and _owner != nilptr)
        return;

    for (AsyncUIComponentHost *childHost in _childHostsByKey.objectEnumerator) {
        [childHost unmountRecursively];
        [childHost detachFromApplication];
    }

    for (AsyncUIHookSlot *hookSlot in _hookSlots)
        [self _cleanupHookSlot: hookSlot];

    [_hookSlots removeAllObjects];
    [_childHostsByKey removeAllObjects];
    _cachedRenderedContent = nilptr;
    _renderedChildKeys = nilptr;

    if (_owner != nilptr and _isMounted)
        [_owner componentWillUnmount];
    _isMounted = false;
    _needsContentUpdate = true;
}

- (void)beginContentTraversal
{
    _renderedChildKeys = [OFMutableSet set];
}

- (void)endContentTraversalWithRenderer: (AsyncUIRenderer *nonnil)renderer
{
    [self _pruneUnusedChildHosts];
    [self _enqueuePendingEffectCommitsWithRenderer: renderer];
    _renderedChildKeys = nilptr;
}

- (id<AsyncUIContent>)resolvedRenderedContent
{
    id<AsyncUIContent> renderedContent;

    if (_owner == nilptr)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Only component-owned hosts can resolve rendered content"];
    if (not _isMounted)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Cannot render a component that is not mounted"];
    if (not _needsContentUpdate and _cachedRenderedContent != nilptr)
        return $assert_nonnil(_cachedRenderedContent);
    if (_isRenderingContent)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"A component render cycle was detected"];

    _isRenderingContent = true;
    _currentHookIndex = 0;

    @try {
        renderedContent = [_owner renderContent];
        if (renderedContent == nilptr)
            @throw [[AsyncUIRenderException alloc] initWithReason: @"-renderContent must return a nonnil content object"];

        _cachedRenderedContent = renderedContent;
        [self _trimHookSlotsToCount: _currentHookIndex];
        _needsContentUpdate = false;
    } @finally {
        _isRenderingContent = false;
    }

    return $assert_nonnil(_cachedRenderedContent);
}

- (AsyncUIComponentHost *)resolveChildHostForComponent: (AsyncUIComponent *nonnil)component
                                                key: (OFString *nonnil)key
{
    AsyncUIComponentHost *existingHost;

    if (_renderedChildKeys == nilptr)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Child components can only be resolved during content traversal"];
    if (key.length == 0)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Child component keys must not be empty"];
    if ([_renderedChildKeys containsObject: key])
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Sibling child components must use unique keys"];

    [_renderedChildKeys addObject: key];
    existingHost = _childHostsByKey[key];

    if (existingHost != nilptr and existingHost.owner != component) {
        [existingHost unmountRecursively];
        [existingHost detachFromApplication];
        [_childHostsByKey removeObjectForKey: key];
        existingHost = nilptr;
    }

    if (existingHost == nilptr) {
        existingHost = component._componentHost;
        if (existingHost.parentHost != nilptr and existingHost.parentHost != self)
            @throw [[AsyncUIRenderException alloc] initWithReason: @"A child component is already attached to a different parent"];
        if (_application != nilptr and existingHost.application != nilptr and existingHost.application != _application)
            @throw [[AsyncUIRenderException alloc] initWithReason: @"A child component is already attached to a different application"];

        [existingHost attachToApplication: _application parentHost: self taskGroup: _mountedTaskGroup];
        if (_mountedTaskGroup != nilptr)
            [existingHost ensureMountedInTaskGroup: $assert_nonnil(_mountedTaskGroup)];
        _childHostsByKey[key] = existingHost;
    }

    return $assert_nonnil(existingHost);
}

- (void)setNeedsRender
{
    _needsContentUpdate = true;
    if (_application != nilptr)
        [_application setNeedsRender];
}

- (AsyncUIState *)useState: (id nillable)initialValue
{
    AsyncUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AsyncUIStateHookSlot *stateSlot;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"State hooks can only run during -renderContent"];

    if (slot == nilptr) {
        stateSlot = [[AsyncUIStateHookSlot alloc] initWithHost: self initialValue: initialValue];
        [self _replaceHookSlot: stateSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AsyncUIStateHookSlot.class]) {
        stateSlot = (AsyncUIStateHookSlot *)slot;
    } else {
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    _currentHookIndex++;
    return stateSlot.state;
}

- (void)useEffect: (AsyncUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies
{
    AsyncUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AsyncUIEffectHookSlot *effectSlot;
    bool dependenciesChanged = false;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Effect hooks can only run during -renderContent"];

    if (slot == nilptr) {
        effectSlot = [[AsyncUIEffectHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: effectSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AsyncUIEffectHookSlot.class]) {
        effectSlot = (AsyncUIEffectHookSlot *)slot;
        dependenciesChanged = (dependencies == nilptr or effectSlot.dependencies == nilptr or
            not [$assert_nonnil(effectSlot.dependencies) isEqual: (dependencies ?: [OFArray array])]);
    } else {
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    effectSlot.dependencies = [dependencies copy];
    effectSlot.effectHandler = [effectHandler copy];
    effectSlot.needsCommit = dependenciesChanged;
    _currentHookIndex++;
}

- (AsyncTask<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name
{
    AsyncUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AsyncUITaskHookSlot *taskSlot;
    bool dependenciesChanged = false;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AsyncUIRenderException alloc] initWithReason: @"AsyncTask hooks can only run during -renderContent"];

    if (slot == nilptr) {
        taskSlot = [[AsyncUITaskHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: taskSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AsyncUITaskHookSlot.class]) {
        taskSlot = (AsyncUITaskHookSlot *)slot;
        dependenciesChanged = (dependencies == nilptr or taskSlot.dependencies == nilptr or
            not [$assert_nonnil(taskSlot.dependencies) isEqual: (dependencies ?: [OFArray array])]);
    } else {
        @throw [[AsyncUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    if (dependenciesChanged) {
        if (taskSlot.task != nilptr)
            [taskSlot.task cancel];

        taskSlot.dependencies = [dependencies copy];
        taskSlot.task = nilptr;
        taskSlot.task = [self launchTask: launchBlock name: name];
    }

    _currentHookIndex++;
    return taskSlot.task;
}

- (AsyncTask<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name
{
    if (_mountedTaskGroup == nilptr or launchBlock == nilptr)
        return nilptr;

    AsyncTaskGroup *mountedTaskGroup = $assert_nonnil(_mountedTaskGroup);
    id (^taskLaunchBlock)(AsyncTaskGroup *taskGroup) = [launchBlock copy];
    unretained AsyncUIComponentHost *unsafeSelf = self;

    auto task = [mountedTaskGroup spawnTask: ^id {
        @try {
            return [mountedTaskGroup performInChildTaskGroupNamed: name
                                                            block: taskLaunchBlock];
        } @finally {
            if (unsafeSelf != nilptr)
                [unsafeSelf setNeedsRender];
        }
    } name: name];
    return task;
}

- (AsyncUIHookSlot *nillable)_hookSlotAtIndex: (size_t)index
{
    if (index >= _hookSlots.count)
        return nilptr;

    return [_hookSlots objectAtIndex: index];
}

- (void)_replaceHookSlot: (AsyncUIHookSlot *nonnil)slot atIndex: (size_t)index
{
    if (index < _hookSlots.count)
        [_hookSlots replaceObjectAtIndex: index withObject: slot];
    else
        [_hookSlots addObject: slot];
}

- (void)_cleanupHookSlot: (AsyncUIHookSlot *nillable)slot
{
    if ([slot isKindOfClass: AsyncUIEffectHookSlot.class]) {
        AsyncUIEffectHookSlot *effectSlot = (AsyncUIEffectHookSlot *)slot;

        if (effectSlot.cleanupHandler != nilptr)
            effectSlot.cleanupHandler();
        effectSlot.cleanupHandler = nilptr;
        return;
    }

    if ([slot isKindOfClass: AsyncUITaskHookSlot.class]) {
        AsyncUITaskHookSlot *taskSlot = (AsyncUITaskHookSlot *)slot;

        if (taskSlot.task != nilptr)
            [taskSlot.task cancel];
        taskSlot.task = nilptr;
        return;
    }
}

- (void)_trimHookSlotsToCount: (size_t)count
{
    while (_hookSlots.count > count) {
        AsyncUIHookSlot *slot = [_hookSlots lastObject];

        [self _cleanupHookSlot: slot];
        [_hookSlots removeLastObject];
    }
}

- (void)_pruneUnusedChildHosts
{
    OFArray<OFString *> *childKeys = [_childHostsByKey.allKeys copy];

    for (OFString *key in childKeys) {
        if (_renderedChildKeys != nilptr and [_renderedChildKeys containsObject: key])
            continue;

        AsyncUIComponentHost *childHost = _childHostsByKey[key];
        [childHost unmountRecursively];
        [childHost detachFromApplication];
        [_childHostsByKey removeObjectForKey: key];
    }
}

- (void)_enqueuePendingEffectCommitsWithRenderer: (AsyncUIRenderer *nonnil)renderer
{
    if (_owner == nilptr)
        return;

    for (AsyncUIHookSlot *slot in _hookSlots) {
        AsyncUIEffectHookSlot *effectSlot;
        unretained AsyncUIComponentHost *unsafeSelf;

        if (not [slot isKindOfClass: AsyncUIEffectHookSlot.class])
            continue;

        effectSlot = (AsyncUIEffectHookSlot *)slot;
        if (not effectSlot.needsCommit or effectSlot.effectHandler == nilptr)
            continue;

        effectSlot.needsCommit = false;
        unsafeSelf = self;
        [renderer enqueuePostRenderEffect: ^{
            if (unsafeSelf == nilptr)
                return;

            if (effectSlot.cleanupHandler != nilptr)
                effectSlot.cleanupHandler();

            effectSlot.cleanupHandler = effectSlot.effectHandler();
        }];
    }
}

@end

#pragma clang assume_nonnull end
