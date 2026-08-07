#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface QualType : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFString *qualifiers;
@property(readonly, nonatomic) JSONQualType *type;

@end

#pragma clang assume_nonnull end
