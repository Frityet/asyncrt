#import "Async/ObjFWAsync/OFTLSStream+Future.h"

#pragma clang assume_nonnull begin

@interface AsyncTLSStreamFutureDelegate : OFObject<OFTLSStreamDelegate>

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge stream: (OFTLSStream *)stream forwardDelegate: (id<OFTLSStreamDelegate> nillable)forwardDelegate host: (OFString *nillable)host performsClientHandshake: (bool)performsClientHandshake OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;

@end

@implementation AsyncTLSStreamFutureDelegate {
    AsyncObjFWFutureBridge *_bridge;
    OFTLSStream *_stream;
    id<OFTLSStreamDelegate> nillable _forwardDelegate;
    OFString *nillable _host;
    bool _performsClientHandshake;
    OFMutex *_lock;
    bool _cleanedUp;
}

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge stream: (OFTLSStream *)stream forwardDelegate: (id<OFTLSStreamDelegate> nillable)forwardDelegate host: (OFString *nillable)host performsClientHandshake: (bool)performsClientHandshake
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

- (void)_cleanup
{
    block_reference bool shouldCleanup = false;

    [_lock scopedLock: ^{
        shouldCleanup = (not _cleanedUp);
        if (shouldCleanup)
            _cleanedUp = true;
    }];

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
        [_bridge reject: (OFException *)exception];
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
        [_bridge reject: (OFException *)exception];
    } else if (stream != _stream) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW completed a TLS server handshake on the wrong stream"];
    } else {
        [_bridge resolve: _stream];
    }

    if ([_forwardDelegate respondsToSelector: @selector(streamDidPerformServerHandshake:exception:)])
        [_forwardDelegate streamDidPerformServerHandshake: stream exception: exception];
}

@end

static Future<OFTLSStream *> *FutureTLSHandshake(OFTLSStream *stream, OFString *nillable host, bool clientHandshake, AsyncScheduler *scheduler, bool cancelOnTaskCancellation)
{
    if ((OFTLSStream *nillable)stream == nilptr or (AsyncScheduler *nillable)scheduler == nilptr or (clientHandshake and (OFString *nillable)host == nilptr))
        @throw [OFInvalidArgumentException exception];

    id<OFTLSStreamDelegate> forwardDelegate = stream.delegate;
    FutureResolver<OFTLSStream *> *resolver = [[FutureResolver alloc] init];
    block_reference AsyncTLSStreamFutureDelegate *delegate = nilptr;
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: stream operation: (clientHandshake ? @"asyncPerformClientHandshakeWithHost:" : @"asyncPerformServerHandshake") scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        delegate = [[AsyncTLSStreamFutureDelegate alloc] initWithBridge: bridge stream: stream forwardDelegate: forwardDelegate host: host performsClientHandshake: clientHandshake];
        [delegate start];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [delegate cancel];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@implementation OFTLSStream (FutureAdditions)

- (Future<OFTLSStream *> *)futurePerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler
{
    return [self futurePerformClientHandshakeWithHost: host onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFTLSStream *> *)futurePerformClientHandshakeWithHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureTLSHandshake(self, host, true, scheduler, cancelOnTaskCancellation);
}

- (Future<OFTLSStream *> *)futurePerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler
{
    return [self futurePerformServerHandshakeOnScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFTLSStream *> *)futurePerformServerHandshakeOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return FutureTLSHandshake(self, nilptr, false, scheduler, cancelOnTaskCancellation);
}

@end

void async_link_objfw_oftlsstream_future_category(void) {}

#pragma clang assume_nonnull end
