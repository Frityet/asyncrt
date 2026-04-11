#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFStreamSocket (PromiseAdditions)

- (Promise<OFStreamSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFStreamSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
