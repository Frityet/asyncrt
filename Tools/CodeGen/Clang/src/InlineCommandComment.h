#import <Schema.h>
#import "AstObject.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface InlineCommandComment : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<OFString *> *nillable args;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceLocation *loc;
@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) OFString *renderKind;

@end

#pragma clang assume_nonnull end
