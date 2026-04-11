#import "Utilities/common.h"

#ifdef OF_HAVE_SCTP

#import "Async/ObjFWAsync/OFSCTPSocket+Future.h"

#pragma clang assume_nonnull begin

@implementation OFSCTPSocket (FutureAdditions)

- (Future<OFSCTPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureConnectToHost: host port: port onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFSCTPSocket *> *)futureConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSCTPSocket *nillable)self == nilptr or (OFString *nillable)host == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    OFString *expectedHost = [host copy];
    FutureResolver<OFSCTPSocket *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncConnectToHost:port:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncConnectToHost: expectedHost port: port runLoopMode: scheduler.mode handler: ^(OFSCTPSocket *socket, OFString *callbackHost, uint16_t callbackPort, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return;
            }
            if (socket != self or not [callbackHost isEqual: expectedHost] or callbackPort != port) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP connect with mismatched connection metadata"];
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

- (Future<AsyncSCTPReceiveResult *> *)futureReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReceiveWithInfoIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncSCTPReceiveResult *> *)futureReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSCTPSocket *nillable)self == nilptr or (void *nillable)buffer == nullptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncSCTPReceiveResult *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncReceiveWithInfoIntoBuffer:length:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncReceiveWithInfoIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFSCTPSocket *socket, void *callbackBuffer, size_t callbackLength, OFSCTPMessageInfo nillable info, id nillable exception) {
            (void)socket;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncSCTPReceiveResult alloc] initWithBuffer: buffer length: callbackLength info: info]];
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

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureSendData: data info: info onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFSCTPSocket *nillable)self == nilptr or (OFData *nillable)data == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    OFSCTPMessageInfo copiedInfo = [info copy];
    FutureResolver<AsyncUnit *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncSendData:info:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [self asyncSendData: data info: copiedInfo runLoopMode: scheduler.mode handler: ^OFData *nillable(OFSCTPSocket *socket, OFData *callbackData, OFSCTPMessageInfo nillable callbackInfo, id nillable exception) {
            (void)socket;
            (void)callbackData;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return nilptr;
            }
            if ((copiedInfo == nilptr and callbackInfo != nilptr) or (copiedInfo != nilptr and not [callbackInfo isEqual: copiedInfo])) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP send with mismatched message info"];
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

#pragma clang assume_nonnull end

#endif

void async_link_objfw_ofsctpsocket_future_category(void) {}
