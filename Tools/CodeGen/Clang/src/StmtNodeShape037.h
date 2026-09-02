#import <Schema.h>
#import "AstObject.h"
#import "BareDeclRef.h"
#import "CleanupStmtRef.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape037 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<id> *nillable cleanups;
@property(readonly, nonatomic) bool cleanupsHaveSideEffects;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
