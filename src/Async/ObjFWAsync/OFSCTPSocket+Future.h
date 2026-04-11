#pragma once

#ifdef OF_HAVE_SCTP

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSCTPSocket (FutureAdditions)

- (Future<OFSCTPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFSCTPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncSCTPReceiveResult *> *)futureReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncSCTPReceiveResult *> *)futureReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end

#endif
