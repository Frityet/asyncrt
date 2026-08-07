#import "CXXConversionDecl.h"

#pragma clang assume_nonnull begin

@implementation CXXConversionDecl

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"TemplateInstantiationPattern"];
        if (value != nilptr)
            _TemplateInstantiationPattern = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"constexpr"];
        if (value != nilptr)
            _jsonConstexpr = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"deletedMessage"];
        if (value != nilptr)
            _deletedMessage = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"explicitlyDefaulted"];
        if (value != nilptr)
            _explicitlyDefaulted = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"explicitlyDeleted"];
        if (value != nilptr)
            _explicitlyDeleted = [$cast(OFNumber, value) boolValue];
    }
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
        auto value = dictionary[@"immediate"];
        if (value != nilptr)
            _immediate = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"inline"];
        if (value != nilptr)
            _jsonInline = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"mangledName"];
        if (value != nilptr)
            _mangledName = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"name"];
        if (value != nilptr)
            _name = $cast(OFString, value);
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
        auto value = dictionary[@"pure"];
        if (value != nilptr)
            _pure = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"storageClass"];
        if (value != nilptr)
            _storageClass = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"variadic"];
        if (value != nilptr)
            _variadic = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"virtual"];
        if (value != nilptr)
            _jsonVirtual = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
