#import "Async/ObjFWAsync/OFDatagramSocket+Future.h"

#pragma clang assume_nonnull begin

@implementation OFDatagramSocket (FutureAdditions)

- (Future<AsyncDatagramReceiveResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReceiveIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncDatagramReceiveResult *> *)futureReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFDatagramSocket *nillable)self == nilptr or (void *nillable)buffer == nullptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncDatagramReceiveResult *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncReceiveIntoBuffer:length:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncReceiveIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFDatagramSocket *socket, void *callbackBuffer, size_t callbackLength, const OFSocketAddress *sender, id nillable exception) {
            (void)socket;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a datagram receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncDatagramReceiveResult alloc] initWithBuffer: buffer length: callbackLength sender: sender]];
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

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureSendData: data receiver: receiver onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFDatagramSocket *nillable)self == nilptr or (OFData *nillable)data == nilptr or (const OFSocketAddress *nillable)receiver == nullptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncUnit *> *resolver = [[FutureResolver alloc] init];
    OFData *receiverData = [AsyncObjFWSupport copySocketAddressData: receiver];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncSendData:receiver:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncSendData: data receiver: (const OFSocketAddress *)receiverData.items runLoopMode: scheduler.mode handler: ^OFData *nillable(OFDatagramSocket *socket, OFData *callbackData, const OFSocketAddress *callbackReceiver, id nillable exception) {
            (void)socket;
            (void)callbackData;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return nilptr;
            }
            if (not [[AsyncObjFWSupport copySocketAddressData: callbackReceiver] isEqual: receiverData]) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a datagram send with a different receiver address"];
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

@end

void async_link_objfw_ofdatagramsocket_future_category(void) {}

#pragma clang assume_nonnull end
