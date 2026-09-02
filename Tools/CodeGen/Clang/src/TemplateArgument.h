#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface TemplateArgument : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareDeclRef *nillable decl;
@property(readonly, nonatomic) BareDeclRef *nillable fromDecl;
@property(readonly, nonatomic) BareDeclRef *nillable inheritedFrom;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isCanonical;
@property(readonly, nonatomic) bool isExpr;
@property(readonly, nonatomic) bool isNull;
@property(readonly, nonatomic) bool isNullptr;
@property(readonly, nonatomic) bool isPack;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) BareDeclRef *nillable previous;
@property(readonly, nonatomic) SourceRange *nillable range;
@property(readonly, nonatomic) JSONQualType *nillable type;
@property(readonly, nonatomic) id nillable value;

@end

#pragma clang assume_nonnull end
