#import "ObjCPropertyDecl.h"

#pragma clang assume_nonnull begin

@implementation ObjCPropertyDecl

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"assign"];
        if (value != nilptr)
            _assign = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"atomic"];
        if (value != nilptr)
            _atomic = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"class"];
        if (value != nilptr)
            _jsonClass = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"control"];
        if (value != nilptr)
            _control = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"copy"];
        if (value != nilptr)
            _jsonCopy = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"direct"];
        if (value != nilptr)
            _jsonDirect = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"firstRedecl"];
        if (value != nilptr)
            _firstRedecl = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"getter"];
        if (value != nilptr)
            _getter = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
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
        auto value = dictionary[@"nonatomic"];
        if (value != nilptr)
            _nonatomic = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"null_resettable"];
        if (value != nilptr)
            _null_resettable = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"nullability"];
        if (value != nilptr)
            _nullability = [$cast(OFNumber, value) boolValue];
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
    {
        auto value = dictionary[@"readonly"];
        if (value != nilptr)
            _readonly = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"readwrite"];
        if (value != nilptr)
            _readwrite = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"retain"];
        if (value != nilptr)
            _jsonRetain = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"setter"];
        if (value != nilptr)
            _setter = [[BareDeclRef alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"strong"];
        if (value != nilptr)
            _strong = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"type"];
        _type = [[JSONQualType alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"unsafe_unretained"];
        if (value != nilptr)
            _unsafe_unretained = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"weak"];
        if (value != nilptr)
            _weak = [$cast(OFNumber, value) boolValue];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
