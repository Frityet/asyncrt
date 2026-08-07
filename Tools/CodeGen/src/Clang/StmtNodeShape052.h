#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "BareDeclRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape052 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareDeclRef *nillable getter;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isMessagingGetter;
@property(readonly, nonatomic) bool isMessagingSetter;
@property(readonly, nonatomic) bool isSuperReceiver;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) BareDeclRef *nillable property;
@property(readonly, nonatomic) OFString *propertyKind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) BareDeclRef *nillable setter;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
