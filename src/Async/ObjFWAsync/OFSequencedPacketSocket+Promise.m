#import "Async/ObjFWAsync/OFSequencedPacketSocket+Promise.h"

#pragma clang assume_nonnull begin

@implementation OFSequencedPacketSocket (PromiseAdditions)

- (Promise<AsyncBufferReadResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReceiveIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncBufferReadResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncBufferReadResult *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncReceiveIntoBuffer:length:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncReceiveIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFSequencedPacketSocket *, void *callbackBuffer, size_t callbackLength, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a packet receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncBufferReadResult alloc] initWithBuffer: buffer length: callbackLength]];
            return false;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToSendData: data onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncUnit *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncSendData:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncSendData: data runLoopMode: scheduler.mode handler: ^OFData *nillable(OFSequencedPacketSocket *, OFData *, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return nilptr;
            }

            [bridge resolve: AsyncUnit.unit];
            return nilptr;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

- (Promise<OFSequencedPacketSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFSequencedPacketSocket *> *)promiseToAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<OFSequencedPacketSocket *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncAccept" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncAcceptWithRunLoopMode: scheduler.mode handler: ^bool(OFSequencedPacketSocket *, OFSequencedPacketSocket *nillable acceptedSocket, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }
            if (acceptedSocket == nilptr) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW accepted a sequenced packet socket without returning a socket or exception"];
                return false;
            }

            OFSequencedPacketSocket *resolvedSocket = acceptedSocket;
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

void async_link_objfw_ofsequencedpacketsocket_promise_category(void) {}

#pragma clang assume_nonnull end
