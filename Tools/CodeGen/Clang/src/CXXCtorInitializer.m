#import "CXXCtorInitializer.h"

#pragma clang assume_nonnull begin

@implementation CXXCtorInitializer

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"anyInit"];
        if (value != nilptr)
            _anyInit = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"baseInit"];
        if (value != nilptr)
            _baseInit = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"delegatingInit"];
        if (value != nilptr)
            _delegatingInit = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
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

    return self;
}

@end

#pragma clang assume_nonnull end
