#import <OWebReflection.h>

#import "OWebReflectionInternal.h"

#include <errno.h>
#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#pragma clang assume_nonnull begin

@interface OWebReflectedProperty ()

- (nullable instancetype)initWithProperty: (objc_property_t)property
                     owningClass: (Class)owningClass
                  componentClass: (Class)componentClass;

@end


@interface OWebActionDefinition ()

- (instancetype)initWithIdentifier: (uint64_t)identifier
                   targetIdentifier: (uint64_t)targetIdentifier
                          eventName: (OFString *)eventName
                        selectorName: (OFString *)selectorName;

@end


@implementation OWebDefinitionException

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"OWeb definition error: %@", _reason];
}

@end


@implementation OWebReflectedProperty {
    Ivar _backingIvar;
    SEL _setter;
    char _typeEncoding;
}

+ (OFString *)kebabCaseName: (OFString *)name
{
    auto result = [OFMutableString string];
    for (size_t index = 0; index < name.length; index++) {
        OFUnichar character = [name characterAtIndex: index];
        bool uppercase = character >= 'A' && character <= 'Z';
        if (uppercase && index > 0) {
            OFUnichar previous = [name characterAtIndex: index - 1];
            OFUnichar next = index + 1 < name.length
                ? [name characterAtIndex: index + 1] : 0;
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
    return result;
}

+ (OWebReflectedPropertyType)propertyTypeForEncoding: (const char *)encoding
                                                  valid: (bool *)valid
{
    *valid = true;
    switch (encoding[0]) {
        case 'B': return OWebReflectedPropertyTypeBool;
        case 'c': case 's': case 'i': case 'l': case 'q':
            return OWebReflectedPropertyTypeSignedInteger;
        case 'C': case 'S': case 'I': case 'L': case 'Q':
            return OWebReflectedPropertyTypeUnsignedInteger;
        case 'f': return OWebReflectedPropertyTypeFloat;
        case 'd': return OWebReflectedPropertyTypeDouble;
        case '@':
            if (strcmp(encoding, "@\"OFString\"") == 0 ||
                strcmp(encoding, "@\"OFMutableString\"") == 0)
                return OWebReflectedPropertyTypeString;
            break;
        default:
            break;
    }
    *valid = false;
    return OWebReflectedPropertyTypeString;
}

+ (SEL)defaultSetterForPropertyName: (OFString *)name
{
    OFString *first = [[name substringWithRange: OFMakeRange(0, 1)]
        uppercaseString];
    OFString *rest = [name substringFromIndex: 1];
    OFString *setterName = [OFString stringWithFormat:
        @"set%@%@:", first, rest];
    return sel_registerName(setterName.UTF8String);
}

- (nullable instancetype)initWithProperty: (objc_property_t)property
                     owningClass: (Class)owningClass
                  componentClass: (Class)componentClass
{
    self = [super init];
    _name = [[OFString alloc] initWithUTF8String: property_getName(property)];
    _attributeName = [[[self class] kebabCaseName: _name] copy];

    char *type = property_copyAttributeValue(property, "T");
    if (type == nullptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Property '%@' has no runtime type encoding", _name]];
    bool valid = false;
    _type = [[self class] propertyTypeForEncoding: type valid: &valid];
    _typeEncoding = type[0];
    free(type);
    if (not valid)
        return nilptr;

    char *readonly = property_copyAttributeValue(property, "R");
    _isReadonly = readonly != nullptr;
    free(readonly);

    char *customSetter = property_copyAttributeValue(property, "S");
    _setter = customSetter != nullptr
        ? sel_registerName(customSetter)
        : [[self class] defaultSetterForPropertyName: _name];
    free(customSetter);

    Method setterMethod = class_getInstanceMethod(componentClass, _setter);
    if (setterMethod != nullptr) {
        char argumentType[8] = { 0 };
        char returnType[8] = { 0 };
        method_getArgumentType(setterMethod, 2, argumentType,
            sizeof(argumentType));
        method_getReturnType(setterMethod, returnType, sizeof(returnType));
        if (method_getNumberOfArguments(setterMethod) != 3 ||
            returnType[0] != 'v' || argumentType[0] != _typeEncoding)
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Setter for property '%@' has an incompatible signature",
                    _name]];
    } else
        _setter = nullptr;

    char *ivarName = property_copyAttributeValue(property, "V");
    if (ivarName != nullptr) {
        _backingIvar = class_getInstanceVariable(owningClass, ivarName);
        if (_backingIvar == nullptr)
            _backingIvar = class_getInstanceVariable(componentClass, ivarName);
    }
    free(ivarName);
    if (_backingIvar != nullptr &&
        ivar_getTypeEncoding(_backingIvar)[0] != _typeEncoding)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Backing ivar for property '%@' has an incompatible type",
                _name]];

    _isHydratable = _setter != nullptr || _backingIvar != nullptr;
    return self;
}

+ (OFArray<OWebReflectedProperty *> *)propertiesForComponentClass:
    (Class)componentClass
{
    auto hierarchy = [OFMutableArray<OFString *> array];
    auto classesByName = [OFMutableDictionary<OFString *, id> dictionary];
    for (Class current = componentClass;
         current != Nil && current != [OWebComponent class];
         current = class_getSuperclass(current)) {
        auto className = [OFString stringWithUTF8String: class_getName(current)];
        [hierarchy insertObject: className atIndex: 0];
        classesByName[className] = current;
    }

    auto propertiesByName = [OFMutableDictionary<OFString *, OWebReflectedProperty *>
        dictionary];
    auto attributeOwners = [OFMutableDictionary<OFString *, OFString *> dictionary];
    for (OFString *className in hierarchy) {
        Class current = classesByName[className];
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(current, &count);
        for (unsigned int index = 0; index < count; index++) {
            OWebReflectedProperty *nillable reflected =
                [[OWebReflectedProperty alloc]
                initWithProperty: properties[index]
                owningClass: current componentClass: componentClass];
            if (reflected == nilptr)
                continue;
            OWebReflectedProperty *property = $assert_nonnil(reflected);
            OFString *priorOwner = attributeOwners[property.attributeName];
            OWebReflectedProperty *prior = propertiesByName[property.name];
            if (priorOwner != nilptr && prior == nilptr)
                @throw [[OWebDefinitionException alloc]
                    initWithReason: [OFString stringWithFormat:
                        @"Properties map to the same attribute '%@'",
                        property.attributeName]];
            propertiesByName[property.name] = property;
            attributeOwners[property.attributeName] = property.name;
        }
        free(properties);
    }

    auto result = [OFMutableArray<OWebReflectedProperty *> array];
    for (OFString *name in propertiesByName.allKeys.sortedArray)
        [result addObject: $assert_nonnil(propertiesByName[name])];
    return [result copy];
}

- (void)raiseInvalidValue: (OFString *)value
{
    @throw [[OWebDefinitionException alloc]
        initWithReason: [OFString stringWithFormat:
            @"Attribute '%@' has invalid value '%@'", _attributeName, value]];
}

- (int64_t)parseSignedValue: (OFString *)value
{
    if (value.length == 0 ||
        not [value isEqual: value.stringByDeletingEnclosingWhitespaces])
        [self raiseInvalidValue: value];
    errno = 0;
    char *end = nullptr;
    long long parsed = strtoll(value.UTF8String, &end, 10);
    if (errno == ERANGE || end == value.UTF8String || *end != '\0')
        [self raiseInvalidValue: value];
    return (int64_t)parsed;
}

- (uint64_t)parseUnsignedValue: (OFString *)value
{
    if ([value hasPrefix: @"-"] || value.length == 0 ||
        not [value isEqual: value.stringByDeletingEnclosingWhitespaces])
        [self raiseInvalidValue: value];
    errno = 0;
    char *end = nullptr;
    unsigned long long parsed = strtoull(value.UTF8String, &end, 10);
    if (errno == ERANGE || end == value.UTF8String || *end != '\0')
        [self raiseInvalidValue: value];
    return (uint64_t)parsed;
}

- (double)parseDoubleValue: (OFString *)value
{
    if (value.length == 0 ||
        not [value isEqual: value.stringByDeletingEnclosingWhitespaces])
        [self raiseInvalidValue: value];
    errno = 0;
    char *end = nullptr;
    double parsed = strtod(value.UTF8String, &end);
    if (errno == ERANGE || end == value.UTF8String || *end != '\0' ||
        not isfinite(parsed))
        [self raiseInvalidValue: value];
    return parsed;
}

- (bool)parseBoolValue: (OFString *)value
{
    OFString *lowercase = value.lowercaseString;
    if (value.length == 0 || [lowercase isEqual: @"true"] ||
        [lowercase isEqual: @"1"] ||
        [lowercase isEqual: _attributeName.lowercaseString])
        return true;
    if ([lowercase isEqual: @"false"] || [lowercase isEqual: @"0"])
        return false;
    [self raiseInvalidValue: value];
    return false;
}

- (void)writeSignedValue: (int64_t)value atAddress: (void *)address
{
    switch (_typeEncoding) {
        case 'c':
            if (value < SCHAR_MIN || value > SCHAR_MAX) [self raiseInvalidValue: @"out of range"];
            *(signed char *)address = (signed char)value; break;
        case 's':
            if (value < SHRT_MIN || value > SHRT_MAX) [self raiseInvalidValue: @"out of range"];
            *(short *)address = (short)value; break;
        case 'i':
            if (value < INT_MIN || value > INT_MAX) [self raiseInvalidValue: @"out of range"];
            *(int *)address = (int)value; break;
        case 'l':
            if (value < LONG_MIN || value > LONG_MAX) [self raiseInvalidValue: @"out of range"];
            *(long *)address = (long)value; break;
        case 'q': *(long long *)address = (long long)value; break;
        default: [self raiseInvalidValue: @"unsupported signed type"];
    }
}

- (void)writeUnsignedValue: (uint64_t)value atAddress: (void *)address
{
    switch (_typeEncoding) {
        case 'C':
            if (value > UCHAR_MAX) [self raiseInvalidValue: @"out of range"];
            *(unsigned char *)address = (unsigned char)value; break;
        case 'S':
            if (value > USHRT_MAX) [self raiseInvalidValue: @"out of range"];
            *(unsigned short *)address = (unsigned short)value; break;
        case 'I':
            if (value > UINT_MAX) [self raiseInvalidValue: @"out of range"];
            *(unsigned int *)address = (unsigned int)value; break;
        case 'L':
            if (value > ULONG_MAX) [self raiseInvalidValue: @"out of range"];
            *(unsigned long *)address = (unsigned long)value; break;
        case 'Q': *(unsigned long long *)address = (unsigned long long)value; break;
        default: [self raiseInvalidValue: @"unsupported unsigned type"];
    }
}

- (void)hydrateComponent: (OWebComponent *)component
                 fromValue: (OFString *)value
{
    if (not _isHydratable)
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Property '%@' has no setter or backing ivar", _name]];

    IMP implementation = _setter != nullptr
        ? class_getMethodImplementation([component class], _setter) : nullptr;
    uint8_t *objectBytes = (uint8_t *)(__bridge void *)component;
    void *ivarAddress = _backingIvar != nullptr
        ? objectBytes + ivar_getOffset(_backingIvar) : nullptr;

    switch (_type) {
        case OWebReflectedPropertyTypeString: {
            OFString *copy = [value copy];
            if (implementation != nullptr)
                ((void (*)(id, SEL, id))implementation)(component, _setter, copy);
            else
                object_setIvarWithStrongDefault(component, _backingIvar, copy);
            break;
        }
        case OWebReflectedPropertyTypeBool: {
            bool parsed = [self parseBoolValue: value];
            if (implementation != nullptr)
                ((void (*)(id, SEL, bool))implementation)(component, _setter, parsed);
            else
                *(bool *)ivarAddress = parsed;
            break;
        }
        case OWebReflectedPropertyTypeSignedInteger: {
            int64_t parsed = [self parseSignedValue: value];
            max_align_t rangeProbe = { 0 };
            [self writeSignedValue: parsed atAddress: &rangeProbe];
            if (implementation != nullptr) {
                switch (_typeEncoding) {
                    case 'c': ((void (*)(id, SEL, signed char))implementation)(component, _setter, (signed char)parsed); break;
                    case 's': ((void (*)(id, SEL, short))implementation)(component, _setter, (short)parsed); break;
                    case 'i': ((void (*)(id, SEL, int))implementation)(component, _setter, (int)parsed); break;
                    case 'l': ((void (*)(id, SEL, long))implementation)(component, _setter, (long)parsed); break;
                    case 'q': ((void (*)(id, SEL, long long))implementation)(component, _setter, (long long)parsed); break;
                    default: [self raiseInvalidValue: value];
                }
            } else
                [self writeSignedValue: parsed atAddress: ivarAddress];
            break;
        }
        case OWebReflectedPropertyTypeUnsignedInteger: {
            uint64_t parsed = [self parseUnsignedValue: value];
            max_align_t rangeProbe = { 0 };
            [self writeUnsignedValue: parsed atAddress: &rangeProbe];
            if (implementation != nullptr) {
                switch (_typeEncoding) {
                    case 'C': ((void (*)(id, SEL, unsigned char))implementation)(component, _setter, (unsigned char)parsed); break;
                    case 'S': ((void (*)(id, SEL, unsigned short))implementation)(component, _setter, (unsigned short)parsed); break;
                    case 'I': ((void (*)(id, SEL, unsigned int))implementation)(component, _setter, (unsigned int)parsed); break;
                    case 'L': ((void (*)(id, SEL, unsigned long))implementation)(component, _setter, (unsigned long)parsed); break;
                    case 'Q': ((void (*)(id, SEL, unsigned long long))implementation)(component, _setter, (unsigned long long)parsed); break;
                    default: [self raiseInvalidValue: value];
                }
            } else
                [self writeUnsignedValue: parsed atAddress: ivarAddress];
            break;
        }
        case OWebReflectedPropertyTypeFloat: {
            double parsed = [self parseDoubleValue: value];
            if (fabs(parsed) > FLT_MAX)
                [self raiseInvalidValue: value];
            if (implementation != nullptr)
                ((void (*)(id, SEL, float))implementation)(component, _setter, (float)parsed);
            else
                *(float *)ivarAddress = (float)parsed;
            break;
        }
        case OWebReflectedPropertyTypeDouble: {
            double parsed = [self parseDoubleValue: value];
            if (implementation != nullptr)
                ((void (*)(id, SEL, double))implementation)(component, _setter, parsed);
            else
                *(double *)ivarAddress = parsed;
            break;
        }
    }
}

@end


@implementation OWebActionDefinition

- (instancetype)initWithIdentifier: (uint64_t)identifier
                   targetIdentifier: (uint64_t)targetIdentifier
                          eventName: (OFString *)eventName
                        selectorName: (OFString *)selectorName
{
    self = [super init];
    if (identifier == 0 || targetIdentifier == 0)
        @throw [OFInvalidArgumentException exception];
    _identifier = identifier;
    _targetIdentifier = targetIdentifier;
    _eventName = [eventName copy];
    _selectorName = [selectorName copy];
    return self;
}

- (void)invokeOnComponent: (OWebComponent *)component event: (OWebEvent *)event
{
    if (not [event.type isEqual: _eventName])
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Action %@ is bound to '%@', not '%@'",
                _selectorName, _eventName, event.type]];
    if (event.targetIdentifier != _targetIdentifier)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Event target does not own the requested action"];
    SEL selector = sel_registerName(_selectorName.UTF8String);
    IMP implementation = class_getMethodImplementation([component class], selector);
    if (implementation == nullptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"A compiled action method disappeared at runtime"];
    ((void (*)(id, SEL, OWebEvent *))implementation)(component, selector, event);
}

@end


@implementation OWebComponentDefinition

- (instancetype)initWithComponentClass: (Class)componentClass
                             elementName: (OFString *)elementName
                                   style: (OFString *)style
                        compiledTemplate: (OWebCompiledTemplate *)compiledTemplate
                              properties:
    (OFArray<OWebReflectedProperty *> *)properties
{
    self = [super init];
    _componentClass = componentClass;
    _elementName = [elementName copy];
    _style = [style copy];
    _compiledLayout = [compiledTemplate.markup copy];
    _actionsByIdentifier = [compiledTemplate.actionsByIdentifier copy];
    _elementIdentifiersByID = [compiledTemplate.elementIdentifiersByID copy];
    _templateIdentifiersByID = [compiledTemplate.templateIdentifiersByID copy];
    _tagNamesByElementIdentifier =
        [compiledTemplate.tagNamesByElementIdentifier copy];
    _rootTagNamesByTemplateIdentifier =
        [compiledTemplate.rootTagNamesByTemplateIdentifier copy];
    _elementIdentifiersContainingStaticCapabilities =
        [compiledTemplate.elementIdentifiersContainingStaticCapabilities copy];
    _maximumStaticIdentifier = compiledTemplate.maximumStaticIdentifier;

    auto byAttribute = [OFMutableDictionary<OFString *, OWebReflectedProperty *>
        dictionary];
    for (OWebReflectedProperty *property in properties) {
        if (byAttribute[property.attributeName] != nilptr)
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Duplicate reflected attribute '%@'",
                    property.attributeName]];
        byAttribute[property.attributeName] = property;
    }
    _propertiesByAttribute = [byAttribute copy];
    return self;
}

- (void)hydrateComponent: (OWebComponent *)component
            withAttributes: (OFDictionary<OFString *, OFString *> *)attributes
{
    if (attributes.count > 64)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Component attribute limit exceeded"];

    for (OFString *name in attributes) {
        OFString *value = $assert_nonnil(attributes[name]);
        if (not [OWebTemplateCompiler isRuntimeAttributeNameSafe: name
                                                          value: value])
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Unsafe component attribute '%@'", name]];

        OWebReflectedProperty *property = _propertiesByAttribute[name];
        if (property != nilptr) {
            [property hydrateComponent: component fromValue: value];
            continue;
        }

        bool global = [name isEqual: @"id"] || [name isEqual: @"class"] ||
            [name isEqual: @"slot"] || [name isEqual: @"title"] ||
            [name isEqual: @"role"] || [name hasPrefix: @"aria-"] ||
            [name hasPrefix: @"data-"];
        if (not global)
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Unknown component attribute '%@'", name]];
    }
}

- (OWebComponent *)instantiateWithAttributes:
    (OFDictionary<OFString *, OFString *> *)attributes
{
    return [self instantiateWithAttributes: attributes patchSink: nilptr];
}

- (OWebComponent *)instantiateWithAttributes:
    (OFDictionary<OFString *, OFString *> *)attributes
                                patchSink: (OWebPatchSink nillable)patchSink
{
    OWebComponent *component = [[_componentClass alloc]
        initWithDefinition: self patchSink: patchSink];
    [self hydrateComponent: component withAttributes: attributes];
    [component onAttach];
    return component;
}

- (void)dispatchActionIdentifier: (uint64_t)actionIdentifier
                     onComponent: (OWebComponent *)component
                           event: (OWebEvent *)event
{
    auto key = @(actionIdentifier);
    OWebActionDefinition *action = _actionsByIdentifier[key];
    if (action == nilptr)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Unknown action identifier"];
    [action invokeOnComponent: component event: event];
}

@end


@implementation OWebComponentRegistry {
    OFMutableDictionary<OFString *, OWebComponentDefinition *>
        *_definitionsByClassName;
    OFMutableDictionary<OFString *, OWebComponentDefinition *>
        *_definitionsByElementName;
}

+ (OWebComponentRegistry *)sharedRegistry
{
    static OWebComponentRegistry *registry = nilptr;
    @synchronized (self) {
        if (registry == nilptr)
            registry = [[self alloc] init];
    }
    return registry;
}

- (instancetype)init
{
    self = [super init];
    _definitionsByClassName = [[OFMutableDictionary alloc] init];
    _definitionsByElementName = [[OFMutableDictionary alloc] init];
    return self;
}

- (bool)isComponentClass: (Class)candidate
{
    for (Class current = candidate; current != Nil;
         current = class_getSuperclass(current))
        if (current == [OWebComponent class])
            return candidate != [OWebComponent class];
    return false;
}

- (void)validateElementName: (OFString *)elementName
{
    if (elementName.length < 3 || not [elementName containsString: @"-"] ||
        not [elementName isEqual: elementName.lowercaseString] ||
        [elementName hasPrefix: @"xml"])
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"'%@' is not a valid custom-element name", elementName]];
    for (size_t index = 0; index < elementName.length; index++) {
        OFUnichar character = [elementName characterAtIndex: index];
        bool valid = (character >= 'a' && character <= 'z') ||
            (index > 0 && character >= '0' && character <= '9') ||
            (index > 0 && (character == '-' || character == '.' ||
                character == '_'));
        if (not valid)
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"'%@' is not a valid custom-element name", elementName]];
    }
    static OFSet<OFString *> *reserved = nilptr;
    if (reserved == nilptr)
        reserved = [[OFSet alloc] initWithObjects:
            @"annotation-xml", @"color-profile", @"font-face",
            @"font-face-src", @"font-face-uri", @"font-face-format",
            @"font-face-name", @"missing-glyph", nilptr];
    if ([reserved containsObject: elementName])
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Custom-element name is reserved by HTML"];
}

- (OWebComponentDefinition *)registerComponentClass: (Class)componentClass
{
    if (not [self isComponentClass: componentClass])
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Registered class is not an OWebComponent subclass"];
    OFString *className = [OFString stringWithUTF8String:
        class_getName(componentClass)];
    @synchronized (self) {
        OWebComponentDefinition *existing = _definitionsByClassName[className];
        if (existing != nilptr)
            return existing;

        OFString *elementName = [componentClass elementName];
        [self validateElementName: elementName];
        OWebComponentDefinition *prior = _definitionsByElementName[elementName];
        if (prior != nilptr && prior.componentClass != componentClass)
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Custom-element name '%@' is already registered",
                    elementName]];

        OFString *style = [componentClass style];
        [OWebTemplateCompiler validateStyle: style];
        auto compiled = [OWebTemplateCompiler
            compileLayout: [componentClass layout]
            forComponentClass: componentClass];
        auto properties = [OWebReflectedProperty
            propertiesForComponentClass: componentClass];
        auto definition = [[OWebComponentDefinition alloc]
            initWithComponentClass: componentClass
            elementName: elementName style: style
            compiledTemplate: compiled properties: properties];
        _definitionsByClassName[className] = definition;
        _definitionsByElementName[elementName] = definition;
        return definition;
    }
}

- (OWebComponentDefinition *)definitionForComponentClass: (Class)componentClass
{
    return [self registerComponentClass: componentClass];
}

- (OWebComponentDefinition *nillable)definitionForElementName:
    (OFString *)elementName
{
    @synchronized (self) {
        return _definitionsByElementName[elementName];
    }
}

- (OFArray<OWebComponentDefinition *> *)definitions
{
    @synchronized (self) {
        auto result = [OFMutableArray<OWebComponentDefinition *> array];
        for (OFString *elementName in _definitionsByElementName.allKeys.sortedArray)
            [result addObject: $assert_nonnil(
                _definitionsByElementName[elementName])];
        return [result copy];
    }
}

- (OFArray<OWebComponentDefinition *> *)discoverLoadedComponentClasses
{
    int count = objc_getClassList(nullptr, 0);
    if (count <= 0)
        return @[];
    Class unretained *classes =
        (Class unretained *)malloc(sizeof(Class) * (size_t)count);
    if (classes == nullptr)
        @throw [OFOutOfMemoryException exception];
    count = objc_getClassList(classes, count);
    auto names = [OFMutableArray<OFString *> array];
    auto classesByName = [OFMutableDictionary<OFString *, id> dictionary];
    for (int index = 0; index < count; index++) {
        if ([self isComponentClass: classes[index]]) {
            auto name = [OFString stringWithUTF8String:
                class_getName(classes[index])];
            [names addObject: name];
            classesByName[name] = classes[index];
        }
    }
    free(classes);

    auto result = [OFMutableArray<OWebComponentDefinition *> array];
    for (OFString *name in names.sortedArray)
        [result addObject: [self registerComponentClass:
            $assert_nonnil(classesByName[name])]];
    return [result copy];
}

@end

#pragma clang assume_nonnull end
