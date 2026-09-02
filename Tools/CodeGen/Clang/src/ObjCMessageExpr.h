#import <Schema.h>
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ObjCMessageExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) JSONQualType *nillable callReturnType;
@property(readonly, nonatomic) JSONQualType *nillable classType;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) OFString *receiverKind;
@property(readonly, nonatomic) OFString *selector;
@property(readonly, nonatomic) JSONQualType *nillable superType;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
