#import <Common.h>

#include <stdint.h>

#pragma clang assume_nonnull begin

/** Wire version emitted and accepted by this implementation. */
static const uint8_t OWebWireProtocolVersion = 1;

/** Hard protocol limits. They are checked by both encoder and decoder. */
static const size_t OWebWireMaximumFrameBytes = 1024 * 1024;
static const size_t OWebWireMaximumStringBytes = 64 * 1024;
static const size_t OWebWireMaximumOperations = 4096;
static const size_t OWebWireMaximumBatchDepth = 8;
static const size_t OWebWireMaximumEventFields = 32;
static const size_t OWebWireMaximumMountAttributes = 64;

/**
 * Exact on-wire frame tags. Values are stable protocol ABI.
 *
 * Patch is server-to-browser. Event, Mount and Detach are browser-to-server.
 * Mount claims a browser-generated instance ID for one server session. Detach
 * releases it after final teardown. Reconnection and duplicate ownership are
 * session policy and are intentionally not inferred by the codec.
 */
typedef enum OWebWireFrameType: uint8_t {
    OWebWireFrameTypePatch = 1,
    OWebWireFrameTypeEvent = 2,
    OWebWireFrameTypeMount = 3,
    OWebWireFrameTypeDetach = 4
} OWebWireFrameType;

/** Exact patch bytecodes. There is deliberately no raw-HTML operation. */
typedef enum OWebPatchOpcode: uint8_t {
    OWebPatchOpcodeSetText = 1,
    OWebPatchOpcodeSetAttribute = 2,
    OWebPatchOpcodeRemoveAttribute = 3,
    OWebPatchOpcodeSetProperty = 4,
    OWebPatchOpcodeFocus = 5,
    OWebPatchOpcodeBatch = 6,
    /** Clone only a template declared by the compiled component layout. */
    OWebPatchOpcodeCloneTemplate = 7,
    OWebPatchOpcodeRemoveNode = 8,
    OWebPatchOpcodeMoveNode = 9
} OWebPatchOpcode;

/** Scalar value tags supported by property and event fields. */
typedef enum OWebWireValueType: uint8_t {
    OWebWireValueTypeNull = 0,
    OWebWireValueTypeFalse = 1,
    OWebWireValueTypeTrue = 2,
    OWebWireValueTypeSignedInteger = 3,
    OWebWireValueTypeUnsignedInteger = 4,
    OWebWireValueTypeDouble = 5,
    OWebWireValueTypeString = 6
} OWebWireValueType;

typedef enum OWebWireProtocolFailure: uint8_t {
    OWebWireProtocolFailureInvalidFrame,
    OWebWireProtocolFailureInvalidMagic,
    OWebWireProtocolFailureUnsupportedVersion,
    OWebWireProtocolFailureUnknownFrameType,
    OWebWireProtocolFailureFrameTooLarge,
    OWebWireProtocolFailureTruncated,
    OWebWireProtocolFailureTrailingData,
    OWebWireProtocolFailureVarintOverflow,
    OWebWireProtocolFailureNonCanonicalVarint,
    OWebWireProtocolFailureStringTooLong,
    OWebWireProtocolFailureInvalidUTF8,
    OWebWireProtocolFailureOperationLimitExceeded,
    OWebWireProtocolFailureNestingLimitExceeded,
    OWebWireProtocolFailureUnknownOpcode,
    OWebWireProtocolFailureUnknownValueType,
    OWebWireProtocolFailureInvalidValue,
    OWebWireProtocolFailureDisallowedEventField,
    OWebWireProtocolFailureNonCanonicalMap,
    OWebWireProtocolFailureInvalidComponentTag,
    OWebWireProtocolFailureInvalidAttributeName
} OWebWireProtocolFailure;

[[subclassing_restricted, direct_members]]
@interface OWebWireProtocolException : OFException

@property(nonatomic, readonly) OWebWireProtocolFailure failure;

@end

@protocol OWebWireFrame <OFObject>

@property(nonatomic, readonly) OWebWireFrameType frameType;

@end

/** An immutable, explicitly typed protocol scalar. */
[[subclassing_restricted, direct_members]]
@interface OWebWireValue : OFObject

@property(nonatomic, readonly) OWebWireValueType type;
@property(nonatomic, readonly) bool boolValue;
@property(nonatomic, readonly) int64_t signedIntegerValue;
@property(nonatomic, readonly) uint64_t unsignedIntegerValue;
@property(nonatomic, readonly) double doubleValue;
@property(nonatomic, readonly, nullable) OFString *stringValue;

+ (instancetype)nullValue;
+ (instancetype)valueWithBool: (bool)value;
+ (instancetype)valueWithSignedInteger: (int64_t)value;
+ (instancetype)valueWithUnsignedInteger: (uint64_t)value;
+ (instancetype)valueWithDouble: (double)value;
+ (instancetype)valueWithString: (OFString *)value;

- (instancetype)init OF_UNAVAILABLE;

@end

/** One immutable patch instruction. */
[[subclassing_restricted, direct_members]]
@interface OWebPatchOperation : OFObject

@property(nonatomic, readonly) OWebPatchOpcode opcode;
@property(nonatomic, readonly) uint64_t elementIdentifier;
@property(nonatomic, readonly) uint64_t templateIdentifier;
@property(nonatomic, readonly) uint64_t parentIdentifier;
@property(nonatomic, readonly) uint64_t nodeIdentifier;
/** Zero means append for MoveNode. */
@property(nonatomic, readonly) uint64_t beforeIdentifier;
@property(nonatomic, readonly, nullable) OFString *name;
@property(nonatomic, readonly, nullable) OWebWireValue *value;
@property(nonatomic, readonly) OFArray<OWebPatchOperation *> *operations;

+ (instancetype)setText: (OFString *)text
              forElement: (uint64_t)elementIdentifier;
+ (instancetype)setAttribute: (OFString *)name
                       value: (OFString *)value
                  forElement: (uint64_t)elementIdentifier;
+ (instancetype)removeAttribute: (OFString *)name
                      forElement: (uint64_t)elementIdentifier;
+ (instancetype)setProperty: (OFString *)name
                       value: (OWebWireValue *)value
                  forElement: (uint64_t)elementIdentifier;
+ (instancetype)focusElement: (uint64_t)elementIdentifier;
+ (instancetype)batch: (OFArray<OWebPatchOperation *> *)operations;
+ (instancetype)cloneTemplate: (uint64_t)templateIdentifier
                    intoParent: (uint64_t)parentIdentifier
                         asNode: (uint64_t)nodeIdentifier;
+ (instancetype)removeNode: (uint64_t)nodeIdentifier;
+ (instancetype)moveNode: (uint64_t)nodeIdentifier
                 intoParent: (uint64_t)parentIdentifier
                 beforeNode: (uint64_t)beforeIdentifier;

- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface OWebPatchFrame : OFObject <OWebWireFrame>

@property(nonatomic, readonly) OWebWireFrameType frameType;
@property(nonatomic, readonly) uint64_t instanceIdentifier;
@property(nonatomic, readonly) OFArray<OWebPatchOperation *> *operations;

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                                 operations:
    (OFArray<OWebPatchOperation *> *)operations OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

/**
 * Browser event. actionIdentifier is an opaque per-render capability; an
 * Objective-C selector is never transmitted to or accepted from the browser.
 */
[[subclassing_restricted]]
@interface OWebEventFrame : OFObject <OWebWireFrame>

@property(nonatomic, readonly) OWebWireFrameType frameType;
@property(nonatomic, readonly) uint64_t instanceIdentifier;
@property(nonatomic, readonly) uint64_t actionIdentifier;
@property(nonatomic, readonly) uint64_t targetIdentifier;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OWebWireValue *> *fields;

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                           actionIdentifier: (uint64_t)actionIdentifier
                           targetIdentifier: (uint64_t)targetIdentifier
                                      fields:
    (OFDictionary<OFString *, OWebWireValue *> *)fields
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

/** Initial custom-element attachment and reflected attributes. */
[[subclassing_restricted]]
@interface OWebMountFrame : OFObject <OWebWireFrame>

@property(nonatomic, readonly) OWebWireFrameType frameType;
@property(nonatomic, readonly) uint64_t instanceIdentifier;
@property(nonatomic, readonly) OFString *componentTag;
@property(nonatomic, readonly) OFDictionary<OFString *, OFString *> *attributes;

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                               componentTag: (OFString *)componentTag
                                 attributes:
    (OFDictionary<OFString *, OFString *> *)attributes
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

/** Final custom-element teardown. */
[[subclassing_restricted]]
@interface OWebDetachFrame : OFObject <OWebWireFrame>

@property(nonatomic, readonly) OWebWireFrameType frameType;
@property(nonatomic, readonly) uint64_t instanceIdentifier;

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

/** Canonical, bounded encoder and strict decoder for OWeb wire frames. */
[[subclassing_restricted, direct_members]]
@interface OWebWireCodec : OFObject

+ (OFData *)encodeFrame: (id<OWebWireFrame>)frame;
+ (id<OWebWireFrame>)decodeFrameData: (OFData *)data;
+ (bool)isEventFieldNameAllowed: (OFString *)name;
+ (bool)isComponentTagValid: (OFString *)tag;
+ (bool)isAttributeNameValid: (OFString *)name;
+ (bool)isPatchAttributeNameAllowed: (OFString *)name;
+ (bool)isPatchPropertyNameAllowed: (OFString *)name;

- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
