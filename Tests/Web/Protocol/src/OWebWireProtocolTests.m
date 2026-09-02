#import <ObjFWTest/ObjFWTest.h>
#import <OWebWireProtocol.h>

#include <math.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface OWebWireProtocolTests : OTTestCase {
    uint64_t _randomState;
}
- (OFData *)frameWithType: (OWebWireFrameType)type body: (OFData *)body;
- (void)appendVarUInt: (uint64_t)value toData: (OFMutableData *)data;
- (void)assertData: (OFData *)data
       failsWith: (OWebWireProtocolFailure)failure;
- (uint8_t)nextRandomByte;
@end

@implementation OWebWireProtocolTests

- (uint8_t)nextRandomByte
{
    _randomState = _randomState * UINT64_C(6364136223846793005) +
        UINT64_C(1442695040888963407);
    return (uint8_t)(_randomState >> 56);
}

- (void)appendVarUInt: (uint64_t)value toData: (OFMutableData *)data
{
    do {
        uint8_t byte = (uint8_t)(value & 0x7F);
        value >>= 7;
        if (value != 0)
            byte |= 0x80;
        [data addItem: &byte];
    } while (value != 0);
}

- (OFData *)frameWithType: (OWebWireFrameType)type body: (OFData *)body
{
    auto data = [OFMutableData data];
    const uint8_t header[] = {
        'O', 'W', 'E', 'B', OWebWireProtocolVersion, (uint8_t)type
    };
    [data addItems: header count: sizeof(header)];
    [self appendVarUInt: body.count toData: data];
    if (body.count > 0)
        [data addItems: $assert_nonnil(body.items) count: body.count];
    return [data copy];
}

- (void)assertData: (OFData *)data
       failsWith: (OWebWireProtocolFailure)failure
{
    bool didThrow = false;
    @try {
        (void)[OWebWireCodec decodeFrameData: data];
    } @catch (OWebWireProtocolException *exception) {
        didThrow = true;
        OTAssertEqual(exception.failure, failure);
    }
    OTAssertTrue(didThrow);
}

- (void)testCanonicalSetTextFixture
{
    auto frame = [[OWebPatchFrame alloc] initWithInstanceIdentifier: 1
        operations: @[[OWebPatchOperation setText: @"Hi" forElement: 2]]];
    const uint8_t expectedBytes[] = {
        'O', 'W', 'E', 'B', 1, 1, 7, 1, 1, 1, 2, 2, 'H', 'i'
    };
    auto expected = [OFData dataWithItems: expectedBytes
                                    count: sizeof(expectedBytes)];
    auto encoded = [OWebWireCodec encodeFrame: frame];
    OTAssertEqualObjects(encoded, expected);

    auto decoded = (OWebPatchFrame *)[OWebWireCodec decodeFrameData: encoded];
    OTAssertEqual(decoded.frameType, OWebWireFrameTypePatch);
    OTAssertEqual(decoded.instanceIdentifier, UINT64_C(1));
    OTAssertEqual(decoded.operations.count, (size_t)1);
    auto operation = decoded.operations[0];
    OTAssertEqual(operation.opcode, OWebPatchOpcodeSetText);
    OTAssertEqual(operation.elementIdentifier, UINT64_C(2));
    OTAssertEqualObjects(operation.value.stringValue, @"Hi");
}

- (void)testCanonicalEventMountDetachAndStructuralFixtures
{
    auto event = [[OWebEventFrame alloc] initWithInstanceIdentifier: 1
        actionIdentifier: 2 targetIdentifier: 3 fields: @{
            @"value": [OWebWireValue valueWithString: @"Rei"],
            @"altKey": [OWebWireValue valueWithBool: false]
        }];
    const uint8_t eventBytes[] = {
        'O', 'W', 'E', 'B', 1, 2, 23,
        1, 2, 3, 2,
        6, 'a', 'l', 't', 'K', 'e', 'y', 1,
        5, 'v', 'a', 'l', 'u', 'e', 6, 3, 'R', 'e', 'i'
    };
    OTAssertEqualObjects([OWebWireCodec encodeFrame: event],
        [OFData dataWithItems: eventBytes count: sizeof(eventBytes)]);

    auto mount = [[OWebMountFrame alloc] initWithInstanceIdentifier: 1
        componentTag: @"my-component"
        attributes: @{ @"name": @"Rei", @"data-mode": @"live" }];
    const uint8_t mountBytes[] = {
        'O', 'W', 'E', 'B', 1, 3, 39,
        1, 12, 'm', 'y', '-', 'c', 'o', 'm', 'p', 'o', 'n', 'e', 'n', 't',
        2,
        9, 'd', 'a', 't', 'a', '-', 'm', 'o', 'd', 'e',
        4, 'l', 'i', 'v', 'e',
        4, 'n', 'a', 'm', 'e', 3, 'R', 'e', 'i'
    };
    OTAssertEqualObjects([OWebWireCodec encodeFrame: mount],
        [OFData dataWithItems: mountBytes count: sizeof(mountBytes)]);

    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 1];
    const uint8_t detachBytes[] = { 'O', 'W', 'E', 'B', 1, 4, 1, 1 };
    OTAssertEqualObjects([OWebWireCodec encodeFrame: detach],
        [OFData dataWithItems: detachBytes count: sizeof(detachBytes)]);

    auto structural = [[OWebPatchFrame alloc] initWithInstanceIdentifier: 1
        operations: @[
            [OWebPatchOperation cloneTemplate: 2 intoParent: 3 asNode: 4]
        ]];
    const uint8_t structuralBytes[] = {
        'O', 'W', 'E', 'B', 1, 1, 6, 1, 1, 7, 2, 3, 4
    };
    OTAssertEqualObjects([OWebWireCodec encodeFrame: structural],
        [OFData dataWithItems: structuralBytes count: sizeof(structuralBytes)]);
}

- (void)testRoundTripsAllPatchOperationsAndValueTypes
{
    auto operations = @[
        [OWebPatchOperation setText: @"ready" forElement: 1],
        [OWebPatchOperation setAttribute: @"aria-label" value: @"Counter"
            forElement: 2],
        [OWebPatchOperation removeAttribute: @"hidden" forElement: 3],
        [OWebPatchOperation setProperty: @"checked"
            value: [OWebWireValue valueWithBool: true] forElement: 4],
        [OWebPatchOperation setProperty: @"value"
            value: [OWebWireValue valueWithSignedInteger: -42] forElement: 5],
        [OWebPatchOperation setProperty: @"scrollTop"
            value: [OWebWireValue valueWithUnsignedInteger: UINT64_MAX]
            forElement: 6],
        [OWebPatchOperation setProperty: @"scrollLeft"
            value: [OWebWireValue valueWithDouble: 1.25] forElement: 7],
        [OWebPatchOperation setProperty: @"value"
            value: [OWebWireValue valueWithString: @"text"] forElement: 8],
        [OWebPatchOperation setProperty: @"value"
            value: [OWebWireValue nullValue] forElement: 9],
        [OWebPatchOperation focusElement: 10],
        [OWebPatchOperation batch: @[
            [OWebPatchOperation setText: @"nested" forElement: 11]
        ]],
        [OWebPatchOperation cloneTemplate: 12 intoParent: 13 asNode: 14],
        [OWebPatchOperation removeNode: 14],
        [OWebPatchOperation moveNode: 15 intoParent: 16 beforeNode: 17],
        [OWebPatchOperation moveNode: 18 intoParent: 16 beforeNode: 0]
    ];
    auto input = [[OWebPatchFrame alloc] initWithInstanceIdentifier: 99
        operations: operations];
    auto output = (OWebPatchFrame *)[OWebWireCodec decodeFrameData:
        [OWebWireCodec encodeFrame: input]];

    OTAssertEqual(output.instanceIdentifier, UINT64_C(99));
    OTAssertEqual(output.operations.count, operations.count);
    OTAssertEqual(output.operations[3].value.type, OWebWireValueTypeTrue);
    OTAssertTrue(output.operations[3].value.boolValue);
    OTAssertEqual(output.operations[4].value.signedIntegerValue,
        INT64_C(-42));
    OTAssertEqual(output.operations[5].value.unsignedIntegerValue, UINT64_MAX);
    OTAssertEqual(output.operations[6].value.doubleValue, 1.25);
    OTAssertEqualObjects(output.operations[7].value.stringValue, @"text");
    OTAssertEqual(output.operations[8].value.type, OWebWireValueTypeNull);
    OTAssertEqual(output.operations[10].operations.count, (size_t)1);
    OTAssertEqual(output.operations[11].templateIdentifier, UINT64_C(12));
    OTAssertEqual(output.operations[11].parentIdentifier, UINT64_C(13));
    OTAssertEqual(output.operations[11].nodeIdentifier, UINT64_C(14));
    OTAssertEqual(output.operations[13].beforeIdentifier, UINT64_C(17));
    OTAssertEqual(output.operations[14].beforeIdentifier, UINT64_C(0));
}

- (void)testEventUsesOpaqueActionAndCanonicalFieldOrder
{
    auto event = [[OWebEventFrame alloc] initWithInstanceIdentifier: 1
        actionIdentifier: 700 targetIdentifier: 9 fields: @{
            @"value": [OWebWireValue valueWithString: @"Rei"],
            @"altKey": [OWebWireValue valueWithBool: false],
            @"clientX": [OWebWireValue valueWithSignedInteger: -12]
        }];
    auto first = [OWebWireCodec encodeFrame: event];
    auto second = [OWebWireCodec encodeFrame: event];
    OTAssertEqualObjects(first, second);

    auto decoded = (OWebEventFrame *)[OWebWireCodec decodeFrameData: first];
    OTAssertEqual(decoded.actionIdentifier, UINT64_C(700));
    OTAssertEqual(decoded.targetIdentifier, UINT64_C(9));
    OTAssertEqual(decoded.fields.count, (size_t)3);
    OTAssertEqualObjects(decoded.fields[@"value"].stringValue, @"Rei");
    OTAssertFalse(decoded.fields[@"altKey"].boolValue);
    OTAssertEqual(decoded.fields[@"clientX"].signedIntegerValue,
        INT64_C(-12));
}

- (void)testMountAndDetachRoundTrip
{
    auto mount = [[OWebMountFrame alloc] initWithInstanceIdentifier: 44
        componentTag: @"my-component"
        attributes: @{ @"name": @"Rei", @"data-mode": @"live" }];
    auto decodedMount = (OWebMountFrame *)[OWebWireCodec decodeFrameData:
        [OWebWireCodec encodeFrame: mount]];
    OTAssertEqual(decodedMount.instanceIdentifier, UINT64_C(44));
    OTAssertEqualObjects(decodedMount.componentTag, @"my-component");
    OTAssertEqualObjects(decodedMount.attributes[@"name"], @"Rei");

    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 44];
    auto decodedDetach = (OWebDetachFrame *)[OWebWireCodec decodeFrameData:
        [OWebWireCodec encodeFrame: detach]];
    OTAssertEqual(decodedDetach.frameType, OWebWireFrameTypeDetach);
    OTAssertEqual(decodedDetach.instanceIdentifier, UINT64_C(44));
}

- (void)testRejectsEveryTruncatedPrefixAndTrailingBytes
{
    auto frame = [[OWebMountFrame alloc] initWithInstanceIdentifier: 44
        componentTag: @"my-component" attributes: @{ @"name": @"Rei" }];
    auto encoded = [OWebWireCodec encodeFrame: frame];
    for (size_t length = 0; length < encoded.count; length++) {
        auto prefix = [OFData dataWithItems: $assert_nonnil(encoded.items)
                                      count: length];
        OTAssertThrowsSpecific((void)[OWebWireCodec decodeFrameData: prefix],
            OWebWireProtocolException);
    }

    auto trailing = [encoded mutableCopy];
    uint8_t extra = 0;
    [trailing addItem: &extra];
    [self assertData: trailing failsWith: OWebWireProtocolFailureTrailingData];
}

- (void)testRejectsInvalidHeaderAndCanonicalVarints
{
    const uint8_t badMagicBytes[] = { 'X', 'W', 'E', 'B', 1, 4, 1, 1 };
    [self assertData: [OFData dataWithItems: badMagicBytes
        count: sizeof(badMagicBytes)]
        failsWith: OWebWireProtocolFailureInvalidMagic];

    const uint8_t badVersionBytes[] = { 'O', 'W', 'E', 'B', 2, 4, 1, 1 };
    [self assertData: [OFData dataWithItems: badVersionBytes
        count: sizeof(badVersionBytes)]
        failsWith: OWebWireProtocolFailureUnsupportedVersion];

    const uint8_t badTypeBytes[] = { 'O', 'W', 'E', 'B', 1, 99, 1, 1 };
    [self assertData: [OFData dataWithItems: badTypeBytes
        count: sizeof(badTypeBytes)]
        failsWith: OWebWireProtocolFailureUnknownFrameType];

    const uint8_t nonCanonicalBytes[] = {
        'O', 'W', 'E', 'B', 1, 4, 0x81, 0x00, 1
    };
    [self assertData: [OFData dataWithItems: nonCanonicalBytes
        count: sizeof(nonCanonicalBytes)]
        failsWith: OWebWireProtocolFailureNonCanonicalVarint];

    const uint8_t overflowBytes[] = {
        'O', 'W', 'E', 'B', 1, 4,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0x02
    };
    [self assertData: [OFData dataWithItems: overflowBytes
        count: sizeof(overflowBytes)]
        failsWith: OWebWireProtocolFailureVarintOverflow];
}

- (void)testRejectsInvalidUTF8UnknownOpcodeAndUnknownValueType
{
    const uint8_t invalidUTF8Body[] = { 1, 1, 1, 1, 1, 0xFF };
    [self assertData: [self frameWithType: OWebWireFrameTypePatch
        body: [OFData dataWithItems: invalidUTF8Body
        count: sizeof(invalidUTF8Body)]]
        failsWith: OWebWireProtocolFailureInvalidUTF8];

    const uint8_t unknownOpcodeBody[] = { 1, 1, 0xFF };
    [self assertData: [self frameWithType: OWebWireFrameTypePatch
        body: [OFData dataWithItems: unknownOpcodeBody
        count: sizeof(unknownOpcodeBody)]]
        failsWith: OWebWireProtocolFailureUnknownOpcode];

    const uint8_t unknownValueBody[] = {
        1, 1, 4, 1, 5, 'v', 'a', 'l', 'u', 'e', 0xFF
    };
    [self assertData: [self frameWithType: OWebWireFrameTypePatch
        body: [OFData dataWithItems: unknownValueBody
        count: sizeof(unknownValueBody)]]
        failsWith: OWebWireProtocolFailureUnknownValueType];
}

- (void)testRejectsLimitsAndDeepBatches
{
    auto oversized = [OFMutableData data];
    [oversized increaseCountBy: OWebWireMaximumFrameBytes + 1];
    [self assertData: oversized
        failsWith: OWebWireProtocolFailureFrameTooLarge];

    auto stringBody = [OFMutableData data];
    const uint8_t prefix[] = { 1, 1, 1, 1 };
    [stringBody addItems: prefix count: sizeof(prefix)];
    [self appendVarUInt: OWebWireMaximumStringBytes + 1 toData: stringBody];
    [self assertData: [self frameWithType: OWebWireFrameTypePatch
        body: stringBody] failsWith: OWebWireProtocolFailureStringTooLong];

    auto countBody = [OFMutableData data];
    uint8_t instance = 1;
    [countBody addItem: &instance];
    [self appendVarUInt: OWebWireMaximumOperations + 1 toData: countBody];
    [self assertData: [self frameWithType: OWebWireFrameTypePatch
        body: countBody]
        failsWith: OWebWireProtocolFailureOperationLimitExceeded];

    OWebPatchOperation *operation = [OWebPatchOperation focusElement: 1];
    for (size_t index = 0; index <= OWebWireMaximumBatchDepth; index++)
        operation = [OWebPatchOperation batch: @[operation]];
    auto deep = [[OWebPatchFrame alloc] initWithInstanceIdentifier: 1
        operations: @[operation]];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: deep],
        OWebWireProtocolException);
}

- (void)testCountsOFDataItemsAsBytes
{
    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 17];
    auto encoded = [OWebWireCodec encodeFrame: detach];
    OTAssertEqual(encoded.count % 2, (size_t)0);
    auto grouped = [OFData dataWithItems: $assert_nonnil(encoded.items)
        count: encoded.count / 2 itemSize: 2];
    auto decoded = (OWebDetachFrame *)[OWebWireCodec
        decodeFrameData: grouped];
    OTAssertEqual(decoded.instanceIdentifier, (uint64_t)17);

    auto oversized = [OFMutableData dataWithItemSize: 2];
    [oversized increaseCountBy: OWebWireMaximumFrameBytes / 2 + 1];
    [self assertData: oversized
        failsWith: OWebWireProtocolFailureFrameTooLarge];
}

- (void)testRejectsNonCanonicalMapsAndDisallowedNames
{
    const uint8_t nonCanonicalMountBody[] = {
        1, 3, 'x', '-', 'y', 2,
        1, 'b', 1, '1', 1, 'a', 1, '2'
    };
    [self assertData: [self frameWithType: OWebWireFrameTypeMount
        body: [OFData dataWithItems: nonCanonicalMountBody
        count: sizeof(nonCanonicalMountBody)]]
        failsWith: OWebWireProtocolFailureNonCanonicalMap];

    const uint8_t disallowedEventBody[] = {
        1, 2, 3, 1, 5, 'w', 'h', 'i', 'c', 'h', 1
    };
    [self assertData: [self frameWithType: OWebWireFrameTypeEvent
        body: [OFData dataWithItems: disallowedEventBody
        count: sizeof(disallowedEventBody)]]
        failsWith: OWebWireProtocolFailureDisallowedEventField];

    auto reservedAttribute = [[OWebPatchFrame alloc]
        initWithInstanceIdentifier: 1 operations: @[
            [OWebPatchOperation setAttribute: @"data-oweb-id" value: @"2"
                forElement: 1]
        ]];
    OTAssertThrowsSpecific(
        (void)[OWebWireCodec encodeFrame: reservedAttribute],
        OWebWireProtocolException);

    auto unsafeProperty = [[OWebPatchFrame alloc]
        initWithInstanceIdentifier: 1 operations: @[
            [OWebPatchOperation setProperty: @"innerHTML"
                value: [OWebWireValue valueWithString: @"<script></script>"]
                forElement: 1]
        ]];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: unsafeProperty],
        OWebWireProtocolException);
}

- (void)testRejectsNonCanonicalAndNonFiniteDoubles
{
    auto body = [OFMutableData data];
    const uint8_t prefix[] = {
        1, 1, 4, 1, 5, 'v', 'a', 'l', 'u', 'e', 5
    };
    [body addItems: prefix count: sizeof(prefix)];
    const uint8_t negativeZero[] = { 0x80, 0, 0, 0, 0, 0, 0, 0 };
    [body addItems: negativeZero count: sizeof(negativeZero)];
    [self assertData: [self frameWithType: OWebWireFrameTypePatch body: body]
        failsWith: OWebWireProtocolFailureInvalidValue];

    OTAssertThrowsSpecific((void)[OWebWireValue valueWithDouble: INFINITY],
        OFInvalidArgumentException);
    OTAssertThrowsSpecific((void)[OWebWireValue valueWithDouble: NAN],
        OFInvalidArgumentException);
}

- (void)testRejectsZeroCapabilitiesAndInvalidMountMetadata
{
    auto detach = [[OWebDetachFrame alloc] initWithInstanceIdentifier: 0];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: detach],
        OWebWireProtocolException);

    auto invalidTag = [[OWebMountFrame alloc] initWithInstanceIdentifier: 1
        componentTag: @"Component" attributes: @{}];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: invalidTag],
        OWebWireProtocolException);

    auto invalidAttribute = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 1 componentTag: @"my-component"
        attributes: @{ @"UPPER": @"bad" }];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: invalidAttribute],
        OWebWireProtocolException);

    auto eventAttribute = [[OWebMountFrame alloc]
        initWithInstanceIdentifier: 1 componentTag: @"my-component"
        attributes: @{ @"onclick": @"attacker()" }];
    OTAssertThrowsSpecific((void)[OWebWireCodec encodeFrame: eventAttribute],
        OWebWireProtocolException);
}

- (void)testDeterministicMutationCorpusCannotEscapeCodecFailures
{
    _randomState = UINT64_C(0x4f57454220260901);
    auto seedFrame = [[OWebPatchFrame alloc] initWithInstanceIdentifier: 19
        operations: @[
            [OWebPatchOperation setText: @"hello" forElement: 1],
            [OWebPatchOperation setAttribute: @"class" value: @"active"
                forElement: 2],
            [OWebPatchOperation setProperty: @"value"
                value: [OWebWireValue valueWithSignedInteger: -900]
                forElement: 3],
            [OWebPatchOperation cloneTemplate: 4 intoParent: 5 asNode: 6]
        ]];
    auto seed = [OWebWireCodec encodeFrame: seedFrame];
    for (size_t iteration = 0; iteration < 4096; iteration++) {
        @autoreleasepool {
            OFMutableData *mutated = [seed mutableCopy];
            auto bytes = (uint8_t *)$assert_nonnil(mutated.mutableItems);
            auto mutationCount = (size_t)([self nextRandomByte] % 3) + 1;
            for (size_t mutation = 0; mutation < mutationCount; mutation++) {
                auto index = (size_t)[self nextRandomByte] % mutated.count;
                bytes[index] ^= (uint8_t)([self nextRandomByte] | 1);
            }
            @try {
                auto decoded = [OWebWireCodec decodeFrameData: mutated];
                OTAssertEqualObjects([OWebWireCodec encodeFrame: decoded], mutated);
            } @catch (OWebWireProtocolException *exception) {
                (void)exception;
            }
        }
    }

    for (size_t iteration = 0; iteration < 2048; iteration++) {
        @autoreleasepool {
            auto body = [OFMutableData data];
            auto length = (size_t)([self nextRandomByte] % 128);
            for (size_t index = 0; index < length; index++) {
                auto byte = [self nextRandomByte];
                [body addItem: &byte];
            }
            auto type = (OWebWireFrameType)([self nextRandomByte] % 4 + 1);
            auto data = [self frameWithType: type body: body];
            @try {
                auto decoded = [OWebWireCodec decodeFrameData: data];
                OTAssertEqualObjects([OWebWireCodec encodeFrame: decoded], data);
            } @catch (OWebWireProtocolException *exception) {
                (void)exception;
            }
        }
    }
}

@end


#pragma clang assume_nonnull end
