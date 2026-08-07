#import "NullPointerNode.h"

#pragma clang assume_nonnull begin

@implementation NullPointerNode

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
