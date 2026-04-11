#pragma once

#ifdef OF_HAVE_SCTP

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSCTPSocket (PromiseAdditions)

- (Promise<OFSCTPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFSCTPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncSCTPReceiveResult *> *)promiseToReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncSCTPReceiveResult *> *)promiseToReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end

#endif
