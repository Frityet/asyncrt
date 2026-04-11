#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFIRIHandler (PromiseAdditions)

+ (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
