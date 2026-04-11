#import "Async/ObjFWAsync/OFTCPSocket+Future.h"

#pragma clang assume_nonnull begin

@implementation OFTCPSocket (FutureAdditions)

- (Future<OFTCPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureConnectToHost: host port: port onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFTCPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFTCPSocket *nillable)self == nilptr or (OFString *nillable)host == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    OFString *expectedHost = [host copy];
    FutureResolver<OFTCPSocket *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncConnectToHost:port:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncConnectToHost: expectedHost port: port runLoopMode: scheduler.mode handler: ^(OFTCPSocket *socket, OFString *callbackHost, uint16_t callbackPort, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return;
            }
            if (socket != self or not [callbackHost isEqual: expectedHost] or callbackPort != port) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a TCP connect with mismatched connection metadata"];
                return;
            }

            [bridge resolve: self];
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

void async_link_objfw_oftcpsocket_future_category(void) {}

#pragma clang assume_nonnull end
