#import "SourceRange.h"

#pragma clang assume_nonnull begin

@implementation SourceRange

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"begin"];
        _begin = [[SourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"end"];
        _end = [[SourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
