#import <OWebWireProtocol.h>

#include <stdlib.h>
#include <time.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface OWebWireProtocolBenchmark : OFObject <OFApplicationDelegate> {
    uint64_t _sink;
}
+ (uint64_t)monotonicNanoseconds;
- (OWebPatchFrame *)representativePatch;
- (OFDictionary *)representativeJSON;
- (uint64_t)measureBinaryEncode: (OWebPatchFrame *)frame
                         iterations: (size_t)iterations;
- (uint64_t)measureBinaryDecode: (OFData *)data
                         iterations: (size_t)iterations;
- (uint64_t)measureJSONEncode: (OFDictionary *)object
                       iterations: (size_t)iterations;
- (uint64_t)measureJSONDecode: (OFString *)JSON
                       iterations: (size_t)iterations;
@end

@implementation OWebWireProtocolBenchmark

+ (uint64_t)monotonicNanoseconds
{
    struct timespec time;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &time) != 0)
        @throw [OFInitializationFailedException exception];
    return (uint64_t)time.tv_sec * UINT64_C(1000000000) +
        (uint64_t)time.tv_nsec;
}

- (OWebPatchFrame *)representativePatch
{
    auto operations = [OFMutableArray<OWebPatchOperation *> array];
    for (uint64_t index = 1; index <= 8; index++) {
        [operations addObject: [OWebPatchOperation setText:
            [OFString stringWithFormat: @"row-%llu",
                (unsigned long long)index]
            forElement: index]];
        [operations addObject: [OWebPatchOperation setAttribute: @"class"
            value: (index % 2 == 0 ? @"row even" : @"row odd")
            forElement: index]];
        [operations addObject: [OWebPatchOperation setProperty: @"value"
            value: [OWebWireValue valueWithUnsignedInteger: index * 10]
            forElement: index]];
    }
    [operations addObject: [OWebPatchOperation batch: @[
        [OWebPatchOperation cloneTemplate: 90 intoParent: 2 asNode: 501],
        [OWebPatchOperation moveNode: 501 intoParent: 2 beforeNode: 7],
        [OWebPatchOperation focusElement: 7]
    ]]];
    return [[OWebPatchFrame alloc] initWithInstanceIdentifier: 4001
        operations: operations];
}

- (OFDictionary *)representativeJSON
{
    auto operations = [OFMutableArray<OFDictionary *> array];
    for (uint64_t index = 1; index <= 8; index++) {
        [operations addObject: @{
            @"op": @"setText", @"element": @(index),
            @"value": [OFString stringWithFormat: @"row-%llu",
                (unsigned long long)index]
        }];
        [operations addObject: @{
            @"op": @"setAttribute", @"element": @(index), @"name": @"class",
            @"value": (index % 2 == 0 ? @"row even" : @"row odd")
        }];
        [operations addObject: @{
            @"op": @"setProperty", @"element": @(index), @"name": @"value",
            @"type": @"uint", @"value": @(index * 10)
        }];
    }
    [operations addObject: @{
        @"op": @"batch", @"operations": @[
            @{ @"op": @"cloneTemplate", @"template": @90, @"parent": @2,
               @"node": @501 },
            @{ @"op": @"moveNode", @"node": @501, @"parent": @2,
               @"before": @7 },
            @{ @"op": @"focus", @"element": @7 }
        ]
    }];
    return @{
        @"version": @1,
        @"type": @"patch",
        @"instance": @4001,
        @"operations": operations
    };
}

- (uint64_t)measureBinaryEncode: (OWebPatchFrame *)frame
                         iterations: (size_t)iterations
{
    auto start = [OWebWireProtocolBenchmark monotonicNanoseconds];
    for (size_t batch = 0; batch < iterations; batch += 256) {
        @autoreleasepool {
            auto end = batch + 256 < iterations ? batch + 256 : iterations;
            for (size_t index = batch; index < end; index++)
                _sink ^= [OWebWireCodec encodeFrame: frame].count + index;
        }
    }
    return [OWebWireProtocolBenchmark monotonicNanoseconds] - start;
}

- (uint64_t)measureBinaryDecode: (OFData *)data
                         iterations: (size_t)iterations
{
    auto start = [OWebWireProtocolBenchmark monotonicNanoseconds];
    for (size_t batch = 0; batch < iterations; batch += 256) {
        @autoreleasepool {
            auto end = batch + 256 < iterations ? batch + 256 : iterations;
            for (size_t index = batch; index < end; index++) {
                auto frame = (OWebPatchFrame *)
                    [OWebWireCodec decodeFrameData: data];
                _sink ^= frame.operations.count + index;
            }
        }
    }
    return [OWebWireProtocolBenchmark monotonicNanoseconds] - start;
}

- (uint64_t)measureJSONEncode: (OFDictionary *)object
                       iterations: (size_t)iterations
{
    auto start = [OWebWireProtocolBenchmark monotonicNanoseconds];
    for (size_t batch = 0; batch < iterations; batch += 256) {
        @autoreleasepool {
            auto end = batch + 256 < iterations ? batch + 256 : iterations;
            for (size_t index = batch; index < end; index++) {
                auto JSON = [object JSONRepresentationWithOptions:
                    OFJSONRepresentationOptionSorted];
                _sink ^= JSON.UTF8StringLength + index;
            }
        }
    }
    return [OWebWireProtocolBenchmark monotonicNanoseconds] - start;
}

- (uint64_t)measureJSONDecode: (OFString *)JSON
                       iterations: (size_t)iterations
{
    auto start = [OWebWireProtocolBenchmark monotonicNanoseconds];
    for (size_t batch = 0; batch < iterations; batch += 256) {
        @autoreleasepool {
            auto end = batch + 256 < iterations ? batch + 256 : iterations;
            for (size_t index = batch; index < end; index++) {
                auto object = [JSON objectByParsingJSONWithDepthLimit: 32];
                _sink ^= [object count] + index;
            }
        }
    }
    return [OWebWireProtocolBenchmark monotonicNanoseconds] - start;
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
    (void)notification;
    const size_t iterations = 20000;
    auto patch = [self representativePatch];
    auto JSONObject = [self representativeJSON];
    auto binary = [OWebWireCodec encodeFrame: patch];
    auto JSON = [JSONObject JSONRepresentationWithOptions:
        OFJSONRepresentationOptionSorted];

    (void)[self measureBinaryEncode: patch iterations: 512];
    (void)[self measureBinaryDecode: binary iterations: 512];
    (void)[self measureJSONEncode: JSONObject iterations: 512];
    (void)[self measureJSONDecode: JSON iterations: 512];

    auto binaryEncode = [self measureBinaryEncode: patch
        iterations: iterations];
    auto binaryDecode = [self measureBinaryDecode: binary
        iterations: iterations];
    auto JSONEncode = [self measureJSONEncode: JSONObject
        iterations: iterations];
    auto JSONDecode = [self measureJSONDecode: JSON
        iterations: iterations];

    auto result = @{
        @"iterations": @(iterations),
        @"payload": @{
            @"binary_bytes": @(binary.count),
            @"json_bytes": @(JSON.UTF8StringLength),
            @"binary_fraction": @((double)binary.count /
                (double)JSON.UTF8StringLength)
        },
        @"nanoseconds_per_operation": @{
            @"binary_encode": @((double)binaryEncode / iterations),
            @"binary_decode": @((double)binaryDecode / iterations),
            @"json_encode": @((double)JSONEncode / iterations),
            @"json_decode": @((double)JSONDecode / iterations)
        },
        @"sink": @(_sink)
    };
    [OFStdOut writeLine: [result JSONRepresentationWithOptions:
        OFJSONRepresentationOptionSorted]];
    [OFApplication terminateWithStatus: EXIT_SUCCESS];
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(OWebWireProtocolBenchmark)
