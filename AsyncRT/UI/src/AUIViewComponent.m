#import "AUIInternal.h"
#import "AUIRenderHost.h"

#pragma clang assume_nonnull begin

@class AUIRenderHost;

[[direct_members]]
@interface AUIStateBinding ()

- (instancetype)initWithOwner: (AUIViewComponent *nillable)owner initialValue: (id nillable)initialValue [[designated_initailiser]];
- (void)_setOwner: (AUIViewComponent *nillable)owner;

@end

@interface AUIViewHookSlot : OFObject @end

[[subclassing_restricted, direct_members]]
@interface AUIViewStateHookSlot : AUIViewHookSlot

@property(readonly, nonatomic) AUIStateBinding *binding;

- (instancetype)initWithOwner: (AUIViewComponent *nillable)owner initialValue: (id nillable)initialValue [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewEffectHookSlot : AUIViewHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(copy, nonatomic) AUIViewEffectHandler nillable effectHandler;
@property(copy, nonatomic) AUIViewEffectCleanupHandler nillable cleanupHandler;
@property(nonatomic) bool needsCommit;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewTaskHookSlot : AUIViewHookSlot

@property(copy, nonatomic) OFArray<id> *nillable dependencies;
@property(retain, nonatomic) Task<id> *nillable task;

@end

[[direct_members]]
@interface AUIViewComponent ()

- (AUIViewHookSlot *nillable)_hookSlotAtIndex: (size_t)index;
- (void)_replaceHookSlot: (AUIViewHookSlot *nillable)slot atIndex: (size_t)index;
- (void)_cleanupHookSlot: (AUIViewHookSlot *nillable)slot;
- (void)_trimHookSlotsToCount: (size_t)count;
- (void)_pruneUnusedChildViewComponents;
- (void)_enqueuePendingEffectCommits;

@end

[[direct_members]]
@implementation AUIStateBinding {
    unretained AUIViewComponent *_owner;
    id nillable _value;
}

- (instancetype)initWithOwner: (AUIViewComponent *nillable)owner initialValue: (id nillable)initialValue
{
    self = [super init];
    _owner = owner;
    _value = initialValue;
    return self;
}

- (void)_setOwner: (AUIViewComponent *nillable)owner
{
    _owner = owner;
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

    if (_owner != nilptr)
        [_owner setNeedsViewUpdate];
}

- (void)updateValueUsingBlock: (id _Nullable (^)(id nillable currentValue))updateBlock
{
    if (updateBlock == nilptr)
        @throw [OFInvalidArgumentException exception];

    self.value = updateBlock(_value);
}

@end

@implementation AUIViewHookSlot @end

[[direct_members]]
@implementation AUIViewStateHookSlot {
    AUIStateBinding *_binding;
}

- (instancetype)initWithOwner: (AUIViewComponent *nillable)owner initialValue: (id nillable)initialValue
{
    if (owner == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _binding = [[AUIStateBinding alloc] initWithOwner: owner initialValue: initialValue];
    return self;
}

@end

[[direct_members]]
@implementation AUIViewEffectHookSlot
@end

[[direct_members]]
@implementation AUIViewTaskHookSlot
@end

[[direct_members]]
@implementation AUIRetainedChildViewComponentNode {
    AUIViewComponent *_childViewComponent;
    OFString *_componentKey;
}

- (instancetype)initWithChildViewComponent: (AUIViewComponent *nillable)childViewComponent
                              componentKey: (OFString *nillable)componentKey
{
    if (childViewComponent == nilptr or componentKey == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super initWithNodeFamily: AUIViewNodeFamilyFragment stableKey: componentKey];
    _childViewComponent = $assert_nonnil(childViewComponent);
    _componentKey = [$assert_nonnil(componentKey) copy];
    return self;
}

@end

[[direct_members]]
@implementation AUIViewComponent {
    AUIApplication *nillable _application;
    AUIViewComponent *nillable _parentViewComponent;
    AsyncTaskGroup *nillable _mountedTaskGroup;
    bool _isMounted;
    bool _needsViewUpdate;
    bool _isRenderingViewNode;
    AUIViewNode *nillable _cachedRenderedViewNode;
    OFMutableDictionary<OFString *, AUIViewComponent *> *_childViewComponentsByKey;
    OFMutableSet<OFString *> *nillable _renderedChildComponentKeys;
    OFMutableArray<AUIViewHookSlot *> *_hookSlots;
    size_t _currentHookIndex;
}

@synthesize application = _application;
@synthesize parentViewComponent = _parentViewComponent;
@synthesize mountedTaskGroup = _mountedTaskGroup;
@synthesize isMounted = _isMounted;

- (instancetype)init
{
    self = [super init];
    _needsViewUpdate = true;
    _childViewComponentsByKey = [OFMutableDictionary dictionary];
    _hookSlots = [OFMutableArray array];
    return self;
}

- (AUIViewNode *)renderViewNode
{
    return [AUIViewFragmentNode fragmentNodeWithChildren: @[]];
}

- (void)viewComponentDidMount
{
}

- (void)viewComponentWillUnmount
{
}

- (void)setNeedsViewUpdate
{
    _needsViewUpdate = true;

    if (_application != nilptr)
        [_application setNeedsRender];
}

- (void)setNeedsRender
{
    [self setNeedsViewUpdate];
}

- (AUIStateBinding *)useStateWithInitialValue: (id nillable)initialValue
{
    AUIViewHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUIViewStateHookSlot *stateSlot;

    if (not _isRenderingViewNode)
        @throw [[AUIRenderException alloc] initWithReason: @"State hooks can only run during -renderViewNode"];

    if (slot == nilptr) {
        stateSlot = [[AUIViewStateHookSlot alloc] initWithOwner: self initialValue: initialValue];
        [self _replaceHookSlot: stateSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUIViewStateHookSlot.class]) {
        stateSlot = (AUIViewStateHookSlot *)slot;
    } else {
        @throw [[AUIRenderException alloc] initWithReason: @"Hook call order changed between renders"];
    }

    _currentHookIndex++;
    return stateSlot.binding;
}

- (void)useEffectWithDependencies: (OFArray<id> *nillable)dependencies
                           effect: (AUIViewEffectHandler nillable)effectHandler
{
    AUIViewHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUIViewEffectHookSlot *effectSlot;
    bool dependenciesChanged = false;

    if (not _isRenderingViewNode)
        @throw [[AUIRenderException alloc] initWithReason: @"Effect hooks can only run during -renderViewNode"];

    if (slot == nilptr) {
        effectSlot = [[AUIViewEffectHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: effectSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUIViewEffectHookSlot.class]) {
        effectSlot = (AUIViewEffectHookSlot *)slot;
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

- (Task<id> *nillable)useTaskWithDependencies: (OFArray<id> *nillable)dependencies
                                         name: (OFString *nillable)name
                                   launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
{
    AUIViewHookSlot *slot = [self _hookSlotAtIndex: _currentHookIndex];
    AUIViewTaskHookSlot *taskSlot;
    bool dependenciesChanged = false;

    if (not _isRenderingViewNode)
        @throw [[AUIRenderException alloc] initWithReason: @"Task hooks can only run during -renderViewNode"];

    if (slot == nilptr) {
        taskSlot = [[AUIViewTaskHookSlot alloc] init];
        dependenciesChanged = true;
        [self _replaceHookSlot: taskSlot atIndex: _currentHookIndex];
    } else if ([slot isKindOfClass: AUIViewTaskHookSlot.class]) {
        taskSlot = (AUIViewTaskHookSlot *)slot;
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

        if (_mountedTaskGroup != nilptr and launchBlock != nilptr) {
            unretained AUIViewComponent *unsafeSelf = self;

            taskSlot.task = [$assert_nonnil(_mountedTaskGroup)
                spawnTaskInChildTaskGroup: ^id(AsyncTaskGroup *taskGroup) {
                    return launchBlock(taskGroup);
                }
                                  name: name];
            (void)[taskSlot.task ensure: ^{
                if (unsafeSelf != nilptr)
                    [unsafeSelf setNeedsViewUpdate];
            }];
        }
    }

    _currentHookIndex++;
    return taskSlot.task;
}

- (AUIRenderContext *)useRenderContext
{
    AUIRenderContext *nillable context = AUIRenderContext.currentContext;

    if (context == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Render context hooks can only run during an active render"];

    return $assert_nonnil(context);
}

- (AUIViewNode *)renderChildViewComponent: (AUIViewComponent *nillable)childViewComponent
                                      key: (OFString *nillable)key
{
    AUIViewComponent *existingChildViewComponent;

    if (childViewComponent == nilptr or key == nilptr)
        @throw [OFInvalidArgumentException exception];
    if (not _isRenderingViewNode)
        @throw [[AUIRenderException alloc] initWithReason: @"Child view components can only be rendered during -renderViewNode"];
    if (_renderedChildComponentKeys == nilptr)
        @throw [[AUIRenderException alloc] initWithReason: @"Internal child component tracking is unavailable"];
    if ([$assert_nonnil(key) length] == 0)
        @throw [[AUIRenderException alloc] initWithReason: @"Child view component keys must not be empty"];
    if ([_renderedChildComponentKeys containsObject: $assert_nonnil(key)])
        @throw [[AUIRenderException alloc] initWithReason: @"Sibling child view components must use unique keys"];

    [_renderedChildComponentKeys addObject: $assert_nonnil(key)];
    existingChildViewComponent = _childViewComponentsByKey[$assert_nonnil(key)];

    if (existingChildViewComponent != nilptr and existingChildViewComponent != $assert_nonnil(childViewComponent)) {
        [existingChildViewComponent _unmountRecursively];
        [existingChildViewComponent _detachFromApplication];
        [_childViewComponentsByKey removeObjectForKey: $assert_nonnil(key)];
        existingChildViewComponent = nilptr;
    }

    if (existingChildViewComponent == nilptr) {
        if ($assert_nonnil(childViewComponent).parentViewComponent != nilptr and childViewComponent.parentViewComponent != self)
            @throw [[AUIRenderException alloc] initWithReason: @"A child view component is already attached to a different parent"];
        if (_application != nilptr and childViewComponent.application != nilptr and childViewComponent.application != _application)
            @throw [[AUIRenderException alloc] initWithReason: @"A child view component is already attached to a different application"];

        [childViewComponent _attachToApplication: _application parentViewComponent: self taskGroup: _mountedTaskGroup];
        [childViewComponent _ensureMountedInTaskGroup: _mountedTaskGroup];
        _childViewComponentsByKey[$assert_nonnil(key)] = $assert_nonnil(childViewComponent);
        existingChildViewComponent = $assert_nonnil(childViewComponent);
    }

    return [[AUIRetainedChildViewComponentNode alloc] initWithChildViewComponent: $assert_nonnil(existingChildViewComponent)
                                                                    componentKey: $assert_nonnil(key)];
}

- (void)_attachToApplication: (AUIApplication *nillable)application
         parentViewComponent: (AUIViewComponent *nillable)parentViewComponent
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    _application = application;
    _parentViewComponent = parentViewComponent;
    _mountedTaskGroup = taskGroup;

    for (OFString *key in _childViewComponentsByKey) {
        AUIViewComponent *childViewComponent = _childViewComponentsByKey[key];

        [childViewComponent _attachToApplication: application parentViewComponent: self taskGroup: taskGroup];
    }
}

- (void)_detachFromApplication
{
    for (AUIViewComponent *childViewComponent in _childViewComponentsByKey.objectEnumerator)
        [childViewComponent _detachFromApplication];

    _application = nilptr;
    _parentViewComponent = nilptr;
    _mountedTaskGroup = nilptr;
}

- (void)_ensureMountedInTaskGroup: (AsyncTaskGroup *nillable)taskGroup
{
    if (_isMounted)
        return;
    if (taskGroup == nilptr)
        @throw [OFInvalidArgumentException exception];

    _mountedTaskGroup = taskGroup;
    _isMounted = true;
    [self viewComponentDidMount];
    [self setNeedsViewUpdate];
}

- (void)_unmountRecursively
{
    if (not _isMounted)
        return;

    for (AUIViewComponent *childViewComponent in _childViewComponentsByKey.objectEnumerator) {
        [childViewComponent _unmountRecursively];
        [childViewComponent _detachFromApplication];
    }

    for (AUIViewHookSlot *hookSlot in _hookSlots)
        [self _cleanupHookSlot: hookSlot];

    [_hookSlots removeAllObjects];
    [_childViewComponentsByKey removeAllObjects];
    _cachedRenderedViewNode = nilptr;
    _renderedChildComponentKeys = nilptr;
    _isMounted = false;
    _needsViewUpdate = true;
    [self viewComponentWillUnmount];
}

- (AUIViewNode *)_resolvedRenderedViewNode
{
    AUIViewNode *renderedViewNode;

    if (not _isMounted)
        @throw [[AUIRenderException alloc] initWithReason: @"Cannot render a view component that is not mounted"];
    if (not _needsViewUpdate and _cachedRenderedViewNode != nilptr)
        return $assert_nonnil(_cachedRenderedViewNode);
    if (_isRenderingViewNode)
        @throw [[AUIRenderException alloc] initWithReason: @"A view component render cycle was detected"];

    _isRenderingViewNode = true;
    _currentHookIndex = 0;
    _renderedChildComponentKeys = [OFMutableSet set];

    @try {
        renderedViewNode = [self renderViewNode];
        if (renderedViewNode == nilptr)
            @throw [[AUIRenderException alloc] initWithReason: @"-renderViewNode must return a nonnil view node"];

        _cachedRenderedViewNode = $assert_nonnil(renderedViewNode);
        [self _trimHookSlotsToCount: _currentHookIndex];
        [self _pruneUnusedChildViewComponents];
        [self _enqueuePendingEffectCommits];
        _needsViewUpdate = false;
    } @finally {
        _renderedChildComponentKeys = nilptr;
        _isRenderingViewNode = false;
    }

    return $assert_nonnil(_cachedRenderedViewNode);
}

- (AUIViewHookSlot *nillable)_hookSlotAtIndex: (size_t)index
{
    if (index >= _hookSlots.count)
        return nilptr;

    return [_hookSlots objectAtIndex: index];
}

- (void)_replaceHookSlot: (AUIViewHookSlot *nillable)slot atIndex: (size_t)index
{
    if (slot == nilptr)
        @throw [OFInvalidArgumentException exception];

    if (index < _hookSlots.count)
        [_hookSlots replaceObjectAtIndex: index withObject: $assert_nonnil(slot)];
    else
        [_hookSlots addObject: $assert_nonnil(slot)];
}

- (void)_cleanupHookSlot: (AUIViewHookSlot *nillable)slot
{
    if ([slot isKindOfClass: AUIViewEffectHookSlot.class]) {
        AUIViewEffectHookSlot *effectSlot = (AUIViewEffectHookSlot *)slot;

        if (effectSlot.cleanupHandler != nilptr)
            effectSlot.cleanupHandler();
        effectSlot.cleanupHandler = nilptr;
        return;
    }

    if ([slot isKindOfClass: AUIViewTaskHookSlot.class]) {
        AUIViewTaskHookSlot *taskSlot = (AUIViewTaskHookSlot *)slot;

        if (taskSlot.task != nilptr)
            [taskSlot.task cancel];
        taskSlot.task = nilptr;
        return;
    }
}

- (void)_trimHookSlotsToCount: (size_t)count
{
    while (_hookSlots.count > count) {
        AUIViewHookSlot *slot = [_hookSlots lastObject];

        [self _cleanupHookSlot: slot];
        [_hookSlots removeLastObject];
    }
}

- (void)_pruneUnusedChildViewComponents
{
    OFArray<OFString *> *childKeys = [_childViewComponentsByKey.allKeys copy];

    for (OFString *key in childKeys) {
        if (_renderedChildComponentKeys != nilptr and [_renderedChildComponentKeys containsObject: key])
            continue;

        AUIViewComponent *childViewComponent = _childViewComponentsByKey[key];
        [childViewComponent _unmountRecursively];
        [childViewComponent _detachFromApplication];
        [_childViewComponentsByKey removeObjectForKey: key];
    }
}

- (void)_enqueuePendingEffectCommits
{
    AUIRenderHost *nillable renderHost;

    if (_application == nilptr)
        return;

    renderHost = [_application _renderHost];
    if (renderHost == nilptr)
        return;

    for (AUIViewHookSlot *slot in _hookSlots) {
        AUIViewEffectHookSlot *effectSlot;
        unretained AUIViewComponent *unsafeSelf;

        if (not [slot isKindOfClass: AUIViewEffectHookSlot.class])
            continue;

        effectSlot = (AUIViewEffectHookSlot *)slot;
        if (not effectSlot.needsCommit or effectSlot.effectHandler == nilptr)
            continue;

        effectSlot.needsCommit = false;
        unsafeSelf = self;
        [renderHost enqueuePostRenderEffect: ^{
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
