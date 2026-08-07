#import "Tools/OCGen/src/Schema.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ApValueNode : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *value;

@end

#pragma clang assume_nonnull end
