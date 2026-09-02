#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape042 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool boundToLValueRef;
@property(readonly, nonatomic) BareDeclRef *nillable extendingDecl;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) OFString *storageDuration;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
