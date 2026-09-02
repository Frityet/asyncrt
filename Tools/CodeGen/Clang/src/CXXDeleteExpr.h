#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CXXDeleteExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isArray;
@property(readonly, nonatomic) bool isArrayAsWritten;
@property(readonly, nonatomic) bool isGlobal;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) BareDeclRef *nillable operatorDeleteDecl;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
