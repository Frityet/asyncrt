#import "CXXDependentScopeMemberExpr.h"

#pragma clang assume_nonnull begin

@implementation CXXDependentScopeMemberExpr

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"explicitTemplateArgs"];
        if (value != nilptr) {
            auto array = $cast(OFArray, value);
            auto converted = [OFMutableArray arrayWithCapacity: array.count];
            for (id item in array)
                [converted addObject: [[TemplateArgument alloc] initFromJSONObject: item]];
            _explicitTemplateArgs = [converted copy];
        }
    }
    {
        auto value = dictionary[@"hasExplicitTemplateArgs"];
        if (value != nilptr)
            _hasExplicitTemplateArgs = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasTemplateKeyword"];
        if (value != nilptr)
            _hasTemplateKeyword = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"isArrow"];
        _isArrow = [$cast(OFNumber, $assert_nonnil(value)) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"member"];
        _member = $cast(OFString, $assert_nonnil(value));
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
