#import <OWebComponent.h>

#import <OWebReflection.h>
#import <OWebTemplate.h>
#import <OWebWireProtocol.h>

#import "OWebReflectionInternal.h"

#include <limits.h>

#pragma clang assume_nonnull begin

@interface OWebElement ()

- (instancetype)initWithLogicalIdentifier: (OFString *)logicalIdentifier
                                identifier: (uint64_t)identifier
                                     owner: (OWebComponent *)owner;
- (void)markDetached;

@end


@implementation OWebEvent

- (instancetype)initWithType: (OFString *)type
             targetIdentifier: (uint64_t)targetIdentifier
                        fields: (OFDictionary<OFString *, id> *)fields
{
    self = [super init];
    if (type.length == 0 || type.length > 32 || targetIdentifier == 0 ||
        fields.count > 32)
        @throw [OFInvalidArgumentException exception];

    for (OFString *name in fields) {
        id value = fields[name];
        if (not [OWebWireCodec isEventFieldNameAllowed: name] ||
            (value != [OFNull null] && not [value isKindOfClass: [OFString class]] &&
             not [value isKindOfClass: [OFNumber class]]))
            @throw [OFInvalidArgumentException exception];
    }
    _type = [type copy];
    _targetIdentifier = targetIdentifier;
    _fields = [fields copy];
    return self;
}

@end


@implementation OWebElement {
    __weak OWebComponent *_owner;
    OFMutableDictionary<OFString *, OFString *> *_attributes;
    OFMutableSet<OFString *> *_knownAttributes;
    OFMutableDictionary<OFString *, OWebElement *> *_childrenByKey;
    OFMutableArray<OWebElement *> *_childOrder;
    bool _isAttached;
    bool _hasAssignedTextContent;
}

- (instancetype)initWithLogicalIdentifier: (OFString *)logicalIdentifier
                                identifier: (uint64_t)identifier
                                     owner: (OWebComponent *)owner
{
    self = [super init];
    if (logicalIdentifier.length == 0 || identifier == 0)
        @throw [OFInvalidArgumentException exception];
    _logicalIdentifier = [logicalIdentifier copy];
    _identifier = identifier;
    _owner = owner;
    _textContent = @"";
    _attributes = [[OFMutableDictionary alloc] init];
    _knownAttributes = [[OFMutableSet alloc] init];
    _childrenByKey = [[OFMutableDictionary alloc] init];
    _childOrder = [[OFMutableArray alloc] init];
    _isAttached = true;
    return self;
}

- (void)requireAttached
{
    if (not _isAttached || _owner == nilptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Element proxy is no longer attached"];
}

- (void)setTextContent: (OFString *)textContent
{
    [self requireAttached];
    if (textContent.UTF8StringLength > 64 * 1024)
        @throw [OFOutOfRangeException exception];
    if (_hasAssignedTextContent && [_textContent isEqual: textContent])
        return;
    _hasAssignedTextContent = true;
    _textContent = [textContent copy];
    [_owner emitPatch: [OWebPatchOperation setText: _textContent
                                             forElement: _identifier]];
}

- (void)setAttribute: (OFString *)name value: (OFString *)value
{
    [self requireAttached];
    if ([name isEqual: @"id"] ||
        not [OWebWireCodec isPatchAttributeNameAllowed: name] ||
        not [OWebTemplateCompiler isRuntimeAttributeNameSafe: name value: value])
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Unsafe runtime attribute '%@'", name]];
    if (value.UTF8StringLength > 64 * 1024)
        @throw [OFOutOfRangeException exception];
    OFString *prior = _attributes[name];
    if ([_knownAttributes containsObject: name] && prior != nilptr &&
        [prior isEqual: value])
        return;
    [_knownAttributes addObject: name];
    _attributes[name] = [value copy];
    [_owner emitPatch: [OWebPatchOperation setAttribute: name value: value
                                                 forElement: _identifier]];
}

- (void)removeAttribute: (OFString *)name
{
    [self requireAttached];
    if ([name isEqual: @"id"] ||
        not [OWebWireCodec isPatchAttributeNameAllowed: name] ||
        not [OWebTemplateCompiler isRuntimeAttributeNameSafe: name
                                                          value: @"oweb-safe"])
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Unsafe runtime attribute '%@'", name]];
    if ([_knownAttributes containsObject: name] && _attributes[name] == nilptr)
        return;
    [_knownAttributes addObject: name];
    [_attributes removeObjectForKey: name];
    [_owner emitPatch: [OWebPatchOperation removeAttribute: name
                                                  forElement: _identifier]];
}

- (void)focus
{
    [self requireAttached];
    [_owner emitPatch: [OWebPatchOperation focusElement: _identifier]];
}

- (void)validateCollectionKey: (OFString *)key
{
    if (key.length == 0 || key.length > 128)
        @throw [OFInvalidArgumentException exception];
    for (size_t index = 0; index < key.length; index++) {
        OFUnichar character = [key characterAtIndex: index];
        if (character <= 0x20 || character == 0x7F)
            @throw [OFInvalidArgumentException exception];
    }
}

- (OWebElement *)appendTemplateWithID: (OFString *)templateID
                                  key: (OFString *)key
{
    [self requireAttached];
    [self validateCollectionKey: key];
    if (_childrenByKey[key] != nilptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Collection key '%@' already exists under '%@'",
                key, _logicalIdentifier]];
    OFNumber *templateIdentifier = [_owner templateIdentifierForID: templateID];
    uint64_t nodeIdentifier = [_owner allocateDynamicNodeIdentifier];
    auto child = [[OWebElement alloc]
        initWithLogicalIdentifier: key identifier: nodeIdentifier owner: _owner];
    _childrenByKey[key] = child;
    [_childOrder addObject: child];
    [_owner emitPatch: [OWebPatchOperation
        cloneTemplate: templateIdentifier.unsignedLongLongValue
        intoParent: _identifier asNode: nodeIdentifier]];
    return child;
}

- (void)requireDirectChild: (OWebElement *)child
{
    if (child == self || child->_owner != _owner ||
        not [_childOrder containsObjectIdenticalTo: child])
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Element is not a direct keyed child of this parent"];
}

- (void)removeChild: (OWebElement *)child
{
    [self requireAttached];
    [self requireDirectChild: child];
    OFString *key = nilptr;
    for (OFString *candidate in _childrenByKey)
        if (_childrenByKey[candidate] == child) {
            key = candidate;
            break;
        }
    [_owner emitPatch: [OWebPatchOperation removeNode: child.identifier]];
    [_childOrder removeObjectIdenticalTo: child];
    if (key != nilptr)
        [_childrenByKey removeObjectForKey: key];
    [child markDetached];
}

- (void)moveChild: (OWebElement *)child
       beforeChild: (OWebElement *nillable)beforeChild
{
    [self requireAttached];
    [self requireDirectChild: child];
    if (beforeChild != nilptr)
        [self requireDirectChild: $assert_nonnil(beforeChild)];
    if (beforeChild == child)
        return;

    [_childOrder removeObjectIdenticalTo: child];
    if (beforeChild == nilptr)
        [_childOrder addObject: child];
    else {
        size_t index = [_childOrder indexOfObjectIdenticalTo:
            $assert_nonnil(beforeChild)];
        [_childOrder insertObject: child atIndex: index];
    }
    [_owner emitPatch: [OWebPatchOperation moveNode: child.identifier
        intoParent: _identifier
        beforeNode: beforeChild != nilptr ? beforeChild.identifier : 0]];
}

- (void)markDetached
{
    _isAttached = false;
    for (OWebElement *child in _childOrder)
        [child markDetached];
    [_childOrder removeAllObjects];
    [_childrenByKey removeAllObjects];
}

@end


@implementation OWebComponent {
    OFMutableDictionary<OFString *, OWebElement *> *_elementsByID;
    OFMutableArray<OWebPatchOperation *> *_pendingPatches;
    OWebPatchSink _patchSink;
    uint64_t _nextDynamicNodeIdentifier;
}

+ (OFString *)style
{
    return @"";
}

+ (OFString *)layout
{
    return @"";
}

+ (OFString *)elementName
{
    OFString *className = [OFString stringWithUTF8String: class_getName(self)];
    auto result = [OFMutableString string];
    for (size_t index = 0; index < className.length; index++) {
        OFUnichar character = [className characterAtIndex: index];
        bool uppercase = character >= 'A' && character <= 'Z';
        if (uppercase && index > 0) {
            OFUnichar previous = [className characterAtIndex: index - 1];
            OFUnichar next = index + 1 < className.length
                ? [className characterAtIndex: index + 1] : 0;
            bool previousLowerOrDigit =
                (previous >= 'a' && previous <= 'z') ||
                (previous >= '0' && previous <= '9');
            bool nextLower = next >= 'a' && next <= 'z';
            if (previousLowerOrDigit || nextLower)
                [result appendString: @"-"];
        }
        if (uppercase)
            character = (OFUnichar)(character - 'A' + 'a');
        [result appendFormat: @"%C", character];
    }
    if (not [result containsString: @"-"])
        [result insertString: @"oweb-" atIndex: 0];
    return result;
}

- (instancetype)initWithDefinition: (OWebComponentDefinition *)definition
                          patchSink: (OWebPatchSink nillable)patchSink
{
    self = [super init];
    _definition = definition;
    _patchSink = [patchSink copy];
    _pendingPatches = [[OFMutableArray alloc] init];
    _elementsByID = [[OFMutableDictionary alloc] init];

    uint64_t maximumIdentifier = definition.maximumStaticIdentifier;
    for (OFString *logicalIdentifier in definition.elementIdentifiersByID) {
        uint64_t identifier = [definition.elementIdentifiersByID[logicalIdentifier]
            unsignedLongLongValue];
        maximumIdentifier = maximumIdentifier > identifier
            ? maximumIdentifier : identifier;
        _elementsByID[logicalIdentifier] = [[OWebElement alloc]
            initWithLogicalIdentifier: logicalIdentifier
            identifier: identifier owner: self];
    }
    for (OFString *templateID in definition.templateIdentifiersByID) {
        uint64_t identifier = [definition.templateIdentifiersByID[templateID]
            unsignedLongLongValue];
        maximumIdentifier = maximumIdentifier > identifier
            ? maximumIdentifier : identifier;
    }
    if (maximumIdentifier == UINT64_MAX)
        @throw [OFOutOfRangeException exception];
    _nextDynamicNodeIdentifier = maximumIdentifier + 1;
    return self;
}

- (void)onAttach
{
}

- (OWebElement *)elementByID: (OFString *)logicalIdentifier
{
    OWebElement *element = _elementsByID[logicalIdentifier];
    if (element == nilptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Template has no element with ID '%@'", logicalIdentifier]];
    return element;
}

- (void)emitPatch: (OWebPatchOperation *)patch
{
    @synchronized (self) {
        if (_pendingPatches.count >= 4096)
            @throw [OFOutOfRangeException exception];
        [_pendingPatches addObject: patch];
        if (_patchSink != nilptr)
            _patchSink(patch);
    }
}

- (OFArray<OWebPatchOperation *> *)drainPatches
{
    @synchronized (self) {
        OFArray<OWebPatchOperation *> *result = [_pendingPatches copy];
        [_pendingPatches removeAllObjects];
        return result;
    }
}

- (void)dispatchActionIdentifier: (uint64_t)actionIdentifier
                           event: (OWebEvent *)event
{
    [_definition dispatchActionIdentifier: actionIdentifier
        onComponent: self event: event];
}

- (uint64_t)allocateDynamicNodeIdentifier
{
    @synchronized (self) {
        if (_nextDynamicNodeIdentifier == 0 ||
            _nextDynamicNodeIdentifier == UINT64_MAX)
            @throw [OFOutOfRangeException exception];
        return _nextDynamicNodeIdentifier++;
    }
}

- (OFNumber *)templateIdentifierForID: (OFString *)templateID
{
    OFNumber *identifier = _definition.templateIdentifiersByID[templateID];
    if (identifier == nilptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Template has no declared <template> named '%@'", templateID]];
    return identifier;
}

@end

#pragma clang assume_nonnull end
