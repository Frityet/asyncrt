#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFTLSStream (PromiseAdditions)

- (Promise<OFTLSStream *> *)promiseToPerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFTLSStream *> *)promiseToPerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<OFTLSStream *> *)promiseToPerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFTLSStream *> *)promiseToPerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
