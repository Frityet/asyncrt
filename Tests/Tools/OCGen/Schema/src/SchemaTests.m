#import <Schema.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

constexpr auto HOMEBREW_CLANG = @"/opt/homebrew/opt/llvm/bin/clang";

[[subclassing_restricted, direct_members]]
@interface SchemaTests: OTTestCase

- (OFString *)_projectPath: (OFString *)relativePath;
- (OFIRI *)_temporaryGenerationDirectory;
- (void)_generateSchema: (Schema *)schema toDirectory: (OFIRI *)directory;
- (OFString *)_contentsOfGeneratedFile: (OFString *)fileName inDirectory: (OFIRI *)directory;

@end

@implementation SchemaTests

- (OFString *)_projectPath: (OFString *)relativePath
{
    auto environment = $assert_nonnil(OFApplication.environment);
    auto projectDirectory = $assert_nonnil(environment[@"ASYNC_RUNTIME_PROJECT_DIR"]);
    return [projectDirectory stringByAppendingPathComponent: relativePath];
}

- (OFIRI *)_temporaryGenerationDirectory
{
    auto temporaryDirectory = $assert_nonnil(OFSystemInfo.temporaryDirectoryIRI);
    auto directory = [temporaryDirectory IRIByAppendingPathComponent:
        [OFString stringWithFormat: @"ocgen-%@", OFUUID.UUID.UUIDString]
        isDirectory: true];
    [OFFileManager.defaultManager createDirectoryAtIRI: directory createParents: true];
    return directory;
}

- (void)_generateSchema: (Schema *)schema toDirectory: (OFIRI *)directory
{
    [[schema taskToGenerateInterfacesToDirectory: directory] runUntilCompletion];
}

- (OFString *)_contentsOfGeneratedFile: (OFString *)fileName inDirectory: (OFIRI *)directory
{
    auto IRI = [directory IRIByAppendingPathComponent: fileName isDirectory: false];
    return [OFString stringWithContentsOfFile: $assert_nonnil(IRI.fileSystemRepresentation)];
}

- (void)testLoadsClangSchema
{
    auto schemaPath = [self _projectPath: @"clang.schema.json"];
    auto object = [OFString stringWithContentsOfFile: schemaPath].objectByParsingJSON;
    auto schema = [Schema fromJSONObject: object];
    auto definitions = $assert_nonnil(schema.definitions);

    OTAssertEqualObjects(schema.schemaURI,
        @"https://json-schema.org/draft/2020-12/schema",
        @"the root schema URI must be loaded");
    OTAssertEqualObjects(schema.ref, @"#/$defs/astObject",
        @"the root reference must be loaded");
    OTAssert(definitions.count > 1000,
        @"the complete $defs map must be recursively loaded");

    auto pointer = $assert_nonnil(definitions[@"pointer"]);
    OTAssertTrue([pointer isKindOfClass: JSONSchemaString.class],
        @"string definitions must use JSONSchemaString");

    auto qualType = $assert_nonnil(definitions[@"qualType"]);
    OTAssertTrue([qualType isKindOfClass: JSONSchemaObject.class],
        @"object definitions must use JSONSchemaObject");
    auto qualTypeSchema = $cast(JSONSchemaObject, qualType);
    OTAssert($assert_nonnil(qualTypeSchema.properties).count == 3,
        @"object properties must be recursively loaded");

    auto translationUnit = $cast(JSONSchemaObject,
        $assert_nonnil(definitions[@"TranslationUnitDecl"]));
    OTAssertEqualObjects(
        $assert_nonnil(translationUnit.extensions)[@"x-clang-class"],
        @"TranslationUnit", @"vendor extensions must be retained");

    auto astObject = $assert_nonnil(definitions[@"astObject"]);
    OTAssert(astObject.ifSchema != nilptr && astObject.thenSchema != nilptr,
        @"conditional keywords must be recursively loaded");
    OTAssertTrue(schema.resolvedReference == astObject,
        @"the root $ref must resolve into the document's definitions");
    OTAssertTrue([schema schemaForReference: @"#/$defs/astObject"] == astObject,
        @"explicit JSON Pointer lookup must resolve into the document's definitions");
    OTAssertTrue(schema.resolvedSchema == astObject,
        @"resolvedSchema must follow the root reference");

    auto kindedAstObject = $assert_nonnil(definitions[@"kindedAstObject"]);
    OTAssert($assert_nonnil(kindedAstObject.anyOf).count != 0,
        @"composition keywords must be recursively loaded");

    auto htmlCommentAttribute = $cast(JSONSchemaArray,
        $assert_nonnil(definitions[@"htmlCommentAttribute"]));
    OTAssertEqual($assert_nonnil(htmlCommentAttribute.prefixItems).count, 2,
        @"array prefixItems must be recursively loaded");
    OTAssertTrue($assert_nonnil(htmlCommentAttribute.items).isBooleanSchema,
        @"boolean schemas must be represented by JSONSchema");
}

- (void)testResolvesReferenceChainsAndReportsCycles
{
    auto object = [@$raw(
        {
            "$defs": {
                "name": {"type": "string"},
                "alias": {"$ref": "#/$defs/name"},
                "cycleA": {"$ref": "#/$defs/cycleB"},
                "cycleB": {"$ref": "#/$defs/cycleA"}
            },
            "$ref": "#/$defs/alias"
        }
    ) objectByParsingJSON];
    auto schema = [Schema fromJSONObject: object];
    auto definitions = $assert_nonnil(schema.definitions);
    auto name = $assert_nonnil(definitions[@"name"]);
    auto alias = $assert_nonnil(definitions[@"alias"]);

    OTAssertTrue(alias.resolvedReference == name,
        @"a direct $ref must resolve to its JSON Pointer target");
    OTAssertTrue(alias.resolvedSchema == name,
        @"resolvedSchema must follow a reference chain to its terminal node");

    bool cycleCaught = false;
    @try {
        (void)$assert_nonnil(definitions[@"cycleA"]).resolvedSchema;
    } @catch (JSONSchemaReferenceCycleException *exception) {
        cycleCaught = true;
        OTAssertEqualObjects(exception.reference, @"#/$defs/cycleB",
            @"cycle exceptions must identify the reference being followed");
    }
    OTAssertTrue(cycleCaught,
        @"resolving a cyclic reference chain must raise a typed exception");
}

- (void)testReportsInvalidReferences
{
    bool missingCaught = false;
    @try {
        auto object = [@$raw({"$ref": "#/$defs/missing"}) objectByParsingJSON];
        (void)[Schema fromJSONObject: object];
    } @catch (JSONSchemaReferenceNotFoundException *exception) {
        missingCaught = true;
        OTAssertEqualObjects(exception.pointer, @"/$defs/missing",
            @"missing reference exceptions must expose the normalized pointer");
    }
    OTAssertTrue(missingCaught,
        @"missing local references must be rejected while loading the document");

    bool externalCaught = false;
    @try {
        auto object = [@$raw({"$ref": "https://example.com/schema.json"}) objectByParsingJSON];
        (void)[Schema fromJSONObject: object];
    } @catch (JSONSchemaExternalReferenceException *) {
        externalCaught = true;
    }
    OTAssertTrue(externalCaught,
        @"external references must use a distinct exception type");
}

- (void)testResolvesAnchorsAndPercentEncodedPointers
{
    auto object = [@$raw(
        {
            "$defs": {
                "slash/name": {"type": "string"},
                "named": {"$anchor": "named", "type": "boolean"},
                "dynamic": {"$dynamicAnchor": "node", "type": "integer"},
                "pointerUser": {"$ref": "#/$defs/slash~1name"},
                "anchorUser": {"$ref": "#named"},
                "dynamicUser": {"$dynamicRef": "#node"}
            }
        }
    ) objectByParsingJSON];
    auto schema = [Schema fromJSONObject: object];
    auto definitions = $assert_nonnil(schema.definitions);

    OTAssertTrue([schema schemaForReference: @"#/$defs/slash~1name"] == $assert_nonnil(definitions[@"slash/name"]),
        @"JSON Pointer escape sequences must be decoded before lookup");
    OTAssertTrue($assert_nonnil(definitions[@"anchorUser"]).resolvedReference == $assert_nonnil(definitions[@"named"]),
        @"$ref anchor fragments must resolve static anchors");
    OTAssertTrue($assert_nonnil(definitions[@"dynamicUser"]).resolvedDynamicReference == $assert_nonnil(definitions[@"dynamic"]),
        @"$dynamicRef anchor fragments must resolve dynamic anchors");
}

- (void)testVerifiesJSONObjectAndReportsConstraintFailures
{
    auto schemaObject = [@$raw(
        {
            "type": "object",
            "properties": {
                "name": {"type": "string", "minLength": 1},
                "count": {"type": "integer", "minimum": 1}
            },
            "required": ["name"],
            "additionalProperties": false
        }
    ) objectByParsingJSON];
    auto schema = [Schema fromJSONObject: schemaObject];
    [schema verifyJSONObject: [@$raw({"name": "point", "count": 2}) objectByParsingJSON]];

    bool caught = false;
    @try {
        [schema verifyJSONObject: [@$raw({"name": "point", "extra": true}) objectByParsingJSON]];
    } @catch (JSONSchemaVerificationException *exception) {
        caught = true;
        OTAssertEqualObjects(exception.path, @"/extra",
            @"verification exceptions must identify the failing JSON Pointer");
    }
    OTAssertTrue(caught,
        @"verifyJSONObject must reject values that violate the schema");
}

- (void)testGeneratesObjCInterfaceList
{
    auto schemaPath = [self _projectPath: @"clang.schema.json"];
    auto schema = [Schema fromJSONObject: [OFString stringWithContentsOfFile: schemaPath].objectByParsingJSON];
    auto directory = [self _temporaryGenerationDirectory];

    @try {
        [self _generateSchema: schema toDirectory: directory];
        auto header = [self _contentsOfGeneratedFile: @"TranslationUnitDecl.h" inDirectory: directory];
        auto identifierHeader = [self _contentsOfGeneratedFile: @"ClassTemplatePartialSpecializationDecl.h" inDirectory: directory];
        auto source = [self _contentsOfGeneratedFile: @"TranslationUnitDecl.m" inDirectory: directory];
        auto umbrella = [self _contentsOfGeneratedFile: @"JSONSchema.h" inDirectory: directory];

        OTAssertTrue([header containsString: @"@interface TranslationUnitDecl : OFObject <JSONDeserialisable>"],
            @"object definitions must become JSONDeserialisable interfaces");
        OTAssertTrue([header containsString: @"@property(readonly, nonatomic, copy) OFString *id;"],
            @"string references must become copied string properties");
        OTAssertTrue([header containsString: @"@property(readonly, nonatomic, retain) SourceRange *range;"],
            @"object references must become generated interface pointers");
        OTAssertTrue([header containsString: @"@property(readonly, nonatomic, retain) SourceLocation *loc;"],
            @"object unions must become generated interface pointers");
        OTAssertTrue([header containsString: @"@property(readonly, nonatomic, retain) OFArray<AstObject *> *nillable inner;"],
            @"array references must become generic array properties");
        OTAssertTrue([identifierHeader containsString: @"strictPackMatch"],
            @"JSON property names must be converted to valid Objective-C identifiers");
        OTAssertFalse([header containsString: @"* nillable"],
            @"generated pointer nullability must use the compact *nillable spelling");
        OTAssertTrue([header containsString: @"#import <Schema.h>"],
            @"each generated header must import the schema protocol declarations");
        OTAssertTrue([header containsString: @"#import \"SourceRange.h\""],
            @"headers must import generated object property types");
        OTAssertTrue([header containsString: @"#import \"AstObject.h\""],
            @"headers must import generated array element types");
        OTAssertTrue([source containsString: @"#import \"TranslationUnitDecl.h\""],
            @"each generated source must import its own header");
        OTAssertTrue([source containsString: @"- (instancetype)initFromJSONObject: (id)obj"],
            @"generated sources must implement JSONDeserialisable loading");
        OTAssertTrue([umbrella containsString: @"#import \"TranslationUnitDecl.h\""],
            @"the generated umbrella header must import every generated interface header");

        size_t headerCount = 0;
        size_t sourceCount = 0;
        for (OFIRI *item in [OFFileManager.defaultManager contentsOfDirectoryAtIRI: directory]) {
            auto fileName = item.lastPathComponent;
            if ([fileName hasSuffix: @".h"])
                headerCount++;
            if ([fileName hasSuffix: @".m"])
                sourceCount++;
        }
        OTAssert(headerCount > 1000,
            @"the complete object-definition header set must be generated");
        OTAssertEqual(headerCount, sourceCount + 1,
            @"every generated interface must have a matching source plus the umbrella header");
    } @finally {
        if ([OFFileManager.defaultManager directoryExistsAtIRI: directory])
            [OFFileManager.defaultManager removeItemAtIRI: directory];
    }
}

- (void)testGeneratesAllOfInheritance
{
    auto object = [@$raw(
        {
            "$defs": {
                "base": {
                    "type": "object",
                    "properties": {"value": {"type": "string"}}
                },
                "derived": {
                    "type": "object",
                    "allOf": [{"$ref": "#/$defs/base"}],
                    "properties": {"count": {"type": "integer"}}
                }
            }
        }
    ) objectByParsingJSON];
    auto schema = [Schema fromJSONObject: object];
    auto directory = [self _temporaryGenerationDirectory];

    @try {
        [self _generateSchema: schema toDirectory: directory];
        auto header = [self _contentsOfGeneratedFile: @"Derived.h" inDirectory: directory];
        OTAssertTrue([header containsString: @"@interface Derived : Base <JSONDeserialisable>"],
            @"allOf object references must become generated interface inheritance");
        OTAssertTrue([header containsString: @"#import \"Base.h\""],
            @"derived headers must import their generated superclass");
    } @finally {
        if ([OFFileManager.defaultManager directoryExistsAtIRI: directory])
            [OFFileManager.defaultManager removeItemAtIRI: directory];
    }
}

- (void)testVerifiesHomebrewClangJSONDump
{
    auto sourcePath = [self _projectPath: @"Tests/Tools/OCGen/Schema/fixtures/verify.c"];
    auto schemaPath = [self _projectPath: @"clang.schema.json"];
    auto process = [OFSubprocess subprocessWithProgram: HOMEBREW_CLANG
                                             arguments: @[ @"-x", @"c", @"-Xclang", @"-ast-dump=json", @"-fsyntax-only", sourcePath ]];
    auto data = [process readDataUntilEndOfStream];
    auto status = [process waitForTermination];

    OTAssertEqual(status, 0, @"Homebrew Clang must produce a valid AST dump");
    auto dump = [[OFString alloc] initWithData: data encoding: OFStringEncodingUTF8];
    auto schema = [Schema fromJSONObject: [OFString stringWithContentsOfFile: schemaPath].objectByParsingJSON];
    [schema verifyJSONObject: dump.objectByParsingJSON];
}

- (void)testVerifiesHomebrewClangObjectiveCJSONDump
{
    auto sourcePath = [self _projectPath: @"Tests/Tools/OCGen/Schema/fixtures/verify.m"];
    auto schemaPath = [self _projectPath: @"clang.schema.json"];
    auto process = [OFSubprocess subprocessWithProgram: HOMEBREW_CLANG
                                             arguments: @[ @"-x", @"objective-c", @"-Xclang", @"-ast-dump=json", @"-fsyntax-only", sourcePath ]];
    auto data = [process readDataUntilEndOfStream];
    auto status = [process waitForTermination];

    OTAssertEqual(status, 0, @"Homebrew Clang must produce a valid Objective-C AST dump");
    auto dump = [[OFString alloc] initWithData: data encoding: OFStringEncodingUTF8];
    auto schema = [Schema fromJSONObject: [OFString stringWithContentsOfFile: schemaPath].objectByParsingJSON];
    [schema verifyJSONObject: dump.objectByParsingJSON];
}

@end

#pragma clang assume_nonnull end
