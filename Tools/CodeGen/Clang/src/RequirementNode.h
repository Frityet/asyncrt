#import <Schema.h>
#import "AstObject.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface RequirementNode : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool containsUnexpandedPack;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isDependent;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) bool jsonNoexcept;
@property(readonly, nonatomic) bool satisfied;

@end

#pragma clang assume_nonnull end
