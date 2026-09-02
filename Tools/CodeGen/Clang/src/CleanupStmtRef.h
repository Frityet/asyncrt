#import <Schema.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CleanupStmtRef : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFString *kind;

@end

#pragma clang assume_nonnull end
