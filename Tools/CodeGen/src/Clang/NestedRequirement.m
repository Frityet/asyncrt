#import "NestedRequirement.h"

#pragma clang assume_nonnull begin

@implementation NestedRequirement

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"containsUnexpandedPack"];
        if (value != nilptr)
            _containsUnexpandedPack = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"noexcept"];
        if (value != nilptr)
            _jsonNoexcept = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"satisfied"];
        if (value != nilptr)
            _satisfied = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
