#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSequencedPacketSocket (PromiseAdditions)

- (Promise<AsyncBufferReadResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncBufferReadResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<OFSequencedPacketSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFSequencedPacketSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
