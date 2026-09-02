#import <OWebSession.h>

#include <limits.h>

#pragma clang assume_nonnull begin

static const size_t OWebMaximumSessionIdentityBytes = 256;

@interface OWebSessionException ()

+ (instancetype)exceptionWithFailure: (OWebSessionFailure)failure;
- (instancetype)initWithFailure: (OWebSessionFailure)failure;

@end


@implementation OWebSessionException

+ (instancetype)exceptionWithFailure: (OWebSessionFailure)failure
{
    return [[self alloc] initWithFailure: failure];
}

- (instancetype)initWithFailure: (OWebSessionFailure)failure
{
    self = [super init];
    _failure = failure;
    return self;
}

- (unsigned short)statusCode
{
    switch (_failure) {
    case OWebSessionFailureInvalidIdentity:
        return 401;
    case OWebSessionFailureInvalidOrigin:
        return 403;
    case OWebSessionFailureNotAcceptable:
        return 406;
    case OWebSessionFailureUnknownComponent:
    case OWebSessionFailureUnknownInstance:
        return 404;
    case OWebSessionFailureInstanceConflict:
    case OWebSessionFailureSequenceConflict:
    case OWebSessionFailureStaleSequence:
        return 409;
    case OWebSessionFailureBodyTooLarge:
        return 413;
    case OWebSessionFailureInvalidContentType:
        return 415;
    case OWebSessionFailureUnknownAction:
    case OWebSessionFailureInvalidTarget:
    case OWebSessionFailureInvalidEventValue:
    case OWebSessionFailureComponentRejectedInput:
        return 422;
    case OWebSessionFailureCapacityExceeded:
        return 503;
    case OWebSessionFailureInternalError:
        return 500;
    case OWebSessionFailureInvalidSequence:
    case OWebSessionFailureInvalidFrame:
    case OWebSessionFailureUnexpectedFrame:
        return 400;
    }
}

- (OFString *)code
{
    switch (_failure) {
    case OWebSessionFailureInvalidIdentity: return @"invalid-session-identity";
    case OWebSessionFailureInvalidOrigin: return @"invalid-origin";
    case OWebSessionFailureInvalidContentType: return @"invalid-content-type";
    case OWebSessionFailureNotAcceptable: return @"not-acceptable";
    case OWebSessionFailureBodyTooLarge: return @"body-too-large";
    case OWebSessionFailureInvalidSequence: return @"invalid-sequence";
    case OWebSessionFailureSequenceConflict: return @"sequence-conflict";
    case OWebSessionFailureStaleSequence: return @"stale-sequence";
    case OWebSessionFailureInvalidFrame: return @"invalid-frame";
    case OWebSessionFailureUnexpectedFrame: return @"unexpected-frame";
    case OWebSessionFailureUnknownComponent: return @"unknown-component";
    case OWebSessionFailureInstanceConflict: return @"instance-conflict";
    case OWebSessionFailureUnknownInstance: return @"unknown-instance";
    case OWebSessionFailureUnknownAction: return @"unknown-action";
    case OWebSessionFailureInvalidTarget: return @"invalid-target";
    case OWebSessionFailureInvalidEventValue: return @"invalid-event-value";
    case OWebSessionFailureComponentRejectedInput:
        return @"component-rejected-input";
    case OWebSessionFailureCapacityExceeded: return @"capacity-exceeded";
    case OWebSessionFailureInternalError: return @"internal-error";
    }
}

@end


[[subclassing_restricted, direct_members]]
@interface OWebMountedState : OFObject

@property(nonatomic, readonly) OFMutableSet<OFNumber *> *dynamicTargets;
@property(nonatomic, readonly)
    OFMutableDictionary<OFNumber *, OFNumber *> *parentByDynamicTarget;
@property(nonatomic, readonly)
    OFMutableDictionary<OFNumber *, OFString *> *tagNamesByDynamicTarget;

- (instancetype)initEmptyState;
- (instancetype)initWithState: (OWebMountedState *)state;
- (instancetype)init OF_UNAVAILABLE;

@end


@implementation OWebMountedState

- (instancetype)initEmptyState
{
    self = [super init];
    _dynamicTargets = [[OFMutableSet alloc] init];
    _parentByDynamicTarget = [[OFMutableDictionary alloc] init];
    _tagNamesByDynamicTarget = [[OFMutableDictionary alloc] init];
    return self;
}

- (instancetype)initWithState: (OWebMountedState *)state
{
    self = [super init];
    _dynamicTargets = [state.dynamicTargets mutableCopy];
    _parentByDynamicTarget = [state.parentByDynamicTarget mutableCopy];
    _tagNamesByDynamicTarget = [state.tagNamesByDynamicTarget mutableCopy];
    return self;
}

@end


[[subclassing_restricted, direct_members]]
@interface OWebMountedComponent : OFObject

@property(nonatomic, readonly) OFString *componentTag;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OFString *> *attributes;
@property(nonatomic, readonly) OWebComponentDefinition *definition;
@property(nonatomic, readonly) OWebComponent *component;
@property(nonatomic) uint64_t lastSequence;

- (instancetype)initWithComponentTag: (OFString *)componentTag
                            attributes:
                                (OFDictionary<OFString *, OFString *> *)attributes
                            definition: (OWebComponentDefinition *)definition
                             component: (OWebComponent *)component;
- (instancetype)init OF_UNAVAILABLE;

- (bool)isValidEventTarget: (uint64_t)identifier;
- (OWebMountedState *)candidateStateForOperations:
    (OFArray<OWebPatchOperation *> *)operations;
- (void)commitState: (OWebMountedState *)state;
- (OFArray<OWebPatchOperation *> *)dynamicTeardownOperations;

@end


@implementation OWebMountedComponent {
    OFSet<OFNumber *> *_staticTargets;
    OFSet<OFNumber *> *_templateIdentifiers;
    OWebMountedState *_state;
}

- (instancetype)initWithComponentTag: (OFString *)componentTag
                            attributes:
                                (OFDictionary<OFString *, OFString *> *)attributes
                            definition: (OWebComponentDefinition *)definition
                             component: (OWebComponent *)component
{
    self = [super init];
    _componentTag = [componentTag copy];
    _attributes = [attributes copy];
    _definition = definition;
    _component = component;
    _state = [[OWebMountedState alloc] initEmptyState];

    auto templateIdentifiers = [OFMutableSet<OFNumber *> set];
    for (OFNumber *identifier in definition.templateIdentifiersByID.objectEnumerator)
        [templateIdentifiers addObject: identifier];
    _templateIdentifiers = [templateIdentifiers copy];

    auto staticTargets = [OFMutableSet<OFNumber *> set];
    for (uint64_t identifier = 1;
         identifier <= definition.maximumStaticIdentifier; identifier++) {
        auto key = @(identifier);
        if (not [_templateIdentifiers containsObject: key])
            [staticTargets addObject: key];
    }
    _staticTargets = [staticTargets copy];
    return self;
}

- (OFNumber *)keyForIdentifier: (uint64_t)identifier
{
    return @(identifier);
}

- (bool)isValidTarget: (uint64_t)identifier
                    state: (OWebMountedState *)state
{
    if (identifier == 0)
        return false;
    auto key = [self keyForIdentifier: identifier];
    return [_staticTargets containsObject: key] ||
        [state.dynamicTargets containsObject: key];
}

- (bool)isValidEventTarget: (uint64_t)identifier
{
    return [self isValidTarget: identifier state: _state];
}

- (void)raiseRejectedPatch
{
    @throw [OWebSessionException exceptionWithFailure:
        OWebSessionFailureComponentRejectedInput];
}

- (void)removeDynamicTargetAndDescendants: (OFNumber *)target
                                      state: (OWebMountedState *)state
{
    auto descendants = [OFMutableArray<OFNumber *> array];
    for (OFNumber *candidate in state.parentByDynamicTarget)
        if ([state.parentByDynamicTarget[candidate] isEqual: target])
            [descendants addObject: candidate];
    for (OFNumber *descendant in descendants)
        [self removeDynamicTargetAndDescendants: descendant state: state];
    [state.parentByDynamicTarget removeObjectForKey: target];
    [state.tagNamesByDynamicTarget removeObjectForKey: target];
    [state.dynamicTargets removeObject: target];
}

- (bool)isVoidTagName: (OFString *)tagName
{
    static OFSet<OFString *> *voidTags = nilptr;
    if (voidTags == nilptr)
        voidTags = [[OFSet alloc] initWithObjects:
            @"area", @"base", @"br", @"col", @"embed", @"hr", @"img",
            @"input", @"link", @"meta", @"param", @"source", @"track",
            @"wbr", nilptr];
    return [voidTags containsObject: tagName];
}

- (bool)targetCanContainChildren: (uint64_t)identifier
                              state: (OWebMountedState *)state
{
    auto key = [self keyForIdentifier: identifier];
    OFString *tagName = _definition.tagNamesByElementIdentifier[key];
    if (tagName == nilptr)
        tagName = state.tagNamesByDynamicTarget[key];
    return tagName != nilptr && not [self isVoidTagName: $assert_nonnil(tagName)];
}

- (bool)targetHasDynamicDescendant: (OFNumber *)target
                                state: (OWebMountedState *)state
{
    for (OFNumber *candidate in state.dynamicTargets) {
        OFNumber *parent = state.parentByDynamicTarget[candidate];
        size_t remaining = state.dynamicTargets.count + 1;
        while (parent != nilptr) {
            if (remaining == 0)
                return true;
            remaining--;
            if ([parent isEqual: target])
                return true;
            parent = state.parentByDynamicTarget[parent];
        }
    }
    return false;
}

- (bool)movingNode: (OFNumber *)node
       belowParent: (OFNumber *)parent
      createsCycle: (OWebMountedState *)state
{
    OFNumber *cursor = parent;
    size_t remaining = state.dynamicTargets.count + 1;
    while (cursor != nilptr) {
        if (remaining == 0)
            return true;
        remaining--;
        if ([cursor isEqual: node])
            return true;
        cursor = state.parentByDynamicTarget[cursor];
    }
    return false;
}

- (void)validateAndApplyOperation: (OWebPatchOperation *)operation
                              state: (OWebMountedState *)state
{
    switch (operation.opcode) {
    case OWebPatchOpcodeSetAttribute:
    case OWebPatchOpcodeRemoveAttribute:
    case OWebPatchOpcodeSetProperty:
    case OWebPatchOpcodeFocus:
        if (not [self isValidTarget: operation.elementIdentifier state: state])
            [self raiseRejectedPatch];
        return;
    case OWebPatchOpcodeSetText: {
        auto targetKey = [self keyForIdentifier: operation.elementIdentifier];
        if (not [self isValidTarget: operation.elementIdentifier state: state] ||
            [_definition.elementIdentifiersContainingStaticCapabilities
                containsObject: targetKey] ||
            [self targetHasDynamicDescendant: targetKey state: state])
            [self raiseRejectedPatch];
        return;
    }
    case OWebPatchOpcodeBatch:
        for (OWebPatchOperation *nested in operation.operations)
            [self validateAndApplyOperation: nested state: state];
        return;
    case OWebPatchOpcodeCloneTemplate: {
        auto templateKey = [self keyForIdentifier:
            operation.templateIdentifier];
        auto nodeKey = [self keyForIdentifier: operation.nodeIdentifier];
        OFString *rootTag =
            _definition.rootTagNamesByTemplateIdentifier[templateKey];
        if (not [_templateIdentifiers containsObject: templateKey] ||
            not [self isValidTarget: operation.parentIdentifier state: state] ||
            not [self targetCanContainChildren: operation.parentIdentifier
                state: state] ||
            rootTag == nilptr ||
            operation.nodeIdentifier <= _definition.maximumStaticIdentifier ||
            [state.dynamicTargets containsObject: nodeKey])
            [self raiseRejectedPatch];
        [state.dynamicTargets addObject: nodeKey];
        state.parentByDynamicTarget[nodeKey] = [self keyForIdentifier:
            operation.parentIdentifier];
        state.tagNamesByDynamicTarget[nodeKey] = $assert_nonnil(rootTag);
        return;
    }
    case OWebPatchOpcodeRemoveNode: {
        auto nodeKey = [self keyForIdentifier: operation.nodeIdentifier];
        if (not [state.dynamicTargets containsObject: nodeKey])
            [self raiseRejectedPatch];
        [self removeDynamicTargetAndDescendants: nodeKey state: state];
        return;
    }
    case OWebPatchOpcodeMoveNode: {
        auto nodeKey = [self keyForIdentifier: operation.nodeIdentifier];
        auto parentKey = [self keyForIdentifier: operation.parentIdentifier];
        if (not [state.dynamicTargets containsObject: nodeKey] ||
            not [self isValidTarget: operation.parentIdentifier state: state] ||
            not [self targetCanContainChildren: operation.parentIdentifier
                state: state] ||
            [self movingNode: nodeKey belowParent: parentKey
                createsCycle: state])
            [self raiseRejectedPatch];
        if (operation.beforeIdentifier != 0) {
            auto beforeKey = [self keyForIdentifier:
                operation.beforeIdentifier];
            if (not [state.dynamicTargets containsObject: beforeKey] ||
                [beforeKey isEqual: nodeKey] ||
                not [state.parentByDynamicTarget[beforeKey] isEqual: parentKey])
                [self raiseRejectedPatch];
        }
        state.parentByDynamicTarget[nodeKey] = parentKey;
        return;
    }
    }
    [self raiseRejectedPatch];
}

- (OWebMountedState *)candidateStateForOperations:
    (OFArray<OWebPatchOperation *> *)operations
{
    auto candidate = [[OWebMountedState alloc] initWithState: _state];
    for (OWebPatchOperation *operation in operations)
        [self validateAndApplyOperation: operation state: candidate];
    return candidate;
}

- (void)commitState: (OWebMountedState *)state
{
    _state = state;
}

- (OFArray<OWebPatchOperation *> *)dynamicTeardownOperations
{
    auto roots = [OFMutableArray<OFNumber *> array];
    for (OFNumber *target in _state.dynamicTargets) {
        OFNumber *parent = _state.parentByDynamicTarget[target];
        if (parent == nilptr || not [_state.dynamicTargets containsObject: parent])
            [roots addObject: target];
    }
    auto operations = [OFMutableArray<OWebPatchOperation *> array];
    for (OFNumber *root in roots.sortedArray)
        [operations addObject: [OWebPatchOperation removeNode:
            root.unsignedLongLongValue]];
    return [operations copy];
}

@end


[[subclassing_restricted, direct_members]]
@interface OWebReplayEntry : OFObject

@property(nonatomic, readonly) uint64_t sequence;
@property(nonatomic, readonly) OFString *requestDigest;
@property(nonatomic, readonly, nullable) OWebPatchFrame *patch;
@property(nonatomic, readonly, nullable) OWebSessionException *failure;

- (instancetype)initWithSequence: (uint64_t)sequence
                    requestDigest: (OFString *)requestDigest
                            patch: (nullable OWebPatchFrame *)patch
                          failure: (nullable OWebSessionException *)failure;
- (instancetype)init OF_UNAVAILABLE;

@end


@implementation OWebReplayEntry

- (instancetype)initWithSequence: (uint64_t)sequence
                    requestDigest: (OFString *)requestDigest
                            patch: (OWebPatchFrame *nillable)patch
                          failure: (OWebSessionException *nillable)failure
{
    self = [super init];
    _sequence = sequence;
    _requestDigest = [requestDigest copy];
    _patch = patch;
    _failure = failure;
    return self;
}

@end


@interface OWebComponentSession ()

- (void)quarantineInstanceIdentifier: (uint64_t)instanceIdentifier;
- (uint64_t)instanceIdentifierForFrame: (id<OWebWireFrame>)frame;

@end


@implementation OWebComponentSession {
    OFMutableDictionary<OFNumber *, OWebMountedComponent *>
        *_mountedComponentsByIdentifier;
    OFMutableDictionary<OFNumber *, OWebReplayEntry *>
        *_replayEntriesByIdentifier;
    OFMutableArray<OFNumber *> *_replayOrder;
}

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
{
    return [self initWithRegistry: registry
         maximumMountedInstances: OWebDefaultMaximumMountedInstances
            maximumReplayEntries: OWebDefaultMaximumReplayEntries];
}

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
             maximumMountedInstances: (size_t)maximumMountedInstances
                maximumReplayEntries: (size_t)maximumReplayEntries
{
    self = [super init];
    if (maximumMountedInstances == 0 || maximumReplayEntries == 0 ||
        maximumReplayEntries < maximumMountedInstances)
        @throw [OFInvalidArgumentException exception];
    _registry = registry;
    _maximumMountedInstances = maximumMountedInstances;
    _maximumReplayEntries = maximumReplayEntries;
    _mountedComponentsByIdentifier = [[OFMutableDictionary alloc] init];
    _replayEntriesByIdentifier = [[OFMutableDictionary alloc] init];
    _replayOrder = [[OFMutableArray alloc] init];
    return self;
}

- (size_t)mountedInstanceCount
{
    @synchronized (self) {
        return _mountedComponentsByIdentifier.count;
    }
}

- (size_t)replayEntryCount
{
    @synchronized (self) {
        return _replayEntriesByIdentifier.count;
    }
}

- (OFNumber *)keyForIdentifier: (uint64_t)identifier
{
    return @(identifier);
}

- (OWebSessionException *)failure: (OWebSessionFailure)failure
{
    return [OWebSessionException exceptionWithFailure: failure];
}

- (void)preflightPatch: (OWebPatchFrame *nillable)patch
{
    if (patch == nilptr)
        return;
    @try {
        (void)[OWebWireCodec encodeFrame: $assert_nonnil(patch)];
    } @catch (OWebWireProtocolException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureComponentRejectedInput];
    }
}

- (OWebPatchFrame *nillable)patchForInstanceIdentifier:
    (uint64_t)instanceIdentifier
                                     mountedComponent:
                                         (OWebMountedComponent *)mounted
                                         operations:
    (OFArray<OWebPatchOperation *> *)operations
{
    if (operations.count == 0)
        return nilptr;
    auto candidate = [mounted candidateStateForOperations: operations];
    auto patch = [[OWebPatchFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier operations: operations];
    [self preflightPatch: patch];
    [mounted commitState: candidate];
    return patch;
}

- (OWebMountedComponent *)newMountedComponentForFrame:
    (OWebMountFrame *)frame
{
    auto definition = [_registry definitionForElementName: frame.componentTag];
    if (definition == nilptr)
        @throw [self failure: OWebSessionFailureUnknownComponent];

    OWebComponent *component;
    @try {
        component = [definition instantiateWithAttributes: frame.attributes];
    } @catch (OWebDefinitionException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureComponentRejectedInput];
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureComponentRejectedInput];
    } @catch (OFOutOfRangeException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureComponentRejectedInput];
    } @catch (id exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureInternalError];
    }
    return [[OWebMountedComponent alloc]
        initWithComponentTag: frame.componentTag attributes: frame.attributes
        definition: $assert_nonnil(definition) component: component];
}

- (OWebPatchFrame *nillable)processMount: (OWebMountFrame *)frame
{
    auto key = [self keyForIdentifier: frame.instanceIdentifier];
    OWebMountedComponent *existing = _mountedComponentsByIdentifier[key];
    if (existing != nilptr) {
        if (not [existing.componentTag isEqual: frame.componentTag])
            @throw [self failure: OWebSessionFailureInstanceConflict];
        if ([existing.attributes isEqual: frame.attributes])
            return [self patchForInstanceIdentifier: frame.instanceIdentifier
                mountedComponent: existing
                operations: existing.component.drainPatches];
    } else if (_mountedComponentsByIdentifier.count >=
        _maximumMountedInstances) {
        @throw [self failure: OWebSessionFailureCapacityExceeded];
    }

    auto replacement = [self newMountedComponentForFrame: frame];
    auto initialOperations = replacement.component.drainPatches;
    auto replacementCandidate = [replacement
        candidateStateForOperations: initialOperations];
    auto operations = [OFMutableArray<OWebPatchOperation *> array];
    OWebMountedState *existingCandidate = nilptr;
    if (existing != nilptr) {
        auto teardown = existing.dynamicTeardownOperations;
        existingCandidate = [existing candidateStateForOperations: teardown];
        [operations addObjectsFromArray: teardown];
    }
    [operations addObjectsFromArray: initialOperations];
    OWebPatchFrame *patch = operations.count == 0 ? nilptr
        : [[OWebPatchFrame alloc]
            initWithInstanceIdentifier: frame.instanceIdentifier
                              operations: operations];
    [self preflightPatch: patch];
    if (existingCandidate != nilptr)
        [existing commitState: $assert_nonnil(existingCandidate)];
    [replacement commitState: replacementCandidate];
    _mountedComponentsByIdentifier[key] = replacement;
    return patch;
}

- (id)eventFieldValue: (OWebWireValue *)value
{
    switch (value.type) {
    case OWebWireValueTypeNull:
        return [OFNull null];
    case OWebWireValueTypeFalse:
    case OWebWireValueTypeTrue:
        return @(value.boolValue);
    case OWebWireValueTypeSignedInteger:
        return @(value.signedIntegerValue);
    case OWebWireValueTypeUnsignedInteger:
        return @(value.unsignedIntegerValue);
    case OWebWireValueTypeDouble:
        return @(value.doubleValue);
    case OWebWireValueTypeString:
        if (value.stringValue == nilptr)
            @throw [self failure: OWebSessionFailureInvalidEventValue];
        return $assert_nonnil(value.stringValue);
    }
    @throw [self failure: OWebSessionFailureInvalidEventValue];
}

- (OWebPatchFrame *nillable)processEvent: (OWebEventFrame *)frame
{
    auto key = [self keyForIdentifier: frame.instanceIdentifier];
    OWebMountedComponent *mounted = _mountedComponentsByIdentifier[key];
    if (mounted == nilptr)
        @throw [self failure: OWebSessionFailureUnknownInstance];

    auto actionKey = [self keyForIdentifier: frame.actionIdentifier];
    OWebActionDefinition *action =
        mounted.definition.actionsByIdentifier[actionKey];
    if (action == nilptr)
        @throw [self failure: OWebSessionFailureUnknownAction];
    if (frame.targetIdentifier != action.targetIdentifier ||
        not [mounted isValidEventTarget: frame.targetIdentifier])
        @throw [self failure: OWebSessionFailureInvalidTarget];

    auto fields = [OFMutableDictionary<OFString *, id> dictionary];
    for (OFString *name in frame.fields) {
        auto value = frame.fields[name];
        if (value == nilptr || not [OWebWireCodec
            isEventFieldNameAllowed: name])
            @throw [self failure: OWebSessionFailureInvalidEventValue];
        fields[name] = [self eventFieldValue: $assert_nonnil(value)];
    }

    OWebEvent *event;
    @try {
        event = [[OWebEvent alloc] initWithType: action.eventName
            targetIdentifier: frame.targetIdentifier fields: fields];
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureInvalidEventValue];
    } @catch (OFOutOfRangeException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureInvalidEventValue];
    }

    @try {
        [mounted.component dispatchActionIdentifier: frame.actionIdentifier
                                             event: event];
        auto operations = mounted.component.drainPatches;
        return [self patchForInstanceIdentifier: frame.instanceIdentifier
            mountedComponent: mounted operations: operations];
    } @catch (OWebSessionException *exception) {
        @throw exception;
    } @catch (id exception) {
        (void)exception;
        @try {
            (void)mounted.component.drainPatches;
        } @catch (id cleanupException) {
            (void)cleanupException;
        }
        @throw [self failure: OWebSessionFailureInternalError];
    }
}

- (OWebPatchFrame *nillable)processDetach: (OWebDetachFrame *)frame
{
    auto key = [self keyForIdentifier: frame.instanceIdentifier];
    if (_mountedComponentsByIdentifier[key] == nilptr)
        @throw [self failure: OWebSessionFailureUnknownInstance];
    [_mountedComponentsByIdentifier removeObjectForKey: key];
    return nilptr;
}

- (uint64_t)instanceIdentifierForFrame: (id<OWebWireFrame>)frame
{
    switch (frame.frameType) {
    case OWebWireFrameTypeMount:
        if ([(id)frame isKindOfClass: [OWebMountFrame class]])
            return ((OWebMountFrame *)frame).instanceIdentifier;
        break;
    case OWebWireFrameTypeEvent:
        if ([(id)frame isKindOfClass: [OWebEventFrame class]])
            return ((OWebEventFrame *)frame).instanceIdentifier;
        break;
    case OWebWireFrameTypeDetach:
        if ([(id)frame isKindOfClass: [OWebDetachFrame class]])
            return ((OWebDetachFrame *)frame).instanceIdentifier;
        break;
    case OWebWireFrameTypePatch:
        break;
    }
    @throw [self failure: OWebSessionFailureUnexpectedFrame];
}

- (OFString *)requestDigestForFrame: (id<OWebWireFrame>)frame
{
    @try {
        return [OWebWireCodec encodeFrame: frame].stringBySHA256Hashing;
    } @catch (OWebWireProtocolException *exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureInvalidFrame];
    }
}

- (void)storeReplayForKey: (OFNumber *)key
                     sequence: (uint64_t)sequence
                requestDigest: (OFString *)requestDigest
                        patch: (OWebPatchFrame *nillable)patch
                      failure: (OWebSessionException *nillable)failure
{
    if (_replayEntriesByIdentifier[key] != nilptr)
        [_replayOrder removeObject: key];
    while (_replayOrder.count >= _maximumReplayEntries) {
        size_t evictionIndex = OFNotFound;
        for (size_t index = 0; index < _replayOrder.count; index++) {
            OFNumber *candidate = _replayOrder[index];
            if (_mountedComponentsByIdentifier[candidate] == nilptr) {
                evictionIndex = index;
                break;
            }
        }
        if (evictionIndex == OFNotFound)
            return;
        OFNumber *evicted = _replayOrder[evictionIndex];
        [_replayEntriesByIdentifier removeObjectForKey: evicted];
        [_replayOrder removeObjectAtIndex: evictionIndex];
    }
    _replayEntriesByIdentifier[key] = [[OWebReplayEntry alloc]
        initWithSequence: sequence requestDigest: requestDigest
        patch: patch failure: failure];
    [_replayOrder addObject: key];
}

- (OWebPatchFrame *nillable)replayEntry: (OWebReplayEntry *)entry
{
    if (entry.failure != nilptr)
        @throw $assert_nonnil(entry.failure);
    return entry.patch;
}

- (OWebPatchFrame *nillable)processFrame: (id<OWebWireFrame>)frame
                                     sequence: (uint64_t)sequence
{
    if (sequence == 0)
        @throw [self failure: OWebSessionFailureInvalidSequence];

    uint64_t instanceIdentifier;
    OFString *requestDigest;
    @try {
        instanceIdentifier = [self instanceIdentifierForFrame: frame];
        requestDigest = [self requestDigestForFrame: frame];
    } @catch (OWebSessionException *exception) {
        @throw exception;
    } @catch (id exception) {
        (void)exception;
        @throw [self failure: OWebSessionFailureInternalError];
    }

    auto key = [self keyForIdentifier: instanceIdentifier];
    @synchronized (self) {
        OWebReplayEntry *replay = _replayEntriesByIdentifier[key];
        if (replay != nilptr) {
            if (sequence < replay.sequence)
                @throw [self failure: OWebSessionFailureStaleSequence];
            if (sequence == replay.sequence) {
                if (not [requestDigest isEqual: replay.requestDigest])
                    @throw [self failure:
                        OWebSessionFailureSequenceConflict];
                return [self replayEntry: replay];
            }
        }
        OWebMountedComponent *prior = _mountedComponentsByIdentifier[key];
        if (prior != nilptr && sequence <= prior.lastSequence)
            @throw [self failure: OWebSessionFailureStaleSequence];

        OWebPatchFrame *patch = nilptr;
        @try {
            switch (frame.frameType) {
            case OWebWireFrameTypeMount:
                patch = [self processMount: (OWebMountFrame *)frame];
                break;
            case OWebWireFrameTypeEvent:
                patch = [self processEvent: (OWebEventFrame *)frame];
                break;
            case OWebWireFrameTypeDetach:
                patch = [self processDetach: (OWebDetachFrame *)frame];
                break;
            case OWebWireFrameTypePatch:
                @throw [self failure: OWebSessionFailureUnexpectedFrame];
            }
        } @catch (OWebSessionException *exception) {
            if (exception.failure == OWebSessionFailureComponentRejectedInput ||
                exception.failure == OWebSessionFailureInternalError)
                [self quarantineInstanceIdentifier: instanceIdentifier];
            [self storeReplayForKey: key sequence: sequence
                requestDigest: requestDigest patch: nilptr failure: exception];
            @throw exception;
        } @catch (id exception) {
            (void)exception;
            [self quarantineInstanceIdentifier: instanceIdentifier];
            auto failure = [self failure: OWebSessionFailureInternalError];
            [self storeReplayForKey: key sequence: sequence
                requestDigest: requestDigest patch: nilptr failure: failure];
            @throw failure;
        }

        OWebMountedComponent *mounted = _mountedComponentsByIdentifier[key];
        if (mounted != nilptr)
            mounted.lastSequence = sequence;
        [self storeReplayForKey: key sequence: sequence
            requestDigest: requestDigest patch: patch failure: nilptr];
        return patch;
    }
}

- (bool)ownsInstanceIdentifier: (uint64_t)instanceIdentifier
{
    if (instanceIdentifier == 0)
        return false;
    @synchronized (self) {
        return _mountedComponentsByIdentifier[
            [self keyForIdentifier: instanceIdentifier]] != nilptr;
    }
}

- (void)quarantineInstanceIdentifier: (uint64_t)instanceIdentifier
{
    if (instanceIdentifier == 0)
        return;
    @synchronized (self) {
        [_mountedComponentsByIdentifier removeObjectForKey:
            [self keyForIdentifier: instanceIdentifier]];
    }
}

@end


[[subclassing_restricted, direct_members]]
@interface OWebEndpointSessionEntry : OFObject

@property(nonatomic, readonly) OWebComponentSession *session;
@property(nonatomic) OFTimeInterval lastAccessTime;

- (instancetype)initWithSession: (OWebComponentSession *)session
                  lastAccessTime: (OFTimeInterval)lastAccessTime;
- (instancetype)init OF_UNAVAILABLE;

@end


@implementation OWebEndpointSessionEntry

- (instancetype)initWithSession: (OWebComponentSession *)session
                  lastAccessTime: (OFTimeInterval)lastAccessTime
{
    self = [super init];
    _session = session;
    _lastAccessTime = lastAccessTime;
    return self;
}

@end


@implementation OWebComponentEndpoint {
    OWebSessionIdentityProvider _sessionIdentityProvider;
    OFMutableDictionary<OFString *, OWebEndpointSessionEntry *>
        *_sessionsByIdentity;
}

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
                   expectedOrigin: (OFString *)expectedOrigin
                 maximumBodyBytes: (size_t)maximumBodyBytes
         sessionIdentityProvider:
             (OWebSessionIdentityProvider)sessionIdentityProvider
{
    return [self initWithRegistry: registry expectedOrigin: expectedOrigin
        maximumBodyBytes: maximumBodyBytes
        maximumSessions: OWebDefaultMaximumSessions
        sessionIdleTimeToLive: OWebDefaultSessionIdleTimeToLive
        maximumMountedInstancesPerSession:
            OWebDefaultMaximumMountedInstances
        maximumReplayEntriesPerSession: OWebDefaultMaximumReplayEntries
        sessionIdentityProvider: sessionIdentityProvider];
}

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
                   expectedOrigin: (OFString *)expectedOrigin
                 maximumBodyBytes: (size_t)maximumBodyBytes
                  maximumSessions: (size_t)maximumSessions
            sessionIdleTimeToLive: (OFTimeInterval)sessionIdleTimeToLive
 maximumMountedInstancesPerSession:
     (size_t)maximumMountedInstancesPerSession
    maximumReplayEntriesPerSession:
        (size_t)maximumReplayEntriesPerSession
         sessionIdentityProvider:
             (OWebSessionIdentityProvider)sessionIdentityProvider
{
    self = [super init];
    if (expectedOrigin.length == 0 || [expectedOrigin hasSuffix: @"/"] ||
        not ([expectedOrigin hasPrefix: @"http://"] ||
             [expectedOrigin hasPrefix: @"https://"]) ||
        maximumBodyBytes == 0 ||
        maximumBodyBytes > OWebWireMaximumFrameBytes ||
        maximumSessions == 0 || sessionIdleTimeToLive <= 0 ||
        maximumMountedInstancesPerSession == 0 ||
        maximumReplayEntriesPerSession <
            maximumMountedInstancesPerSession ||
        sessionIdentityProvider == nilptr)
        @throw [OFInvalidArgumentException exception];
    _registry = registry;
    _expectedOrigin = [expectedOrigin copy];
    _maximumBodyBytes = maximumBodyBytes;
    _maximumSessions = maximumSessions;
    _sessionIdleTimeToLive = sessionIdleTimeToLive;
    _maximumMountedInstancesPerSession = maximumMountedInstancesPerSession;
    _maximumReplayEntriesPerSession = maximumReplayEntriesPerSession;
    _sessionIdentityProvider = [sessionIdentityProvider copy];
    _sessionsByIdentity = [[OFMutableDictionary alloc] init];
    return self;
}

- (void)installOnRouter: (OWebRouter *)router path: (OFString *)path
{
    __weak OWebComponentEndpoint *weakSelf = self;
    [router post: path handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
        auto strongSelf = weakSelf;
        if (strongSelf == nilptr)
            return [OWebHTTPResponse textResponse: @"endpoint-unavailable"
                                         statusCode: 503];
        return [strongSelf handleRequest: request];
    }];
}

- (OWebSessionException *)failure: (OWebSessionFailure)failure
{
    return [OWebSessionException exceptionWithFailure: failure];
}

- (bool)header: (OFString *)header equalsToken: (OFString *)token
{
    return [[header stringByDeletingEnclosingWhitespaces]
        caseInsensitiveCompare: token] == OFOrderedSame;
}

- (uint64_t)sequenceFromRequest: (OWebHTTPRequest *)request
{
    OFString *value = [request headerForName: @"X-OWeb-Sequence"];
    if (value == nilptr || value.length == 0 || value.length > 20 ||
        [value characterAtIndex: 0] == '0')
        @throw [self failure: OWebSessionFailureInvalidSequence];
    uint64_t result = 0;
    for (size_t index = 0; index < value.length; index++) {
        OFUnichar character = [value characterAtIndex: index];
        if (character < '0' || character > '9')
            @throw [self failure: OWebSessionFailureInvalidSequence];
        uint8_t digit = (uint8_t)(character - '0');
        if (result > (UINT64_MAX - digit) / 10)
            @throw [self failure: OWebSessionFailureInvalidSequence];
        result = result * 10 + digit;
    }
    if (result == 0)
        @throw [self failure: OWebSessionFailureInvalidSequence];
    return result;
}

- (void)validateRequestBoundary: (OWebHTTPRequest *)request
{
    OFString *origin = [request headerForName: @"Origin"];
    if (origin == nilptr || not [origin isEqual: _expectedOrigin])
        @throw [self failure: OWebSessionFailureInvalidOrigin];
    OFString *contentType = [request headerForName: @"Content-Type"];
    if (contentType == nilptr || not [self header: contentType
        equalsToken: @"application/vnd.oweb.frame"])
        @throw [self failure: OWebSessionFailureInvalidContentType];
    OFString *accept = [request headerForName: @"Accept"];
    if (accept == nilptr || not [self header: accept
        equalsToken: @"application/vnd.oweb.frame"])
        @throw [self failure: OWebSessionFailureNotAcceptable];
    if (request.bodyByteCount == 0)
        @throw [self failure: OWebSessionFailureInvalidFrame];
    if (request.bodyByteCount > _maximumBodyBytes ||
        request.bodyByteCount > OWebWireMaximumFrameBytes)
        @throw [self failure: OWebSessionFailureBodyTooLarge];
}

- (OFString *)identityForRequest: (OWebHTTPRequest *)request
{
    OFString *identity = _sessionIdentityProvider(request);
    if (identity == nilptr || identity.length == 0 ||
        identity.UTF8StringLength > OWebMaximumSessionIdentityBytes)
        @throw [self failure: OWebSessionFailureInvalidIdentity];
    return $assert_nonnil(identity);
}

- (OFTimeInterval)currentTime
{
    return OFDate.date.timeIntervalSince1970;
}

- (void)purgeExpiredSessionsAtTime: (OFTimeInterval)time
{
    auto expired = [OFMutableArray<OFString *> array];
    for (OFString *identity in _sessionsByIdentity) {
        auto entry = _sessionsByIdentity[identity];
        if (entry != nilptr &&
            time - entry.lastAccessTime >= _sessionIdleTimeToLive)
            [expired addObject: identity];
    }
    for (OFString *identity in expired)
        [_sessionsByIdentity removeObjectForKey: identity];
}

- (OWebComponentSession *)sessionForIdentity: (OFString *)identity
{
    @synchronized (self) {
        auto now = [self currentTime];
        [self purgeExpiredSessionsAtTime: now];
        OWebEndpointSessionEntry *entry = _sessionsByIdentity[identity];
        if (entry == nilptr) {
            if (_sessionsByIdentity.count >= _maximumSessions)
                @throw [self failure: OWebSessionFailureCapacityExceeded];
            auto session = [[OWebComponentSession alloc]
                initWithRegistry: _registry
                maximumMountedInstances:
                    _maximumMountedInstancesPerSession
                maximumReplayEntries: _maximumReplayEntriesPerSession];
            entry = [[OWebEndpointSessionEntry alloc]
                initWithSession: session lastAccessTime: now];
            _sessionsByIdentity[identity] = entry;
        } else
            entry.lastAccessTime = now;
        return entry.session;
    }
}

- (OWebHTTPResponse *)successfulResponseForPatch:
    (OWebPatchFrame *nillable)patch sequence: (uint64_t)sequence
{
    OFData *body = patch == nilptr ? [OFData data] : nilptr;
    if (patch != nilptr)
        body = [OWebWireCodec encodeFrame: $assert_nonnil(patch)];
    auto headers = [OFMutableDictionary<OFString *, OFString *> dictionary];
    headers[@"X-OWeb-Sequence"] = [OFString stringWithFormat: @"%llu",
        (unsigned long long)sequence];
    headers[@"Cache-Control"] = @"no-store";
    headers[@"Vary"] = @"Origin";
    if (patch != nilptr)
        headers[@"Content-Type"] = @"application/vnd.oweb.frame";
    return [[OWebHTTPResponse alloc]
        initWithStatusCode: patch == nilptr ? 204 : 200
                    headers: headers body: body];
}

- (OWebHTTPResponse *)errorResponseForException:
    (OWebSessionException *)exception
{
    auto response = [OWebHTTPResponse textResponse: exception.code
                                          statusCode: exception.statusCode];
    auto headers = [response.headers mutableCopy];
    headers[@"Cache-Control"] = @"no-store";
    headers[@"Vary"] = @"Origin";
    headers[@"X-Content-Type-Options"] = @"nosniff";
    response.headers = headers;
    return response;
}

- (OWebHTTPResponse *)handleRequest: (OWebHTTPRequest *)request
{
    OWebComponentSession *session = nilptr;
    uint64_t instanceIdentifier = 0;
    @try {
        if (request.method != OFHTTPRequestMethodPost)
            @throw [self failure: OWebSessionFailureUnexpectedFrame];
        [self validateRequestBoundary: request];
        uint64_t sequence = [self sequenceFromRequest: request];
        OFString *identity = [self identityForRequest: request];
        id<OWebWireFrame> frame;
        @try {
            frame = [OWebWireCodec decodeFrameData: request.body];
        } @catch (OWebWireProtocolException *exception) {
            (void)exception;
            @throw [self failure: OWebSessionFailureInvalidFrame];
        }
        session = [self sessionForIdentity: identity];
        instanceIdentifier = [session instanceIdentifierForFrame: frame];
        auto patch = [session processFrame: frame sequence: sequence];
        return [self successfulResponseForPatch: patch sequence: sequence];
    } @catch (OWebSessionException *exception) {
        return [self errorResponseForException: exception];
    } @catch (id exception) {
        (void)exception;
        if (session != nilptr && instanceIdentifier != 0)
            [session quarantineInstanceIdentifier: instanceIdentifier];
        return [self errorResponseForException:
            [self failure: OWebSessionFailureInternalError]];
    }
}

- (OWebComponentSession *nillable)existingSessionForIdentity:
    (OFString *)identity
{
    @synchronized (self) {
        [self purgeExpiredSessionsAtTime: [self currentTime]];
        return _sessionsByIdentity[identity].session;
    }
}

- (size_t)activeSessionCount
{
    @synchronized (self) {
        [self purgeExpiredSessionsAtTime: [self currentTime]];
        return _sessionsByIdentity.count;
    }
}

- (void)removeSessionForIdentity: (OFString *)identity
{
    @synchronized (self) {
        [_sessionsByIdentity removeObjectForKey: identity];
    }
}

@end


#pragma clang assume_nonnull end
