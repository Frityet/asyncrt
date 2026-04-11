#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFStreamSocket (FutureAdditions)

- (Future<OFStreamSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler;
- (Future<OFStreamSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
