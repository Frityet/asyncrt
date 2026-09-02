#import "Common.h"
#import <AsyncTask.h>
#import <ObjFW/OFIRI.h>

#pragma clang assume_nonnull begin

@interface JSONSchemaException : OFException

@property(readonly, nonatomic, copy) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason;
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaInvalidObjectException : JSONSchemaException
@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaVerificationException : JSONSchemaException

@property(readonly, nonatomic, copy) OFString *path;
@property(readonly, nonatomic, copy) OFString *keyword;

- (instancetype)initWithPath: (OFString *)path keyword: (OFString *)keyword reason: (OFString *)reason [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaInvalidTypeException : JSONSchemaException

@property(readonly, nonatomic, copy) OFString *typeName;

- (instancetype)initWithTypeName: (OFString *)typeName [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end

@interface JSONSchemaReferenceException : JSONSchemaException

@property(readonly, nonatomic, copy) OFString *reference;

- (instancetype)initWithReference: (OFString *)reference reason: (OFString *)reason;
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaInvalidReferenceException : JSONSchemaReferenceException
@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaExternalReferenceException : JSONSchemaReferenceException
@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaReferenceNotFoundException : JSONSchemaReferenceException

@property(readonly, nonatomic, copy) OFString *pointer;

- (instancetype)initWithReference: (OFString *)reference pointer: (OFString *)pointer [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaReferenceCycleException : JSONSchemaReferenceException

@property(readonly, nonatomic, copy) OFString *cycle;

- (instancetype)initWithReference: (OFString *)reference cycle: (OFString *)cycle [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaReferenceContextException : JSONSchemaException
@end

[[subclassing_restricted, direct_members]]
@interface JSONSchemaDuplicateAnchorException : JSONSchemaException

@property(readonly, nonatomic, copy) OFString *anchor;

- (instancetype)initWithAnchor: (OFString *)anchor [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end

/** A value which can be initialized from an already parsed JSON object. */
@protocol JSONDeserialisable

- (instancetype)initFromJSONObject: (id)obj;

@end

/** The common JSON Schema vocabulary shared by every schema node. */
@interface JSONSchema : OFObject <JSONDeserialisable>

/** The complete parsed JSON value represented by this node. */
@property(readonly, nonatomic, retain) id JSONObject;

/** Whether this node is a JSON Schema boolean schema rather than an object. */
@property(readonly, nonatomic) bool isBooleanSchema;
@property(readonly, nonatomic) bool booleanValue;

@property(readonly, nonatomic, copy) OFString *nillable schemaURI;
@property(readonly, nonatomic, copy) OFString *nillable schemaID;
@property(readonly, nonatomic, copy) OFString *nillable anchor;
@property(readonly, nonatomic, copy) OFString *nillable dynamicAnchor;
@property(readonly, nonatomic, copy) OFString *nillable ref;
@property(readonly, nonatomic, copy) OFString *nillable dynamicRef;
@property(readonly, nonatomic, copy) OFString *nillable comment;
@property(readonly, nonatomic, copy) OFString *nillable title;
@property(readonly, nonatomic, copy) OFString *nillable schemaDescription;

@property(readonly, nonatomic, retain) id nillable defaultValue;
@property(readonly, nonatomic, retain) OFArray *nillable enumValues;
@property(readonly, nonatomic, retain) id nillable constValue;

@property(readonly, nonatomic, retain) OFArray<JSONSchema *> *nillable allOf;
@property(readonly, nonatomic, retain) OFArray<JSONSchema *> *nillable anyOf;
@property(readonly, nonatomic, retain) OFArray<JSONSchema *> *nillable oneOf;
@property(readonly, nonatomic, retain) JSONSchema *nillable notSchema;
@property(readonly, nonatomic, retain) JSONSchema *nillable ifSchema;
@property(readonly, nonatomic, retain) JSONSchema *nillable thenSchema;
@property(readonly, nonatomic, retain) JSONSchema *nillable elseSchema;

/** The contents of `$defs` (or legacy `definitions`) after recursive loading. */
@property(readonly, nonatomic, retain) OFDictionary<OFString *, JSONSchema *> *nillable definitions;

/** Vendor extension keywords, such as the `x-clang-*` keys in clang.schema.json. */
@property(readonly, nonatomic, retain) OFDictionary<OFString *, id> *nillable extensions;

/** The direct target of this node's local `$ref`, if it has one. */
@property(readonly, nonatomic, retain) JSONSchema *nillable resolvedReference;

/** The direct target of this node's local `$dynamicRef`, if it has one. */
@property(readonly, nonatomic, retain) JSONSchema *nillable resolvedDynamicReference;

/** Follows `$ref` and `$dynamicRef` chains until a non-reference schema is reached. */
- (JSONSchema *)resolvedSchema;

+ (instancetype)fromJSONObject: (id)obj;
- (instancetype)initFromJSONObject: (id)obj [[designated_initailiser]];

@end

/** A schema whose `type` keyword contains one JSON Schema type name. */
@interface JSONSchemaTyped : JSONSchema <JSONDeserialisable>

@property(readonly, nonatomic, copy) OFString *typeName;

@end

/** A schema with `type: "object"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaObject : JSONSchemaTyped <JSONDeserialisable>

@property(readonly, nonatomic, retain) OFDictionary<OFString *, JSONSchema *> *nillable properties;
@property(readonly, nonatomic, retain) OFDictionary<OFString *, JSONSchema *> *nillable patternProperties;
@property(readonly, nonatomic, retain) OFArray<OFString *> *nillable required;
@property(readonly, nonatomic, retain) JSONSchema *nillable additionalProperties;
@property(readonly, nonatomic, retain) JSONSchema *nillable unevaluatedProperties;
@property(readonly, nonatomic, retain) JSONSchema *nillable propertyNames;
@property(readonly, nonatomic, retain) OFDictionary<OFString *, OFArray<OFString *> *> *nillable dependentRequired;
@property(readonly, nonatomic, retain) OFDictionary<OFString *, JSONSchema *> *nillable dependentSchemas;
@property(readonly, nonatomic, retain) OFNumber *nillable minProperties;
@property(readonly, nonatomic, retain) OFNumber *nillable maxProperties;

@end

/** A schema with `type: "array"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaArray : JSONSchemaTyped <JSONDeserialisable>

@property(readonly, nonatomic, retain) OFArray<JSONSchema *> *nillable prefixItems;
/** Boolean schemas are represented by JSONSchema with isBooleanSchema set. */
@property(readonly, nonatomic, retain) JSONSchema *nillable items;
@property(readonly, nonatomic, retain) JSONSchema *nillable contains;
@property(readonly, nonatomic, retain) JSONSchema *nillable unevaluatedItems;
@property(readonly, nonatomic, retain) OFNumber *nillable minContains;
@property(readonly, nonatomic, retain) OFNumber *nillable maxContains;
@property(readonly, nonatomic, retain) OFNumber *nillable minItems;
@property(readonly, nonatomic, retain) OFNumber *nillable maxItems;
@property(readonly, nonatomic) bool uniqueItems;
@property(readonly, nonatomic) bool hasUniqueItems;

@end

/** A schema with `type: "string"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaString : JSONSchemaTyped <JSONDeserialisable>

@property(readonly, nonatomic, retain) OFNumber *nillable minLength;
@property(readonly, nonatomic, retain) OFNumber *nillable maxLength;
@property(readonly, nonatomic, copy) OFString *nillable pattern;
@property(readonly, nonatomic, copy) OFString *nillable format;
@property(readonly, nonatomic, copy) OFString *nillable contentEncoding;
@property(readonly, nonatomic, copy) OFString *nillable contentMediaType;
@property(readonly, nonatomic, retain) JSONSchema *nillable contentSchema;

@end

/** A schema with `type: "number"`. */
@interface JSONSchemaNumber : JSONSchemaTyped <JSONDeserialisable>

@property(readonly, nonatomic, retain) OFNumber *nillable multipleOf;
@property(readonly, nonatomic, retain) OFNumber *nillable maximum;
@property(readonly, nonatomic, retain) OFNumber *nillable exclusiveMaximum;
@property(readonly, nonatomic, retain) OFNumber *nillable minimum;
@property(readonly, nonatomic, retain) OFNumber *nillable exclusiveMinimum;

@end

/** A schema with `type: "integer"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaInteger : JSONSchemaNumber <JSONDeserialisable>
@end

/** A schema with `type: "boolean"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaBoolean : JSONSchemaTyped <JSONDeserialisable>
@end

/** A schema with `type: "null"`. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaNull : JSONSchemaTyped <JSONDeserialisable>
@end

/** A schema whose `type` keyword contains multiple JSON Schema type names. */
[[subclassing_restricted, direct_members]]
@interface JSONSchemaTypeUnion : JSONSchema <JSONDeserialisable>

@property(readonly, nonatomic, retain) OFArray<OFString *> *typeNames;

@end

/** The root schema document, recursively materialized from a JSON object. */
[[subclassing_restricted, direct_members]]
@interface Schema : JSONSchema <JSONDeserialisable>

+ (instancetype)fromJSONObject: (id)obj;
- (JSONSchema *)schemaForReference: (OFString *)reference;
- (void)verifyJSONObject: (id)obj;
- (AsyncTask *)taskToGenerateInterfacesToDirectory: (OFIRI *)dir;

@end

#pragma clang assume_nonnull end
