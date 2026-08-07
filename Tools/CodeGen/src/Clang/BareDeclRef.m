#import "BareDeclRef.h"

#pragma clang assume_nonnull begin

@implementation BareDeclRef

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"kind"];
        if (value != nilptr)
            _kind = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"name"];
        if (value != nilptr)
            _name = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"type"];
        if (value != nilptr)
            _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
