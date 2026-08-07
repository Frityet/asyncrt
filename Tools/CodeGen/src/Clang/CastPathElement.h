#import "Tools/OCGen/src/Schema.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CastPathElement : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool isVirtual;
@property(readonly, nonatomic) OFString *name;

@end

#pragma clang assume_nonnull end
