#import <Schema.h>
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface BareDeclRef : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFString *nillable kind;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) JSONQualType *nillable type;

@end

#pragma clang assume_nonnull end
