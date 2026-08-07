#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface GenericSelectionAssociation : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *associationKind;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool selected;

@end

#pragma clang assume_nonnull end
