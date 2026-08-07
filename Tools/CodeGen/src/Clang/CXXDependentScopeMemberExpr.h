#import "Tools/OCGen/src/Schema.h"
#import "AstObject.h"
#import "JSONQualType.h"
#import "SourceRange.h"
#import "TemplateArgument.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CXXDependentScopeMemberExpr : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFArray<TemplateArgument *> *nillable explicitTemplateArgs;
@property(readonly, nonatomic) bool hasExplicitTemplateArgs;
@property(readonly, nonatomic) bool hasTemplateKeyword;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isArrow;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) OFString *member;
@property(readonly, nonatomic) SourceRange *range;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) OFString *valueCategory;

@end

#pragma clang assume_nonnull end
