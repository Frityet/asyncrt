#import <Schema.h>
#import "AstObject.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ClauseNode : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;

@end

#pragma clang assume_nonnull end
