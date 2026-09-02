#import <Schema.h>
#import "AstObject.h"
#import "JSONQualType.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface FunctionProtoType : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFString *cc;
@property(readonly, nonatomic) bool conditionEvaluatesTo;
@property(readonly, nonatomic) bool jsonConst;
@property(readonly, nonatomic) bool containsErrors;
@property(readonly, nonatomic) bool containsUnexpandedPack;
@property(readonly, nonatomic) OFString *nillable exceptionSpec;
@property(readonly, nonatomic) OFArray<JSONQualType *> *nillable exceptionTypes;
@property(readonly, nonatomic) OFString *id;
@property(readonly, nonatomic) OFArray<AstObject *> *nillable inner;
@property(readonly, nonatomic) bool isDependent;
@property(readonly, nonatomic) bool isImported;
@property(readonly, nonatomic) bool isInstantiationDependent;
@property(readonly, nonatomic) bool isVariablyModified;
@property(readonly, nonatomic) OFString *kind;
@property(readonly, nonatomic) bool noreturn;
@property(readonly, nonatomic) bool producesResult;
@property(readonly, nonatomic) OFString *nillable refQualifier;
@property(readonly, nonatomic) OFNumber *nillable regParm;
@property(readonly, nonatomic) bool jsonRestrict;
@property(readonly, nonatomic) bool throwsAny;
@property(readonly, nonatomic) bool trailingReturn;
@property(readonly, nonatomic) JSONQualType *type;
@property(readonly, nonatomic) bool variadic;
@property(readonly, nonatomic) bool jsonVolatile;

@end

#pragma clang assume_nonnull end
