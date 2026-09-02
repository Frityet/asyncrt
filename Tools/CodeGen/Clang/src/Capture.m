#import "Capture.h"

#pragma clang assume_nonnull begin

@implementation Capture

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"byref"];
        if (value != nilptr)
            _byref = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"nested"];
        if (value != nilptr)
            _nested = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"var"];
        if (value != nilptr)
            _var = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
