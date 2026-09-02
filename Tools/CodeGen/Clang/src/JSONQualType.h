#import <Schema.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface JSONQualType : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *nillable desugaredQualType;
@property(readonly, nonatomic) OFString *qualType;
@property(readonly, nonatomic) OFString *nillable typeAliasDeclId;

@end

#pragma clang assume_nonnull end
