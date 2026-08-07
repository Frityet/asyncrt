#import "Tools/OCGen/src/Schema.h"
#import "SourceLocation.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface SourceRange : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) SourceLocation *begin;
@property(readonly, nonatomic) SourceLocation *end;

@end

#pragma clang assume_nonnull end
