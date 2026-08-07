#import "TypeNodeShape008.h"

#pragma clang assume_nonnull begin

@implementation TypeNodeShape008

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"cc"];
        _cc = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"conditionEvaluatesTo"];
        if (value != nilptr)
            _conditionEvaluatesTo = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"const"];
        if (value != nilptr)
            _jsonConst = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"exceptionSpec"];
        if (value != nilptr)
            _exceptionSpec = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"exceptionTypes"];
        if (value != nilptr) {
            auto array = $cast(OFArray, value);
            auto converted = [OFMutableArray arrayWithCapacity: array.count];
            for (id item in array)
                [converted addObject: [[JSONQualType alloc] initFromJSONObject: item]];
            _exceptionTypes = [converted copy];
        }
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
        auto value = dictionary[@"refQualifier"];
        if (value != nilptr)
            _refQualifier = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"regParm"];
        if (value != nilptr)
            _regParm = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"restrict"];
        if (value != nilptr)
            _jsonRestrict = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"throwsAny"];
        if (value != nilptr)
            _throwsAny = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"trailingReturn"];
        if (value != nilptr)
            _trailingReturn = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"variadic"];
        if (value != nilptr)
            _variadic = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"volatile"];
        if (value != nilptr)
            _jsonVolatile = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
