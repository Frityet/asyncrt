#import "IncludedFrom.h"

#pragma clang assume_nonnull begin

@implementation IncludedFrom

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"file"];
        _file = $cast(OFString, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
