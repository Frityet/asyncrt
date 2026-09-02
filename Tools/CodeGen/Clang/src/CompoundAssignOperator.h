#import <Schema.h>
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CompoundAssignOperator : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) JSONQualType *computeLHSType;
@property(readonly, nonatomic) JSONQualType *computeResultType;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFString *opcode;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
