#include "Schema.h"

#include <math.h>
#include <regex.h>

#pragma clang assume_nonnull begin

@implementation JSONSchemaException

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];

    _reason = reason;
    return self;
}

- (OFString *)description
{
    return _reason;
}

@end

@implementation JSONSchemaInvalidObjectException
@end

@implementation JSONSchemaVerificationException

- (instancetype)initWithPath: (OFString *)path keyword: (OFString *)keyword reason: (OFString *)reason
{
    self = [super initWithReason: [OFString stringWithFormat: @"JSON Schema verification failed at %@ for %@: %@", path, keyword, reason]];


    _path = path;
    _keyword = keyword;
    return self;
}

@end

@implementation JSONSchemaInvalidTypeException

- (instancetype)initWithTypeName: (OFString *)typeName
{
    self = [super initWithReason: [OFString stringWithFormat: @"Invalid JSON Schema type: %@", typeName]];


    _typeName = typeName;
    return self;
}

@end

@implementation JSONSchemaReferenceException

- (instancetype)initWithReference: (OFString *)reference reason: (OFString *)reason
{
    self = [super initWithReason: reason];


    _reference = reference;
    return self;
}

@end

@implementation JSONSchemaInvalidReferenceException
@end

@implementation JSONSchemaExternalReferenceException
@end

@implementation JSONSchemaReferenceNotFoundException

- (instancetype)initWithReference: (OFString *)reference pointer: (OFString *)pointer
{
    self = [super initWithReference: reference
                             reason: [OFString stringWithFormat: @"JSON Schema reference %@ was not found at %@", reference, pointer]];


    _pointer = pointer;
    return self;
}

@end

@implementation JSONSchemaReferenceCycleException

- (instancetype)initWithReference: (OFString *)reference cycle: (OFString *)cycle
{
    self = [super initWithReference: reference
                             reason: [OFString stringWithFormat: @"JSON Schema reference cycle while resolving %@: %@", reference, cycle]];


    _cycle = cycle;
    return self;
}

@end

@implementation JSONSchemaReferenceContextException
@end

@implementation JSONSchemaDuplicateAnchorException

- (instancetype)initWithAnchor: (OFString *)anchor
{
    self = [super initWithReason: [OFString stringWithFormat: @"Duplicate JSON Schema anchor: %@", anchor]];


    _anchor = anchor;
    return self;
}

@end

@class JSONSchemaResolutionContext;
@class JSONSchemaVerificationContext;

[[subclassing_restricted, direct_members]]
@interface JSONSchemaResolutionContext : OFObject {
    unretained JSONSchema *_rootSchema;
    id _rootJSONObject;
    OFMutableDictionary<OFString *, JSONSchema *> *_schemasByPointer;
    OFMutableDictionary<OFString *, JSONSchema *> *_anchors;
    OFMutableDictionary<OFString *, OFMutableArray<JSONSchema *> *> *_dynamicAnchors;
}

- (instancetype)initWithRootSchema: (JSONSchema *)rootSchema rootJSONObject: (id)rootJSONObject [[designated_initailiser]];
- (OFString *)pointerByAppendingToken: (OFString *)token toPointer: (OFString *)pointer;
- (void)registerSchema: (JSONSchema *)schema atPointer: (OFString *)pointer;
- (JSONSchema *nillable)_dynamicAnchorNamed: (OFString *)name fromSchema: (JSONSchema *)schema;
- (JSONSchema *)resolveReference: (OFString *)reference fromSchema: (JSONSchema *)schema dynamic: (bool)dynamic;
- (void)validateReferences;

@end

@interface JSONSchema ()

+ (JSONSchema *)_schemaFromJSONObject: (id)obj;
+ (Class)_classForTypeName: (OFString *)typeName;

- (OFString *nillable)_stringForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (OFNumber *nillable)_numberForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (OFArray *nillable)_arrayForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (OFArray<OFString *> *)_stringArrayFromJSONObject: (id)obj;
- (OFArray<JSONSchema *> *)_schemaArrayFromJSONObject: (id)obj;
- (OFArray<JSONSchema *> *nillable)_schemaArrayForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (OFDictionary<OFString *, JSONSchema *> *)_schemaMapFromJSONObject: (id)obj;
- (OFDictionary<OFString *, JSONSchema *> *nillable)_schemaMapForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (OFDictionary<OFString *, OFArray<OFString *> *> *)_stringArrayMapFromJSONObject: (id)obj;
- (OFDictionary<OFString *, OFArray<OFString *> *> *nillable)_stringArrayMapForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (JSONSchema *nillable)_schemaValueForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary;
- (void)_prepareResolutionContext;
- (void)_attachResolutionContext: (JSONSchemaResolutionContext *)context atPointer: (OFString *)pointer;
- (void)_attachSchema: (JSONSchema *nillable)schema context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer;
- (void)_attachSchemaArray: (OFArray<JSONSchema *> *nillable)schemas context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer;
- (void)_attachSchemaMap: (OFDictionary<OFString *, JSONSchema *> *nillable)schemas context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer;
- (OFString *nillable)_resolutionPointer;
- (JSONSchema *)_resolveReference: (OFString *)reference dynamic: (bool)dynamic;
- (void)_verifyJSONObject: (id)obj atPath: (OFString *)path context: (JSONSchemaVerificationContext *)context;
- (void)_failVerificationAtPath: (OFString *)path keyword: (OFString *)keyword reason: (OFString *)reason;
- (bool)_isBooleanNumber: (OFNumber *)number;
- (bool)_isIntegerNumber: (OFNumber *)number;
- (bool)_JSONObject: (id)obj matchesTypeName: (OFString *)typeName;
- (bool)_JSONObject: (id)left isEqualToJSONObject: (id)right;
- (bool)_string: (OFString *)string matchesPattern: (OFString *)pattern;
- (void)_verifySchemaArray: (OFArray<JSONSchema *> *)schemas object: (id)obj path: (OFString *)path keyword: (OFString *)keyword context: (JSONSchemaVerificationContext *)context;
- (void)_verifySchemaMap: (OFDictionary<OFString *, JSONSchema *> *)schemas object: (OFDictionary *)object path: (OFString *)path keyword: (OFString *)keyword context: (JSONSchemaVerificationContext *)context evaluatedKeys: (OFMutableSet<OFString *> *)evaluatedKeys;

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaVerificationPair : OFObject

@property(readonly, nonatomic, retain) JSONSchema *schema;
@property(readonly, nonatomic, retain) id JSONObject;

- (instancetype)initWithSchema: (JSONSchema *)schema JSONObject: (id)obj [[designated_initailiser]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaVerificationContext : OFObject {
    OFMutableArray<JSONSchemaVerificationPair *> *_activePairs;
}

- (bool)containsSchema: (JSONSchema *)schema object: (id)obj;
- (void)pushSchema: (JSONSchema *)schema object: (id)obj;
- (void)popSchema: (JSONSchema *)schema object: (id)obj;
- (OFString *)pathByAppendingToken: (OFString *)token toPath: (OFString *)path;

@end

@implementation JSONSchemaResolutionContext

- (instancetype)initWithRootSchema: (JSONSchema *)rootSchema rootJSONObject: (id)rootJSONObject
{
    self = [super init];


    _rootSchema = rootSchema;
    _rootJSONObject = rootJSONObject;
    _schemasByPointer = [[OFMutableDictionary alloc] init];
    _anchors = [[OFMutableDictionary alloc] init];
    _dynamicAnchors = [[OFMutableDictionary alloc] init];
    return self;
}

- (OFString *)pointerByAppendingToken: (OFString *)token toPointer: (OFString *)pointer
{
    auto escapedToken = [token stringByReplacingOccurrencesOfString: @"~" withString: @"~0"];
    escapedToken = [escapedToken stringByReplacingOccurrencesOfString: @"/" withString: @"~1"];
    return [pointer stringByAppendingFormat: @"/%@", escapedToken];
}

- (void)registerSchema: (JSONSchema *)schema atPointer: (OFString *)pointer
{
    if (pointer.length != 0) {
        auto existingSchema = _schemasByPointer[pointer];
        if (existingSchema != nilptr and existingSchema != schema)
            @throw [[JSONSchemaException alloc] initWithReason: [OFString stringWithFormat: @"Multiple schema nodes were registered at JSON Pointer %@", pointer]];

        _schemasByPointer[pointer] = schema;
    }

    auto anchor = schema.anchor;
    if (anchor != nilptr) {
        auto anchorName = $as_nonnil(anchor);
        auto existingAnchor = _anchors[anchorName];
        if (existingAnchor != nilptr and existingAnchor != schema)
            @throw [[JSONSchemaDuplicateAnchorException alloc] initWithAnchor: anchorName];

        _anchors[anchorName] = schema;
    }

    auto dynamicAnchor = schema.dynamicAnchor;
    if (dynamicAnchor != nilptr) {
        auto dynamicAnchorName = $as_nonnil(dynamicAnchor);
        auto dynamicAnchors = _dynamicAnchors[dynamicAnchorName];
        if (dynamicAnchors == nilptr) {
            dynamicAnchors = [[OFMutableArray alloc] init];
            _dynamicAnchors[dynamicAnchorName] = dynamicAnchors;
        }

        [dynamicAnchors addObject: schema];
    }
}

- (JSONSchema *nillable)_dynamicAnchorNamed: (OFString *)name fromSchema: (JSONSchema *)schema
{
    auto candidates = _dynamicAnchors[name];
    if (candidates == nilptr)
        return nilptr;

    auto sourcePointer = [schema _resolutionPointer];
    JSONSchema *nillable best = nilptr;
    JSONSchema *nillable fallback = nilptr;
    size_t bestLength = 0;
    for (JSONSchema *candidate in candidates) {
        if (fallback == nilptr)
            fallback = candidate;

        auto candidatePointer = [candidate _resolutionPointer];
        if (sourcePointer == nilptr or candidatePointer == nilptr)
            continue;
        auto nonnilCandidatePointer = $as_nonnil(candidatePointer);
        if (not [sourcePointer hasPrefix: nonnilCandidatePointer])
            continue;

        if (nonnilCandidatePointer.length != 0 and sourcePointer.length > nonnilCandidatePointer.length and [sourcePointer characterAtIndex: nonnilCandidatePointer.length] != '/')
            continue;

        if (best == nilptr or nonnilCandidatePointer.length > bestLength) {
            best = candidate;
            bestLength = nonnilCandidatePointer.length;
        }
    }

    return best != nilptr ? best : fallback;
}

- (OFString *)_decodedPointerToken: (OFString *)token reference: (OFString *)reference
{
    auto parts = [token componentsSeparatedByString: @"~"];
    if (parts.count == 1)
        return token;

    auto result = [OFMutableString string];
    [result appendString: $assert_nonnil(parts[0])];

    for (size_t index = 1; index < parts.count; index++) {
        auto part = $assert_nonnil(parts[index]);
        if (part.length == 0 or ([part characterAtIndex: 0] != '0' and [part characterAtIndex: 0] != '1'))
            @throw [[JSONSchemaInvalidReferenceException alloc] initWithReference: reference
                                                                            reason: [OFString stringWithFormat: @"Invalid JSON Pointer escape in reference %@", reference]];

        [result appendString: [part characterAtIndex: 0] == '0' ? @"~" : @"/"];
        if (part.length > 1)
            [result appendString: [part substringFromIndex: 1]];
    }

    return result;
}

- (OFString *)_pointerFromReferenceFragment: (OFString *)fragment reference: (OFString *)reference
{
    if (not [fragment hasPrefix: @"/"])
        @throw [[JSONSchemaInvalidReferenceException alloc] initWithReference: reference
                                                                        reason: [OFString stringWithFormat: @"JSON Pointer reference %@ does not start with '/'", reference]];

    auto components = [fragment componentsSeparatedByString: @"/"];
    OFString *pointer = @"";
    for (size_t index = 1; index < components.count; index++) {
        auto token = [self _decodedPointerToken: $assert_nonnil(components[index]) reference: reference];
        pointer = [self pointerByAppendingToken: token toPointer: pointer];
    }

    return pointer;
}

- (JSONSchema *)resolveReference: (OFString *)reference fromSchema: (JSONSchema *)schema dynamic: (bool)dynamic
{
    if (not [reference hasPrefix: @"#"])
        @throw [[JSONSchemaExternalReferenceException alloc] initWithReference: reference
                                                                         reason: [OFString stringWithFormat: @"External JSON Schema references are not loaded: %@", reference]];

    auto fragment = [reference substringFromIndex: 1].stringByRemovingPercentEncoding;
    if (fragment.length == 0)
        return $assert_nonnil(_rootSchema);

    if (not [fragment hasPrefix: @"/"]) {
        auto anchor = dynamic ? [self _dynamicAnchorNamed: fragment fromSchema: schema] : _anchors[fragment];
        if (anchor == nilptr and dynamic)
            anchor = _anchors[fragment];
        if (anchor != nilptr)
            return $as_nonnil(anchor);

        @throw [[JSONSchemaReferenceNotFoundException alloc] initWithReference: reference pointer: fragment];
    }

    auto pointer = [self _pointerFromReferenceFragment: fragment reference: reference];
    auto target = _schemasByPointer[pointer];
    if (target == nilptr)
        @throw [[JSONSchemaReferenceNotFoundException alloc] initWithReference: reference pointer: pointer];

    return $as_nonnil(target);
}

- (void)validateReferencesForSchema: (JSONSchema *)schema
{
    if (schema.ref != nilptr)
        (void)schema.resolvedReference;
    if (schema.dynamicRef != nilptr)
        (void)schema.resolvedDynamicReference;
}

- (void)validateReferences
{
    [self validateReferencesForSchema: $assert_nonnil(_rootSchema)];
    for (OFString *pointer in _schemasByPointer)
        [self validateReferencesForSchema: $assert_nonnil(_schemasByPointer[pointer])];
}

@end

@implementation JSONSchemaVerificationPair

- (instancetype)initWithSchema: (JSONSchema *)schema JSONObject: (id)obj
{
    self = [super init];


    _schema = schema;
    _JSONObject = obj;
    return self;
}

@end

@implementation JSONSchemaVerificationContext

- (instancetype)init
{
    self = [super init];


    _activePairs = [[OFMutableArray alloc] init];
    return self;
}

- (bool)containsSchema: (JSONSchema *)schema object: (id)obj
{
    for (JSONSchemaVerificationPair *pair in _activePairs)
        if (pair.schema == schema and pair.JSONObject == obj)
            return true;

    return false;
}

- (void)pushSchema: (JSONSchema *)schema object: (id)obj
{
    [_activePairs addObject: [[JSONSchemaVerificationPair alloc] initWithSchema: schema JSONObject: obj]];
}

- (void)popSchema: (JSONSchema *)schema object: (id)obj
{
    for (size_t index = _activePairs.count; index-- > 0;) {
        auto pair = $assert_nonnil(_activePairs[index]);
        if (pair.schema == schema and pair.JSONObject == obj) {
            [_activePairs removeObjectAtIndex: index];
            return;
        }
    }
}

- (OFString *)pathByAppendingToken: (OFString *)token toPath: (OFString *)path
{
    auto escapedToken = [token stringByReplacingOccurrencesOfString: @"~" withString: @"~0"];
    escapedToken = [escapedToken stringByReplacingOccurrencesOfString: @"/" withString: @"~1"];
    return [path stringByAppendingFormat: @"/%@", escapedToken];
}

@end

@implementation JSONSchema {
    JSONSchemaResolutionContext *nillable _ownedResolutionContext;
    unretained JSONSchemaResolutionContext *nillable _resolutionContext;
    OFString *nillable _jsonPointer;
}

+ (instancetype)fromJSONObject: (id)obj
{
    JSONSchema *schema;
    if (self != JSONSchema.class)
        schema = [[self alloc] initFromJSONObject: obj];
    else
        schema = [self _schemaFromJSONObject: obj];

    [schema _prepareResolutionContext];
    return schema;
}

+ (JSONSchema *)_schemaFromJSONObject: (id)obj
{
    if ([obj isKindOfClass: OFNumber.class])
        return [[JSONSchema alloc] initFromJSONObject: obj];

    if (not [obj isKindOfClass: OFDictionary.class])
        @throw [[JSONSchemaInvalidObjectException alloc] initWithReason: @"A JSON Schema must be a boolean or an object"];

    auto dictionary = $cast(OFDictionary, obj);
    auto type = dictionary[@"type"];

    if (type == nilptr)
        return [[JSONSchema alloc] initFromJSONObject: dictionary];

    if ([type isKindOfClass: OFString.class]) {
        auto typeName = $cast(OFString, type);
        return [[[self _classForTypeName: typeName] alloc] initFromJSONObject: dictionary];
    }

    if ([type isKindOfClass: OFArray.class])
        return [[JSONSchemaTypeUnion alloc] initFromJSONObject: dictionary];

    @throw [[JSONSchemaInvalidObjectException alloc] initWithReason: @"The JSON Schema type keyword must be a string or an array of strings"];
}

+ (Class)_classForTypeName: (OFString *)typeName
{
    if ([typeName isEqual: @"object"])
        return JSONSchemaObject.class;
    if ([typeName isEqual: @"array"])
        return JSONSchemaArray.class;
    if ([typeName isEqual: @"string"])
        return JSONSchemaString.class;
    if ([typeName isEqual: @"number"])
        return JSONSchemaNumber.class;
    if ([typeName isEqual: @"integer"])
        return JSONSchemaInteger.class;
    if ([typeName isEqual: @"boolean"])
        return JSONSchemaBoolean.class;
    if ([typeName isEqual: @"null"])
        return JSONSchemaNull.class;

    @throw [[JSONSchemaInvalidTypeException alloc] initWithTypeName: typeName];
}

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];


    _JSONObject = obj;

    if ([obj isKindOfClass: OFNumber.class]) {
        _isBooleanSchema = true;
        auto number = $cast(OFNumber, obj);
        _booleanValue = number.boolValue;
        return self;
    }

    if (not [obj isKindOfClass: OFDictionary.class])
        @throw [[JSONSchemaInvalidObjectException alloc] initWithReason: @"A JSON Schema must be a boolean or an object"];

    auto dictionary = $cast(OFDictionary, obj);

    _schemaURI = [self _stringForKey: @"$schema" inDictionary: dictionary];
    _schemaID = [self _stringForKey: @"$id" inDictionary: dictionary];
    _anchor = [self _stringForKey: @"$anchor" inDictionary: dictionary];
    _dynamicAnchor = [self _stringForKey: @"$dynamicAnchor"
                           inDictionary: dictionary];
    _ref = [self _stringForKey: @"$ref" inDictionary: dictionary];
    _dynamicRef = [self _stringForKey: @"$dynamicRef"
                        inDictionary: dictionary];
    _comment = [self _stringForKey: @"$comment" inDictionary: dictionary];
    _title = [self _stringForKey: @"title" inDictionary: dictionary];
    _schemaDescription = [self _stringForKey: @"description"
                                inDictionary: dictionary];

    _defaultValue = dictionary[@"default"];
    _constValue = dictionary[@"const"];

    auto enumValues = [self _arrayForKey: @"enum" inDictionary: dictionary];
    _enumValues = enumValues;

    _allOf = [self _schemaArrayForKey: @"allOf" inDictionary: dictionary];
    _anyOf = [self _schemaArrayForKey: @"anyOf" inDictionary: dictionary];
    _oneOf = [self _schemaArrayForKey: @"oneOf" inDictionary: dictionary];
    _notSchema = [self _schemaValueForKey: @"not" inDictionary: dictionary];
    _ifSchema = [self _schemaValueForKey: @"if" inDictionary: dictionary];
    _thenSchema = [self _schemaValueForKey: @"then" inDictionary: dictionary];
    _elseSchema = [self _schemaValueForKey: @"else" inDictionary: dictionary];

    auto definitions = dictionary[@"$defs"];
    if (definitions == nilptr)
        definitions = dictionary[@"definitions"];
    if (definitions != nilptr)
        _definitions = [self _schemaMapFromJSONObject: $assert_nonnil(definitions)];

    auto extensions = [[OFMutableDictionary alloc] init];
    for (OFString *key in dictionary) {
        if ([key hasPrefix: @"x-"])
            extensions[key] = dictionary[key];
    }
    if (extensions.count != 0)
        _extensions = extensions;

    return self;
}

- (OFString *nillable)_stringForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return $cast(OFString, value);
}

- (OFNumber *nillable)_numberForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return $cast(OFNumber, value);
}

- (OFArray *nillable)_arrayForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return $cast(OFArray, value);
}

- (OFArray<OFString *> *)_stringArrayFromJSONObject: (id)obj
{
    auto array = $cast(OFArray, obj);
    auto result = [[OFMutableArray alloc] initWithCapacity: array.count];

    for (id value in array)
        [result addObject: $cast(OFString, value)];

    return result;
}

- (OFArray<JSONSchema *> *)_schemaArrayFromJSONObject: (id)obj
{
    auto array = $cast(OFArray, obj);
    auto result = [[OFMutableArray alloc] initWithCapacity: array.count];

    for (id value in array)
        [result addObject: [JSONSchema _schemaFromJSONObject: value]];

    return result;
}

- (OFArray<JSONSchema *> *nillable)_schemaArrayForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = [self _arrayForKey: key inDictionary: dictionary];
    if (value == nilptr)
        return nilptr;

    return [self _schemaArrayFromJSONObject: $assert_nonnil(value)];
}

- (OFDictionary<OFString *, JSONSchema *> *)_schemaMapFromJSONObject: (id)obj
{
    auto dictionary = $cast(OFDictionary, obj);
    auto result = [[OFMutableDictionary alloc] initWithCapacity: dictionary.count];

    for (OFString *key in dictionary) {
        auto value = dictionary[key];
        result[key] = [JSONSchema _schemaFromJSONObject: $assert_nonnil(value)];
    }

    return result;
}

- (OFDictionary<OFString *, JSONSchema *> *nillable)_schemaMapForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return [self _schemaMapFromJSONObject: $assert_nonnil(value)];
}

- (OFDictionary<OFString *, OFArray<OFString *> *> *)_stringArrayMapFromJSONObject: (id)obj
{
    auto dictionary = $cast(OFDictionary, obj);
    auto result = [[OFMutableDictionary alloc] initWithCapacity: dictionary.count];

    for (OFString *key in dictionary) {
        auto value = dictionary[key];
        result[key] = [self _stringArrayFromJSONObject: $assert_nonnil(value)];
    }

    return result;
}

- (OFDictionary<OFString *, OFArray<OFString *> *> *nillable)_stringArrayMapForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return [self _stringArrayMapFromJSONObject: $assert_nonnil(value)];
}

- (JSONSchema *nillable)_schemaValueForKey: (OFString *)key inDictionary: (OFDictionary *)dictionary
{
    auto value = dictionary[key];
    if (value == nilptr)
        return nilptr;

    return [JSONSchema _schemaFromJSONObject: $assert_nonnil(value)];
}

- (void)_prepareResolutionContext
{
    auto context = [[JSONSchemaResolutionContext alloc] initWithRootSchema: self
                                                             rootJSONObject: self.JSONObject];
    _ownedResolutionContext = context;
    [self _attachResolutionContext: context atPointer: @""];
    [context validateReferences];
}

- (void)_attachSchema: (JSONSchema *nillable)schema context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer
{
    if (schema != nilptr)
        [schema _attachResolutionContext: context atPointer: pointer];
}

- (void)_attachSchemaArray: (OFArray<JSONSchema *> *nillable)schemas context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer
{
    if (schemas == nilptr)
        return;

    for (size_t index = 0; index < schemas.count; index++) {
        auto schema = $assert_nonnil(schemas[index]);
        [self _attachSchema: schema
                    context: context
                     pointer: [context pointerByAppendingToken: [OFString stringWithFormat: @"%zu", index]
                                                        toPointer: pointer]];
    }
}

- (void)_attachSchemaMap: (OFDictionary<OFString *, JSONSchema *> *nillable)schemas context: (JSONSchemaResolutionContext *)context pointer: (OFString *)pointer
{
    if (schemas == nilptr)
        return;

    for (OFString *key in schemas) {
        auto schema = $assert_nonnil(schemas[key]);
        [self _attachSchema: schema
                    context: context
                     pointer: [context pointerByAppendingToken: key toPointer: pointer]];
    }
}

- (void)_attachResolutionContext: (JSONSchemaResolutionContext *)context atPointer: (OFString *)pointer
{
    _resolutionContext = context;
    _jsonPointer = pointer;
    [context registerSchema: self atPointer: pointer];

    if (self.isBooleanSchema)
        return;

    auto dictionary = $cast(OFDictionary, self.JSONObject);
    OFString *definitionsKey = dictionary[@"$defs"] != nilptr ? @"$defs" : @"definitions";
    [self _attachSchemaMap: self.definitions
                    context: context
                     pointer: [context pointerByAppendingToken: definitionsKey toPointer: pointer]];
    [self _attachSchemaArray: self.allOf
                      context: context
                       pointer: [context pointerByAppendingToken: @"allOf" toPointer: pointer]];
    [self _attachSchemaArray: self.anyOf
                      context: context
                       pointer: [context pointerByAppendingToken: @"anyOf" toPointer: pointer]];
    [self _attachSchemaArray: self.oneOf
                      context: context
                       pointer: [context pointerByAppendingToken: @"oneOf" toPointer: pointer]];
    [self _attachSchema: self.notSchema
                context: context
                 pointer: [context pointerByAppendingToken: @"not" toPointer: pointer]];
    [self _attachSchema: self.ifSchema
                context: context
                 pointer: [context pointerByAppendingToken: @"if" toPointer: pointer]];
    [self _attachSchema: self.thenSchema
                context: context
                 pointer: [context pointerByAppendingToken: @"then" toPointer: pointer]];
    [self _attachSchema: self.elseSchema
                context: context
                 pointer: [context pointerByAppendingToken: @"else" toPointer: pointer]];

    if ([self isKindOfClass: JSONSchemaObject.class]) {
        auto objectSchema = $cast(JSONSchemaObject, self);
        [self _attachSchemaMap: objectSchema.properties
                        context: context
                         pointer: [context pointerByAppendingToken: @"properties" toPointer: pointer]];
        [self _attachSchemaMap: objectSchema.patternProperties
                        context: context
                         pointer: [context pointerByAppendingToken: @"patternProperties" toPointer: pointer]];
        [self _attachSchema: objectSchema.additionalProperties
                    context: context
                     pointer: [context pointerByAppendingToken: @"additionalProperties" toPointer: pointer]];
        [self _attachSchema: objectSchema.unevaluatedProperties
                    context: context
                     pointer: [context pointerByAppendingToken: @"unevaluatedProperties" toPointer: pointer]];
        [self _attachSchema: objectSchema.propertyNames
                    context: context
                     pointer: [context pointerByAppendingToken: @"propertyNames" toPointer: pointer]];
        [self _attachSchemaMap: objectSchema.dependentSchemas
                        context: context
                         pointer: [context pointerByAppendingToken: @"dependentSchemas" toPointer: pointer]];
    } else if ([self isKindOfClass: JSONSchemaArray.class]) {
        auto arraySchema = $cast(JSONSchemaArray, self);
        [self _attachSchemaArray: arraySchema.prefixItems
                          context: context
                           pointer: [context pointerByAppendingToken: @"prefixItems" toPointer: pointer]];
        [self _attachSchema: arraySchema.items
                    context: context
                     pointer: [context pointerByAppendingToken: @"items" toPointer: pointer]];
        [self _attachSchema: arraySchema.contains
                    context: context
                     pointer: [context pointerByAppendingToken: @"contains" toPointer: pointer]];
        [self _attachSchema: arraySchema.unevaluatedItems
                    context: context
                     pointer: [context pointerByAppendingToken: @"unevaluatedItems" toPointer: pointer]];
    } else if ([self isKindOfClass: JSONSchemaString.class]) {
        auto stringSchema = $cast(JSONSchemaString, self);
        [self _attachSchema: stringSchema.contentSchema
                    context: context
                     pointer: [context pointerByAppendingToken: @"contentSchema" toPointer: pointer]];
    }
}

- (OFString *nillable)_resolutionPointer
{
    return _jsonPointer;
}

- (JSONSchema *nillable)resolvedReference
{
    if (_ref == nilptr)
        return nilptr;

    return [self _resolveReference: $as_nonnil(_ref) dynamic: false];
}

- (JSONSchema *nillable)resolvedDynamicReference
{
    if (_dynamicRef == nilptr)
        return nilptr;

    return [self _resolveReference: $as_nonnil(_dynamicRef) dynamic: true];
}

- (JSONSchema *)_resolveReference: (OFString *)reference dynamic: (bool)dynamic
{
    if (_resolutionContext == nilptr)
        @throw [[JSONSchemaReferenceContextException alloc] initWithReason: @"A JSON Schema reference needs a root document context"];

    auto context = $assert_nonnil(_resolutionContext);
    return [context resolveReference: reference fromSchema: self dynamic: dynamic];
}

- (JSONSchema *)resolvedSchema
{
    auto seen = [OFMutableSet set];
    JSONSchema *current = self;

    while (current.ref != nilptr or current.dynamicRef != nilptr) {
        if ([seen containsObject: current]) {
            auto reference = current.ref != nilptr ? current.ref : $assert_nonnil(current.dynamicRef);
            auto pointer = [current _resolutionPointer];
            auto cycle = pointer != nilptr ? pointer : reference;
            @throw [[JSONSchemaReferenceCycleException alloc] initWithReference: $as_nonnil(reference)
                                                                           cycle: $as_nonnil(cycle)];
        }

        [seen addObject: current];
        if (current.ref != nilptr)
            current = $assert_nonnil(current.resolvedReference);
        else
            current = $assert_nonnil(current.resolvedDynamicReference);
    }

    return current;
}

- (void)_failVerificationAtPath: (OFString *)path keyword: (OFString *)keyword reason: (OFString *)reason
{
    @throw [[JSONSchemaVerificationException alloc] initWithPath: path keyword: keyword reason: reason];
}

- (bool)_isBooleanNumber: (OFNumber *)number
{
    auto type = number.objCType;
    return type[0] == 'B' and type[1] == '\0';
}

- (bool)_isIntegerNumber: (OFNumber *)number
{
    return not [self _isBooleanNumber: number] and isfinite(number.doubleValue) and floor(number.doubleValue) == number.doubleValue;
}

- (bool)_JSONObject: (id)obj matchesTypeName: (OFString *)typeName
{
    if ([typeName isEqual: @"object"])
        return [obj isKindOfClass: OFDictionary.class];
    if ([typeName isEqual: @"array"])
        return [obj isKindOfClass: OFArray.class];
    if ([typeName isEqual: @"string"])
        return [obj isKindOfClass: OFString.class];
    if ([typeName isEqual: @"number"])
        return [obj isKindOfClass: OFNumber.class] and not [self _isBooleanNumber: $cast(OFNumber, obj)];
    if ([typeName isEqual: @"integer"])
        return [obj isKindOfClass: OFNumber.class] and [self _isIntegerNumber: $cast(OFNumber, obj)];
    if ([typeName isEqual: @"boolean"])
        return [obj isKindOfClass: OFNumber.class] and [self _isBooleanNumber: $cast(OFNumber, obj)];
    if ([typeName isEqual: @"null"])
        return [obj isKindOfClass: OFNull.class];

    return false;
}

- (bool)_JSONObject: (id)left isEqualToJSONObject: (id)right
{
    if ([left isKindOfClass: OFNumber.class] and [right isKindOfClass: OFNumber.class]) {
        auto leftNumber = $cast(OFNumber, left);
        auto rightNumber = $cast(OFNumber, right);
        if ([self _isBooleanNumber: leftNumber] != [self _isBooleanNumber: rightNumber])
            return false;
    }

    return [left isEqual: right];
}

- (bool)_string: (OFString *)string matchesPattern: (OFString *)pattern
{
    regex_t expression;
    auto status = regcomp(&expression, pattern.UTF8String, REG_EXTENDED | REG_NOSUB);
    if (status != 0)
        @throw [[JSONSchemaException alloc] initWithReason: [OFString stringWithFormat: @"Invalid regular expression in JSON Schema: %@", pattern]];

    auto matches = regexec(&expression, string.UTF8String, 0, nullptr, 0) == 0;
    regfree(&expression);
    return matches;
}

- (void)_verifySchemaArray: (OFArray<JSONSchema *> *)schemas object: (id)obj path: (OFString *)path keyword: (OFString *)keyword context: (JSONSchemaVerificationContext *)context
{
    for (size_t index = 0; index < schemas.count; index++) {
        auto schema = $assert_nonnil(schemas[index]);
        [schema _verifyJSONObject: obj
                           atPath: [context pathByAppendingToken: [OFString stringWithFormat: @"%zu", index]
                                                    toPath: path]
                          context: context];
    }
}

- (void)_verifySchemaMap: (OFDictionary<OFString *, JSONSchema *> *)schemas object: (OFDictionary *)object path: (OFString *)path keyword: (OFString *)keyword context: (JSONSchemaVerificationContext *)context evaluatedKeys: (OFMutableSet<OFString *> *)evaluatedKeys
{
    for (OFString *key in schemas) {
        auto value = object[key];
        if (value == nilptr)
            continue;

        [evaluatedKeys addObject: key];
        auto schema = $assert_nonnil(schemas[key]);
        [schema _verifyJSONObject: $assert_nonnil(value)
                           atPath: [context pathByAppendingToken: key toPath: path]
                          context: context];
    }
}

- (void)_verifyJSONObject: (id)obj atPath: (OFString *)path context: (JSONSchemaVerificationContext *)context
{
    if ([context containsSchema: self object: obj])
        return;

    [context pushSchema: self object: obj];
    @try {
        if (self.isBooleanSchema) {
            if (not self.booleanValue)
                [self _failVerificationAtPath: path keyword: @"booleanSchema" reason: @"The false schema rejects this value"];
            return;
        }

        if (self.ref != nilptr)
            [$assert_nonnil(self.resolvedReference) _verifyJSONObject: obj atPath: path context: context];
        if (self.dynamicRef != nilptr)
            [$assert_nonnil(self.resolvedDynamicReference) _verifyJSONObject: obj atPath: path context: context];

        if ([self isKindOfClass: JSONSchemaTyped.class]) {
            auto typedSchema = $cast(JSONSchemaTyped, self);
            if (not [self _JSONObject: obj matchesTypeName: typedSchema.typeName])
                [self _failVerificationAtPath: path keyword: @"type" reason: [OFString stringWithFormat: @"Expected a value of type %@", typedSchema.typeName]];
        } else if ([self isKindOfClass: JSONSchemaTypeUnion.class]) {
            auto unionSchema = $cast(JSONSchemaTypeUnion, self);
            bool matches = false;
            for (OFString *typeName in unionSchema.typeNames)
                if ([self _JSONObject: obj matchesTypeName: typeName]) {
                    matches = true;
                    break;
                }
            if (not matches)
                [self _failVerificationAtPath: path keyword: @"type" reason: @"The value does not match any type in the schema union"];
        }

        if (self.enumValues != nilptr) {
            bool matches = false;
            for (id enumValue in self.enumValues)
                if ([self _JSONObject: obj isEqualToJSONObject: enumValue]) {
                    matches = true;
                    break;
                }
            if (not matches)
                [self _failVerificationAtPath: path keyword: @"enum" reason: @"The value is not one of the enumerated values"];
        }

        auto constValue = self.constValue;
        if (constValue != nilptr and not [self _JSONObject: obj isEqualToJSONObject: $as_nonnil(constValue)])
            [self _failVerificationAtPath: path keyword: @"const" reason: @"The value does not equal the schema constant"];

        if (self.allOf != nilptr)
            [self _verifySchemaArray: $assert_nonnil(self.allOf) object: obj path: path keyword: @"allOf" context: context];

        if (self.anyOf != nilptr) {
            bool matches = false;
            for (JSONSchema *schema in self.anyOf) {
                @try {
                    [schema _verifyJSONObject: obj atPath: path context: context];
                    matches = true;
                } @catch (JSONSchemaVerificationException *) {
                }
                if (matches)
                    break;
            }
            if (not matches)
                [self _failVerificationAtPath: path keyword: @"anyOf" reason: @"The value does not match any schema in anyOf"];
        }

        if (self.oneOf != nilptr) {
            size_t matches = 0;
            for (JSONSchema *schema in self.oneOf) {
                @try {
                    [schema _verifyJSONObject: obj atPath: path context: context];
                    matches++;
                } @catch (JSONSchemaVerificationException *) {
                }
            }
            if (matches != 1)
                [self _failVerificationAtPath: path keyword: @"oneOf" reason: @"The value must match exactly one schema in oneOf"];
        }

        if (self.notSchema != nilptr) {
            bool matches = true;
            @try {
                [$assert_nonnil(self.notSchema) _verifyJSONObject: obj atPath: path context: context];
            } @catch (JSONSchemaVerificationException *) {
                matches = false;
            }
            if (matches)
                [self _failVerificationAtPath: path keyword: @"not" reason: @"The value matches a schema forbidden by not"];
        }

        if (self.ifSchema != nilptr) {
            bool conditionMatches = true;
            @try {
                [$assert_nonnil(self.ifSchema) _verifyJSONObject: obj atPath: path context: context];
            } @catch (JSONSchemaVerificationException *) {
                conditionMatches = false;
            }

            if (conditionMatches and self.thenSchema != nilptr)
                [$assert_nonnil(self.thenSchema) _verifyJSONObject: obj atPath: path context: context];
            if (not conditionMatches and self.elseSchema != nilptr)
                [$assert_nonnil(self.elseSchema) _verifyJSONObject: obj atPath: path context: context];
        }

        if ([self isKindOfClass: JSONSchemaObject.class] and [obj isKindOfClass: OFDictionary.class]) {
            auto objectSchema = $cast(JSONSchemaObject, self);
            auto dictionary = $cast(OFDictionary, obj);
            auto evaluatedKeys = [OFMutableSet set];

            if (objectSchema.minProperties != nilptr and dictionary.count < objectSchema.minProperties.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"minProperties" reason: @"The object has too few properties"];
            if (objectSchema.maxProperties != nilptr and dictionary.count > objectSchema.maxProperties.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"maxProperties" reason: @"The object has too many properties"];

            if (objectSchema.required != nilptr)
                for (OFString *key in objectSchema.required)
                    if (dictionary[key] == nilptr)
                        [self _failVerificationAtPath: path keyword: @"required" reason: [OFString stringWithFormat: @"The required property %@ is missing", key]];

            if (objectSchema.properties != nilptr)
                [self _verifySchemaMap: $assert_nonnil(objectSchema.properties) object: dictionary path: path keyword: @"properties" context: context evaluatedKeys: evaluatedKeys];

            if (objectSchema.patternProperties != nilptr)
                for (OFString *pattern in objectSchema.patternProperties)
                    for (OFString *key in dictionary)
                        if ([self _string: key matchesPattern: pattern]) {
                            [evaluatedKeys addObject: key];
                            auto schema = $assert_nonnil(objectSchema.patternProperties[pattern]);
                            [schema _verifyJSONObject: $assert_nonnil(dictionary[key])
                                               atPath: [context pathByAppendingToken: key toPath: path]
                                              context: context];
                        }

            if (objectSchema.propertyNames != nilptr)
                for (OFString *key in dictionary)
                    [$assert_nonnil(objectSchema.propertyNames) _verifyJSONObject: key atPath: [context pathByAppendingToken: key toPath: path] context: context];

            if (objectSchema.dependentRequired != nilptr)
                for (OFString *key in objectSchema.dependentRequired)
                    if (dictionary[key] != nilptr)
                        for (OFString *dependentKey in $assert_nonnil(objectSchema.dependentRequired[key]))
                            if (dictionary[dependentKey] == nilptr)
                                [self _failVerificationAtPath: path keyword: @"dependentRequired" reason: [OFString stringWithFormat: @"Property %@ requires property %@", key, dependentKey]];

            if (objectSchema.dependentSchemas != nilptr)
                for (OFString *key in objectSchema.dependentSchemas)
                    if (dictionary[key] != nilptr)
                        [$assert_nonnil(objectSchema.dependentSchemas[key]) _verifyJSONObject: obj atPath: path context: context];

            for (OFString *key in dictionary)
                if (not [evaluatedKeys containsObject: key] and objectSchema.additionalProperties != nilptr) {
                    [$assert_nonnil(objectSchema.additionalProperties) _verifyJSONObject: $assert_nonnil(dictionary[key]) atPath: [context pathByAppendingToken: key toPath: path] context: context];
                    [evaluatedKeys addObject: key];
                }

            if (objectSchema.unevaluatedProperties != nilptr)
                for (OFString *key in dictionary)
                    if (not [evaluatedKeys containsObject: key])
                        [$assert_nonnil(objectSchema.unevaluatedProperties) _verifyJSONObject: $assert_nonnil(dictionary[key]) atPath: [context pathByAppendingToken: key toPath: path] context: context];
        }

        if ([self isKindOfClass: JSONSchemaArray.class] and [obj isKindOfClass: OFArray.class]) {
            auto arraySchema = $cast(JSONSchemaArray, self);
            auto array = $cast(OFArray, obj);
            if (arraySchema.minItems != nilptr and array.count < arraySchema.minItems.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"minItems" reason: @"The array has too few items"];
            if (arraySchema.maxItems != nilptr and array.count > arraySchema.maxItems.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"maxItems" reason: @"The array has too many items"];

            if (arraySchema.uniqueItems)
                for (size_t leftIndex = 0; leftIndex < array.count; leftIndex++)
                    for (size_t rightIndex = leftIndex + 1; rightIndex < array.count; rightIndex++)
                        if ([self _JSONObject: $assert_nonnil(array[leftIndex]) isEqualToJSONObject: $assert_nonnil(array[rightIndex])])
                            [self _failVerificationAtPath: path keyword: @"uniqueItems" reason: @"The array contains duplicate items"];

            auto evaluatedIndexes = [OFMutableSet<OFString *> set];
            auto prefixItems = arraySchema.prefixItems;
            if (prefixItems != nilptr)
                for (size_t index = 0; index < array.count and index < prefixItems.count; index++) {
                    [evaluatedIndexes addObject: [OFString stringWithFormat: @"%zu", index]];
                    [$assert_nonnil(prefixItems[index]) _verifyJSONObject: $assert_nonnil(array[index]) atPath: [context pathByAppendingToken: [OFString stringWithFormat: @"%zu", index] toPath: path] context: context];
                }

            if (arraySchema.items != nilptr)
                for (size_t index = prefixItems == nilptr ? 0 : prefixItems.count; index < array.count; index++) {
                    [evaluatedIndexes addObject: [OFString stringWithFormat: @"%zu", index]];
                    [$assert_nonnil(arraySchema.items) _verifyJSONObject: $assert_nonnil(array[index]) atPath: [context pathByAppendingToken: [OFString stringWithFormat: @"%zu", index] toPath: path] context: context];
                }

            if (arraySchema.contains != nilptr) {
                size_t matches = 0;
                for (size_t index = 0; index < array.count; index++)
                    @try {
                        [$assert_nonnil(arraySchema.contains) _verifyJSONObject: $assert_nonnil(array[index]) atPath: [context pathByAppendingToken: [OFString stringWithFormat: @"%zu", index] toPath: path] context: context];
                        matches++;
                        [evaluatedIndexes addObject: [OFString stringWithFormat: @"%zu", index]];
                    } @catch (JSONSchemaVerificationException *) {
                    }

                size_t minimum = arraySchema.minContains == nilptr ? 1 : arraySchema.minContains.unsignedLongLongValue;
                if (matches < minimum)
                    [self _failVerificationAtPath: path keyword: @"contains" reason: @"Too few array items match contains"];
                if (arraySchema.maxContains != nilptr and matches > arraySchema.maxContains.unsignedLongLongValue)
                    [self _failVerificationAtPath: path keyword: @"contains" reason: @"Too many array items match contains"];
            }

            if (arraySchema.unevaluatedItems != nilptr)
                for (size_t index = 0; index < array.count; index++) {
                    auto indexString = [OFString stringWithFormat: @"%zu", index];
                    if (not [evaluatedIndexes containsObject: indexString])
                        [$assert_nonnil(arraySchema.unevaluatedItems) _verifyJSONObject: $assert_nonnil(array[index]) atPath: [context pathByAppendingToken: indexString toPath: path] context: context];
                }
        }

        if ([self isKindOfClass: JSONSchemaString.class] and [obj isKindOfClass: OFString.class]) {
            auto stringSchema = $cast(JSONSchemaString, self);
            auto string = $cast(OFString, obj);
            if (stringSchema.minLength != nilptr and string.length < stringSchema.minLength.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"minLength" reason: @"The string is too short"];
            if (stringSchema.maxLength != nilptr and string.length > stringSchema.maxLength.unsignedLongLongValue)
                [self _failVerificationAtPath: path keyword: @"maxLength" reason: @"The string is too long"];
            if (stringSchema.pattern != nilptr and not [self _string: string matchesPattern: $assert_nonnil(stringSchema.pattern)])
                [self _failVerificationAtPath: path keyword: @"pattern" reason: @"The string does not match the schema pattern"];
        }

        if ([self isKindOfClass: JSONSchemaNumber.class] and [obj isKindOfClass: OFNumber.class] and not [self _isBooleanNumber: $cast(OFNumber, obj)]) {
            auto numberSchema = $cast(JSONSchemaNumber, self);
            auto number = $cast(OFNumber, obj);
            auto value = number.doubleValue;
            if (numberSchema.multipleOf != nilptr) {
                auto multiple = numberSchema.multipleOf.doubleValue;
                auto quotient = value / multiple;
                if (multiple <= 0 or not isfinite(quotient) or fabs(quotient - round(quotient)) > 1e-9 * fmax(1.0, fabs(quotient)))
                    [self _failVerificationAtPath: path keyword: @"multipleOf" reason: @"The number is not a multiple of the schema value"];
            }
            if (numberSchema.maximum != nilptr and value > numberSchema.maximum.doubleValue)
                [self _failVerificationAtPath: path keyword: @"maximum" reason: @"The number is greater than maximum"];
            if (numberSchema.exclusiveMaximum != nilptr and value >= numberSchema.exclusiveMaximum.doubleValue)
                [self _failVerificationAtPath: path keyword: @"exclusiveMaximum" reason: @"The number is not below exclusiveMaximum"];
            if (numberSchema.minimum != nilptr and value < numberSchema.minimum.doubleValue)
                [self _failVerificationAtPath: path keyword: @"minimum" reason: @"The number is less than minimum"];
            if (numberSchema.exclusiveMinimum != nilptr and value <= numberSchema.exclusiveMinimum.doubleValue)
                [self _failVerificationAtPath: path keyword: @"exclusiveMinimum" reason: @"The number is not above exclusiveMinimum"];
        }
    } @finally {
        [context popSchema: self object: obj];
    }
}

@end

@implementation JSONSchemaTyped

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);
    OFString *nillable typeName = [self _stringForKey: @"type"
                                      inDictionary: dictionary];
    if (typeName == nilptr)
        @throw [[JSONSchemaInvalidTypeException alloc] initWithTypeName: @"<missing>"];
    _typeName = $as_nonnil(typeName);

    return self;
}

@end

@implementation JSONSchemaObject

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);

    _properties = [self _schemaMapForKey: @"properties"
                            inDictionary: dictionary];
    _patternProperties = [self _schemaMapForKey: @"patternProperties"
                                  inDictionary: dictionary];

    OFArray *required = [self _arrayForKey: @"required"
                              inDictionary: dictionary];
    if (required != nilptr)
        _required = [self _stringArrayFromJSONObject: $assert_nonnil(required)];

    _additionalProperties = [self _schemaValueForKey: @"additionalProperties"
                                         inDictionary: dictionary];
    _unevaluatedProperties = [self _schemaValueForKey: @"unevaluatedProperties"
                                          inDictionary: dictionary];
    _propertyNames = [self _schemaValueForKey: @"propertyNames"
                                 inDictionary: dictionary];
    _dependentRequired = [self _stringArrayMapForKey: @"dependentRequired"
                                        inDictionary: dictionary];
    _dependentSchemas = [self _schemaMapForKey: @"dependentSchemas"
                                  inDictionary: dictionary];
    _minProperties = [self _numberForKey: @"minProperties"
                             inDictionary: dictionary];
    _maxProperties = [self _numberForKey: @"maxProperties"
                             inDictionary: dictionary];

    return self;
}

@end

@implementation JSONSchemaArray

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);

    OFArray *prefixItems = [self _arrayForKey: @"prefixItems"
                                 inDictionary: dictionary];
    if (prefixItems != nilptr)
        _prefixItems = [self _schemaArrayFromJSONObject: $assert_nonnil(prefixItems)];

    _items = [self _schemaValueForKey: @"items" inDictionary: dictionary];
    _contains = [self _schemaValueForKey: @"contains" inDictionary: dictionary];
    _unevaluatedItems = [self _schemaValueForKey: @"unevaluatedItems"
                                    inDictionary: dictionary];
    _minContains = [self _numberForKey: @"minContains"
                           inDictionary: dictionary];
    _maxContains = [self _numberForKey: @"maxContains"
                           inDictionary: dictionary];
    _minItems = [self _numberForKey: @"minItems" inDictionary: dictionary];
    _maxItems = [self _numberForKey: @"maxItems" inDictionary: dictionary];

    auto uniqueItems = dictionary[@"uniqueItems"];
    if (uniqueItems != nilptr) {
        auto number = $cast(OFNumber, uniqueItems);
        _uniqueItems = number.boolValue;
        _hasUniqueItems = true;
    }

    return self;
}

@end

@implementation JSONSchemaString

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);

    _minLength = [self _numberForKey: @"minLength" inDictionary: dictionary];
    _maxLength = [self _numberForKey: @"maxLength" inDictionary: dictionary];
    _pattern = [self _stringForKey: @"pattern" inDictionary: dictionary];
    _format = [self _stringForKey: @"format" inDictionary: dictionary];
    _contentEncoding = [self _stringForKey: @"contentEncoding"
                              inDictionary: dictionary];
    _contentMediaType = [self _stringForKey: @"contentMediaType"
                                inDictionary: dictionary];
    _contentSchema = [self _schemaValueForKey: @"contentSchema"
                                  inDictionary: dictionary];

    return self;
}

@end

@implementation JSONSchemaNumber

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);

    _multipleOf = [self _numberForKey: @"multipleOf" inDictionary: dictionary];
    _maximum = [self _numberForKey: @"maximum" inDictionary: dictionary];
    _exclusiveMaximum = [self _numberForKey: @"exclusiveMaximum"
                               inDictionary: dictionary];
    _minimum = [self _numberForKey: @"minimum" inDictionary: dictionary];
    _exclusiveMinimum = [self _numberForKey: @"exclusiveMinimum"
                               inDictionary: dictionary];

    return self;
}

@end

@implementation JSONSchemaInteger
@end

@implementation JSONSchemaBoolean
@end

@implementation JSONSchemaNull
@end

@implementation JSONSchemaTypeUnion

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super initFromJSONObject: obj];


    auto dictionary = $cast(OFDictionary, obj);
    OFArray *typeNames = [self _arrayForKey: @"type"
                               inDictionary: dictionary];
    if (typeNames == nilptr or typeNames.count == 0)
        @throw [[JSONSchemaInvalidObjectException alloc] initWithReason: @"The JSON Schema type array must not be empty"];

    _typeNames = [self _stringArrayFromJSONObject: $assert_nonnil(typeNames)];
    for (OFString *typeName in _typeNames)
        [JSONSchema _classForTypeName: typeName];

    return self;
}

@end

@interface SchemaObjectiveCGenerationSupport : OFObject

+ (AsyncTask *)taskToGenerateInterfacesFromSchema: (Schema *)schema toDirectory: (OFIRI *)dir;

@end

@implementation Schema

+ (instancetype)fromJSONObject: (id)obj
{
    if (not [obj isKindOfClass: OFDictionary.class])
        @throw [[JSONSchemaInvalidObjectException alloc] initWithReason: @"The root Schema must be a JSON object"];

    auto schema = [[self alloc] initFromJSONObject: obj];
    [schema _prepareResolutionContext];
    return schema;
}

- (AsyncTask *)taskToGeneratedInterfacesToDirectory: (OFIRI *)dir
{
    return [SchemaObjectiveCGenerationSupport taskToGenerateInterfacesFromSchema: self toDirectory: dir];
}

- (JSONSchema *)schemaForReference: (OFString *)reference
{
    return [self _resolveReference: reference dynamic: false];
}

- (void)verifyJSONObject: (id)obj
{
    auto dictionary = $cast(OFDictionary, self.JSONObject);
    if (dictionary[@"type"] != nilptr) {
        auto validationSchema = [JSONSchema _schemaFromJSONObject: dictionary];
        [validationSchema _prepareResolutionContext];
        auto context = [[JSONSchemaVerificationContext alloc] init];
        [validationSchema _verifyJSONObject: obj atPath: @"" context: context];
        return;
    }

    auto context = [[JSONSchemaVerificationContext alloc] init];
    [self _verifyJSONObject: obj atPath: @"" context: context];
}

@end

#pragma clang assume_nonnull end
