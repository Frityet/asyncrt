#import "Tools/OCGen/src/Schema.h"
#import "BareSourceLocation.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface MacroSourceLocation : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) BareSourceLocation *expansionLoc;
@property(readonly, nonatomic) BareSourceLocation *spellingLoc;

@end

#pragma clang assume_nonnull end
