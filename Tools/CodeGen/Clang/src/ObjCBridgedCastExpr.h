#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "CastPathElement.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ObjCBridgedCastExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *castKind;
@property(readonly, nonatomic) BareDeclRef *nillable conversionFunc;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFArray<CastPathElement *> *nillable path;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
