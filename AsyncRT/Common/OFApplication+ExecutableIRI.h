#import <ObjFW/OFApplication.h>
#import <ObjFW/OFIRI.h>

#import "Common.h"

#pragma clang assume_nonnull begin

@interface CannotGetExecutablePathException : OFException

@end

@interface OFApplication(ExecutableIRI)

+ (OFIRI *)executableIRI;

@end

#pragma clang assume_nonnull end
