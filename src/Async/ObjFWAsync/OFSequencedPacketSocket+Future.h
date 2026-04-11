#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSequencedPacketSocket (FutureAdditions)

- (Future<AsyncBufferReadResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncBufferReadResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<OFSequencedPacketSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler;
- (Future<OFSequencedPacketSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
