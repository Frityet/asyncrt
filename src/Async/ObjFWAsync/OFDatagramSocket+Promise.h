#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFDatagramSocket (PromiseAdditions)

- (Promise<AsyncDatagramReceiveResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncDatagramReceiveResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
