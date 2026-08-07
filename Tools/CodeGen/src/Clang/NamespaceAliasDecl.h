#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "BareDeclRef.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface NamespaceAliasDecl : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareDeclRef *aliasedNamespace;
@property(readonly, nonatomic) OFString *nillable firstRedecl;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isHidden;
@property(readonly, nonatomic) bool isImplicit;
@property(readonly, nonatomic) bool isInvalid;
@property(readonly, nonatomic) bool isReferenced;
@property(readonly, nonatomic) bool isUsed;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceLocation *loc;
@property(readonly, nonatomic) OFString *nillable mangledName;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) OFString *nillable parentDeclContextId;
@property(readonly, nonatomic) OFString *nillable previousDecl;
@property(readonly, nonatomic) SourceRange *range;

@end

#pragma clang assume_nonnull end
