#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface StmtNodeShape009 : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *declId;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) bool sideEntry;

@end

#pragma clang assume_nonnull end
