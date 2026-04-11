#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFTLSStream (FutureAdditions)

- (Future<OFTLSStream *> *)futurePerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFTLSStream *> *)futurePerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<OFTLSStream *> *)futurePerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler;
- (Future<OFTLSStream *> *)futurePerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
