#import "FunctionNoProtoType.h"

#pragma clang assume_nonnull begin

@implementation FunctionNoProtoType

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"cc"];
        _cc = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"containsErrors"];
        if (value != nilptr)
            _containsErrors = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"containsUnexpandedPack"];
        if (value != nilptr)
            _containsUnexpandedPack = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"inner"];
        if (value != nilptr) {
            auto array = $cast(OFArray, value);
            auto converted = [OFMutableArray arrayWithCapacity: array.count];
            for (id item in array)
                [converted addObject: [[AstObject alloc] initFromJSONObject: item]];
            _inner = [converted copy];
        }
    }
    {
        auto value = dictionary[@"isDependent"];
        if (value != nilptr)
            _isDependent = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isImported"];
        if (value != nilptr)
            _isImported = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isInstantiationDependent"];
        if (value != nilptr)
            _isInstantiationDependent = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isVariablyModified"];
        if (value != nilptr)
            _isVariablyModified = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"noreturn"];
        if (value != nilptr)
            _noreturn = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"producesResult"];
        if (value != nilptr)
            _producesResult = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"regParm"];
        if (value != nilptr)
            _regParm = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
