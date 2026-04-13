#import "Async/ObjFWAsync/OFStreamSocket+Promise.h"

#pragma clang assume_nonnull begin

@implementation OFStreamSocket (PromiseAdditions)

- (Promise<OFStreamSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFStreamSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<OFStreamSocket *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncAccept" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncAcceptWithRunLoopMode: scheduler.mode handler: ^bool(OFStreamSocket *, OFStreamSocket *nillable acceptedSocket, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }
            if (acceptedSocket == nilptr) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW accepted a stream socket without returning a socket or exception"];
                return false;
            }

            OFStreamSocket *resolvedSocket = acceptedSocket;
            [bridge resolve: resolvedSocket];
            return false;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

@end

void async_link_objfw_ofstreamsocket_promise_category(void) {}

#pragma clang assume_nonnull end
