#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "FpOptions.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape002 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) FpOptions *nillable fpoptions;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;

@end

#pragma clang assume_nonnull end
