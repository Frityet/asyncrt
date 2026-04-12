#import "Async/ObjFWAsync/OFTLSStream+Promise.h"

#pragma clang assume_nonnull begin

@interface AsyncTLSStreamPromiseDelegate : OFObject<OFTLSStreamDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge stream: (OFTLSStream *)stream forwardDelegate: (id<OFTLSStreamDelegate> nillable)forwardDelegate host: (OFString *nillable)host performsClientHandshake: (bool)performsClientHandshake designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;
- (void)_cleanup [[clang::objc_direct]];
+ (Promise<OFTLSStream *> *)promiseHandshakeForStream: (OFTLSStream *)stream
                                                 host: (OFString *nillable)host
                                      clientHandshake: (bool)clientHandshake
                                          onScheduler: (AsyncScheduler *)scheduler
                             cancelOnTaskCancellation: (bool)cancelOnTaskCancellation [[clang::objc_direct]];
- (void)start;
- (void)cancel;

@end

@implementation AsyncTLSStreamPromiseDelegate {
    AsyncObjFWPromiseBridge *_bridge;
    OFTLSStream *_stream;
    id<OFTLSStreamDelegate> nillable _forwardDelegate;
    OFString *nillable _host;
    bool _performsClientHandshake;
    OFMutex *_lock;
    bool _cleanedUp;
}

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge stream: (OFTLSStream *)stream forwardDelegate: (id<OFTLSStreamDelegate> nillable)forwardDelegate host: (OFString *nillable)host performsClientHandshake: (bool)performsClientHandshake
{
    self = [super init];
    _bridge = bridge;
    _stream = stream;
    _forwardDelegate = forwardDelegate;
    _host = [host copy];
    _performsClientHandshake = performsClientHandshake;
    _lock = [OFMutex mutex];
    _cleanedUp = false;
    return self;
}

+ (Promise<OFTLSStream *> *)promiseHandshakeForStream: (OFTLSStream *)stream
                                                 host: (OFString *nillable)host
                                      clientHandshake: (bool)clientHandshake
                                          onScheduler: (AsyncScheduler *)scheduler
                             cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if (clientHandshake and host == nilptr)
        @throw [OFInvalidArgumentException exception];

    id<OFTLSStreamDelegate> forwardDelegate = stream.delegate;
    auto resolver = [[PromiseResolver<OFTLSStream *> alloc] init];
    block_reference AsyncTLSStreamPromiseDelegate *delegate = nilptr;
    auto bridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: stream
              operation: (clientHandshake ? @"asyncPerformClientHandshakeWithHost:" : @"asyncPerformServerHandshake")
              scheduler: scheduler
               resolver: (PromiseResolver<id> *)resolver
             startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
                 delegate = [[AsyncTLSStreamPromiseDelegate alloc]
                     initWithBridge: bridge
                             stream: stream
                    forwardDelegate: forwardDelegate
                               host: host
             performsClientHandshake: clientHandshake];
                 [delegate start];
             }
            cancelBlock: ^(AsyncObjFWPromiseBridge *) {
                [delegate cancel];
            }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.promise cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

- (void)_cleanup
{
    block_reference bool shouldCleanup = false;

    [_lock lock];
    @try {
        shouldCleanup = (not _cleanedUp);
        if (shouldCleanup)
            _cleanedUp = true;
    } @finally {
        [_lock unlock];
    }

    if (shouldCleanup)
        _stream.delegate = _forwardDelegate;
}

- (void)start
{
    _stream.delegate = self;

    @try {
        if (_performsClientHandshake)
            [_stream asyncPerformClientHandshakeWithHost: $assert_nonnil(_host) runLoopMode: _bridge.scheduler.mode];
        else
            [_stream asyncPerformServerHandshakeWithRunLoopMode: _bridge.scheduler.mode];
    } @catch (OFException *exception) {
        [self _cleanup];
        @throw exception;
    }
}

- (void)cancel
{
    [self _cleanup];
    [_stream cancelAsyncRequests];
}

- (bool)stream: (OFStream *)stream didReadIntoBuffer: (void *)buffer length: (size_t)length exception: (id nillable)exception
{
    if ([_forwardDelegate respondsToSelector: @selector(stream:didReadIntoBuffer:length:exception:)])
        return [_forwardDelegate stream: stream didReadIntoBuffer: buffer length: length exception: exception];

    return false;
}

- (bool)stream: (OFStream *)stream didReadString: (OFString *nillable)string exception: (id nillable)exception
{
    if ([_forwardDelegate respondsToSelector: @selector(stream:didReadString:exception:)])
        return [_forwardDelegate stream: stream didReadString: string exception: exception];

    return false;
}

- (bool)stream: (OFStream *)stream didReadLine: (OFString *nillable)line exception: (id nillable)exception
{
    if ([_forwardDelegate respondsToSelector: @selector(stream:didReadLine:exception:)])
        return [_forwardDelegate stream: stream didReadLine: line exception: exception];

    return false;
}

- (OFData *nillable)stream: (OFStream *)stream didWriteData: (OFData *)data bytesWritten: (size_t)bytesWritten exception: (id nillable)exception
{
    if ([_forwardDelegate respondsToSelector: @selector(stream:didWriteData:bytesWritten:exception:)])
        return [_forwardDelegate stream: stream didWriteData: data bytesWritten: bytesWritten exception: exception];

    return nilptr;
}

- (OFString *nillable)stream: (OFStream *)stream didWriteString: (OFString *)string encoding: (OFStringEncoding)encoding bytesWritten: (size_t)bytesWritten exception: (id nillable)exception
{
    if ([_forwardDelegate respondsToSelector: @selector(stream:didWriteString:encoding:bytesWritten:exception:)])
        return [_forwardDelegate stream: stream didWriteString: string encoding: encoding bytesWritten: bytesWritten exception: exception];

    return nilptr;
}

- (void)stream: (OFTLSStream *)stream didPerformClientHandshakeWithHost: (OFString *)host exception: (id nillable)exception
{
    [self _cleanup];

    if (exception != nilptr) {
        [_bridge reject: $as_nonnil((OFException *)exception)];
    } else if (stream != _stream or not [host isEqual: _host]) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW completed a TLS client handshake with mismatched metadata"];
    } else {
        [_bridge resolve: _stream];
    }

    if ([_forwardDelegate respondsToSelector: @selector(stream:didPerformClientHandshakeWithHost:exception:)])
        [_forwardDelegate stream: stream didPerformClientHandshakeWithHost: host exception: exception];
}

- (void)streamDidPerformServerHandshake: (OFTLSStream *)stream exception: (id nillable)exception
{
    [self _cleanup];

    if (exception != nilptr) {
        [_bridge reject: $as_nonnil((OFException *)exception)];
    } else if (stream != _stream) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW completed a TLS server handshake on the wrong stream"];
    } else {
        [_bridge resolve: _stream];
    }

    if ([_forwardDelegate respondsToSelector: @selector(streamDidPerformServerHandshake:exception:)])
        [_forwardDelegate streamDidPerformServerHandshake: stream exception: exception];
}

@end

@implementation OFTLSStream (PromiseAdditions)

- (Promise<OFTLSStream *> *)promiseToPerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToPerformClientHandshakeWithHost: host onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFTLSStream *> *)promiseToPerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncTLSStreamPromiseDelegate
        promiseHandshakeForStream: self
                             host: host
                  clientHandshake: true
                      onScheduler: scheduler
         cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<OFTLSStream *> *)promiseToPerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToPerformServerHandshakeOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFTLSStream *> *)promiseToPerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [AsyncTLSStreamPromiseDelegate
        promiseHandshakeForStream: self
                             host: nilptr
                  clientHandshake: false
                      onScheduler: scheduler
         cancelOnTaskCancellation: cancelOnTaskCancellation];
}

@end

void async_link_objfw_oftlsstream_promise_category(void) {}

#pragma clang assume_nonnull end
