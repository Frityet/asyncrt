#import <OWebWireProtocol.h>

#include <math.h>
#include <string.h>

#pragma clang assume_nonnull begin

@interface OWebWireProtocolException ()
+ (instancetype)exceptionWithFailure: (OWebWireProtocolFailure)failure;
- (instancetype)initWithFailure: (OWebWireProtocolFailure)failure;
@end

@interface OWebWireCodec ()
+ (size_t)byteCountForData: (OFData *)data;
@end

@implementation OWebWireProtocolException

+ (instancetype)exceptionWithFailure: (OWebWireProtocolFailure)failure
{
    return [[self alloc] initWithFailure: failure];
}

- (instancetype)initWithFailure: (OWebWireProtocolFailure)failure
{
    self = [super init];
    _failure = failure;
    return self;
}

@end

@interface OWebWireValue ()
- (instancetype)initWithType: (OWebWireValueType)type
                  boolValue: (bool)boolValue
         signedIntegerValue: (int64_t)signedIntegerValue
       unsignedIntegerValue: (uint64_t)unsignedIntegerValue
                 doubleValue: (double)doubleValue
                  stringValue: (nullable OFString *)stringValue;
@end

@implementation OWebWireValue

- (instancetype)initWithType: (OWebWireValueType)type
                  boolValue: (bool)boolValue
         signedIntegerValue: (int64_t)signedIntegerValue
       unsignedIntegerValue: (uint64_t)unsignedIntegerValue
                 doubleValue: (double)doubleValue
                  stringValue: (OFString *nillable)stringValue
{
    self = [super init];
    _type = type;
    _boolValue = boolValue;
    _signedIntegerValue = signedIntegerValue;
    _unsignedIntegerValue = unsignedIntegerValue;
    _doubleValue = doubleValue;
    _stringValue = [stringValue copy];
    return self;
}

+ (instancetype)nullValue
{
    return [[self alloc] initWithType: OWebWireValueTypeNull
        boolValue: false signedIntegerValue: 0 unsignedIntegerValue: 0
        doubleValue: 0 stringValue: nilptr];
}

+ (instancetype)valueWithBool: (bool)value
{
    return [[self alloc] initWithType: value ? OWebWireValueTypeTrue
                                             : OWebWireValueTypeFalse
        boolValue: value signedIntegerValue: 0 unsignedIntegerValue: 0
        doubleValue: 0 stringValue: nilptr];
}

+ (instancetype)valueWithSignedInteger: (int64_t)value
{
    return [[self alloc] initWithType: OWebWireValueTypeSignedInteger
        boolValue: false signedIntegerValue: value unsignedIntegerValue: 0
        doubleValue: 0 stringValue: nilptr];
}

+ (instancetype)valueWithUnsignedInteger: (uint64_t)value
{
    return [[self alloc] initWithType: OWebWireValueTypeUnsignedInteger
        boolValue: false signedIntegerValue: 0 unsignedIntegerValue: value
        doubleValue: 0 stringValue: nilptr];
}

+ (instancetype)valueWithDouble: (double)value
{
    if (!isfinite(value))
        @throw [OFInvalidArgumentException exception];
    if (value == 0)
        value = 0;
    return [[self alloc] initWithType: OWebWireValueTypeDouble
        boolValue: false signedIntegerValue: 0 unsignedIntegerValue: 0
        doubleValue: value stringValue: nilptr];
}

+ (instancetype)valueWithString: (OFString *)value
{
    return [[self alloc] initWithType: OWebWireValueTypeString
        boolValue: false signedIntegerValue: 0 unsignedIntegerValue: 0
        doubleValue: 0 stringValue: value];
}

@end

@interface OWebPatchOperation ()
- (instancetype)initWithOpcode: (OWebPatchOpcode)opcode
              elementIdentifier: (uint64_t)elementIdentifier
             templateIdentifier: (uint64_t)templateIdentifier
               parentIdentifier: (uint64_t)parentIdentifier
                 nodeIdentifier: (uint64_t)nodeIdentifier
               beforeIdentifier: (uint64_t)beforeIdentifier
                           name: (nullable OFString *)name
                          value: (nullable OWebWireValue *)value
                     operations: (OFArray<OWebPatchOperation *> *)operations;
@end

@implementation OWebPatchOperation

- (instancetype)initWithOpcode: (OWebPatchOpcode)opcode
              elementIdentifier: (uint64_t)elementIdentifier
             templateIdentifier: (uint64_t)templateIdentifier
               parentIdentifier: (uint64_t)parentIdentifier
                 nodeIdentifier: (uint64_t)nodeIdentifier
               beforeIdentifier: (uint64_t)beforeIdentifier
                           name: (OFString *nillable)name
                          value: (OWebWireValue *nillable)value
                     operations: (OFArray<OWebPatchOperation *> *)operations
{
    self = [super init];
    _opcode = opcode;
    _elementIdentifier = elementIdentifier;
    _templateIdentifier = templateIdentifier;
    _parentIdentifier = parentIdentifier;
    _nodeIdentifier = nodeIdentifier;
    _beforeIdentifier = beforeIdentifier;
    _name = [name copy];
    _value = value;
    _operations = [operations copy];
    return self;
}

+ (instancetype)setText: (OFString *)text
              forElement: (uint64_t)elementIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeSetText
        elementIdentifier: elementIdentifier templateIdentifier: 0
        parentIdentifier: 0 nodeIdentifier: 0 beforeIdentifier: 0
        name: nilptr value: [OWebWireValue valueWithString: text]
        operations: @[]];
}

+ (instancetype)setAttribute: (OFString *)name
                       value: (OFString *)value
                  forElement: (uint64_t)elementIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeSetAttribute
        elementIdentifier: elementIdentifier templateIdentifier: 0
        parentIdentifier: 0 nodeIdentifier: 0 beforeIdentifier: 0 name: name
        value: [OWebWireValue valueWithString: value] operations: @[]];
}

+ (instancetype)removeAttribute: (OFString *)name
                      forElement: (uint64_t)elementIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeRemoveAttribute
        elementIdentifier: elementIdentifier templateIdentifier: 0
        parentIdentifier: 0 nodeIdentifier: 0 beforeIdentifier: 0 name: name
        value: nilptr operations: @[]];
}

+ (instancetype)setProperty: (OFString *)name
                       value: (OWebWireValue *)value
                  forElement: (uint64_t)elementIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeSetProperty
        elementIdentifier: elementIdentifier templateIdentifier: 0
        parentIdentifier: 0 nodeIdentifier: 0 beforeIdentifier: 0 name: name
        value: value operations: @[]];
}

+ (instancetype)focusElement: (uint64_t)elementIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeFocus
        elementIdentifier: elementIdentifier templateIdentifier: 0
        parentIdentifier: 0 nodeIdentifier: 0 beforeIdentifier: 0
        name: nilptr value: nilptr operations: @[]];
}

+ (instancetype)batch: (OFArray<OWebPatchOperation *> *)operations
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeBatch
        elementIdentifier: 0 templateIdentifier: 0 parentIdentifier: 0
        nodeIdentifier: 0 beforeIdentifier: 0 name: nilptr value: nilptr
        operations: operations];
}

+ (instancetype)cloneTemplate: (uint64_t)templateIdentifier
                    intoParent: (uint64_t)parentIdentifier
                         asNode: (uint64_t)nodeIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeCloneTemplate
        elementIdentifier: 0 templateIdentifier: templateIdentifier
        parentIdentifier: parentIdentifier nodeIdentifier: nodeIdentifier
        beforeIdentifier: 0 name: nilptr value: nilptr operations: @[]];
}

+ (instancetype)removeNode: (uint64_t)nodeIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeRemoveNode
        elementIdentifier: 0 templateIdentifier: 0 parentIdentifier: 0
        nodeIdentifier: nodeIdentifier beforeIdentifier: 0 name: nilptr
        value: nilptr operations: @[]];
}

+ (instancetype)moveNode: (uint64_t)nodeIdentifier
                 intoParent: (uint64_t)parentIdentifier
                 beforeNode: (uint64_t)beforeIdentifier
{
    return [[self alloc] initWithOpcode: OWebPatchOpcodeMoveNode
        elementIdentifier: 0 templateIdentifier: 0
        parentIdentifier: parentIdentifier nodeIdentifier: nodeIdentifier
        beforeIdentifier: beforeIdentifier name: nilptr value: nilptr
        operations: @[]];
}

@end

@implementation OWebPatchFrame

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                                 operations:
    (OFArray<OWebPatchOperation *> *)operations
{
    self = [super init];
    _frameType = OWebWireFrameTypePatch;
    _instanceIdentifier = instanceIdentifier;
    _operations = [operations copy];
    return self;
}

@end

@implementation OWebEventFrame

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                           actionIdentifier: (uint64_t)actionIdentifier
                           targetIdentifier: (uint64_t)targetIdentifier
                                      fields:
    (OFDictionary<OFString *, OWebWireValue *> *)fields
{
    self = [super init];
    _frameType = OWebWireFrameTypeEvent;
    _instanceIdentifier = instanceIdentifier;
    _actionIdentifier = actionIdentifier;
    _targetIdentifier = targetIdentifier;
    _fields = [fields copy];
    return self;
}

@end

@implementation OWebMountFrame

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
                               componentTag: (OFString *)componentTag
                                 attributes:
    (OFDictionary<OFString *, OFString *> *)attributes
{
    self = [super init];
    _frameType = OWebWireFrameTypeMount;
    _instanceIdentifier = instanceIdentifier;
    _componentTag = [componentTag copy];
    _attributes = [attributes copy];
    return self;
}

@end

@implementation OWebDetachFrame

- (instancetype)initWithInstanceIdentifier: (uint64_t)instanceIdentifier
{
    self = [super init];
    _frameType = OWebWireFrameTypeDetach;
    _instanceIdentifier = instanceIdentifier;
    return self;
}

@end

[[subclassing_restricted, direct_members]]
@interface OWebWireWriter : OFObject
@property(nonatomic, readonly) OFData *data;
- (void)appendByte: (uint8_t)byte;
- (void)appendVarUInt: (uint64_t)value;
- (void)appendString: (OFString *)string;
- (void)appendValue: (OWebWireValue *)value;
- (void)appendData: (OFData *)data;
- (void)requireCapacityForAdditionalBytes: (size_t)additionalBytes;
@end

@implementation OWebWireWriter {
    OFMutableData *_mutableData;
}

- (instancetype)init
{
    self = [super init];
    _mutableData = [[OFMutableData alloc] init];
    return self;
}

- (OFData *)data
{
    return [_mutableData copy];
}

- (void)appendByte: (uint8_t)byte
{
    [self requireCapacityForAdditionalBytes: 1];
    [_mutableData addItem: &byte];
}

- (void)requireCapacityForAdditionalBytes: (size_t)additionalBytes
{
    if (additionalBytes > OWebWireMaximumFrameBytes - _mutableData.count)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureFrameTooLarge];
}

- (void)appendData: (OFData *)data
{
    [self requireCapacityForAdditionalBytes: data.count];
    if (data.count > 0)
        [_mutableData addItems: $assert_nonnil(data.items) count: data.count];
}

- (void)appendVarUInt: (uint64_t)value
{
    do {
        uint8_t byte = (uint8_t)(value & 0x7F);
        value >>= 7;
        if (value != 0)
            byte |= 0x80;
        [self appendByte: byte];
    } while (value != 0);
}

- (void)appendString: (OFString *)string
{
    size_t length;
    const char *bytes;
    @try {
        length = string.UTF8StringLength;
        bytes = string.UTF8String;
    } @catch (OFInvalidEncodingException *exception) {
        (void)exception;
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidUTF8];
    }
    if (length > OWebWireMaximumStringBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureStringTooLong];
    [self appendVarUInt: length];
    [self requireCapacityForAdditionalBytes: length];
    if (length > 0)
        [_mutableData addItems: bytes count: length];
}

- (void)appendValue: (OWebWireValue *)value
{
    [self appendByte: (uint8_t)value.type];
    switch (value.type) {
    case OWebWireValueTypeNull:
    case OWebWireValueTypeFalse:
    case OWebWireValueTypeTrue:
        return;
    case OWebWireValueTypeSignedInteger: {
        auto signedValue = value.signedIntegerValue;
        auto zigzag = ((uint64_t)signedValue << 1) ^
            (uint64_t)-(signedValue < 0);
        [self appendVarUInt: zigzag];
        return;
    }
    case OWebWireValueTypeUnsignedInteger:
        [self appendVarUInt: value.unsignedIntegerValue];
        return;
    case OWebWireValueTypeDouble: {
        double doubleValue = value.doubleValue;
        if (!isfinite(doubleValue))
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        if (doubleValue == 0)
            doubleValue = 0;
        uint64_t bits;
        memcpy(&bits, &doubleValue, sizeof(bits));
        for (size_t index = 0; index < sizeof(bits); index++)
            [self appendByte: (uint8_t)(bits >> (56 - index * 8))];
        return;
    }
    case OWebWireValueTypeString:
        if (value.stringValue == nilptr)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [self appendString: $assert_nonnil(value.stringValue)];
        return;
    }
    @throw [OWebWireProtocolException exceptionWithFailure:
        OWebWireProtocolFailureUnknownValueType];
}

@end

[[subclassing_restricted, direct_members]]
@interface OWebWireReader : OFObject
@property(nonatomic, readonly) size_t remainingBytes;
@property(nonatomic, readonly) bool isAtEnd;
@property(nonatomic) size_t operationCount;
- (instancetype)initWithData: (OFData *)data;
- (uint8_t)readByte;
- (uint64_t)readVarUInt;
- (uint64_t)readRequiredIdentifier;
- (OFString *)readString;
- (OWebWireValue *)readValue;
- (OWebPatchOperation *)readPatchOperationAtDepth: (size_t)depth;
@end

@implementation OWebWireReader {
    OFData *_data;
    const uint8_t *nillable _bytes;
    size_t _length;
    size_t _offset;
}

- (instancetype)initWithData: (OFData *)data
{
    self = [super init];
    _data = [data copy];
    if (_data.itemSize != 0 && _data.count > SIZE_MAX / _data.itemSize)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureFrameTooLarge];
    _length = _data.count * _data.itemSize;
    if (_length == 0)
        _bytes = nullptr;
    else
        _bytes = $assert_nonnil(_data.items);
    return self;
}

- (size_t)remainingBytes
{
    return _length - _offset;
}

- (bool)isAtEnd
{
    return _offset == _length;
}

- (uint8_t)readByte
{
    if (_offset >= _length)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTruncated];
    return ((const uint8_t *)$assert_nonnil(_bytes))[_offset++];
}

- (uint64_t)readVarUInt
{
    uint64_t result = 0;
    for (size_t index = 0; index < 10; index++) {
        auto byte = [self readByte];
        auto payload = (uint8_t)(byte & 0x7F);
        if (index == 9 && payload > 1)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureVarintOverflow];
        result |= (uint64_t)payload << (index * 7);
        if ((byte & 0x80) == 0) {
            if (index > 0 && payload == 0)
                @throw [OWebWireProtocolException exceptionWithFailure:
                    OWebWireProtocolFailureNonCanonicalVarint];
            return result;
        }
    }
    @throw [OWebWireProtocolException exceptionWithFailure:
        OWebWireProtocolFailureVarintOverflow];
}

- (uint64_t)readRequiredIdentifier
{
    auto identifier = [self readVarUInt];
    if (identifier == 0)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidValue];
    return identifier;
}

- (OFString *)readString
{
    auto encodedLength = [self readVarUInt];
    if (encodedLength > OWebWireMaximumStringBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureStringTooLong];
    auto length = (size_t)encodedLength;
    if (length > self.remainingBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTruncated];
    OFString *string;
    @try {
        string = [[OFString alloc] initWithUTF8String:
            (const char *)$assert_nonnil(_bytes) + _offset length: length];
        (void)string.UTF8String;
    } @catch (OFInvalidEncodingException *exception) {
        (void)exception;
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidUTF8];
    }
    _offset += length;
    return string;
}

- (OWebWireValue *)readValue
{
    auto type = (OWebWireValueType)[self readByte];
    switch (type) {
    case OWebWireValueTypeNull:
        return [OWebWireValue nullValue];
    case OWebWireValueTypeFalse:
        return [OWebWireValue valueWithBool: false];
    case OWebWireValueTypeTrue:
        return [OWebWireValue valueWithBool: true];
    case OWebWireValueTypeSignedInteger: {
        auto encoded = [self readVarUInt];
        auto value = (int64_t)((encoded >> 1) ^ (uint64_t)-(encoded & 1));
        return [OWebWireValue valueWithSignedInteger: value];
    }
    case OWebWireValueTypeUnsignedInteger:
        return [OWebWireValue valueWithUnsignedInteger: [self readVarUInt]];
    case OWebWireValueTypeDouble: {
        uint64_t bits = 0;
        for (size_t index = 0; index < sizeof(bits); index++)
            bits = (bits << 8) | [self readByte];
        if (bits == UINT64_C(0x8000000000000000))
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        double value;
        memcpy(&value, &bits, sizeof(value));
        if (!isfinite(value))
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        return [OWebWireValue valueWithDouble: value];
    }
    case OWebWireValueTypeString:
        return [OWebWireValue valueWithString: [self readString]];
    }
    @throw [OWebWireProtocolException exceptionWithFailure:
        OWebWireProtocolFailureUnknownValueType];
}

- (OWebPatchOperation *)readPatchOperationAtDepth: (size_t)depth
{
    if (depth > OWebWireMaximumBatchDepth)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureNestingLimitExceeded];
    _operationCount++;
    if (_operationCount > OWebWireMaximumOperations)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureOperationLimitExceeded];

    auto opcode = (OWebPatchOpcode)[self readByte];
    switch (opcode) {
    case OWebPatchOpcodeSetText: {
        auto elementIdentifier = [self readRequiredIdentifier];
        auto text = [self readString];
        return [OWebPatchOperation setText: text
            forElement: elementIdentifier];
    }
    case OWebPatchOpcodeSetAttribute: {
        auto elementIdentifier = [self readRequiredIdentifier];
        auto name = [self readString];
        if (![OWebWireCodec isPatchAttributeNameAllowed: name])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        auto value = [self readString];
        return [OWebPatchOperation setAttribute: name value: value
            forElement: elementIdentifier];
    }
    case OWebPatchOpcodeRemoveAttribute: {
        auto elementIdentifier = [self readRequiredIdentifier];
        auto name = [self readString];
        if (![OWebWireCodec isPatchAttributeNameAllowed: name])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        return [OWebPatchOperation removeAttribute: name
            forElement: elementIdentifier];
    }
    case OWebPatchOpcodeSetProperty: {
        auto elementIdentifier = [self readRequiredIdentifier];
        auto name = [self readString];
        if (![OWebWireCodec isPatchPropertyNameAllowed: name])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        auto value = [self readValue];
        return [OWebPatchOperation setProperty: name value: value
            forElement: elementIdentifier];
    }
    case OWebPatchOpcodeFocus:
        return [OWebPatchOperation focusElement:
            [self readRequiredIdentifier]];
    case OWebPatchOpcodeBatch: {
        auto encodedCount = [self readVarUInt];
        if (encodedCount > OWebWireMaximumOperations - _operationCount)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureOperationLimitExceeded];
        auto operations = [OFMutableArray<OWebPatchOperation *> array];
        for (uint64_t index = 0; index < encodedCount; index++)
            [operations addObject: [self readPatchOperationAtDepth: depth + 1]];
        return [OWebPatchOperation batch: operations];
    }
    case OWebPatchOpcodeCloneTemplate: {
        auto templateIdentifier = [self readRequiredIdentifier];
        auto parentIdentifier = [self readRequiredIdentifier];
        auto nodeIdentifier = [self readRequiredIdentifier];
        return [OWebPatchOperation cloneTemplate: templateIdentifier
            intoParent: parentIdentifier asNode: nodeIdentifier];
    }
    case OWebPatchOpcodeRemoveNode:
        return [OWebPatchOperation removeNode:
            [self readRequiredIdentifier]];
    case OWebPatchOpcodeMoveNode: {
        auto nodeIdentifier = [self readRequiredIdentifier];
        auto parentIdentifier = [self readRequiredIdentifier];
        auto beforeIdentifier = [self readVarUInt];
        return [OWebPatchOperation moveNode: nodeIdentifier
            intoParent: parentIdentifier beforeNode: beforeIdentifier];
    }
    }
    @throw [OWebWireProtocolException exceptionWithFailure:
        OWebWireProtocolFailureUnknownOpcode];
}

@end

@interface OWebWireCodec ()
+ (void)appendOperation: (OWebPatchOperation *)operation
                  writer: (OWebWireWriter *)writer
                   depth: (size_t)depth
                   count: (size_t *)count;
+ (OWebPatchFrame *)decodePatchFromReader: (OWebWireReader *)reader;
+ (OWebEventFrame *)decodeEventFromReader: (OWebWireReader *)reader;
+ (OWebMountFrame *)decodeMountFromReader: (OWebWireReader *)reader;
+ (OWebDetachFrame *)decodeDetachFromReader: (OWebWireReader *)reader;
+ (void)validateMapKey: (OFString *)key follows: (nullable OFString *)previous;
@end

@implementation OWebWireCodec

+ (bool)isEventFieldNameAllowed: (OFString *)name
{
    return [@[
        @"altKey", @"button", @"buttons", @"clientX", @"clientY",
        @"code", @"ctrlKey", @"data", @"deltaX", @"deltaY", @"detail",
        @"inputType", @"key", @"metaKey", @"offsetX", @"offsetY",
        @"pointerId", @"repeat", @"shiftKey", @"value"
    ] containsObject: name];
}

+ (bool)isComponentTagValid: (OFString *)tag
{
    auto length = tag.UTF8StringLength;
    if (length < 3 || length > 128)
        return false;
    auto bytes = (const unsigned char *)tag.UTF8String;
    if (bytes[0] < 'a' || bytes[0] > 'z')
        return false;
    bool hasHyphen = false;
    for (size_t index = 0; index < length; index++) {
        auto byte = bytes[index];
        if (byte == '-') {
            hasHyphen = true;
            continue;
        }
        if ((byte >= 'a' && byte <= 'z') ||
            (byte >= '0' && byte <= '9') || byte == '.' || byte == '_')
            continue;
        return false;
    }
    return hasHyphen;
}

+ (bool)isAttributeNameValid: (OFString *)name
{
    auto length = name.UTF8StringLength;
    if (length == 0 || length > 128)
        return false;
    auto bytes = (const unsigned char *)name.UTF8String;
    if (!((bytes[0] >= 'a' && bytes[0] <= 'z') || bytes[0] == '_' ||
        bytes[0] == ':'))
        return false;
    if (length > 2 && bytes[0] == 'o' && bytes[1] == 'n')
        return false;
    for (size_t index = 1; index < length; index++) {
        auto byte = bytes[index];
        if ((byte >= 'a' && byte <= 'z') ||
            (byte >= '0' && byte <= '9') || byte == '-' || byte == '_' ||
            byte == '.' || byte == ':')
            continue;
        return false;
    }
    return true;
}

+ (bool)isPatchAttributeNameAllowed: (OFString *)name
{
    if (![self isAttributeNameValid: name])
        return false;
    if ([name hasPrefix: @"data-oweb-"])
        return false;
    if ([name hasPrefix: @"aria-"] || [name hasPrefix: @"data-"])
        return true;
    return [@[
        @"aria-hidden", @"checked", @"class", @"disabled", @"hidden",
        @"id", @"open", @"placeholder", @"role", @"selected", @"tabindex",
        @"title", @"value"
    ] containsObject: name];
}

+ (bool)isPatchPropertyNameAllowed: (OFString *)name
{
    return [@[
        @"checked", @"disabled", @"hidden", @"indeterminate", @"open",
        @"scrollLeft", @"scrollTop", @"selected", @"value"
    ] containsObject: name];
}

+ (void)validateMapKey: (OFString *)key follows: (OFString *nillable)previous
{
    if (previous != nilptr && [previous compare: key] != OFOrderedAscending)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureNonCanonicalMap];
}

+ (void)appendOperation: (OWebPatchOperation *)operation
                  writer: (OWebWireWriter *)writer
                   depth: (size_t)depth
                   count: (size_t *)count
{
    if (depth > OWebWireMaximumBatchDepth)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureNestingLimitExceeded];
    (*count)++;
    if (*count > OWebWireMaximumOperations)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureOperationLimitExceeded];
    [writer appendByte: (uint8_t)operation.opcode];
    switch (operation.opcode) {
    case OWebPatchOpcodeSetText:
        if (operation.elementIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendVarUInt: operation.elementIdentifier];
        if (operation.value.type != OWebWireValueTypeString ||
            operation.value.stringValue == nilptr)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendString: $assert_nonnil(operation.value.stringValue)];
        return;
    case OWebPatchOpcodeSetAttribute:
        if (operation.elementIdentifier == 0 || operation.name == nilptr ||
            ![self isPatchAttributeNameAllowed:
                $assert_nonnil(operation.name)])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        [writer appendVarUInt: operation.elementIdentifier];
        if (operation.name == nilptr ||
            operation.value.type != OWebWireValueTypeString ||
            operation.value.stringValue == nilptr)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendString: $assert_nonnil(operation.name)];
        [writer appendString: $assert_nonnil(operation.value.stringValue)];
        return;
    case OWebPatchOpcodeRemoveAttribute:
        if (operation.elementIdentifier == 0 || operation.name == nilptr ||
            ![self isPatchAttributeNameAllowed:
                $assert_nonnil(operation.name)])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        [writer appendVarUInt: operation.elementIdentifier];
        if (operation.name == nilptr)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendString: $assert_nonnil(operation.name)];
        return;
    case OWebPatchOpcodeSetProperty:
        if (operation.elementIdentifier == 0 || operation.name == nilptr ||
            ![self isPatchPropertyNameAllowed:
                $assert_nonnil(operation.name)])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        [writer appendVarUInt: operation.elementIdentifier];
        if (operation.name == nilptr || operation.value == nilptr)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendString: $assert_nonnil(operation.name)];
        [writer appendValue: $assert_nonnil(operation.value)];
        return;
    case OWebPatchOpcodeFocus:
        if (operation.elementIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendVarUInt: operation.elementIdentifier];
        return;
    case OWebPatchOpcodeBatch:
        if (operation.operations.count > OWebWireMaximumOperations - *count)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureOperationLimitExceeded];
        [writer appendVarUInt: operation.operations.count];
        for (OWebPatchOperation *child in operation.operations)
            [self appendOperation: child writer: writer depth: depth + 1
                count: count];
        return;
    case OWebPatchOpcodeCloneTemplate:
        if (operation.templateIdentifier == 0 ||
            operation.parentIdentifier == 0 || operation.nodeIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendVarUInt: operation.templateIdentifier];
        [writer appendVarUInt: operation.parentIdentifier];
        [writer appendVarUInt: operation.nodeIdentifier];
        return;
    case OWebPatchOpcodeRemoveNode:
        if (operation.nodeIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendVarUInt: operation.nodeIdentifier];
        return;
    case OWebPatchOpcodeMoveNode:
        if (operation.nodeIdentifier == 0 || operation.parentIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [writer appendVarUInt: operation.nodeIdentifier];
        [writer appendVarUInt: operation.parentIdentifier];
        [writer appendVarUInt: operation.beforeIdentifier];
        return;
    }
    @throw [OWebWireProtocolException exceptionWithFailure:
        OWebWireProtocolFailureUnknownOpcode];
}

+ (OFData *)encodeFrame: (id<OWebWireFrame>)frame
{
    auto body = [[OWebWireWriter alloc] init];
    switch (frame.frameType) {
    case OWebWireFrameTypePatch: {
        if (![frame isKindOfClass: [OWebPatchFrame class]])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        auto patch = (OWebPatchFrame *)frame;
        if (patch.instanceIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [body appendVarUInt: patch.instanceIdentifier];
        if (patch.operations.count > OWebWireMaximumOperations)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureOperationLimitExceeded];
        [body appendVarUInt: patch.operations.count];
        size_t count = 0;
        for (OWebPatchOperation *operation in patch.operations)
            [self appendOperation: operation writer: body depth: 0 count: &count];
        break;
    }
    case OWebWireFrameTypeEvent: {
        if (![frame isKindOfClass: [OWebEventFrame class]])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        auto event = (OWebEventFrame *)frame;
        if (event.instanceIdentifier == 0 || event.actionIdentifier == 0 ||
            event.targetIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [body appendVarUInt: event.instanceIdentifier];
        [body appendVarUInt: event.actionIdentifier];
        [body appendVarUInt: event.targetIdentifier];
        if (event.fields.count > OWebWireMaximumEventFields)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        auto keys = event.fields.allKeys.sortedArray;
        [body appendVarUInt: keys.count];
        for (OFString *key in keys) {
            if (![self isEventFieldNameAllowed: key])
                @throw [OWebWireProtocolException exceptionWithFailure:
                    OWebWireProtocolFailureDisallowedEventField];
            [body appendString: key];
            [body appendValue: $assert_nonnil(event.fields[key])];
        }
        break;
    }
    case OWebWireFrameTypeMount: {
        if (![frame isKindOfClass: [OWebMountFrame class]])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        auto mount = (OWebMountFrame *)frame;
        if (mount.instanceIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        if (![self isComponentTagValid: mount.componentTag])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidComponentTag];
        if (mount.attributes.count > OWebWireMaximumMountAttributes)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        [body appendVarUInt: mount.instanceIdentifier];
        [body appendString: mount.componentTag];
        auto keys = mount.attributes.allKeys.sortedArray;
        [body appendVarUInt: keys.count];
        for (OFString *key in keys) {
            if (![self isAttributeNameValid: key])
                @throw [OWebWireProtocolException exceptionWithFailure:
                    OWebWireProtocolFailureInvalidAttributeName];
            [body appendString: key];
            [body appendString: $assert_nonnil(mount.attributes[key])];
        }
        break;
    }
    case OWebWireFrameTypeDetach: {
        if (![frame isKindOfClass: [OWebDetachFrame class]])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidFrame];
        auto detach = (OWebDetachFrame *)frame;
        if (detach.instanceIdentifier == 0)
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidValue];
        [body appendVarUInt: detach.instanceIdentifier];
        break;
    }
    default:
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureUnknownFrameType];
    }

    auto bodyData = body.data;
    auto output = [[OWebWireWriter alloc] init];
    const uint8_t magic[] = { 'O', 'W', 'E', 'B' };
    [output appendData: [OFData dataWithItems: magic count: sizeof(magic)]];
    [output appendByte: OWebWireProtocolVersion];
    [output appendByte: (uint8_t)frame.frameType];
    [output appendVarUInt: bodyData.count];
    [output appendData: bodyData];
    auto encoded = output.data;
    if (encoded.count > OWebWireMaximumFrameBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureFrameTooLarge];
    return encoded;
}

+ (OWebPatchFrame *)decodePatchFromReader: (OWebWireReader *)reader
{
    auto instanceIdentifier = [reader readRequiredIdentifier];
    auto encodedCount = [reader readVarUInt];
    if (encodedCount > OWebWireMaximumOperations)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureOperationLimitExceeded];
    auto operations = [OFMutableArray<OWebPatchOperation *> array];
    for (uint64_t index = 0; index < encodedCount; index++)
        [operations addObject: [reader readPatchOperationAtDepth: 0]];
    return [[OWebPatchFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier operations: operations];
}

+ (OWebEventFrame *)decodeEventFromReader: (OWebWireReader *)reader
{
    auto instanceIdentifier = [reader readRequiredIdentifier];
    auto actionIdentifier = [reader readRequiredIdentifier];
    auto targetIdentifier = [reader readRequiredIdentifier];
    auto encodedCount = [reader readVarUInt];
    if (encodedCount > OWebWireMaximumEventFields)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidFrame];
    auto fields = [OFMutableDictionary<OFString *, OWebWireValue *> dictionary];
    OFString *nillable previous = nilptr;
    for (uint64_t index = 0; index < encodedCount; index++) {
        auto key = [reader readString];
        [self validateMapKey: key follows: previous];
        if (![self isEventFieldNameAllowed: key])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureDisallowedEventField];
        fields[key] = [reader readValue];
        previous = key;
    }
    return [[OWebEventFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier
        actionIdentifier: actionIdentifier targetIdentifier: targetIdentifier
        fields: fields];
}

+ (OWebMountFrame *)decodeMountFromReader: (OWebWireReader *)reader
{
    auto instanceIdentifier = [reader readRequiredIdentifier];
    auto componentTag = [reader readString];
    if (![self isComponentTagValid: componentTag])
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidComponentTag];
    auto encodedCount = [reader readVarUInt];
    if (encodedCount > OWebWireMaximumMountAttributes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureInvalidFrame];
    auto attributes = [OFMutableDictionary<OFString *, OFString *> dictionary];
    OFString *nillable previous = nilptr;
    for (uint64_t index = 0; index < encodedCount; index++) {
        auto key = [reader readString];
        [self validateMapKey: key follows: previous];
        if (![self isAttributeNameValid: key])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidAttributeName];
        attributes[key] = [reader readString];
        previous = key;
    }
    return [[OWebMountFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier componentTag: componentTag
        attributes: attributes];
}

+ (OWebDetachFrame *)decodeDetachFromReader: (OWebWireReader *)reader
{
    auto instanceIdentifier = [reader readRequiredIdentifier];
    return [[OWebDetachFrame alloc]
        initWithInstanceIdentifier: instanceIdentifier];
}

+ (id<OWebWireFrame>)decodeFrameData: (OFData *)data
{
    auto byteCount = [self byteCountForData: data];
    if (byteCount > OWebWireMaximumFrameBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureFrameTooLarge];
    if (byteCount < 7)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTruncated];
    auto reader = [[OWebWireReader alloc] initWithData: data];
    const uint8_t magic[] = { 'O', 'W', 'E', 'B' };
    for (size_t index = 0; index < sizeof(magic); index++) {
        if ([reader readByte] != magic[index])
            @throw [OWebWireProtocolException exceptionWithFailure:
                OWebWireProtocolFailureInvalidMagic];
    }
    if ([reader readByte] != OWebWireProtocolVersion)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureUnsupportedVersion];
    auto frameType = (OWebWireFrameType)[reader readByte];
    if (frameType < OWebWireFrameTypePatch ||
        frameType > OWebWireFrameTypeDetach)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureUnknownFrameType];
    auto bodyLength = [reader readVarUInt];
    if (bodyLength > reader.remainingBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTruncated];
    if (bodyLength < reader.remainingBytes)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTrailingData];

    id<OWebWireFrame> frame;
    switch (frameType) {
    case OWebWireFrameTypePatch:
        frame = [self decodePatchFromReader: reader];
        break;
    case OWebWireFrameTypeEvent:
        frame = [self decodeEventFromReader: reader];
        break;
    case OWebWireFrameTypeMount:
        frame = [self decodeMountFromReader: reader];
        break;
    case OWebWireFrameTypeDetach:
        frame = [self decodeDetachFromReader: reader];
        break;
    }
    if (!reader.isAtEnd)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureTrailingData];
    return frame;
}

+ (size_t)byteCountForData: (OFData *)data
{
    if (data.itemSize != 0 && data.count > SIZE_MAX / data.itemSize)
        @throw [OWebWireProtocolException exceptionWithFailure:
            OWebWireProtocolFailureFrameTooLarge];
    return data.count * data.itemSize;
}

@end


#pragma clang assume_nonnull end
