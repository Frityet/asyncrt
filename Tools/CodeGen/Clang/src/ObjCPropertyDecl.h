#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ObjCPropertyDecl : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool assign;
@property(readonly, nonatomic) bool atomic;
@property(readonly, nonatomic) bool jsonClass;
@property(readonly, nonatomic) OFString *nillable control;
@property(readonly, nonatomic) bool jsonCopy;
@property(readonly, nonatomic) bool jsonDirect;
@property(readonly, nonatomic) OFString *nillable firstRedecl;
@property(readonly, nonatomic) BareDeclRef *nillable getter;
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
@property(readonly, nonatomic) bool nonatomic;
@property(readonly, nonatomic) bool null_resettable;
@property(readonly, nonatomic) bool nullability;
@property(readonly, nonatomic) OFString *nillable parentDeclContextId;
@property(readonly, nonatomic) OFString *nillable previousDecl;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) bool readonly;
@property(readonly, nonatomic) bool readwrite;
@property(readonly, nonatomic) bool jsonRetain;
@property(readonly, nonatomic) BareDeclRef *nillable setter;
@property(readonly, nonatomic) bool strong;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) bool unsafe_unretained;
@property(readonly, nonatomic) bool weak;

@end

#pragma clang assume_nonnull end
