#import "BareSourceLocation.h"

#pragma clang assume_nonnull begin

@implementation BareSourceLocation

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"col"];
        if (value != nilptr)
            _col = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"file"];
        if (value != nilptr)
            _file = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"includedFrom"];
        if (value != nilptr)
            _includedFrom = [[IncludedFrom alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"isMacroArgExpansion"];
        if (value != nilptr)
            _isMacroArgExpansion = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"line"];
        if (value != nilptr)
            _line = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"offset"];
        if (value != nilptr)
            _offset = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"presumedFile"];
        if (value != nilptr)
            _presumedFile = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"presumedLine"];
        if (value != nilptr)
            _presumedLine = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"tokLen"];
        if (value != nilptr)
            _tokLen = $cast(OFNumber, value);
    }

    return self;
}

@end

#pragma clang assume_nonnull end
