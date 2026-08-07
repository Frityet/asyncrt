#import "StmtNodeShape048.h"

#pragma clang assume_nonnull begin

@implementation StmtNodeShape048

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"callReturnType"];
        if (value != nilptr)
            _callReturnType = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"classType"];
        if (value != nilptr)
            _classType = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"id"];
        _id = $cast(OFString, $assert_nonnil(value));
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
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"receiverKind"];
        _receiverKind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"selector"];
        _selector = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"superType"];
        if (value != nilptr)
            _superType = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
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
