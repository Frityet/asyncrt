#pragma once

#import <ObjFW/OFApplication.h>
#import <ObjFW/OFIRI.h>

#pragma clang assume_nonnull begin

@interface OFApplication(ExecutableIRI)

+ (OFIRI *_Nullable)executableIRI;

@end

#pragma clang assume_nonnull end
