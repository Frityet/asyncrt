#import "TemplateArgument.h"

#pragma clang assume_nonnull begin

@implementation TemplateArgument

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"decl"];
        if (value != nilptr)
            _decl = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"fromDecl"];
        if (value != nilptr)
            _fromDecl = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"inherited from"];
        if (value != nilptr)
            _inheritedFrom = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
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
        auto value = dictionary[@"isCanonical"];
        if (value != nilptr)
            _isCanonical = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isExpr"];
        if (value != nilptr)
            _isExpr = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isNull"];
        if (value != nilptr)
            _isNull = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isNullptr"];
        if (value != nilptr)
            _isNullptr = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isPack"];
        if (value != nilptr)
            _isPack = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"previous"];
        if (value != nilptr)
            _previous = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"range"];
        if (value != nilptr)
            _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"type"];
        if (value != nilptr)
            _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"value"];
        if (value != nilptr)
            _value = value;
    }

    return self;
}

@end

#pragma clang assume_nonnull end
