#import <Schema.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface FpOptions : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFNumber *nillable AllowApproxFunc;
@property(readonly, nonatomic) OFNumber *nillable AllowFEnvAccess;
@property(readonly, nonatomic) OFNumber *nillable AllowFPReassociate;
@property(readonly, nonatomic) OFNumber *nillable AllowReciprocal;
@property(readonly, nonatomic) OFNumber *nillable BFloat16ExcessPrecision;
@property(readonly, nonatomic) OFNumber *nillable ComplexRange;
@property(readonly, nonatomic) OFNumber *nillable ConstRoundingMode;
@property(readonly, nonatomic) OFNumber *nillable FPContractMode;
@property(readonly, nonatomic) OFNumber *nillable FPEvalMethod;
@property(readonly, nonatomic) OFNumber *nillable Float16ExcessPrecision;
@property(readonly, nonatomic) OFNumber *nillable MathErrno;
@property(readonly, nonatomic) OFNumber *nillable NoHonorInfs;
@property(readonly, nonatomic) OFNumber *nillable NoHonorNaNs;
@property(readonly, nonatomic) OFNumber *nillable NoSignedZero;
@property(readonly, nonatomic) OFNumber *nillable RoundingMath;
@property(readonly, nonatomic) OFNumber *nillable SpecifiedExceptionMode;

@end

#pragma clang assume_nonnull end
