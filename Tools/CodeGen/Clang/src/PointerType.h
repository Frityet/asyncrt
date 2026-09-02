#import <Schema.h>
#import "AstObject.h"
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface PointerType : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool containsErrors;
@property(readonly, nonatomic) bool containsUnexpandedPack;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isDependent;
@property(readonly, nonatomic) bool isImported;
@property(readonly, nonatomic) bool isInstantiationDependent;
@property(readonly, nonatomic) bool isVariablyModified;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) JSONQualType *type;

@end

#pragma clang assume_nonnull end
