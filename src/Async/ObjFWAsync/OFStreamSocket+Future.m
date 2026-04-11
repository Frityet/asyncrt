#import "Async/ObjFWAsync/OFStreamSocket+Future.h"

#pragma clang assume_nonnull begin

@implementation OFStreamSocket (FutureAdditions)

- (Future<OFStreamSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler
{
    return [self futureAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFStreamSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFStreamSocket *nillable)self == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<OFStreamSocket *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncAccept" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncAcceptWithRunLoopMode: scheduler.mode handler: ^bool(OFStreamSocket *socket, OFStreamSocket *nillable acceptedSocket, id nillable exception) {
            (void)socket;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if ((OFStreamSocket *nillable)acceptedSocket == nilptr) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW accepted a stream socket without returning a socket or exception"];
                return false;
            }

            OFStreamSocket *resolvedSocket = acceptedSocket;
            [bridge resolve: resolvedSocket];
            return false;
        }];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@end

void async_link_objfw_ofstreamsocket_future_category(void) {}

#pragma clang assume_nonnull end
