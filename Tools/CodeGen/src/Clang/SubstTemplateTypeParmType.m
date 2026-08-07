#import "SubstTemplateTypeParmType.h"

#pragma clang assume_nonnull begin

@implementation SubstTemplateTypeParmType

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
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
        auto value = dictionary[@"index"];
        _index = $cast(OFNumber, $assert_nonnil(value));
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
        auto value = dictionary[@"pack_index"];
        if (value != nilptr)
            _pack_index = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
