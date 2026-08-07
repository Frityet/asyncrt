#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface DecltypeTypeLoc : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;

@end

#pragma clang assume_nonnull end
