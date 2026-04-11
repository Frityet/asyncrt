#import "Async/ObjFWAsync/OFSequencedPacketSocket+Future.h"

#pragma clang assume_nonnull begin

@implementation OFSequencedPacketSocket (FutureAdditions)

- (Future<AsyncBufferReadResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReceiveIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncBufferReadResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSequencedPacketSocket *nillable)self == nilptr or (void *nillable)buffer == nullptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncBufferReadResult *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncReceiveIntoBuffer:length:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncReceiveIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFSequencedPacketSocket *socket, void *callbackBuffer, size_t callbackLength, id nillable exception) {
            (void)socket;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a packet receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncBufferReadResult alloc] initWithBuffer: buffer length: callbackLength]];
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

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureSendData: data onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSequencedPacketSocket *nillable)self == nilptr or (OFData *nillable)data == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncUnit *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncSendData:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncSendData: data runLoopMode: scheduler.mode handler: ^OFData *nillable(OFSequencedPacketSocket *socket, OFData *callbackData, id nillable exception) {
            (void)socket;
            (void)callbackData;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return nilptr;
            }

            [bridge resolve: AsyncUnit.unit];
            return nilptr;
        }];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

- (Future<OFSequencedPacketSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler
{
    return [self futureAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFSequencedPacketSocket *> *)futureAcceptOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSequencedPacketSocket *nillable)self == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<OFSequencedPacketSocket *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncAccept" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncAcceptWithRunLoopMode: scheduler.mode handler: ^bool(OFSequencedPacketSocket *socket, OFSequencedPacketSocket *nillable acceptedSocket, id nillable exception) {
            (void)socket;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if ((OFSequencedPacketSocket *nillable)acceptedSocket == nilptr) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW accepted a sequenced packet socket without returning a socket or exception"];
                return false;
            }

            OFSequencedPacketSocket *resolvedSocket = acceptedSocket;
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

void async_link_objfw_ofsequencedpacketsocket_future_category(void) {}

#pragma clang assume_nonnull end
