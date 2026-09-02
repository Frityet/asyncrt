#import <OWebSession.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

static size_t OWebSessionTestActionCount;
static OFString *nillable OWebSessionTestLastValue;
static size_t OWebSessionNoPatchActionCount;
static size_t OWebSessionThrowingActionCount;

@interface OWebSessionTestComponent : OWebComponent

@property(nonatomic) bool isEnabled;

@end


@implementation OWebSessionTestComponent

+ (OFString *)layout
{
    return $html(
        <div id="root">
            <button id="button" onclick="tap:">Tap</button>
            <section id="items"></section>
            <template id="row"><span>Row</span></template>
        </div>
    );
}

- (void)onAttach
{
    [self elementByID: @"button"].textContent =
        self.isEnabled ? @"enabled" : @"disabled";
}

- (void)tap: (OWebEvent *)event
{
    OWebSessionTestActionCount++;
    id value = event.fields[@"value"];
    if ([value isKindOfClass: [OFString class]])
        OWebSessionTestLastValue = [value copy];
    [self elementByID: @"button"].textContent = @"handled";
    [[self elementByID: @"items"]
        appendTemplateWithID: @"row"
                           key: [OFString stringWithFormat: @"row-%zu",
                               OWebSessionTestActionCount]];
}

@end


@interface OWebSessionNoPatchComponent : OWebComponent
@end

@implementation OWebSessionNoPatchComponent

+ (OFString *)layout
{
    return $html(<button id="button" onclick="noop:">Noop</button>);
}

- (void)noop: (OWebEvent *)event
{
    (void)event;
    OWebSessionNoPatchActionCount++;
}

@end


@interface OWebSessionThrowingComponent : OWebComponent
@end

@implementation OWebSessionThrowingComponent

+ (OFString *)layout
{
    return $html(<button id="button" onclick="explode:">Explode</button>);
}

- (void)explode: (OWebEvent *)event
{
    (void)event;
    OWebSessionThrowingActionCount++;
    @throw [OFException exception];
}

@end


@interface OWebSessionTransactionalComponent : OWebComponent

@property(nonatomic) bool isInvalid;

@end


@implementation OWebSessionTransactionalComponent

+ (OFString *)layout
{
    return $html(
        <div id="root">
            <span id="status"></span>
            <template id="row"><span>Row</span></template>
        </div>
    );
}

- (void)onAttach
{
    if (self.isInvalid)
        [[self elementByID: @"root"] appendTemplateWithID: @"row" key: @"row"];
    else
        [self elementByID: @"status"].textContent = @"valid";
}

- (OFArray<OWebPatchOperation *> *)drainPatches
{
    auto patches = [super drainPatches];
    if (not self.isInvalid)
        return patches;
    return @[[OWebPatchOperation batch: @[
        $assert_nonnil(patches.firstObject),
        [OWebPatchOperation setText: @"invalid" forElement: UINT64_MAX]
    ]]];
}

@end


@interface OWebSessionStructuralAttackComponent : OWebComponent

@property(nonatomic, copy) OFString *attack;

@end


@implementation OWebSessionStructuralAttackComponent

+ (OFString *)layout
{
    return $html(
        <div id="root">
            <div id="static-parent"><span id="static-child"></span></div>
            <div id="template-parent">
                <template id="nested-row"><span></span></template>
            </div>
            <div id="dynamic-parent"></div>
            <input id="void-parent"/>
            <template id="row"><section></section></template>
            <template id="void-row"><input/></template>
        </div>
    );
}

- (uint64_t)elementIdentifierForLogicalID: (OFString *)logicalID
{
    return [self.definition.elementIdentifiersByID[logicalID]
        unsignedLongLongValue];
}

- (uint64_t)templateIdentifierForLogicalID: (OFString *)logicalID
{
    return [self.definition.templateIdentifiersByID[logicalID]
        unsignedLongLongValue];
}

- (OFArray<OWebPatchOperation *> *)drainPatches
{
    (void)[super drainPatches];
    uint64_t root = [self elementIdentifierForLogicalID: @"root"];
    uint64_t staticParent = [self elementIdentifierForLogicalID:
        @"static-parent"];
    uint64_t templateParent = [self elementIdentifierForLogicalID:
        @"template-parent"];
    uint64_t dynamicParent = [self elementIdentifierForLogicalID:
        @"dynamic-parent"];
    uint64_t voidParent = [self elementIdentifierForLogicalID: @"void-parent"];
    uint64_t row = [self templateIdentifierForLogicalID: @"row"];
    uint64_t voidRow = [self templateIdentifierForLogicalID: @"void-row"];
    uint64_t firstDynamic = self.definition.maximumStaticIdentifier + 1;
    uint64_t secondDynamic = firstDynamic + 1;

    if ([self.attack isEqual: @"set-static-element"])
        return @[[OWebPatchOperation setText: @"unsafe"
            forElement: staticParent]];
    if ([self.attack isEqual: @"set-static-template"])
        return @[[OWebPatchOperation setText: @"unsafe"
            forElement: templateParent]];
    if ([self.attack isEqual: @"set-dynamic-descendant"])
        return @[[OWebPatchOperation batch: @[
            [OWebPatchOperation cloneTemplate: row
                intoParent: dynamicParent asNode: firstDynamic],
            [OWebPatchOperation setText: @"unsafe" forElement: dynamicParent]
        ]]];
    if ([self.attack isEqual: @"clone-static-void"])
        return @[[OWebPatchOperation cloneTemplate: row
            intoParent: voidParent asNode: firstDynamic]];
    if ([self.attack isEqual: @"clone-dynamic-void"])
        return @[[OWebPatchOperation batch: @[
            [OWebPatchOperation cloneTemplate: voidRow
                intoParent: dynamicParent asNode: firstDynamic],
            [OWebPatchOperation cloneTemplate: row
                intoParent: firstDynamic asNode: secondDynamic]
        ]]];
    if ([self.attack isEqual: @"move-static-void"])
        return @[[OWebPatchOperation batch: @[
            [OWebPatchOperation cloneTemplate: row
                intoParent: dynamicParent asNode: firstDynamic],
            [OWebPatchOperation moveNode: firstDynamic
                intoParent: voidParent beforeNode: 0]
        ]]];
    if ([self.attack isEqual: @"move-dynamic-void"])
        return @[[OWebPatchOperation batch: @[
            [OWebPatchOperation cloneTemplate: voidRow
                intoParent: dynamicParent asNode: firstDynamic],
            [OWebPatchOperation cloneTemplate: row
                intoParent: root asNode: secondDynamic],
            [OWebPatchOperation moveNode: secondDynamic
                intoParent: firstDynamic beforeNode: 0]
        ]]];
    if ([self.attack isEqual: @"move-before-self"])
        return @[[OWebPatchOperation batch: @[
            [OWebPatchOperation cloneTemplate: row
                intoParent: dynamicParent asNode: firstDynamic],
            [OWebPatchOperation moveNode: firstDynamic
                intoParent: dynamicParent beforeNode: firstDynamic]
        ]]];
    return @[];
}

@end


@interface OWebSessionOtherComponent : OWebComponent
@end

@implementation OWebSessionOtherComponent
+ (OFString *)layout
{
    return $html(<div id="other"></div>);
}
@end


@interface OWebSessionTests : OTTestCase
@end


@implementation OWebSessionTests

- (void)setUp
{
    OWebSessionTestActionCount = 0;
    OWebSessionTestLastValue = nilptr;
    OWebSessionNoPatchActionCount = 0;
    OWebSessionThrowingActionCount = 0;
    auto registry = OWebComponentRegistry.sharedRegistry;
    [registry registerComponentClass: [OWebSessionTestComponent class]];
    [registry registerComponentClass: [OWebSessionNoPatchComponent class]];
    [registry registerComponentClass: [OWebSessionThrowingComponent class]];
    [registry registerComponentClass: [OWebSessionTransactionalComponent class]];
    [registry registerComponentClass:
        [OWebSessionStructuralAttackComponent class]];
    [registry registerComponentClass: [OWebSessionOtherComponent class]];
}

- (OWebComponentSession *)session
{
    return [[OWebComponentSession alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry];
}

- (OWebMountFrame *)mountWithIdentifier: (uint64_t)identifier
                                  enabled: (bool)enabled
{
    auto attributes = enabled
        ? @{ @"is-enabled": @"true" }
        : @{};
    return [[OWebMountFrame alloc]
        initWithInstanceIdentifier: identifier
                       componentTag: @"o-web-session-test-component"
                         attributes: attributes];
}

- (uint64_t)actionIdentifierForDefinition: (OWebComponentDefinition *)definition
                                 selector: (OFString *)selector
{
    for (OFNumber *identifier in definition.actionsByIdentifier) {
        auto action = definition.actionsByIdentifier[identifier];
        if ([action.selectorName isEqual: selector])
            return identifier.unsignedLongLongValue;
    }
    @throw [OFInvalidArgumentException exception];
}

- (uint64_t)targetIdentifierForDefinition:
    (OWebComponentDefinition *)definition logicalID: (OFString *)logicalID
{
    return [definition.elementIdentifiersByID[logicalID]
        unsignedLongLongValue];
}

- (void)testMountClaimsInstanceAndEmitsTypedInitialPatch
{
    auto session = self.session;
    auto patch = [session processFrame: [self mountWithIdentifier: 41
                                                              enabled: true]
                              sequence: 1];
    OTAssertNotNil(patch);
    OTAssertEqual(patch.instanceIdentifier, UINT64_C(41));
    OTAssertEqual(patch.operations.count, (size_t)1);
    auto operation = $assert_nonnil(patch.operations.firstObject);
    OTAssertEqual(operation.opcode, OWebPatchOpcodeSetText);
    OTAssertEqualObjects(operation.value.stringValue, @"enabled");
    OTAssertTrue([session ownsInstanceIdentifier: 41]);
    OTAssertEqual(session.mountedInstanceCount, (size_t)1);

    auto encoded = [OWebWireCodec encodeFrame: $assert_nonnil(patch)];
    auto decoded = (OWebPatchFrame *)[OWebWireCodec decodeFrameData: encoded];
    OTAssertEqual(decoded.frameType, OWebWireFrameTypePatch);
    OTAssertEqual(decoded.instanceIdentifier, UINT64_C(41));
}

- (void)testRepeatedMountIsIdempotentAndChangedSnapshotReinstantiatesServerState
{
    auto session = self.session;
    (void)[session processFrame: [self mountWithIdentifier: 42 enabled: true]
                       sequence: 5];
    auto duplicate = [session processFrame:
        [self mountWithIdentifier: 42 enabled: true] sequence: 6];
    OTAssertNil(duplicate);
    OTAssertEqual(session.mountedInstanceCount, (size_t)1);

    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebSessionTestComponent class]];
    uint64_t actionIdentifier = [self actionIdentifierForDefinition: definition
        selector: @"tap:"];
    uint64_t targetIdentifier = [self targetIdentifierForDefinition: definition
        logicalID: @"button"];
    auto event = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 42 actionIdentifier: actionIdentifier
        targetIdentifier: targetIdentifier fields: @{}];
    auto eventPatch = [session processFrame: event sequence: 7];
    OTAssertEqual(eventPatch.operations.lastObject.opcode,
        OWebPatchOpcodeCloneTemplate);

    auto refreshed = [session processFrame:
        [self mountWithIdentifier: 42 enabled: false] sequence: 8];
    OTAssertNotNil(refreshed);
    OTAssertEqual(refreshed.operations.count, (size_t)2);
    OTAssertEqual(refreshed.operations.firstObject.opcode,
        OWebPatchOpcodeRemoveNode);
    OTAssertEqual(refreshed.operations.lastObject.opcode,
        OWebPatchOpcodeSetText);
    OTAssertEqualObjects(
        $assert_nonnil(refreshed.operations.lastObject).value.stringValue,
        @"disabled");
    OTAssertEqual(session.mountedInstanceCount, (size_t)1);
}

- (void)testConflictingTagAndStaleSequenceAreRejectedDeterministically
{
    auto session = self.session;
    (void)[session processFrame: [self mountWithIdentifier: 43 enabled: false]
                       sequence: 1];

    @try {
        (void)[session processFrame: [self mountWithIdentifier: 43 enabled: true]
                           sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure,
            OWebSessionFailureSequenceConflict);
        OTAssertEqualObjects(exception.code, @"sequence-conflict");
        OTAssertEqual(exception.statusCode, (unsigned short)409);
    }

    auto conflict = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 43
                       componentTag: @"o-web-session-other-component"
                         attributes: @{}];
    @try {
        (void)[session processFrame: conflict sequence: 2];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureInstanceConflict);
        OTAssertEqualObjects(exception.code, @"instance-conflict");
        OTAssertEqual(exception.statusCode, (unsigned short)409);
    }

    @try {
        (void)[session processFrame: [self mountWithIdentifier: 43 enabled: false]
                           sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureStaleSequence);
    }
}

- (void)testExactRetransmissionReplaysPatchAndNoPatchWithoutRedispatch
{
    auto session = self.session;
    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebSessionTestComponent class]];
    uint64_t actionIdentifier = [self actionIdentifierForDefinition: definition
        selector: @"tap:"];
    uint64_t targetIdentifier = [self targetIdentifierForDefinition: definition
        logicalID: @"button"];
    (void)[session processFrame: [self mountWithIdentifier: 61 enabled: false]
                       sequence: 1];
    auto event = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 61 actionIdentifier: actionIdentifier
        targetIdentifier: targetIdentifier fields: @{}];
    auto firstPatch = [session processFrame: event sequence: 2];
    OTAssertNotNil(firstPatch);
    OTAssertEqual(OWebSessionTestActionCount, (size_t)1);
    auto replayedPatch = [session processFrame: event sequence: 2];
    OTAssertNotNil(replayedPatch);
    OTAssertEqual(OWebSessionTestActionCount, (size_t)1);
    OTAssertEqualObjects(
        [OWebWireCodec encodeFrame: $assert_nonnil(firstPatch)],
        [OWebWireCodec encodeFrame: $assert_nonnil(replayedPatch)]);

    auto noPatchDefinition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebSessionNoPatchComponent class]];
    auto mount = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 62
        componentTag: noPatchDefinition.elementName attributes: @{}];
    OTAssertNil([session processFrame: mount sequence: 1]);
    uint64_t noPatchAction = [self actionIdentifierForDefinition:
        noPatchDefinition selector: @"noop:"];
    uint64_t noPatchTarget = [self targetIdentifierForDefinition:
        noPatchDefinition logicalID: @"button"];
    auto noPatchEvent = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 62 actionIdentifier: noPatchAction
        targetIdentifier: noPatchTarget fields: @{}];
    OTAssertNil([session processFrame: noPatchEvent sequence: 2]);
    OTAssertNil([session processFrame: noPatchEvent sequence: 2]);
    OTAssertEqual(OWebSessionNoPatchActionCount, (size_t)1);
}

- (void)testStructuralValidationIsTransactionalAndQuarantinesTheInstance
{
    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass:
            [OWebSessionTransactionalComponent class]];
    auto invalid = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 63 componentTag: definition.elementName
        attributes: @{ @"is-invalid": @"true" }];
    auto session = self.session;
    @try {
        (void)[session processFrame: invalid sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure,
            OWebSessionFailureComponentRejectedInput);
    }
    OTAssertFalse([session ownsInstanceIdentifier: 63]);

    /* The exact failed request is cached and cannot execute again. */
    @try {
        (void)[session processFrame: invalid sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure,
            OWebSessionFailureComponentRejectedInput);
    }
    auto valid = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 63 componentTag: definition.elementName
        attributes: @{}];
    auto patch = [session processFrame: valid sequence: 2];
    OTAssertNotNil(patch);
    OTAssertTrue([session ownsInstanceIdentifier: 63]);
}

- (void)assertStructuralAttackIsRejected: (OFString *)attack
                             instanceIdentifier: (uint64_t)instanceIdentifier
{
    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass:
            [OWebSessionStructuralAttackComponent class]];
    auto mount = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier
        componentTag: definition.elementName
        attributes: @{ @"attack": attack }];
    auto session = self.session;
    @try {
        (void)[session processFrame: mount sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure,
            OWebSessionFailureComponentRejectedInput);
    }
    OTAssertFalse([session ownsInstanceIdentifier: instanceIdentifier]);
}

- (void)testSetTextRejectsEveryCapabilityDescendantSeenByBrowserPreflight
{
    [self assertStructuralAttackIsRejected: @"set-static-element"
                              instanceIdentifier: 70];
    [self assertStructuralAttackIsRejected: @"set-static-template"
                              instanceIdentifier: 71];
    [self assertStructuralAttackIsRejected: @"set-dynamic-descendant"
                              instanceIdentifier: 72];
}

- (void)testCloneTemplateRejectsStaticAndDynamicVoidParents
{
    [self assertStructuralAttackIsRejected: @"clone-static-void"
                              instanceIdentifier: 73];
    [self assertStructuralAttackIsRejected: @"clone-dynamic-void"
                              instanceIdentifier: 74];
}

- (void)testMoveNodeRejectsVoidParentsAndSelfSibling
{
    [self assertStructuralAttackIsRejected: @"move-static-void"
                              instanceIdentifier: 75];
    [self assertStructuralAttackIsRejected: @"move-dynamic-void"
                              instanceIdentifier: 76];
    [self assertStructuralAttackIsRejected: @"move-before-self"
                              instanceIdentifier: 77];
}

- (void)testMountedAndReplayStateHaveHardCaps
{
    auto session = [[OWebComponentSession alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry
        maximumMountedInstances: 1 maximumReplayEntries: 1];
    (void)[session processFrame: [self mountWithIdentifier: 64 enabled: false]
                       sequence: 1];
    @try {
        (void)[session processFrame: [self mountWithIdentifier: 65 enabled: false]
                           sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureCapacityExceeded);
        OTAssertEqual(exception.statusCode, (unsigned short)503);
    }
    OTAssertEqual(session.mountedInstanceCount, (size_t)1);
    OTAssertTrue(session.replayEntryCount <= session.maximumReplayEntries);

    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 64];
    OTAssertNil([session processFrame: detach sequence: 2]);
    (void)[session processFrame: [self mountWithIdentifier: 65 enabled: false]
                       sequence: 2];
    OTAssertEqual(session.mountedInstanceCount, (size_t)1);
    OTAssertTrue(session.replayEntryCount <= (size_t)1);
}

- (void)testInvalidReplayChurnCannotEvictMountedInstances
{
    auto session = [[OWebComponentSession alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry
        maximumMountedInstances: 2 maximumReplayEntries: 2];
    auto first = [self mountWithIdentifier: 101 enabled: false];
    auto second = [self mountWithIdentifier: 102 enabled: true];
    auto firstPatch = [session processFrame: first sequence: 1];
    (void)[session processFrame: second sequence: 1];

    for (uint64_t identifier = 200; identifier < 220; identifier++) {
        auto invalid = [[OWebDetachFrame alloc]
            initWithInstanceIdentifier: identifier];
        OTAssertThrowsSpecific((void)[session processFrame: invalid sequence: 1],
            OWebSessionException);
    }

    auto replay = [session processFrame: first sequence: 1];
    OTAssertEqualObjects([OWebWireCodec encodeFrame: $assert_nonnil(replay)],
        [OWebWireCodec encodeFrame: $assert_nonnil(firstPatch)]);
    OTAssertTrue([session ownsInstanceIdentifier: 101]);
    OTAssertTrue([session ownsInstanceIdentifier: 102]);
    OTAssertEqual(session.replayEntryCount, (size_t)2);
}

- (void)testValidatesOpaqueActionAndTargetBeforeDispatch
{
    auto session = self.session;
    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebSessionTestComponent class]];
    uint64_t actionIdentifier = [self actionIdentifierForDefinition: definition
        selector: @"tap:"];
    uint64_t targetIdentifier = [self targetIdentifierForDefinition: definition
        logicalID: @"button"];
    (void)[session processFrame: [self mountWithIdentifier: 44 enabled: false]
                       sequence: 1];

    auto unknownAction = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 44 actionIdentifier: UINT64_MAX
        targetIdentifier: targetIdentifier fields: @{}];
    @try {
        (void)[session processFrame: unknownAction sequence: 2];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureUnknownAction);
    }
    OTAssertEqual(OWebSessionTestActionCount, (size_t)0);

    auto invalidTarget = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 44 actionIdentifier: actionIdentifier
        targetIdentifier: UINT64_MAX fields: @{}];
    @try {
        (void)[session processFrame: invalidTarget sequence: 3];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureInvalidTarget);
    }
    OTAssertEqual(OWebSessionTestActionCount, (size_t)0);

    uint64_t otherValidTarget = [self targetIdentifierForDefinition: definition
        logicalID: @"items"];
    auto forgedValidTarget = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 44 actionIdentifier: actionIdentifier
        targetIdentifier: otherValidTarget fields: @{}];
    @try {
        (void)[session processFrame: forgedValidTarget sequence: 4];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureInvalidTarget);
    }
    OTAssertEqual(OWebSessionTestActionCount, (size_t)0);

    auto valid = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 44 actionIdentifier: actionIdentifier
        targetIdentifier: targetIdentifier
        fields: @{ @"value": [OWebWireValue valueWithString: @"typed"] }];
    auto patch = [session processFrame: valid sequence: 5];
    OTAssertEqual(OWebSessionTestActionCount, (size_t)1);
    OTAssertEqualObjects(OWebSessionTestLastValue, @"typed");
    OTAssertNotNil(patch);
    OTAssertEqual(patch.operations.count, (size_t)2);
    OTAssertEqual(patch.operations[0].opcode, OWebPatchOpcodeSetText);
    OTAssertEqual(patch.operations[1].opcode, OWebPatchOpcodeCloneTemplate);
}

- (void)testDetachReleasesOwnershipAndTearsDownDispatch
{
    auto session = self.session;
    (void)[session processFrame: [self mountWithIdentifier: 45 enabled: false]
                       sequence: 1];
    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 45];
    OTAssertNil([session processFrame: detach sequence: 2]);
    OTAssertNil([session processFrame: detach sequence: 2]);
    OTAssertFalse([session ownsInstanceIdentifier: 45]);
    OTAssertEqual(session.mountedInstanceCount, (size_t)0);

    auto event = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 45 actionIdentifier: 1
        targetIdentifier: 1 fields: @{}];
    @try {
        (void)[session processFrame: event sequence: 3];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureUnknownInstance);
    }

    /* Detach releases the capability; a later Mount may claim it anew. */
    auto remount = [session processFrame:
        [self mountWithIdentifier: 45 enabled: true] sequence: 4];
    OTAssertNotNil(remount);
    OTAssertTrue([session ownsInstanceIdentifier: 45]);
}

- (void)testRejectsBrowserSuppliedPatchFrames
{
    auto patch = [[OWebPatchFrame alloc]
        initWithInstanceIdentifier: 1 operations: @[]];
    @try {
        (void)[self.session processFrame: patch sequence: 1];
        OTAssert(false);
    } @catch (OWebSessionException *exception) {
        OTAssertEqual(exception.failure, OWebSessionFailureUnexpectedFrame);
    }
}

- (OWebComponentEndpoint *)endpointWithBodyCap: (size_t)bodyCap
{
    return [[OWebComponentEndpoint alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry
        expectedOrigin: @"http://127.0.0.1:8080"
        maximumBodyBytes: bodyCap
        sessionIdentityProvider: ^OFString *(OWebHTTPRequest *request) {
            return [request headerForName: @"X-Test-Session"];
        }];
}

- (OWebComponentEndpoint *)endpointWithMaximumSessions:
    (size_t)maximumSessions
{
    return [[OWebComponentEndpoint alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry
        expectedOrigin: @"http://127.0.0.1:8080"
        maximumBodyBytes: OWebWireMaximumFrameBytes
        maximumSessions: maximumSessions
        sessionIdleTimeToLive: 60
        maximumMountedInstancesPerSession: 2
        maximumReplayEntriesPerSession: 4
        sessionIdentityProvider: ^OFString *(OWebHTTPRequest *request) {
            return [request headerForName: @"X-Test-Session"];
        }];
}

- (OWebHTTPRequest *)requestWithFrame: (id<OWebWireFrame>)frame
                                  sequence: (OFString *)sequence
                                  identity: (OFString *)identity
{
    return [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodPost path: @"/_oweb/frame"
        headers: @{
            @"Origin": @"http://127.0.0.1:8080",
            @"Content-Type": @"application/vnd.oweb.frame",
            @"Accept": @"application/vnd.oweb.frame",
            @"X-OWeb-Sequence": sequence,
            @"X-Test-Session": identity
        }
        body: [OWebWireCodec encodeFrame: frame]];
}

- (void)testHTTPBoundaryReturnsSequencedBinaryPatchAndNoContent
{
    auto endpoint = [self endpointWithBodyCap: OWebWireMaximumFrameBytes];
    auto frame = [self mountWithIdentifier: 51 enabled: true];
    auto response = [endpoint handleRequest:
        [self requestWithFrame: frame sequence: @"1" identity: @"page-a"]];
    OTAssertEqual(response.statusCode, (unsigned short)200);
    OTAssertEqualObjects(response.headers[@"X-OWeb-Sequence"], @"1");
    OTAssertEqualObjects(response.headers[@"Content-Type"],
        @"application/vnd.oweb.frame");
    auto patch = (OWebPatchFrame *)[OWebWireCodec decodeFrameData:
        response.body];
    OTAssertEqual(patch.instanceIdentifier, UINT64_C(51));

    auto replayedPatch = [endpoint handleRequest:
        [self requestWithFrame: frame sequence: @"1" identity: @"page-a"]];
    OTAssertEqual(replayedPatch.statusCode, (unsigned short)200);
    OTAssertEqualObjects(replayedPatch.body, response.body);

    auto duplicate = [endpoint handleRequest:
        [self requestWithFrame: frame sequence: @"2" identity: @"page-a"]];
    OTAssertEqual(duplicate.statusCode, (unsigned short)204);
    OTAssertEqual(duplicate.body.count, (size_t)0);
    OTAssertEqualObjects(duplicate.headers[@"X-OWeb-Sequence"], @"2");
    OTAssertNil(duplicate.headers[@"Content-Type"]);

    auto replayedNoContent = [endpoint handleRequest:
        [self requestWithFrame: frame sequence: @"2" identity: @"page-a"]];
    OTAssertEqual(replayedNoContent.statusCode, (unsigned short)204);
    OTAssertEqual(replayedNoContent.body.count, (size_t)0);
    OTAssertEqualObjects(replayedNoContent.headers[@"X-OWeb-Sequence"], @"2");
}

- (void)testOwnershipAndSequencesAreScopedToInjectedSessionIdentity
{
    auto endpoint = [self endpointWithBodyCap: OWebWireMaximumFrameBytes];
    auto first = [self mountWithIdentifier: 52 enabled: false];
    OTAssertEqual([endpoint handleRequest:
        [self requestWithFrame: first sequence: @"1"
                              identity: @"page-a"]].statusCode,
        (unsigned short)200);
    OTAssertEqual([endpoint handleRequest:
        [self requestWithFrame: first sequence: @"1"
                              identity: @"page-b"]].statusCode,
        (unsigned short)200);

    /* A second component has its own monotonic stream in the same page. */
    auto second = [self mountWithIdentifier: 53 enabled: false];
    OTAssertEqual([endpoint handleRequest:
        [self requestWithFrame: second sequence: @"1"
                               identity: @"page-a"]].statusCode,
        (unsigned short)200);
    OTAssertEqual([endpoint existingSessionForIdentity: @"page-a"]
        .mountedInstanceCount, (size_t)2);

    [endpoint removeSessionForIdentity: @"page-a"];
    OTAssertNil([endpoint existingSessionForIdentity: @"page-a"]);
}

- (void)testGenericComponentFailureIsSanitizedQuarantinedAndReplayed
{
    auto endpoint = [self endpointWithBodyCap: OWebWireMaximumFrameBytes];
    auto definition = [OWebComponentRegistry.sharedRegistry
        definitionForComponentClass: [OWebSessionThrowingComponent class]];
    auto mount = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 66 componentTag: definition.elementName
        attributes: @{}];
    OTAssertEqual([endpoint handleRequest: [self requestWithFrame: mount
        sequence: @"1" identity: @"throwing-page"]].statusCode,
        (unsigned short)204);
    uint64_t action = [self actionIdentifierForDefinition: definition
        selector: @"explode:"];
    uint64_t target = [self targetIdentifierForDefinition: definition
        logicalID: @"button"];
    auto event = [[OWebEventFrame alloc]
        initWithInstanceIdentifier: 66 actionIdentifier: action
        targetIdentifier: target fields: @{}];
    auto first = [endpoint handleRequest: [self requestWithFrame: event
        sequence: @"2" identity: @"throwing-page"]];
    OTAssertEqual(first.statusCode, (unsigned short)500);
    OTAssertEqualObjects([OFString stringWithData: first.body
        encoding: OFStringEncodingUTF8], @"internal-error");
    OTAssertFalse([[endpoint existingSessionForIdentity: @"throwing-page"]
        ownsInstanceIdentifier: 66]);

    auto replay = [endpoint handleRequest: [self requestWithFrame: event
        sequence: @"2" identity: @"throwing-page"]];
    OTAssertEqual(replay.statusCode, (unsigned short)500);
    OTAssertEqualObjects([OFString stringWithData: replay.body
        encoding: OFStringEncodingUTF8], @"internal-error");
    OTAssertEqual(OWebSessionThrowingActionCount, (size_t)1);
}

- (void)testEndpointContainsGenericProviderFailureAndBoundsSessions
{
    auto throwingEndpoint = [[OWebComponentEndpoint alloc]
        initWithRegistry: OWebComponentRegistry.sharedRegistry
        expectedOrigin: @"http://127.0.0.1:8080"
        maximumBodyBytes: OWebWireMaximumFrameBytes
        sessionIdentityProvider: ^OFString *(OWebHTTPRequest *request) {
            (void)request;
            @throw @"private-provider-detail";
        }];
    auto request = [self requestWithFrame:
        [self mountWithIdentifier: 67 enabled: false]
        sequence: @"1" identity: @"ignored"];
    auto failure = [throwingEndpoint handleRequest: request];
    OTAssertEqual(failure.statusCode, (unsigned short)500);
    OTAssertEqualObjects([OFString stringWithData: failure.body
        encoding: OFStringEncodingUTF8], @"internal-error");

    auto bounded = [self endpointWithMaximumSessions: 1];
    OTAssertEqual([bounded handleRequest: [self requestWithFrame:
        [self mountWithIdentifier: 68 enabled: false]
        sequence: @"1" identity: @"page-a"]].statusCode,
        (unsigned short)200);
    auto atCapacity = [bounded handleRequest: [self requestWithFrame:
        [self mountWithIdentifier: 69 enabled: false]
        sequence: @"1" identity: @"page-b"]];
    OTAssertEqual(atCapacity.statusCode, (unsigned short)503);
    OTAssertEqualObjects([OFString stringWithData: atCapacity.body
        encoding: OFStringEncodingUTF8], @"capacity-exceeded");
    OTAssertEqual(bounded.activeSessionCount, (size_t)1);
    [bounded removeSessionForIdentity: @"page-a"];
    OTAssertEqual([bounded handleRequest: [self requestWithFrame:
        [self mountWithIdentifier: 69 enabled: false]
        sequence: @"1" identity: @"page-b"]].statusCode,
        (unsigned short)200);
}

- (void)testHTTPBoundaryStrictlyRejectsOriginMediaSizeSequenceAndIdentity
{
    auto endpoint = [self endpointWithBodyCap: 64];
    auto good = [self requestWithFrame:
        [self mountWithIdentifier: 54 enabled: false]
                              sequence: @"1" identity: @"page"];

    auto wrongOrigin = [[OWebHTTPRequest alloc]
        initWithMethod: good.method path: good.path
        headers: @{
            @"Origin": @"http://evil.invalid",
            @"Content-Type": @"application/vnd.oweb.frame",
            @"Accept": @"application/vnd.oweb.frame",
            @"X-OWeb-Sequence": @"1",
            @"X-Test-Session": @"page"
        } body: good.body];
    OTAssertEqual([endpoint handleRequest: wrongOrigin].statusCode,
        (unsigned short)403);

    auto wrongType = [[OWebHTTPRequest alloc]
        initWithMethod: good.method path: good.path
        headers: @{
            @"Origin": @"http://127.0.0.1:8080",
            @"Content-Type": @"application/octet-stream",
            @"Accept": @"application/vnd.oweb.frame",
            @"X-OWeb-Sequence": @"1",
            @"X-Test-Session": @"page"
        } body: good.body];
    OTAssertEqual([endpoint handleRequest: wrongType].statusCode,
        (unsigned short)415);

    auto wrongAccept = [[OWebHTTPRequest alloc]
        initWithMethod: good.method path: good.path
        headers: @{
            @"Origin": @"http://127.0.0.1:8080",
            @"Content-Type": @"application/vnd.oweb.frame",
            @"Accept": @"application/json",
            @"X-OWeb-Sequence": @"1",
            @"X-Test-Session": @"page"
        } body: good.body];
    OTAssertEqual([endpoint handleRequest: wrongAccept].statusCode,
        (unsigned short)406);

    auto oversized = [[OWebHTTPRequest alloc]
        initWithMethod: good.method path: good.path headers: good.headers
        body: [OFData dataWithItems: (uint8_t[65]){ 0 } count: 65]];
    OTAssertEqual([endpoint handleRequest: oversized].statusCode,
        (unsigned short)413);

    auto invalidSequence = [self requestWithFrame:
        [self mountWithIdentifier: 54 enabled: false]
                                        sequence: @"01" identity: @"page"];
    OTAssertEqual([endpoint handleRequest: invalidSequence].statusCode,
        (unsigned short)400);

    auto noIdentity = [[OWebHTTPRequest alloc]
        initWithMethod: good.method path: good.path
        headers: @{
            @"Origin": @"http://127.0.0.1:8080",
            @"Content-Type": @"application/vnd.oweb.frame",
            @"Accept": @"application/vnd.oweb.frame",
            @"X-OWeb-Sequence": @"1"
        } body: good.body];
    OTAssertEqual([endpoint handleRequest: noIdentity].statusCode,
        (unsigned short)401);
}

- (void)testRouterInstallationUsesTheSameHardenedBoundary
{
    auto endpoint = [self endpointWithBodyCap: OWebWireMaximumFrameBytes];
    auto router = [[OWebRouter alloc]
        initWithMaximumBodyBytes: OWebWireMaximumFrameBytes];
    [endpoint installOnRouter: router path: @"/_oweb/frame"];
    auto response = [router dispatchRequest: [self requestWithFrame:
        [self mountWithIdentifier: 55 enabled: true]
        sequence: @"1" identity: @"page"]];
    OTAssertEqual(response.statusCode, (unsigned short)200);
    OTAssertEqualObjects(response.headers[@"X-OWeb-Sequence"], @"1");
}

@end

#pragma clang assume_nonnull end
