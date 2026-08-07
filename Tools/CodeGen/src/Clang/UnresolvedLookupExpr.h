#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface UnresolvedLookupExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFArray<BareDeclRef *> *lookups;
@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) bool usesADL;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
