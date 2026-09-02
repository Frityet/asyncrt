#import <Schema.h>
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface DeclNodeShape015 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *nillable TemplateInstantiationPattern;
@property(readonly, nonatomic) bool jsonConstexpr;
@property(readonly, nonatomic) bool explicitObjectParameter;
@property(readonly, nonatomic) OFString *nillable firstRedecl;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFString *nillable jsonInit;
@property(readonly, nonatomic) bool jsonInline;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isHidden;
@property(readonly, nonatomic) bool isImplicit;
@property(readonly, nonatomic) bool isInvalid;
@property(readonly, nonatomic) bool isParameterPack;
@property(readonly, nonatomic) bool isReferenced;
@property(readonly, nonatomic) bool isUsed;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceLocation *loc;
@property(readonly, nonatomic) OFString *nillable mangledName;
@property(readonly, nonatomic) bool modulePrivate;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) bool nrvo;
@property(readonly, nonatomic) OFString *nillable parentDeclContextId;
@property(readonly, nonatomic) OFString *nillable previousDecl;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) OFString *nillable storageClass;
@property(readonly, nonatomic) OFString *nillable tls;
@property(readonly, nonatomic) JSONQualType *type;

@end

#pragma clang assume_nonnull end
