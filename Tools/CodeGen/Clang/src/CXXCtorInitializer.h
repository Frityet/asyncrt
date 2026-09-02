#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CXXCtorInitializer : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareDeclRef *nillable anyInit;
@property(readonly, nonatomic) JSONQualType *nillable baseInit;
@property(readonly, nonatomic) JSONQualType *nillable delegatingInit;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;

@end

#pragma clang assume_nonnull end
