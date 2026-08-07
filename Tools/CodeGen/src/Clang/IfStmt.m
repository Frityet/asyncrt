#import "IfStmt.h"

#pragma clang assume_nonnull begin

@implementation IfStmt

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"constevalIsNegated"];
        if (value != nilptr)
            _constevalIsNegated = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasElse"];
        if (value != nilptr)
            _hasElse = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasInit"];
        if (value != nilptr)
            _hasInit = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasVar"];
        if (value != nilptr)
            _hasVar = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"isConsteval"];
        if (value != nilptr)
            _isConsteval = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isConstexpr"];
        if (value != nilptr)
            _isConstexpr = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"kind"];
        _kind = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
