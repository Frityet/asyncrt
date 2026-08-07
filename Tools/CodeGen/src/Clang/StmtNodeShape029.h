#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape029 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) JSONQualType *nillable adjustedTypeArg;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) JSONQualType *nillable typeArg;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
