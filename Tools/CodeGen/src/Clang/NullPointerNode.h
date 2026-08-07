#import "Tools/OCGen/src/Schema.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface NullPointerNode : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;

@end

#pragma clang assume_nonnull end
