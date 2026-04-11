#pragma once

#ifdef OF_HAVE_IPX

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFSPXStreamSocket (PromiseAdditions)

- (Promise<OFSPXStreamSocket *> *)promiseToConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFSPXStreamSocket *> *)promiseToConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end

#endif
