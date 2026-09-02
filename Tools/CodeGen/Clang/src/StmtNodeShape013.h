#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape013 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareDeclRef *nillable foundReferencedDecl;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isImmediateEscalating;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFString *nillable nonOdrUseReason;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) BareDeclRef *referencedDecl;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
