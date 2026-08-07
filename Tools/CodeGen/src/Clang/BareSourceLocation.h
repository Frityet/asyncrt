#import "Tools/OCGen/src/Schema.h"
#import "IncludedFrom.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface BareSourceLocation : OFObject <JSONDeserialisable>
@property(readonly, nonatomic) OFNumber *nillable col;
@property(readonly, nonatomic) OFString *nillable file;
@property(readonly, nonatomic) IncludedFrom *nillable includedFrom;
@property(readonly, nonatomic) bool isMacroArgExpansion;
@property(readonly, nonatomic) OFNumber *nillable line;
@property(readonly, nonatomic) OFNumber *nillable offset;
@property(readonly, nonatomic) OFString *nillable presumedFile;
@property(readonly, nonatomic) OFNumber *nillable presumedLine;
@property(readonly, nonatomic) OFNumber *nillable tokLen;

@end

#pragma clang assume_nonnull end
