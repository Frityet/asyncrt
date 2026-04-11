#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFTCPSocket (PromiseAdditions)

- (Promise<OFTCPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFTCPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
