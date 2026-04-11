#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFDatagramSocket (FutureAdditions)

- (Future<AsyncDatagramReceiveResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncDatagramReceiveResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
