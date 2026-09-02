#import <Schema.h>
#import "AstObject.h"
#import "SourceRange.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface IfStmt : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool constevalIsNegated;
@property(readonly, nonatomic) bool hasElse;
@property(readonly, nonatomic) bool hasInit;
@property(readonly, nonatomic) bool hasVar;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isConsteval;
@property(readonly, nonatomic) bool isConstexpr;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) SourceRange *range;

@end

#pragma clang assume_nonnull end
