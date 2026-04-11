#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFTCPSocket (FutureAdditions)

- (Future<OFTCPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFTCPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
