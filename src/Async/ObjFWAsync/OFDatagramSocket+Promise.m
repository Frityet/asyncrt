#import "Async/ObjFWAsync/OFDatagramSocket+Promise.h"

#pragma clang assume_nonnull begin

@implementation OFDatagramSocket (PromiseAdditions)

- (Promise<AsyncDatagramReceiveResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReceiveIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncDatagramReceiveResult *> *)promiseToReceiveIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncDatagramReceiveResult *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncReceiveIntoBuffer:length:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncReceiveIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFDatagramSocket *, void *callbackBuffer, size_t callbackLength, const OFSocketAddress *sender, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a datagram receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncDatagramReceiveResult alloc] initWithBuffer: buffer length: callbackLength sender: sender]];
            return false;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToSendData: data receiver: receiver onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data receiver: (const OFSocketAddress *)receiver onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncUnit *> alloc] init];
    OFData *receiverData = [AsyncObjFWSupport copySocketAddressData: receiver];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncSendData:receiver:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncSendData: data receiver: (const OFSocketAddress *)receiverData.items runLoopMode: scheduler.mode handler: ^OFData *nillable(OFDatagramSocket *, OFData *, const OFSocketAddress *callbackReceiver, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return nilptr;
            }
            if (not [[AsyncObjFWSupport copySocketAddressData: callbackReceiver] isEqual: receiverData]) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a datagram send with a different receiver address"];
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

@end

void async_link_objfw_ofdatagramsocket_promise_category(void) {}

#pragma clang assume_nonnull end
