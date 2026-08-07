#import "MacroSourceLocation.h"

#pragma clang assume_nonnull begin

@implementation MacroSourceLocation

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"expansionLoc"];
        _expansionLoc = [[BareSourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"spellingLoc"];
        _spellingLoc = [[BareSourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
