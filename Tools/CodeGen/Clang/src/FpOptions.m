#import "FpOptions.h"

#pragma clang assume_nonnull begin

@implementation FpOptions

- (instancetype)initFromJSONObject: (id)obj
{
    self = [super init];

    auto dictionary = $cast(OFDictionary, obj);
    {
        auto value = dictionary[@"AllowApproxFunc"];
        if (value != nilptr)
            _AllowApproxFunc = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"AllowFEnvAccess"];
        if (value != nilptr)
            _AllowFEnvAccess = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"AllowFPReassociate"];
        if (value != nilptr)
            _AllowFPReassociate = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"AllowReciprocal"];
        if (value != nilptr)
            _AllowReciprocal = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"BFloat16ExcessPrecision"];
        if (value != nilptr)
            _BFloat16ExcessPrecision = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"ComplexRange"];
        if (value != nilptr)
            _ComplexRange = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"ConstRoundingMode"];
        if (value != nilptr)
            _ConstRoundingMode = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"FPContractMode"];
        if (value != nilptr)
            _FPContractMode = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"FPEvalMethod"];
        if (value != nilptr)
            _FPEvalMethod = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"Float16ExcessPrecision"];
        if (value != nilptr)
            _Float16ExcessPrecision = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"MathErrno"];
        if (value != nilptr)
            _MathErrno = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"NoHonorInfs"];
        if (value != nilptr)
            _NoHonorInfs = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"NoHonorNaNs"];
        if (value != nilptr)
            _NoHonorNaNs = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"NoSignedZero"];
        if (value != nilptr)
            _NoSignedZero = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"RoundingMath"];
        if (value != nilptr)
            _RoundingMath = $cast(OFNumber, value);
    }
    {
        auto value = dictionary[@"SpecifiedExceptionMode"];
        if (value != nilptr)
            _SpecifiedExceptionMode = $cast(OFNumber, value);
    }

    return self;
}

@end

#pragma clang assume_nonnull end
