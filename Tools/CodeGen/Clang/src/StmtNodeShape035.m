#import "StmtNodeShape035.h"

#pragma clang assume_nonnull begin

@implementation StmtNodeShape035

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"constructionKind"];
        _constructionKind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"ctorType"];
        _ctorType = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"elidable"];
        if (value != nilptr)
            _elidable = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hadMultipleCandidates"];
        if (value != nilptr)
            _hadMultipleCandidates = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"initializer_list"];
        if (value != nilptr)
            _jsonInitializer_list = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"isImmediateEscalating"];
        if (value != nilptr)
            _isImmediateEscalating = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"list"];
        if (value != nilptr)
            _list = [$cast(OFNumber, value) boolValue];
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
    {
        auto value = dictionary[@"zeroing"];
        if (value != nilptr)
            _zeroing = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
