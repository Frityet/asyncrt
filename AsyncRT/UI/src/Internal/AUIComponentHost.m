#import "Internal/AUIComponentHost.h"

#import "AUIApplication.h"
#import "AUIExceptions.h"
#import "Internal/AUIRenderer.h"

#pragma clang assume_nonnull begin

@class AUIRenderException;

@interface AUIHookSlot : OFObject @end

[[subclassing_restricted, direct_members]]
@interface AUIStateHookSlot : AUIHookSlot

@property(readonly, nonatomic) AUIState *state;

- (instancetype)initWithHost: (AUIComponentHost *nonnil)host
                initialValue: (id nillable)initialValue [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIEffectHookSlot : AUIHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(copy, nonatomic) AUIEffectHandler nillable effectHandler;
@property(copy, nonatomic) AUIEffectCleanupHandler nillable cleanupHandler;
@property(nonatomic) bool needsCommit;

@end

[[subclassing_restricted, direct_members]]
@interface AUITaskHookSlot : AUIHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(retain, nonatomic) Task<id> *nillable task;

@end

[[direct_members]]
@implementation AUIState {
    unretained AUIComponentHost *_host;
    id nillable _value;
}

- (instancetype)initWithHost: (AUIComponentHost *nillable)host
                initialValue: (id nillable)initialValue
{
    self = [super init];
    _host = host;
    _value = initialValue;
    return self;
}

- (void)_setHost: (AUIComponentHost *nillable)host
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

@implementation AUIHookSlot @end

[[direct_members]]
@implementation AUIStateHookSlot {
    AUIState *_state;
}

- (instancetype)initWithHost: (AUIComponentHost *nonnil)host
                initialValue: (id nillable)initialValue
{
    self = [super init];
    _state = [[AUIState alloc] initWithHost: host initialValue: initialValue];
    return self;
}

@end

[[direct_members]]
@implementation AUIEffectHookSlot
@end

[[direct_members]]
@implementation AUITaskHookSlot
@end

[[direct_members]]
@implementation AUIComponentHost {
    unretained AUIComponent *nillable _owner;
    AUIApplication *nillable _application;
    AUIComponentHost *nillable _parentHost;
    AsyncTaskGroup *nillable _mountedTaskGroup;
    bool _isMounted;
    bool _needsContentUpdate;
    bool _isRenderingContent;
    id<AUIContent> nillable _cachedRenderedContent;
    OFMutableDictionary<OFString *, AUIComponentHost *> *_childHostsByKey;
    OFMutableSet<OFString *> *nillable _renderedChildKeys;
    OFMutableArray<AUIHookSlot *> *_hookSlots;
    size_t _currentHookIndex;
}

- (instancetype)initWithOwner: (AUIComponent *nillable)owner
{
    self = [super init];
    _owner = owner;
    _needsContentUpdate = true;
    _childHostsByKey = [OFMutableDictionary dictionary];
    _hookSlots = [OFMutableArray array];
    return self;
}

- (void)attachToApplication: (AUIApplication *nillable)application
                  parentHost: (AUIComponentHost *nillable)parentHost
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    _application = application;
    _parentHost = parentHost;
    _mountedTaskGroup = taskGroup;

    for (AUIComponentHost *childHost in _childHostsByKey.objectEnumerator)
        [childHost attachToApplication: application parentHost: self taskGroup: taskGroup];
}

- (void)detachFromApplication
{
    for (AUIComponentHost *childHost in _childHostsByKey.objectEnumerator)
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

    for (AUIComponentHost *childHost in _childHostsByKey.objectEnumerator) {
        [childHost unmountRecursively];
        [childHost detachFromApplication];
    }

    for (AUIHookSlot *hookSlot in _hookSlots)
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

- (void)endContentTraversalWithRenderer: (AUIRenderer *nonnil)renderer
{
    [self _pruneUnusedChildHosts];
    [self _enqueuePendingEffectCommitsWithRenderer: renderer];
    _renderedChildKeys = nilptr;
}

- (id<AUIContent>)resolvedRenderedContent
{
    id<AUIContent> renderedContent;

    if (_owner == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Only component-owned hosts can resolve rendered content"];
    if (not _isMounted)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render a component that is not mounted"];
    if (not _needsContentUpdate and _cachedRenderedContent != nilptr)
        return $assert_nonnil(_cachedRenderedContent);
    if (_isRenderingContent)
        @throw [[AUIRenderException alloc] initWithReason: @"A component render cycle was detected"];

    _isRenderingContent = true;
    _currentHookIndex = 0;

    @try {
        renderedContent = [_owner renderContent];
        if (renderedContent == nilptr)
            @throw [[AUIRenderException alloc] initWithReason: @"-renderContent must return a nonnil content object"];

        _cachedRenderedContent = renderedContent;
        [self _trimHookSlotsToCount: _currentHookIndex];
        _needsContentUpdate = false;
    } @finally {
        _isRenderingContent = false;
    }

    return $assert_nonnil(_cachedRenderedContent);
}

- (AUIComponentHost *)resolveChildHostForComponent: (AUIComponent *nonnil)component
                                                key: (OFString *nonnil)key
{
    AUIComponentHost *existingHost;

    if (_renderedChildKeys == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Child components can only be resolved during content traversal"];
    if (key.length == 0)
        @throw [[AUIRenderException alloc] initWithReason: @"Child component keys must not be empty"];
    if ([_renderedChildKeys containsObject: key])
        @throw [[AUIRenderException alloc] initWithReason: @"Sibling child components must use unique keys"];

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
            @throw [[AUIRenderException alloc] initWithReason: @"A child component is already attached to a different parent"];
        if (_application != nilptr and existingHost.application != nilptr and existingHost.application != _application)
            @throw [[AUIRenderException alloc] initWithReason: @"A child component is already attached to a different application"];

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

- (AUIState *)useState: (id nillable)initialValue
{
    AUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUIStateHookSlot *stateSlot;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AUIRenderException alloc] initWithReason: @"State hooks can only run during -renderContent"];

    if (slot == nilptr) {
        stateSlot = [[AUIStateHookSlot alloc] initWithHost: self initialValue: initialValue];
        [self _replaceHookSlot: stateSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUIStateHookSlot.class]) {
        stateSlot = (AUIStateHookSlot *)slot;
    } else {
        @throw [[AUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    _currentHookIndex++;
    return stateSlot.state;
}

- (void)useEffect: (AUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies
{
    AUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUIEffectHookSlot *effectSlot;
    bool dependenciesChanged = false;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AUIRenderException alloc] initWithReason: @"Effect hooks can only run during -renderContent"];

    if (slot == nilptr) {
        effectSlot = [[AUIEffectHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: effectSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUIEffectHookSlot.class]) {
        effectSlot = (AUIEffectHookSlot *)slot;
        dependenciesChanged = (dependencies == nilptr or effectSlot.dependencies == nilptr or
            not [$assert_nonnil(effectSlot.dependencies) isEqual: (dependencies ?: @[])]);
    } else {
        @throw [[AUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    effectSlot.dependencies = [dependencies copy];
    effectSlot.effectHandler = [effectHandler copy];
    effectSlot.needsCommit = dependenciesChanged;
    _currentHookIndex++;
}

- (Task<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name
{
    AUIHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUITaskHookSlot *taskSlot;
    bool dependenciesChanged = false;

    if (_owner == nilptr or not _isRenderingContent)
        @throw [[AUIRenderException alloc] initWithReason: @"Task hooks can only run during -renderContent"];

    if (slot == nilptr) {
        taskSlot = [[AUITaskHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: taskSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUITaskHookSlot.class]) {
        taskSlot = (AUITaskHookSlot *)slot;
        dependenciesChanged = (dependencies == nilptr or taskSlot.dependencies == nilptr or
            not [$assert_nonnil(taskSlot.dependencies) isEqual: (dependencies ?: @[])]);
    } else {
        @throw [[AUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
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

- (Task<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name
{
    if (_mountedTaskGroup == nilptr or launchBlock == nilptr)
        return nilptr;

    AsyncTaskGroup *mountedTaskGroup = $assert_nonnil(_mountedTaskGroup);
    id (^taskLaunchBlock)(AsyncTaskGroup *taskGroup) = [launchBlock copy];
    unretained AUIComponentHost *unsafeSelf = self;

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

- (AUIHookSlot *nillable)_hookSlotAtIndex: (size_t)index
{
    if (index >= _hookSlots.count)
        return nilptr;

    return [_hookSlots objectAtIndex: index];
}

- (void)_replaceHookSlot: (AUIHookSlot *nonnil)slot atIndex: (size_t)index
{
    if (index < _hookSlots.count)
        [_hookSlots replaceObjectAtIndex: index withObject: slot];
    else
        [_hookSlots addObject: slot];
}

- (void)_cleanupHookSlot: (AUIHookSlot *nillable)slot
{
    if ([slot isKindOfClass: AUIEffectHookSlot.class]) {
        AUIEffectHookSlot *effectSlot = (AUIEffectHookSlot *)slot;

        if (effectSlot.cleanupHandler != nilptr)
            effectSlot.cleanupHandler();
        effectSlot.cleanupHandler = nilptr;
        return;
    }

    if ([slot isKindOfClass: AUITaskHookSlot.class]) {
        AUITaskHookSlot *taskSlot = (AUITaskHookSlot *)slot;

        if (taskSlot.task != nilptr)
            [taskSlot.task cancel];
        taskSlot.task = nilptr;
        return;
    }
}

- (void)_trimHookSlotsToCount: (size_t)count
{
    while (_hookSlots.count > count) {
        AUIHookSlot *slot = [_hookSlots lastObject];

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

        AUIComponentHost *childHost = _childHostsByKey[key];
        [childHost unmountRecursively];
        [childHost detachFromApplication];
        [_childHostsByKey removeObjectForKey: key];
    }
}

- (void)_enqueuePendingEffectCommitsWithRenderer: (AUIRenderer *nonnil)renderer
{
    if (_owner == nilptr)
        return;

    for (AUIHookSlot *slot in _hookSlots) {
        AUIEffectHookSlot *effectSlot;
        unretained AUIComponentHost *unsafeSelf;

        if (not [slot isKindOfClass: AUIEffectHookSlot.class])
            continue;

        effectSlot = (AUIEffectHookSlot *)slot;
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
