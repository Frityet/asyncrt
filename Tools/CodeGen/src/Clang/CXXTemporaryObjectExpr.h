#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CXXTemporaryObjectExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *constructionKind;
@property(readonly, nonatomic) JSONQualType *ctorType;
@property(readonly, nonatomic) bool elidable;
@property(readonly, nonatomic) bool hadMultipleCandidates;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) bool jsonInitializer_list;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isImmediateEscalating;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) bool list;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;
@property(readonly, nonatomic) bool zeroing;

@end

#pragma clang assume_nonnull end
