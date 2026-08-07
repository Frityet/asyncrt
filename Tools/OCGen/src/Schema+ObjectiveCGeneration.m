#include "Schema.h"

#import <AsyncRT/IO/OFStream+AsyncIO.h>

#pragma clang assume_nonnull begin

constexpr auto GENERATED_HEADER_FILENAME = @"JSONSchema.h";

[[subclassing_restricted, direct_members]]
@interface SchemaObjectiveCGenerationContext : OFObject {
    OFDictionary<OFString *, JSONSchema *> *_interfaceDefinitions;
    OFDictionary<OFString *, OFString *> *_classNames;
}

- (instancetype)initWithSchema: (Schema *)schema [[designated_initailiser]];
- (OFArray<OFString *> *)_definitionNames;
- (OFString *)_classNameForDefinitionName: (OFString *)definitionName;
- (OFString *)_headerForDefinitionName: (OFString *)definitionName;
- (OFString *)_sourceForDefinitionName: (OFString *)definitionName;
- (OFString *)_umbrellaHeader;
- (OFArray<OFString *> *)_dependencyNamesForDefinitionName: (OFString *)definitionName;
- (OFString *)_objcStringLiteralForString: (OFString *)string;
- (void)_appendDependencyNamesForSchema: (JSONSchema *)schema toSet: (OFMutableSet<OFString *> *)dependencies;
- (OFString *)_propertyNameForJSONName: (OFString *)name usedNames: (OFMutableSet<OFString *> *)usedNames;
- (void)_appendInitializerForJSONName: (OFString *)JSONName propertyName: (OFString *)propertyName schema: (JSONSchema *)schema required: (bool)required toOutput: (OFMutableString *)output;
- (AsyncTask<OFNumber *> *)_taskToWriteString: (OFString *)string toIRI: (OFIRI *)IRI streams: (OFMutableArray<OFStream *> *)streams;
- (OFString *)_baseClassNameForDefinitionName: (OFString *)name;
- (OFString *nillable)_classNameForSchema: (JSONSchema *)schema;
- (OFString *)_propertyNameForJSONName: (OFString *)name;
- (OFString *)_typeForSchema: (JSONSchema *)schema required: (bool)required;
- (OFString *)_baseTypeForSchema: (JSONSchema *)schema;
- (OFString *)_baseTypeForUnion: (OFArray<JSONSchema *> *)schemas;
- (OFString *)_propertyDeclarationForType: (OFString *)type name: (OFString *)name;
- (OFString *)_superclassForSchema: (JSONSchema *)schema;
- (OFString *)_attributesForType: (OFString *)type;
- (bool)_isIdentifierCharacter: (OFUnichar)character;

@end

@implementation SchemaObjectiveCGenerationContext

- (instancetype)initWithSchema: (Schema *)schema
{
    self = [super init];

    auto definitions = $assert_nonnil(schema.definitions);
    auto interfaceDefinitions = [OFMutableDictionary<OFString *, JSONSchema *> dictionary];
    for (OFString *name in definitions) {
        auto definition = $assert_nonnil(definitions[name]);
        if ([definition isKindOfClass: JSONSchemaObject.class] or definition.anyOf != nilptr or definition.oneOf != nilptr or definition.ifSchema != nilptr)
            interfaceDefinitions[name] = definition;
    }
    _interfaceDefinitions = [interfaceDefinitions copy];

    auto definitionNames = [OFMutableArray<OFString *> array];
    for (OFString *name in interfaceDefinitions)
        [definitionNames addObject: name];
    [definitionNames sort];

    auto baseNameCounts = [OFMutableDictionary<OFString *, OFNumber *> dictionary];
    for (OFString *name in definitionNames) {
        auto baseName = [self _baseClassNameForDefinitionName: name];
        auto count = baseNameCounts[baseName];
        baseNameCounts[baseName] = count == nilptr ? @1 : @(count.unsignedLongLongValue + 1);
    }

    auto classNames = [OFMutableDictionary<OFString *, OFString *> dictionary];
    auto usedClassNames = [OFMutableSet<OFString *> set];
    for (OFString *name in definitionNames) {
        auto baseName = [self _baseClassNameForDefinitionName: name];
        auto count = $assert_nonnil(baseNameCounts[baseName]);
        auto className = baseName;
        auto firstCharacter = [name characterAtIndex: 0];
        if (count.unsignedLongLongValue > 1 and (firstCharacter == '_' or (firstCharacter >= 'a' and firstCharacter <= 'z')))
            className = [OFString stringWithFormat: @"JSON%@", baseName];

        if ([usedClassNames containsObject: className]) {
            className = [baseName stringByAppendingString: @"Schema"];
            size_t suffix = 2;
            while ([usedClassNames containsObject: className])
                className = [OFString stringWithFormat: @"%@%zu", [baseName stringByAppendingString: @"Schema"], suffix++];
        }

        classNames[name] = className;
        [usedClassNames addObject: className];
    }
    _classNames = [classNames copy];

    return self;
}

- (OFArray<OFString *> *)_definitionNames
{
    auto names = [OFMutableArray<OFString *> array];
    for (OFString *name in _interfaceDefinitions)
        [names addObject: name];
    [names sort];
    return [names copy];
}

- (OFString *)_classNameForDefinitionName: (OFString *)definitionName
{
    return $assert_nonnil(_classNames[definitionName]);
}

- (OFString *)_headerForDefinitionName: (OFString *)definitionName
{
    auto output = [OFMutableString string];
    auto schema = $assert_nonnil(_interfaceDefinitions[definitionName]);
    auto className = $assert_nonnil(_classNames[definitionName]);
    [output appendString: @"#import \"Tools/OCGen/src/Schema.h\"\n"];

    for (OFString *dependencyName in [self _dependencyNamesForDefinitionName: definitionName])
        [output appendFormat: @"#import \"%@.h\"\n", dependencyName];

    [output appendString: @"\n#pragma clang assume_nonnull begin\n\n"];
    [output appendString: @"[[subclassing_restricted, direct_members]]\n"];
    [output appendFormat: @"@interface %@ : %@ <JSONDeserialisable>\n", className, [self _superclassForSchema: schema]];

    if ([schema isKindOfClass: JSONSchemaObject.class]) {
        auto objectSchema = $cast(JSONSchemaObject, schema);
        auto properties = objectSchema.properties;
        auto propertyNames = [OFMutableArray<OFString *> array];
        if (properties != nilptr)
            for (OFString *propertyName in $assert_nonnil(properties))
                [propertyNames addObject: propertyName];
        [propertyNames sort];

        auto usedPropertyNames = [OFMutableSet<OFString *> set];
        for (OFString *JSONName in propertyNames) {
            auto propertyName = [self _propertyNameForJSONName: JSONName usedNames: usedPropertyNames];
            auto required = objectSchema.required != nilptr and [$assert_nonnil(objectSchema.required) containsObject: JSONName];
            auto propertySchema = $assert_nonnil($assert_nonnil(properties)[JSONName]);
            auto type = [self _typeForSchema: propertySchema required: required];
            [output appendFormat: @"@property(%@) %@;\n", [self _attributesForType: type], [self _propertyDeclarationForType: type name: propertyName]];
        }
    }

    [output appendString: @"\n@end\n\n#pragma clang assume_nonnull end\n"];
    return [output copy];
}

- (OFString *)_sourceForDefinitionName: (OFString *)definitionName
{
    auto output = [OFMutableString string];
    auto schema = $assert_nonnil(_interfaceDefinitions[definitionName]);
    auto className = $assert_nonnil(_classNames[definitionName]);
    [output appendFormat: @"#import \"%@.h\"\n\n#pragma clang assume_nonnull begin\n\n", className];
    [output appendFormat: @"@implementation %@\n\n", className];
    [output appendString: @"- (instancetype)initFromJSONObject: (id)obj\n{\n    self = [super init];\n\n"];

    if ([schema isKindOfClass: JSONSchemaObject.class]) {
        auto objectSchema = $cast(JSONSchemaObject, schema);
        auto properties = objectSchema.properties;
        auto propertyNames = [OFMutableArray<OFString *> array];
        if (properties != nilptr)
            for (OFString *propertyName in $assert_nonnil(properties))
                [propertyNames addObject: propertyName];
        [propertyNames sort];

        if (propertyNames.count > 0) {
            [output appendString: @"    auto dictionary = $cast(OFDictionary, obj);\n"];
            auto usedPropertyNames = [OFMutableSet<OFString *> set];
            for (OFString *JSONName in propertyNames) {
                auto propertyName = [self _propertyNameForJSONName: JSONName usedNames: usedPropertyNames];
                auto required = objectSchema.required != nilptr and [$assert_nonnil(objectSchema.required) containsObject: JSONName];
                auto propertySchema = $assert_nonnil($assert_nonnil(properties)[JSONName]);
                [self _appendInitializerForJSONName: JSONName propertyName: propertyName schema: propertySchema required: required toOutput: output];
            }
        }
    }

    [output appendString: @"\n    return self;\n}\n\n@end\n\n#pragma clang assume_nonnull end\n"];
    return [output copy];
}

- (OFString *)_umbrellaHeader
{
    auto output = [OFMutableString stringWithString: @"#import \"Tools/OCGen/src/Schema.h\"\n\n"];
    for (OFString *definitionName in self._definitionNames)
        [output appendFormat: @"#import \"%@.h\"\n", $assert_nonnil(_classNames[definitionName])];
    return [output copy];
}

- (void)_appendDependencyNamesForSchema: (JSONSchema *)schema toSet: (OFMutableSet<OFString *> *)dependencies
{
    auto resolved = schema;
    if (schema.ref != nilptr or schema.dynamicRef != nilptr)
        resolved = schema.resolvedSchema;

    auto className = [self _classNameForSchema: resolved];
    if (className != nilptr) {
        [dependencies addObject: $as_nonnil(className)];
        return;
    }

    if ([resolved isKindOfClass: JSONSchemaArray.class]) {
        auto arraySchema = $cast(JSONSchemaArray, resolved);
        if (arraySchema.items != nilptr)
            [self _appendDependencyNamesForSchema: $assert_nonnil(arraySchema.items) toSet: dependencies];
    }

    if (resolved.allOf != nilptr)
        for (JSONSchema *candidate in $assert_nonnil(resolved.allOf))
            [self _appendDependencyNamesForSchema: candidate toSet: dependencies];
    if (resolved.anyOf != nilptr)
        for (JSONSchema *candidate in $assert_nonnil(resolved.anyOf))
            [self _appendDependencyNamesForSchema: candidate toSet: dependencies];
    if (resolved.oneOf != nilptr)
        for (JSONSchema *candidate in $assert_nonnil(resolved.oneOf))
            [self _appendDependencyNamesForSchema: candidate toSet: dependencies];
}

- (OFArray<OFString *> *)_dependencyNamesForDefinitionName: (OFString *)definitionName
{
    auto dependencies = [OFMutableSet<OFString *> set];
    auto schema = $assert_nonnil(_interfaceDefinitions[definitionName]);
    if (schema.allOf != nilptr)
        for (JSONSchema *candidate in $assert_nonnil(schema.allOf))
            [self _appendDependencyNamesForSchema: candidate toSet: dependencies];

    if ([schema isKindOfClass: JSONSchemaObject.class]) {
        auto objectSchema = $cast(JSONSchemaObject, schema);
        auto properties = objectSchema.properties;
        if (properties != nilptr)
            for (OFString *JSONName in $assert_nonnil(properties))
                [self _appendDependencyNamesForSchema: $assert_nonnil(properties[JSONName]) toSet: dependencies];
    }

    [dependencies removeObject: $assert_nonnil(_classNames[definitionName])];
    auto names = [OFMutableArray<OFString *> array];
    for (OFString *name in dependencies)
        [names addObject: name];
    [names sort];
    return [names copy];
}

- (OFString *)_baseClassNameForDefinitionName: (OFString *)name
{
    size_t firstIndex = 0;
    while (firstIndex < name.length and [name characterAtIndex: firstIndex] == '_')
        firstIndex++;

    if (firstIndex == name.length)
        return @"JSONSchema";

    auto result = [name substringFromIndex: firstIndex];
    auto firstCharacter = [result substringToIndex: 1];
    return [firstCharacter.uppercaseString stringByAppendingString: [result substringFromIndex: 1]];
}

- (OFString *nillable)_classNameForSchema: (JSONSchema *)schema
{
    for (OFString *name in _interfaceDefinitions)
        if (_interfaceDefinitions[name] == schema)
            return $assert_nonnil(_classNames[name]);

    return nilptr;
}

- (OFString *)_propertyNameForJSONName: (OFString *)name
{
    auto result = [OFMutableString string];
    bool uppercaseNext = false;
    for (size_t index = 0; index < name.length; index++) {
        auto character = [name characterAtIndex: index];
        if (not [self _isIdentifierCharacter: character]) {
            uppercaseNext = true;
            continue;
        }

        auto characterString = [OFString stringWithFormat: @"%C", character];
        if (uppercaseNext) {
            characterString = characterString.uppercaseString;
            uppercaseNext = false;
        }
        [result appendString: characterString];
    }

    if (result.length == 0)
        result = [@"value" mutableCopy];

    OFString *propertyName = [result copy];
    if ([propertyName hasPrefix: @"init"] or [propertyName hasPrefix: @"alloc"] or [propertyName hasPrefix: @"copy"] or [propertyName hasPrefix: @"mutableCopy"] or [propertyName hasPrefix: @"new"] or [propertyName isEqual: @"autorelease"] or [propertyName isEqual: @"class"] or [propertyName isEqual: @"const"] or [propertyName isEqual: @"constexpr"] or [propertyName isEqual: @"dealloc"] or [propertyName isEqual: @"direct"] or [propertyName isEqual: @"explicit"] or [propertyName isEqual: @"inline"] or [propertyName isEqual: @"mutable"] or [propertyName isEqual: @"noexcept"] or [propertyName isEqual: @"release"] or [propertyName isEqual: @"restrict"] or [propertyName isEqual: @"retain"] or [propertyName isEqual: @"virtual"] or [propertyName isEqual: @"volatile"]) {
        auto firstCharacter = [[propertyName substringToIndex: 1] uppercaseString];
        propertyName = [OFString stringWithFormat: @"json%@%@", firstCharacter, [propertyName substringFromIndex: 1]];
    }

    return propertyName;
}

- (OFString *)_propertyNameForJSONName: (OFString *)name usedNames: (OFMutableSet<OFString *> *)usedNames
{
    auto propertyName = [self _propertyNameForJSONName: name];
    if ([usedNames containsObject: propertyName])
        propertyName = [propertyName stringByAppendingString: @"Value"];
    [usedNames addObject: propertyName];
    return propertyName;
}

- (OFString *)_objcStringLiteralForString: (OFString *)string
{
    auto result = [OFMutableString string];
    [result appendString: @"@\""];
    for (size_t index = 0; index < string.length; index++) {
        auto character = [string characterAtIndex: index];
        switch (character) {
            case '\\':
                [result appendString: @"\\\\"];
                break;
            case '\"':
                [result appendString: @"\\\""];
                break;
            case '\n':
                [result appendString: @"\\n"];
                break;
            case '\r':
                [result appendString: @"\\r"];
                break;
            case '\t':
                [result appendString: @"\\t"];
                break;
            default:
                [result appendFormat: @"%C", character];
                break;
        }
    }
    [result appendString: @"\""];
    return [result copy];
}

- (void)_appendInitializerForJSONName: (OFString *)JSONName propertyName: (OFString *)propertyName schema: (JSONSchema *)schema required: (bool)required toOutput: (OFMutableString *)output
{
    auto JSONKey = [self _objcStringLiteralForString: JSONName];
    [output appendFormat: @"    {\n        auto value = dictionary[%@];\n", JSONKey];

    auto valueExpression = required ? @"$assert_nonnil(value)" : @"value";
    auto resolved = schema;
    if (schema.ref != nilptr or schema.dynamicRef != nilptr)
        resolved = schema.resolvedSchema;

    if ([resolved isKindOfClass: JSONSchemaArray.class]) {
        auto arraySchema = $cast(JSONSchemaArray, resolved);
        JSONSchema *nillable itemSchema = arraySchema.items;
        OFString *nillable itemClassName = nilptr;
        if (itemSchema != nilptr) {
            auto resolvedItem = $assert_nonnil(itemSchema);
            if (itemSchema.ref != nilptr or itemSchema.dynamicRef != nilptr)
                resolvedItem = $assert_nonnil(itemSchema.resolvedSchema);
            itemClassName = [self _classNameForSchema: resolvedItem];
        }

        if (itemClassName != nilptr) {
            if (not required)
                [output appendString: @"        if (value != nilptr) {\n"];

            auto indent = required ? @"        " : @"            ";
            [output appendFormat: @"%@auto array = $cast(OFArray, %@);\n", indent, valueExpression];
            [output appendFormat: @"%@auto converted = [OFMutableArray arrayWithCapacity: array.count];\n", indent];
            [output appendFormat: @"%@for (id item in array)\n%@    [converted addObject: [[%@ alloc] initFromJSONObject: item]];\n", indent, indent, $as_nonnil(itemClassName)];
            [output appendFormat: @"%@_%@ = [converted copy];\n", indent, propertyName];
            if (not required)
                [output appendString: @"        }\n"];
            [output appendString: @"    }\n"];
            return;
        }
    }

    auto className = [self _classNameForSchema: resolved];
    OFString *expression;
    if (className != nilptr)
        expression = [OFString stringWithFormat: @"[[%@ alloc] initFromJSONObject: $assert_nonnil(value)]", $as_nonnil(className)];
    else {
        auto baseType = [self _baseTypeForSchema: resolved];
        if ([baseType isEqual: @"bool"])
            expression = [OFString stringWithFormat: @"[$cast(OFNumber, %@) boolValue]", valueExpression];
        else if ([baseType hasPrefix: @"OFString *"])
            expression = [OFString stringWithFormat: @"$cast(OFString, %@)", valueExpression];
        else if ([baseType hasPrefix: @"OFNumber *"])
            expression = [OFString stringWithFormat: @"$cast(OFNumber, %@)", valueExpression];
        else if ([baseType hasPrefix: @"OFNull *"])
            expression = [OFString stringWithFormat: @"$cast(OFNull, %@)", valueExpression];
        else if ([baseType hasPrefix: @"OFDictionary *"])
            expression = [OFString stringWithFormat: @"$cast(OFDictionary, %@)", valueExpression];
        else if ([baseType hasPrefix: @"OFArray"])
            expression = [OFString stringWithFormat: @"$cast(OFArray, %@)", valueExpression];
        else
            expression = valueExpression;
    }

    if (required)
        [output appendFormat: @"        _%@ = %@;\n", propertyName, expression];
    else
        [output appendFormat: @"        if (value != nilptr)\n            _%@ = %@;\n", propertyName, expression];
    [output appendString: @"    }\n"];
}

- (AsyncTask<OFNumber *> *)_taskToWriteString: (OFString *)string toIRI: (OFIRI *)IRI streams: (OFMutableArray<OFStream *> *)streams
{
    auto stream = [OFIRIHandler openItemAtIRI: IRI mode: @"w"];
    [streams addObject: stream];
    return [stream taskToWriteString: string];
}

- (OFString *)_typeForSchema: (JSONSchema *)schema required: (bool)required
{
    auto baseType = [self _baseTypeForSchema: schema];
    if (required or [baseType isEqual: @"bool"])
        return baseType;
    if ([baseType hasSuffix: @" *"])
        return [baseType stringByAppendingString: @"nillable"];

    return [baseType stringByAppendingString: @" nillable"];
}

- (OFString *)_baseTypeForSchema: (JSONSchema *)schema
{
    if (schema.ref != nilptr or schema.dynamicRef != nilptr) {
        auto resolved = schema.resolvedSchema;
        auto className = [self _classNameForSchema: resolved];
        if (className != nilptr)
            return [OFString stringWithFormat: @"%@ *", $as_nonnil(className)];
        return [self _baseTypeForSchema: resolved];
    }

    auto className = [self _classNameForSchema: schema];
    if (className != nilptr)
        return [OFString stringWithFormat: @"%@ *", $as_nonnil(className)];

    if (schema.isBooleanSchema)
        return @"id";

    auto dictionary = $cast(OFDictionary, schema.JSONObject);
    auto constValue = dictionary[@"const"];
    if (constValue != nilptr) {
        if ([constValue isKindOfClass: OFString.class])
            return @"OFString *";
        if ([constValue isKindOfClass: OFNumber.class]) {
            auto number = $cast(OFNumber, constValue);
            auto objCType = number.objCType;
            if (objCType[0] == 'B' and objCType[1] == '\0')
                return @"bool";
            return @"OFNumber *";
        }
        if ([constValue isKindOfClass: OFNull.class])
            return @"OFNull *";
    }

    auto type = dictionary[@"type"];
    if ([type isKindOfClass: OFString.class]) {
        auto typeName = $cast(OFString, type);
        if ([typeName isEqual: @"object"])
            return @"OFDictionary *";
        if ([typeName isEqual: @"array"] and [schema isKindOfClass: JSONSchemaArray.class]) {
            auto arraySchema = $cast(JSONSchemaArray, schema);
            if (arraySchema.items == nilptr)
                return @"OFArray *";

            auto itemType = [self _typeForSchema: $assert_nonnil(arraySchema.items) required: true];
            if ([itemType isEqual: @"bool"])
                itemType = @"OFNumber *";
            return [OFString stringWithFormat: @"OFArray<%@> *", itemType];
        }
        if ([typeName isEqual: @"string"])
            return @"OFString *";
        if ([typeName isEqual: @"number"] or [typeName isEqual: @"integer"])
            return @"OFNumber *";
        if ([typeName isEqual: @"boolean"])
            return @"bool";
        if ([typeName isEqual: @"null"])
            return @"OFNull *";
    }

    if (schema.anyOf != nilptr)
        return [self _baseTypeForUnion: $assert_nonnil(schema.anyOf)];
    if (schema.oneOf != nilptr)
        return [self _baseTypeForUnion: $assert_nonnil(schema.oneOf)];

    return @"id";
}

- (OFString *)_baseTypeForUnion: (OFArray<JSONSchema *> *)schemas
{
    OFString *nillable type = nilptr;
    for (JSONSchema *schema in schemas) {
        auto candidate = [self _baseTypeForSchema: schema];
        if (type == nilptr)
            type = candidate;
        else if (not [type isEqual: candidate])
            return @"id";
    }

    return type == nilptr ? @"id" : $as_nonnil(type);
}

- (OFString *)_propertyDeclarationForType: (OFString *)type name: (OFString *)name
{
    if ([type containsString: @"*"] and [type hasSuffix: @"*"])
        return [type stringByAppendingString: name];
    if ([type containsString: @"*"] and [type hasSuffix: @"nillable"])
        return [type stringByAppendingFormat: @" %@", name];

    return [type stringByAppendingFormat: @" %@", name];
}

- (OFString *)_superclassForSchema: (JSONSchema *)schema
{
    if (schema.allOf != nilptr)
        for (JSONSchema *candidate in $assert_nonnil(schema.allOf)) {
            if (candidate.ref == nilptr and candidate.dynamicRef == nilptr)
                continue;

            auto superclass = [self _classNameForSchema: candidate.resolvedSchema];
            if (superclass != nilptr)
                return $as_nonnil(superclass);
        }

    return @"OFObject";
}

- (OFString *)_attributesForType: (OFString *)type
{
    return @"readonly, nonatomic";
}

- (bool)_isIdentifierCharacter: (OFUnichar)character
{
    return (character >= 'a' and character <= 'z') or (character >= 'A' and character <= 'Z') or (character >= '0' and character <= '9') or character == '_';
}

@end

[[subclassing_restricted, direct_members]]
@interface SchemaObjectiveCGenerationSupport : OFObject

+ (AsyncTask *)taskToGenerateInterfacesFromSchema: (Schema *)schema toDirectory: (OFIRI *)dir;

@end

@implementation SchemaObjectiveCGenerationSupport

+ (AsyncTask *)taskToGenerateInterfacesFromSchema: (Schema *)schema toDirectory: (OFIRI *)dir
{
    return [AsyncTask spawn: ^{
        auto fileManager = OFFileManager.defaultManager;
        if (not [fileManager directoryExistsAtIRI: dir])
            [fileManager createDirectoryAtIRI: dir createParents: true];

        auto context = [[SchemaObjectiveCGenerationContext alloc] initWithSchema: schema];
        auto streams = [OFMutableArray<OFStream *> array];
        auto tasks = [OFMutableArray<AsyncTask<OFNumber *> *> array];
        @try {
            [tasks addObject: [context _taskToWriteString: context._umbrellaHeader
                                                     toIRI: [dir IRIByAppendingPathComponent: GENERATED_HEADER_FILENAME isDirectory: false]
                                                  streams: streams]];

            for (OFString *definitionName in [context _definitionNames]) {
                auto className = [context _classNameForDefinitionName: definitionName];
                [tasks addObject: [context _taskToWriteString: [context _headerForDefinitionName: definitionName]
                                                         toIRI: [dir IRIByAppendingPathComponent: [OFString stringWithFormat: @"%@.h", className] isDirectory: false]
                                                      streams: streams]];
                [tasks addObject: [context _taskToWriteString: [context _sourceForDefinitionName: definitionName]
                                                         toIRI: [dir IRIByAppendingPathComponent: [OFString stringWithFormat: @"%@.m", className] isDirectory: false]
                                                      streams: streams]];
            }

            [[AsyncTask all: tasks] await];
        } @finally {
            for (OFStream *stream in streams)
                [stream close];
        }

        return nilptr;
    }];
}

@end

#pragma clang assume_nonnull end
