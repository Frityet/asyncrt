#import "Async/ObjFWAsync/OFStream+Future.h"

#pragma clang assume_nonnull begin

static Future<AsyncBufferReadResult *> *FutureReadStream(OFStream *stream, void *buffer, size_t length, bool exactLength, AsyncScheduler *scheduler, bool cancelOnTaskCancellation)
{
    if ((OFStream *nillable)stream == nilptr or (void *nillable)buffer == nullptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncBufferReadResult *> *resolver = [[FutureResolver alloc] init];
    OFString *operation = (exactLength ? @"asyncReadIntoBuffer:exactLength:" : @"asyncReadIntoBuffer:length:");
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: stream operation: operation scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        OFStreamReadHandler handler = ^bool(OFStream *callbackStream, void *callbackBuffer, size_t callbackLength, id nillable exception) {
            (void)callbackStream;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }
            if (callbackBuffer != buffer) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a stream read with a different buffer pointer"];
                return false;
            }

            [bridge resolve: [[AsyncBufferReadResult alloc] initWithBuffer: buffer length: callbackLength]];
            return false;
        };

        if (exactLength) {
            [stream asyncReadIntoBuffer: buffer exactLength: length runLoopMode: scheduler.mode handler: handler];
        } else {
            [stream asyncReadIntoBuffer: buffer length: length runLoopMode: scheduler.mode handler: handler];
        }
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

static Future<Optional<OFString *> *> *FutureReadStringLike(OFStream *stream, OFStringEncoding encoding, bool line, AsyncScheduler *scheduler, bool cancelOnTaskCancellation)
{
    if ((OFStream *nillable)stream == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<Optional<OFString *> *> *resolver = [[FutureResolver alloc] init];
    OFString *operation = (line ? @"asyncReadLineWithEncoding:" : @"asyncReadStringWithEncoding:");
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: stream operation: operation scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        OFStreamStringReadHandler handler = ^bool(OFStream *callbackStream, OFString *nillable string, id nillable exception) {
            (void)callbackStream;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return false;
            }

            [bridge resolve: [Optional<OFString *> fromNillable: string]];

            return false;
        };

        if (line)
            [stream asyncReadLineWithEncoding: encoding runLoopMode: scheduler.mode handler: handler];
        else
            [stream asyncReadStringWithEncoding: encoding runLoopMode: scheduler.mode handler: handler];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

static Future<AsyncUnit *> *FutureWriteStreamData(OFStream *stream, OFData *data, AsyncScheduler *scheduler, bool cancelOnTaskCancellation)
{
    if ((OFStream *nillable)stream == nilptr or (OFData *nillable)data == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<AsyncUnit *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: stream operation: @"asyncWriteData:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [stream asyncWriteData: data runLoopMode: scheduler.mode handler: ^OFData *nillable(OFStream *callbackStream, OFData *callbackData, size_t bytesWritten, id nillable exception) {
            (void)callbackStream;
            (void)callbackData;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return nilptr;
            }
            if (bytesWritten != data.count * data.itemSize) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW reported a partial data write without an exception"];
                return nilptr;
            }

            [bridge resolve: AsyncUnit.unit];
            return nilptr;
        }];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

static Future<AsyncUnit *> *FutureWriteStreamString(OFStream *stream, OFString *string, OFStringEncoding encoding, AsyncScheduler *scheduler, bool cancelOnTaskCancellation)
{
    if ((OFStream *nillable)stream == nilptr or (OFString *nillable)string == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    size_t expectedLength = [string cStringLengthWithEncoding: encoding];
    FutureResolver<AsyncUnit *> *resolver = [[FutureResolver alloc] init];
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: stream operation: @"asyncWriteString:encoding:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        [stream asyncWriteString: string encoding: encoding runLoopMode: scheduler.mode handler: ^OFString *nillable(OFStream *callbackStream, OFString *callbackString, OFStringEncoding callbackEncoding, size_t bytesWritten, id nillable exception) {
            (void)callbackStream;
            (void)callbackString;

            if (exception != nilptr) {
                [bridge reject: (OFException *)exception];
                return nilptr;
            }
            if (callbackEncoding != encoding) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW completed a string write with a different encoding"];
                return nilptr;
            }
            if (bytesWritten != expectedLength) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW reported a partial string write without an exception"];
                return nilptr;
            }

            [bridge resolve: AsyncUnit.unit];
            return nilptr;
        }];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@implementation OFStream (FutureAdditions)

- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureReadStream(self, buffer, length, false, scheduler, cancelOnTaskCancellation);
}

- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadIntoBuffer: buffer exactLength: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureReadStream(self, buffer, length, true, scheduler, cancelOnTaskCancellation);
}

- (Future<Optional<OFString *> *> *)futureReadStringOnScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadStringOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<Optional<OFString *> *> *)futureReadStringOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self futureReadStringWithEncoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Future<Optional<OFString *> *> *)futureReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadStringWithEncoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<Optional<OFString *> *> *)futureReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureReadStringLike(self, encoding, false, scheduler, cancelOnTaskCancellation);
}

- (Future<Optional<OFString *> *> *)futureReadLineOnScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadLineOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<Optional<OFString *> *> *)futureReadLineOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self futureReadLineWithEncoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Future<Optional<OFString *> *> *)futureReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureReadLineWithEncoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<Optional<OFString *> *> *)futureReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureReadStringLike(self, encoding, true, scheduler, cancelOnTaskCancellation);
}

- (Future<AsyncUnit *> *)futureWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureWriteData: data onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureWriteStreamData(self, data, scheduler, cancelOnTaskCancellation);
}

- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureWriteString: string onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self futureWriteString: string encoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureWriteString: string encoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureWriteStreamString(self, string, encoding, scheduler, cancelOnTaskCancellation);
}

@end

void async_link_objfw_ofstream_future_category(void) {}

#pragma clang assume_nonnull end
