#import <Schema.h>
#import "AstObject.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface HTMLStartTagComment : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<OFArray<id> *> *nillable attrs;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceLocation *loc;
@property(readonly, nonatomic) bool malformed;
@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) bool selfClosing;

@end

#pragma clang assume_nonnull end
