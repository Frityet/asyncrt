#import "CommentNodeShape007.h"

#pragma clang assume_nonnull begin

@implementation CommentNodeShape007

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"direction"];
        _direction = $cast(OFString, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"explicit"];
        if (value != nilptr)
            _jsonExplicit = [$cast(OFNumber, value) boolValue];
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
        auto value = dictionary[@"loc"];
        _loc = [[SourceLocation alloc] initFromJSONObject: $assert_nonnil(value)];
    }
    {
        auto value = dictionary[@"param"];
        if (value != nilptr)
            _param = $cast(OFString, value);
    }
    {
        auto value = dictionary[@"paramIdx"];
        if (value != nilptr)
            _paramIdx = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"range"];
        _range = [[SourceRange alloc] initFromJSONObject: $assert_nonnil(value)];
    }

    return self;
}

@end

#pragma clang assume_nonnull end
