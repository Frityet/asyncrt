#import "Tools/OCGen/src/Schema.h"
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CxxBaseSpecifier : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *access;
@property(readonly, nonatomic) bool isPackExpansion;
@property(readonly, nonatomic) bool isVirtual;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *writtenAccess;

@end

#pragma clang assume_nonnull end
