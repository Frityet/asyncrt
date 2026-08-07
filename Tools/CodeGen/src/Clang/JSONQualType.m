#import "JSONQualType.h"

#pragma clang assume_nonnull begin

@implementation JSONQualType

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"desugaredQualType"];
        if (value != nilptr)
            _desugaredQualType = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"qualType"];
        _qualType = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"typeAliasDeclId"];
        if (value != nilptr)
            _typeAliasDeclId = $cast(OFString, value);
    }

    return self;
}

@end

#pragma clang assume_nonnull end
