#import "Utilities/common.h"

#ifdef OF_HAVE_SCTP

#import "Async/ObjFWAsync/OFSCTPSocket+Promise.h"

#pragma clang assume_nonnull begin

@implementation OFSCTPSocket (PromiseAdditions)

- (Promise<OFSCTPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToConnectToHost: host port: port onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFSCTPSocket *> *)promiseToConnectToHost: (OFString *)host port: (uint16_t)port onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    OFString *expectedHost = [host copy];
    auto resolver = [[PromiseResolver<OFSCTPSocket *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncConnectToHost:port:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncConnectToHost: expectedHost port: port runLoopMode: scheduler.mode handler: ^(OFSCTPSocket *socket, OFString *callbackHost, uint16_t callbackPort, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return;
            }
            if (socket != self or not [callbackHost isEqual: expectedHost] or callbackPort != port) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP connect with mismatched connection metadata"];
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

- (Promise<AsyncSCTPReceiveResult *> *)promiseToReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReceiveWithInfoIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncSCTPReceiveResult *> *)promiseToReceiveWithInfoIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncSCTPReceiveResult *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncReceiveWithInfoIntoBuffer:length:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncReceiveWithInfoIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: ^bool(OFSCTPSocket *, void *callbackBuffer, size_t callbackLength, OFSCTPMessageInfo nillable info, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP receive with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncSCTPReceiveResult alloc] initWithBuffer: buffer length: callbackLength info: info]];
            return false;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToSendData: data info: info onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToSendData: (OFData *)data info: (OFSCTPMessageInfo nillable)info onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    OFSCTPMessageInfo copiedInfo = [info copy];
    auto resolver = [[PromiseResolver<AsyncUnit *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncSendData:info:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [self asyncSendData: data info: copiedInfo runLoopMode: scheduler.mode handler: ^OFData *nillable(OFSCTPSocket *, OFData *, OFSCTPMessageInfo nillable callbackInfo, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return nilptr;
            }
            if ((copiedInfo == nilptr and callbackInfo != nilptr) or (copiedInfo != nilptr and not [callbackInfo isEqual: copiedInfo])) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed an SCTP send with mismatched message info"];
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

#pragma clang assume_nonnull end

#endif

void async_link_objfw_ofsctpsocket_promise_category(void) {}
