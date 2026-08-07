#import "CxxRecordDefinitionData.h"

#pragma clang assume_nonnull begin

@implementation CxxRecordDefinitionData

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"canConstDefaultInit"];
        if (value != nilptr)
            _canConstDefaultInit = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"canPassInRegisters"];
        if (value != nilptr)
            _canPassInRegisters = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"copyAssign"];
        _jsonCopyAssign = $cast(OFDictionary, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"copyCtor"];
        _jsonCopyCtor = $cast(OFDictionary, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"defaultCtor"];
        _defaultCtor = $cast(OFDictionary, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"dtor"];
        _dtor = $cast(OFDictionary, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"hasConstexprNonCopyMoveConstructor"];
        if (value != nilptr)
            _hasConstexprNonCopyMoveConstructor = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasMutableFields"];
        if (value != nilptr)
            _hasMutableFields = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasUserDeclaredConstructor"];
        if (value != nilptr)
            _hasUserDeclaredConstructor = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"hasVariantMembers"];
        if (value != nilptr)
            _hasVariantMembers = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isAbstract"];
        if (value != nilptr)
            _isAbstract = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isAggregate"];
        if (value != nilptr)
            _isAggregate = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isEmpty"];
        if (value != nilptr)
            _isEmpty = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isGenericLambda"];
        if (value != nilptr)
            _isGenericLambda = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isLambda"];
        if (value != nilptr)
            _isLambda = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isLiteral"];
        if (value != nilptr)
            _isLiteral = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isPOD"];
        if (value != nilptr)
            _isPOD = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isPolymorphic"];
        if (value != nilptr)
            _isPolymorphic = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isStandardLayout"];
        if (value != nilptr)
            _isStandardLayout = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isTrivial"];
        if (value != nilptr)
            _isTrivial = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"isTriviallyCopyable"];
        if (value != nilptr)
            _isTriviallyCopyable = [$cast(OFNumber, value) boolValue];
    }
    {
        auto value = dictionary[@"moveAssign"];
        _moveAssign = $cast(OFDictionary, $assert_nonnil(value));
    }
    {
        auto value = dictionary[@"moveCtor"];
        _moveCtor = $cast(OFDictionary, $assert_nonnil(value));
    }

    return self;
}

@end

#pragma clang assume_nonnull end
