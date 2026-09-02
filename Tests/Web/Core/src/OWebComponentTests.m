#import <Web.h>
#import <OWebWireProtocol.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

@interface OWebTestBaseComponent : Component
@property(readonly, nonatomic) OFString *subtitle;
@end

@implementation OWebTestBaseComponent
@end


@interface MyComponent : OWebTestBaseComponent

@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) uint32_t count;
@property(nonatomic) bool isEnabled;

- (bool)wasClicked;

@end

@implementation MyComponent {
    bool _wasClicked;
}

+ (OFString *)style
{
    return $css(:host { display: block; } h1 { font-weight: 600; });
}

+ (OFString *)layout
{
    return $html(
        <div id="root">
            <h1 id="name" title="initial"></h1>
            <button id="button" onclick="onButtonClick:">Click me!</button>
            <section id="items"></section>
            <template id="row"><span>Row</span></template>
        </div>
    );
}

- (void)onAttach
{
    [self elementByID: @"name"].textContent = self.name;
}

- (void)onButtonClick: (OWebEvent *)event
{
    (void)event;
    _wasClicked = true;
    [self elementByID: @"name"].textContent = @"Clicked";
}

- (bool)wasClicked
{
    return _wasClicked;
}

@end


@interface OWebDuplicateIDComponent : Component
@end
@implementation OWebDuplicateIDComponent
+ (OFString *)layout
{ return $html(<div id="same"></div><span id="same"></span>); }
@end

@interface OWebMissingActionComponent : Component
@end
@implementation OWebMissingActionComponent
+ (OFString *)layout
{ return $html(<button onclick="missingAction:">No</button>); }
@end

@interface OWebBadActionSignatureComponent : Component
@end
@implementation OWebBadActionSignatureComponent
+ (OFString *)layout
{ return $html(<button onclick="badAction:">No</button>); }
- (int)badAction: (OWebEvent *)event
{ (void)event; return 1; }
@end

@interface OWebUnsafeElementComponent : Component
@end
@implementation OWebUnsafeElementComponent
+ (OFString *)layout
{ return $html(<script>window.evil = true;</script>); }
@end

@interface OWebUnsafeURLComponent : Component
@end
@implementation OWebUnsafeURLComponent
+ (OFString *)layout
{ return $html(<a href="javascript:alert(1)">No</a>); }
@end

@interface OWebUnsafeStyleComponent : Component
@end
@implementation OWebUnsafeStyleComponent
+ (OFString *)style
{ return @"@import 'https://example.invalid/style.css';"; }
+ (OFString *)layout
{ return $html(<div></div>); }
@end

@interface OWebTemplateActionComponent : Component
@end
@implementation OWebTemplateActionComponent
+ (OFString *)layout
{
    return $html(
        <template id="row"><button onclick="tap:">No</button></template>
    );
}
- (void)tap: (OWebEvent *)event
{ (void)event; }
@end

@interface OWebTemplateMultipleRootsComponent : Component
@end
@implementation OWebTemplateMultipleRootsComponent
+ (OFString *)layout
{
    return $html(
        <template id="row"><span>One</span><span>Two</span></template>
    );
}
@end

@interface OWebTemplateDirectTextComponent : Component
@end
@implementation OWebTemplateDirectTextComponent
+ (OFString *)layout
{ return $html(<template id="row">Text only</template>); }
@end

@interface OWebMalformedComponent : Component
@end
@implementation OWebMalformedComponent
+ (OFString *)layout
{ return @"<div><span></div>"; }
@end

@interface OWebUnsafeRuntimePropertyComponent : Component
@property(readonly, nonatomic) OFString *virtualName;
@end
@implementation OWebUnsafeRuntimePropertyComponent
+ (OFString *)layout
{ return $html(<div></div>); }
- (OFString *)virtualName
{ return @"computed"; }
@end


@interface OWebComponentTests : OTTestCase
@end

@implementation OWebComponentTests

- (OWebComponentDefinition *)definition
{
    return [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [MyComponent class]];
}

- (void)testAuthoringSyntaxReflectionAndStrictCompilation
{
    auto definition = self.definition;
    OTAssertEqualObjects(definition.elementName, @"my-component");
    OTAssertTrue([definition.compiledLayout containsString: @"<h1 id=\"name\""]);
    OTAssertFalse([definition.compiledLayout containsString: @"onclick"]);
    OTAssertTrue([definition.compiledLayout
        containsString: @"data-oweb-on-click="]);
    OTAssertTrue([definition.compiledLayout containsString: @"data-oweb-id="]);
    OTAssertEqual(definition.actionsByIdentifier.count, (size_t)1);
    OTAssertEqual(definition.elementIdentifiersByID.count, (size_t)4);
    OTAssertNotNil(definition.elementIdentifiersByID[@"root"]);
    OTAssertNotNil(definition.elementIdentifiersByID[@"name"]);
    OTAssertNotNil(definition.elementIdentifiersByID[@"items"]);
    OTAssertNotNil(definition.elementIdentifiersByID[@"button"]);
    OTAssertNotNil(definition.templateIdentifiersByID[@"row"]);

    OWebReflectedProperty *name = $assert_nonnil(
        definition.propertiesByAttribute[@"name"]);
    OWebReflectedProperty *subtitle = $assert_nonnil(
        definition.propertiesByAttribute[@"subtitle"]);
    OWebReflectedProperty *enabled = $assert_nonnil(
        definition.propertiesByAttribute[@"is-enabled"]);
    OTAssertTrue(name.isReadonly);
    OTAssertTrue(name.isHydratable);
    OTAssertTrue(subtitle.isReadonly);
    OTAssertEqual(enabled.type, OWebReflectedPropertyTypeBool);
}

- (void)testHydratesInheritedReadonlyStringScalarAndWritableBoolProperties
{
    auto component = (MyComponent *)[self.definition instantiateWithAttributes: @{
        @"name": @"Rei",
        @"subtitle": @"Assistant",
        @"count": @"42",
        @"is-enabled": @"true"
    }];
    OTAssertEqualObjects(component.name, @"Rei");
    OTAssertEqualObjects(component.subtitle, @"Assistant");
    OTAssertEqual(component.count, (uint32_t)42);
    OTAssertTrue(component.isEnabled);

    auto patches = component.drainPatches;
    OTAssertEqual(patches.count, (size_t)1);
    auto patch = $assert_nonnil(patches.firstObject);
    OTAssertEqual(patch.opcode, OWebPatchOpcodeSetText);
    OTAssertEqualObjects(patch.value.stringValue, @"Rei");
    OTAssertEqual(component.drainPatches.count, (size_t)0);
}

- (void)testPatchSinkAndActionDispatchStayTypedAndSelectorFree
{
    auto observed = [OFMutableArray<OWebPatchOperation *> array];
    auto component = (MyComponent *)[self.definition instantiateWithAttributes:
        @{ @"name": @"Rei" }
        patchSink: ^(OWebPatchOperation *patch) {
            [observed addObject: patch];
        }];
    OTAssertEqual(observed.count, (size_t)1);

    OFNumber *actionKey = $assert_nonnil(
        self.definition.actionsByIdentifier.allKeys.firstObject);
    OWebActionDefinition *action = $assert_nonnil(
        self.definition.actionsByIdentifier[actionKey]);
    auto event = [[OWebEvent alloc] initWithType: @"click"
        targetIdentifier: action.targetIdentifier fields: @{}];
    [component dispatchActionIdentifier: action.identifier event: event];
    OTAssertTrue(component.wasClicked);
    OTAssertEqual(observed.count, (size_t)2);
    OTAssertFalse([self.definition.compiledLayout
        containsString: action.selectorName]);
    OTAssertEqual(action.targetIdentifier,
        self.definition.elementIdentifiersByID[@"button"].unsignedLongLongValue);

    auto forgedTarget = [[OWebEvent alloc] initWithType: @"click"
        targetIdentifier: 99 fields: @{}];
    OTAssertThrowsSpecific(
        [component dispatchActionIdentifier: action.identifier event: forgedTarget],
        OWebDefinitionException);

    auto wrongEvent = [[OWebEvent alloc] initWithType: @"change"
        targetIdentifier: 99 fields: @{}];
    OTAssertThrowsSpecific(
        [component dispatchActionIdentifier: action.identifier event: wrongEvent],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [component dispatchActionIdentifier: UINT64_MAX event: event],
        OWebDefinitionException);
}

- (void)testEventProjectionUsesTheWireProtocolsSingleAllowlist
{
    auto event = [[OWebEvent alloc] initWithType: @"click"
        targetIdentifier: 99 fields: @{
            @"detail": @1,
            @"offsetX": @12.5,
            @"offsetY": @4,
            @"repeat": @false
        }];
    OTAssertEqual(event.fields.count, (size_t)4);
    OTAssertEqualObjects(event.fields[@"detail"], @1);
    OTAssertThrowsSpecific(
        (void)[[OWebEvent alloc] initWithType: @"click"
            targetIdentifier: 99 fields: @{ @"checked": @true }],
        OFInvalidArgumentException);
}

- (void)testDeclaredTemplateCollectionOperationsEmitStructuralPatches
{
    auto component = [self.definition instantiateWithAttributes:
        @{ @"name": @"Rei" }];
    (void)component.drainPatches;
    auto parent = [component elementByID: @"items"];
    auto first = [parent appendTemplateWithID: @"row" key: @"first"];
    auto second = [parent appendTemplateWithID: @"row" key: @"second"];
    [parent moveChild: second beforeChild: first];
    [parent removeChild: first];

    auto patches = component.drainPatches;
    OTAssertEqual(patches.count, (size_t)4);
    OTAssertEqual([patches[0] opcode], OWebPatchOpcodeCloneTemplate);
    OTAssertEqual([patches[1] opcode], OWebPatchOpcodeCloneTemplate);
    OTAssertEqual([patches[2] opcode], OWebPatchOpcodeMoveNode);
    OTAssertEqual([patches[3] opcode], OWebPatchOpcodeRemoveNode);
    OTAssertNotEqual(first.identifier, second.identifier);
    OTAssertThrowsSpecific(first.textContent = @"detached",
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [parent appendTemplateWithID: @"missing" key: @"missing"],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [parent appendTemplateWithID: @"row" key: @"second"],
        OWebDefinitionException);
}

- (void)testRejectsUnknownAndInvalidReflectedAttributeValues
{
    OTAssertThrowsSpecific(
        ([self.definition instantiateWithAttributes:
            @{ @"name": @"Rei", @"typo": @"value" }]),
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        ([self.definition instantiateWithAttributes:
            @{ @"name": @"Rei", @"count": @"4294967296" }]),
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        ([self.definition instantiateWithAttributes:
            @{ @"name": @"Rei", @"is-enabled": @"sometimes" }]),
        OWebDefinitionException);

    auto virtualDefinition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebUnsafeRuntimePropertyComponent class]];
    OTAssertThrowsSpecific(
        [virtualDefinition instantiateWithAttributes:
            @{ @"virtual-name": @"attempt" }],
        OWebDefinitionException);
}

- (void)testRejectsMalformedExecutableAndAmbiguousTemplates
{
    auto registry = OWebComponentRegistry.sharedRegistry;
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebDuplicateIDComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebMissingActionComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass:
            [OWebBadActionSignatureComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebUnsafeElementComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebUnsafeURLComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebUnsafeStyleComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebTemplateActionComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass:
            [OWebTemplateMultipleRootsComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass:
            [OWebTemplateDirectTextComponent class]],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [registry definitionForComponentClass: [OWebMalformedComponent class]],
        OWebDefinitionException);
}

- (void)testRuntimeElementBoundaryRejectsMarkupAndURLChannels
{
    auto component = [self.definition instantiateWithAttributes:
        @{ @"name": @"Rei" }];
    auto element = [component elementByID: @"name"];
    OTAssertThrowsSpecific(
        [element setAttribute: @"onclick" value: @"alert(1)"],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [element setAttribute: @"href" value: @"javascript:alert(1)"],
        OWebDefinitionException);
    OTAssertThrowsSpecific(
        [element setAttribute: @"style" value: @"background:url(x)"],
        OWebDefinitionException);
    [element setAttribute: @"aria-label" value: @"Safe"];
    [element removeAttribute: @"aria-label"];
}

- (void)testFirstMutationCannotBeMistakenForUnknownStaticTemplateState
{
    auto component = [self.definition instantiateWithAttributes:
        @{ @"name": @"Rei" }];
    (void)component.drainPatches;
    auto element = [component elementByID: @"name"];

    element.textContent = @"";
    [element removeAttribute: @"title"];
    auto patches = component.drainPatches;
    OTAssertEqual(patches.count, (size_t)2);
    OTAssertEqual([patches[0] opcode], OWebPatchOpcodeSetText);
    OTAssertEqual([patches[1] opcode], OWebPatchOpcodeRemoveAttribute);

    element.textContent = @"";
    [element removeAttribute: @"title"];
    OTAssertEqual(component.drainPatches.count, (size_t)0);
}

@end

#pragma clang assume_nonnull end
