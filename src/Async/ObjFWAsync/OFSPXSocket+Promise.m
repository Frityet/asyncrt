#import "Utilities/common.h"

#ifdef OF_HAVE_IPX

#import "Async/ObjFWAsync/OFSPXSocket+Promise.h"

#include <string.h>

#pragma clang assume_nonnull begin

@implementation OFSPXSocket (PromiseAdditions)

- (Promise<OFSPXSocket *> *)promiseToConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToConnectToNetwork: network node: node port: port onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFSPXSocket *> *)promiseToConnectToNetwork: (uint32_t)network node: (const unsigned char [_Nonnull IPX_NODE_LEN])node port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    unsigned char expectedNode[IPX_NODE_LEN];
    const unsigned char *expectedNodePointer = expectedNode;
    memcpy(expectedNode, node, IPX_NODE_LEN);

    auto resolver = [[PromiseResolver<OFSPXSocket *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncConnectToNetwork:node:port:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncConnectToNetwork: network node: expectedNodePointer port: port runLoopMode: scheduler.mode handler: ^(OFSPXSocket *socket, uint32_t callbackNetwork, const unsigned char callbackNode[_Nonnull IPX_NODE_LEN], uint16_t callbackPort, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return;
            }
            if (socket != self or callbackNetwork != network or memcmp(callbackNode, expectedNodePointer, IPX_NODE_LEN) != 0 or callbackPort != port) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SPX connect with mismatched connection metadata"];
                return;
            }

            [bridge resolve: self];
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@end

#pragma clang assume_nonnull end

#endif

void async_link_objfw_ofspxsocket_promise_category(void) {}
