#import "CXXNewExpr.h"

#pragma clang assume_nonnull begin

@implementation CXXNewExpr

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"initStyle"];
        if (value != nilptr)
            _jsonInitStyle = $cast(OFString, value);
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
        auto value = dictionary[@"isArray"];
        if (value != nilptr)
            _isArray = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isGlobal"];
        if (value != nilptr)
            _isGlobal = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isPlacement"];
        if (value != nilptr)
            _isPlacement = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"operatorDeleteDecl"];
        if (value != nilptr)
            _operatorDeleteDecl = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"operatorNewDecl"];
        if (value != nilptr)
            _operatorNewDecl = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"valueCategory"];
        _valueCategory = $cast(OFString, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
