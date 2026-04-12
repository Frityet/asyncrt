#import "Async/ObjFWAsync/OFTCPSocket+Promise.h"

#pragma clang assume_nonnull begin

@implementation OFTCPSocket (PromiseAdditions)

- (Promise<OFTCPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToConnectToHost: host port: port onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFTCPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    OFString *expectedHost = [host copy];
    auto resolver = [[PromiseResolver<OFTCPSocket *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncConnectToHost:port:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncConnectToHost: expectedHost port: port runLoopMode: scheduler.mode handler: ^(OFTCPSocket *socket, OFString *callbackHost, uint16_t callbackPort, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return;
            }
            if (socket != self or not [callbackHost isEqual: expectedHost] or callbackPort != port) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a TCP connect with mismatched connection metadata"];
                return;
            }

            [bridge resolve: self];
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

@end

void async_link_objfw_oftcpsocket_promise_category(void) {}

#pragma clang assume_nonnull end
