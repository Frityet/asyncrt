#import "CxxBaseSpecifier.h"

#pragma clang assume_nonnull begin

@implementation CxxBaseSpecifier

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"access"];
        _access = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"isPackExpansion"];
        if (value != nilptr)
            _isPackExpansion = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isVirtual"];
        if (value != nilptr)
            _isVirtual = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"writtenAccess"];
        _writtenAccess = $cast(OFString, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
