#import "Async/ObjFWAsync/OFStream+Promise.h"

#pragma clang assume_nonnull begin

@namespace(AsyncObjFWStreamPromiseSupport)

+ (Promise<AsyncBufferReadResult *> *)readStream: (OFStream *)stream
                                      intoBuffer: (void *)buffer
                                          length: (size_t)length
                                     exactLength: (bool)exactLength
                                     onScheduler: (AsyncScheduler *)scheduler
                         cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
+ (Promise<Optional<OFString *> *> *)readStringFromStream: (OFStream *)stream
                                                 encoding: (OFStringEncoding)encoding
                                                     line: (bool)line
                                              onScheduler: (AsyncScheduler *)scheduler
                                  cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
+ (Promise<AsyncUnit *> *)writeData: (OFData *)data
                                to: (OFStream *)stream
                       onScheduler: (AsyncScheduler *)scheduler
           cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
+ (Promise<AsyncUnit *> *)writeString: (OFString *)string
                                   to: (OFStream *)stream
                             encoding: (OFStringEncoding)encoding
                          onScheduler: (AsyncScheduler *)scheduler
              cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

@namespace_implementation(AsyncObjFWStreamPromiseSupport)

+ (Promise<AsyncBufferReadResult *> *)readStream: (OFStream *)stream
                                      intoBuffer: (void *)buffer
                                          length: (size_t)length
                                     exactLength: (bool)exactLength
                                     onScheduler: (AsyncScheduler *)scheduler
                         cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncBufferReadResult *> alloc] init];
    OFString *operation = (exactLength ? @"asyncReadIntoBuffer:exactLength:" : @"asyncReadIntoBuffer:length:");
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: stream operation: operation scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        OFStreamReadHandler handler = ^bool(OFStream *, void *callbackBuffer, size_t callbackLength, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
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
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

+ (Promise<Optional<OFString *> *> *)readStringFromStream: (OFStream *)stream
                                                 encoding: (OFStringEncoding)encoding
                                                     line: (bool)line
                                              onScheduler: (AsyncScheduler *)scheduler
                                  cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<Optional<OFString *> *> alloc] init];
    OFString *operation = (line ? @"asyncReadLineWithEncoding:" : @"asyncReadStringWithEncoding:");
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: stream operation: operation scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        OFStreamStringReadHandler handler = ^bool(OFStream *, OFString *nillable string, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return false;
            }

            [bridge resolve: [Optional<OFString *> fromNillable: string]];

            return false;
        };

        if (line)
            [stream asyncReadLineWithEncoding: encoding runLoopMode: scheduler.mode handler: handler];
        else
            [stream asyncReadStringWithEncoding: encoding runLoopMode: scheduler.mode handler: handler];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

+ (Promise<AsyncUnit *> *)writeData: (OFData *)data
                                to: (OFStream *)stream
                       onScheduler: (AsyncScheduler *)scheduler
           cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<AsyncUnit *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: stream operation: @"asyncWriteData:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [stream asyncWriteData: data runLoopMode: scheduler.mode handler: ^OFData *nillable(OFStream *, OFData *, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
                return nilptr;
            }
            if (bytesWritten != data.count * data.itemSize) {
                [bridge rejectInvalidCompletionWithReason: @"ObjFW reported a partial data write without an exception"];
                return nilptr;
            }

            [bridge resolve: AsyncUnit.unit];
            return nilptr;
        }];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

+ (Promise<AsyncUnit *> *)writeString: (OFString *)string
                                   to: (OFStream *)stream
                             encoding: (OFStringEncoding)encoding
                          onScheduler: (AsyncScheduler *)scheduler
              cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    size_t expectedLength = [string cStringLengthWithEncoding: encoding];
    auto resolver = [[PromiseResolver<AsyncUnit *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: stream operation: @"asyncWriteString:encoding:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        [stream asyncWriteString: string encoding: encoding runLoopMode: scheduler.mode handler: ^OFString *nillable(OFStream *, OFString *, OFStringEncoding callbackEncoding, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr) {
                [bridge reject: $as_nonnil((OFException *)exception)];
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
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [stream cancelAsyncRequests];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

@end

@implementation OFStream (PromiseAdditions)

- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadIntoBuffer: buffer length: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport readStream: self
                                           intoBuffer: buffer
                                               length: length
                                          exactLength: false
                                          onScheduler: scheduler
                              cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadIntoBuffer: buffer exactLength: length onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport readStream: self
                                           intoBuffer: buffer
                                               length: length
                                          exactLength: true
                                          onScheduler: scheduler
                              cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<Optional<OFString *> *> *)promiseToReadStringOnScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadStringOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<Optional<OFString *> *> *)promiseToReadStringOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self promiseToReadStringWithEncoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<Optional<OFString *> *> *)promiseToReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadStringWithEncoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<Optional<OFString *> *> *)promiseToReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport readStringFromStream: self
                                                       encoding: encoding
                                                           line: false
                                                    onScheduler: scheduler
                                        cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<Optional<OFString *> *> *)promiseToReadLineOnScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadLineOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<Optional<OFString *> *> *)promiseToReadLineOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self promiseToReadLineWithEncoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<Optional<OFString *> *> *)promiseToReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToReadLineWithEncoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<Optional<OFString *> *> *)promiseToReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport readStringFromStream: self
                                                       encoding: encoding
                                                           line: true
                                                    onScheduler: scheduler
                                        cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<AsyncUnit *> *)promiseToWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToWriteData: data onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport writeData: data
                                                  to: self
                                         onScheduler: scheduler
                             cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToWriteString: string onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self promiseToWriteString: string encoding: self.encoding onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToWriteString: string encoding: encoding onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncObjFWStreamPromiseSupport writeString: string
                                                    to: self
                                              encoding: encoding
                                           onScheduler: scheduler
                               cancelOnTaskCancellation: cancelOnTaskCancellation];
}

@end

void async_link_objfw_ofstream_promise_category(void) {}

#pragma clang assume_nonnull end
