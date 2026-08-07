#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "BareDeclRef.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface Capture : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool byref;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) bool nested;
@property(readonly, nonatomic) BareDeclRef *nillable var;

@end

#pragma clang assume_nonnull end
