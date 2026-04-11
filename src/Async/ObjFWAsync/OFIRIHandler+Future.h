#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFIRIHandler (FutureAdditions)

+ (Future<OFStream *> *)futureOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFStream *> *)futureOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
