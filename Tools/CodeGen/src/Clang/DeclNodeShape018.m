#import "DeclNodeShape018.h"

#pragma clang assume_nonnull begin

@implementation DeclNodeShape018

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"firstRedecl"];
        if (value != nilptr)
            _firstRedecl = $cast(OFString, value);
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
        auto value = dictionary[@"isHidden"];
        if (value != nilptr)
            _isHidden = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isImplicit"];
        if (value != nilptr)
            _isImplicit = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isInvalid"];
        if (value != nilptr)
            _isInvalid = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isReferenced"];
        if (value != nilptr)
            _isReferenced = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isUsed"];
        if (value != nilptr)
            _isUsed = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"loc"];
        _loc = [[SourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"name"];
        _name = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"parentDeclContextId"];
        if (value != nilptr)
            _parentDeclContextId = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"previousDecl"];
        if (value != nilptr)
            _previousDecl = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
