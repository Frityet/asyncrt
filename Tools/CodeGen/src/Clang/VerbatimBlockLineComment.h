#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "SourceLocation.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface VerbatimBlockLineComment : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceLocation *loc;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) OFString *text;

@end

#pragma clang assume_nonnull end
