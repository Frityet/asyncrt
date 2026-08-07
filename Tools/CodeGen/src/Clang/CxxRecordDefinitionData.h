#import "Tools/OCGen/src/Schema.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CxxRecordDefinitionData : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) bool canConstDefaultInit;
@property(readonly, nonatomic) bool canPassInRegisters;
@property(readonly, nonatomic) OFDictionary *jsonCopyAssign;
@property(readonly, nonatomic) OFDictionary *jsonCopyCtor;
@property(readonly, nonatomic) OFDictionary *defaultCtor;
@property(readonly, nonatomic) OFDictionary *dtor;
@property(readonly, nonatomic) bool hasConstexprNonCopyMoveConstructor;
@property(readonly, nonatomic) bool hasMutableFields;
@property(readonly, nonatomic) bool hasUserDeclaredConstructor;
@property(readonly, nonatomic) bool hasVariantMembers;
@property(readonly, nonatomic) bool isAbstract;
@property(readonly, nonatomic) bool isAggregate;
@property(readonly, nonatomic) bool isEmpty;
@property(readonly, nonatomic) bool isGenericLambda;
@property(readonly, nonatomic) bool isLambda;
@property(readonly, nonatomic) bool isLiteral;
@property(readonly, nonatomic) bool isPOD;
@property(readonly, nonatomic) bool isPolymorphic;
@property(readonly, nonatomic) bool isStandardLayout;
@property(readonly, nonatomic) bool isTrivial;
@property(readonly, nonatomic) bool isTriviallyCopyable;
@property(readonly, nonatomic) OFDictionary *moveAssign;
@property(readonly, nonatomic) OFDictionary *moveCtor;

@end

#pragma clang assume_nonnull end
