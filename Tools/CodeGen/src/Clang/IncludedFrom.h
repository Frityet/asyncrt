#import "Tools/OCGen/src/Schema.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface IncludedFrom : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *file;

@end

#pragma clang assume_nonnull end
