#import "CastPathElement.h"

#pragma clang assume_nonnull begin

@implementation CastPathElement

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"isVirtual"];
        if (value != nilptr)
            _isVirtual = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"name"];
        _name = $cast(OFString, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
