#pragma once

#ifdef OF_HAVE_IPX

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSPXStreamSocket (FutureAdditions)

- (Future<OFSPXStreamSocket *> *)futureConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFSPXStreamSocket *> *)futureConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end

#endif
