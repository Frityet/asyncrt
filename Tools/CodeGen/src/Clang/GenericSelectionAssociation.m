#import "GenericSelectionAssociation.h"

#pragma clang assume_nonnull begin

@implementation GenericSelectionAssociation

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"associationKind"];
        _associationKind = $cast(OFString, $assert_nonnil(value));
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
        auto value = dictionary[@"selected"];
        if (value != nilptr)
            _selected = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
