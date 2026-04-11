#import "Async/AsyncRuntimeInternal.h"
#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

@class AsyncHTTPClientFutureBridge;

static unsigned int const asyncHTTPDefaultRedirects = 10;
static OFOnceControl asyncHTTPBridgeOnce = OFOnceControlInitValue;
static OFMutex *nillable asyncHTTPBridgeLock;
static OFMutableSet<AsyncHTTPClientFutureBridge *> *nillable asyncHTTPInflightBridges;

[[gnu::constructor]]
static void AsyncEnsureObjFWBindingsLoaded(void)
{
    /*
     * Force a symbol reference into libobjfwtls.a so static links keep the
     * TLS backend object and its +load hook can register OFTLSStream.
     */
    volatile int objfwTLSReference = _ObjFWTLS_reference;
    (void)objfwTLSReference;
}


static void InitaliseAsyncHTTPBridgeState(void)
{
    asyncHTTPBridgeLock = [OFMutex mutex];
    asyncHTTPInflightBridges = [OFMutableSet set];
}


static void RetainAsyncHTTPBridge(AsyncHTTPClientFutureBridge *bridge)
{
    OFOnce(&asyncHTTPBridgeOnce, InitaliseAsyncHTTPBridgeState);

    [asyncHTTPBridgeLock lock];
    @try {
        [asyncHTTPInflightBridges addObject: bridge];
    } @finally {
        [asyncHTTPBridgeLock unlock];
    }
}

static void ReleaseAsyncHTTPBridge(AsyncHTTPClientFutureBridge *bridge)
{
    OFOnce(&asyncHTTPBridgeOnce, InitaliseAsyncHTTPBridgeState);

    [asyncHTTPBridgeLock lock];
    @try {
        [asyncHTTPInflightBridges removeObject: bridge];
    } @finally {
        [asyncHTTPBridgeLock unlock];
    }
}

@interface AsyncHTTPClientFutureBridge : OFObject<OFHTTPClientDelegate>

@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) OFObject<OFHTTPClientDelegate> *nillable forwardDelegate;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) unsigned int redirects;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) FutureResolver<OFHTTPResponse *> *resolver;

- (instancetype)initWithClient: (OFHTTPClient *)client forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate request: (OFHTTPRequest *)request redirects: (unsigned int)redirects scheduler: (AsyncScheduler *)scheduler resolver: (FutureResolver<OFHTTPResponse *> *)resolver OF_DESIGNATED_INITIALIZER;
- (void)start;
- (void)cancel;

@end

@implementation FutureHTTPClientInvalidCompletionException

- (instancetype)initWithFuture: (Future *)future client: (OFHTTPClient *)client request: (OFHTTPRequest *)request reason: (OFString *)reason
{
    self = [super initWithFuture: future];
    _client = client;
    _request = request;
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureHTTPClientInvalidCompletionException: %@ received an invalid completion for request %@ on %@: %@", DescribeFuture(self.future), self.request, self.client, self.reason];
}

@end

@implementation FutureHTTPClientCancelledException

@synthesize request = _request;

- (instancetype)initWithFuture: (Future *)future request: (OFHTTPRequest *)request
{
    self = [super initWithFuture: future];
    _request = request;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureHTTPClientCancelledException: %@ cancelled request %@", DescribeFuture(self.future), self.request];
}

@end

@implementation AsyncHTTPClientFutureBridge {
    OFMutex *_lock;
    bool _completed, _started, _cleanedUp;
}

- (instancetype)initWithClient: (OFHTTPClient *)client forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate request: (OFHTTPRequest *)request redirects: (unsigned int)redirects scheduler: (AsyncScheduler *)scheduler resolver: (FutureResolver<OFHTTPResponse *> *)resolver
{
    self = [super init];
    _client = client;
    _forwardDelegate = forwardDelegate;
    _request = request;
    _redirects = redirects;
    _scheduler = scheduler;
    _resolver = resolver;
    _lock = [OFMutex mutex];
    _completed = false;
    _started = false;
    _cleanedUp = false;
    return self;
}

- (bool)_markCompletedOnce
{
    block_reference bool shouldComplete;
    [_lock scopedLock: ^{
        shouldComplete = (not _completed);
        if (shouldComplete)
            _completed = true;
    }];

    return shouldComplete;
}

- (bool)_markCleanupOnce
{
    block_reference bool shouldCleanup;

    [_lock scopedLock: ^{
        shouldCleanup = (not _cleanedUp);
        if (shouldCleanup)
            _cleanedUp = true;
    }];

    return shouldCleanup;
}

- (void)_cleanup
{
    if (not [self _markCleanupOnce])
        return;

    _client.delegate = nilptr;

    @try {
        [_client close];
    } @catch (OFException *unusedException) {
        (void)unusedException;
    }

    ReleaseAsyncHTTPBridge(self);
}

- (void)_finishWithResponse: (OFHTTPResponse *nillable)response exception: (OFException *nillable)exception
{
    [[clang::objc_precise_lifetime]] AsyncHTTPClientFutureBridge *retainedSelf = self;
    (void)retainedSelf;

    @try {
        if ([self _markCompletedOnce]) {
            if (response != nilptr) {
                [_resolver resolve: $assert_nonnil(response)];
            } else if (exception != nilptr) {
                [_resolver reject: $assert_nonnil(exception)];
            } else {
                [_resolver reject: [[FutureHTTPClientInvalidCompletionException alloc] initWithFuture: _resolver.future client: _client request: _request reason: @"ObjFW completed the request without a response or exception"]];
            }

            if (_forwardDelegate != nilptr)
                [_forwardDelegate client: _client didPerformRequest: _request response: response exception: exception];
        }
    } @finally {
        [self _cleanup];
    }
}

- (void)start
{
    [[clang::objc_precise_lifetime]] AsyncHTTPClientFutureBridge *retainedSelf = self;
    (void)retainedSelf;
    block_reference bool shouldStart = false;

    [_lock scopedLock: ^{
        if (not _completed) {
            _started = true;
            shouldStart = true;
        }
    }];

    if (not shouldStart) {
        [self _cleanup];
        return;
    }

    @try {
        _client.delegate = self;
        [_client asyncPerformRequest: _request redirects: _redirects runLoopMode: _scheduler.mode];
    } @catch (OFException *exception) {
        [self _finishWithResponse: nilptr exception: exception];
    }
}

- (void)cancel
{
    [[clang::objc_precise_lifetime]] AsyncHTTPClientFutureBridge *retainedSelf = self;
    (void)retainedSelf;
    block_reference bool shouldReject = false;
    block_reference bool started = false;

    [_lock scopedLock: ^{
        if (not _completed) {
            _completed = true;
            shouldReject = true;
            started = _started;
        }
    }];

    if (not shouldReject)
        return;

    [_resolver reject: [[FutureHTTPClientCancelledException alloc] initWithFuture: _resolver.future request: _request]];

    if (not started)
        [self _cleanup];
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
           response: (OFHTTPResponse *nillable)response
          exception: (id nillable)exception
{
    (void)client;
    (void)request;
    [self _finishWithResponse: response exception: (OFException *nillable)exception];
}

-   (void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
             request: (OFHTTPRequest *)request
{
    if ([_forwardDelegate respondsToSelector: @selector(client:didCreateTCPSocket:request:)])
        [_forwardDelegate client: client didCreateTCPSocket: TCPSocket request: request];
}

-   (void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
             request: (OFHTTPRequest *)request
{
    if ([_forwardDelegate respondsToSelector: @selector(client:didCreateTLSStream:request:)])
        [_forwardDelegate client: client didCreateTLSStream: TLSStream request: request];
}

-      (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)requestBody
           request: (OFHTTPRequest *)request
{
    if ([_forwardDelegate respondsToSelector: @selector(client:wantsRequestBody:request:)])
        [_forwardDelegate client: client wantsRequestBody: requestBody request: request];
}

-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers
         statusCode: (short)statusCode
            request: (OFHTTPRequest *)request
{
    if ([_forwardDelegate respondsToSelector: @selector(client:didReceiveHeaders:statusCode:request:)])
        [_forwardDelegate client: client didReceiveHeaders: headers statusCode: statusCode request: request];
}

-       (bool)client: (OFHTTPClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)IRI
                 statusCode: (short)statusCode
                    request: (OFHTTPRequest *)request
                   response: (OFHTTPResponse *)response
{
    if ([_forwardDelegate respondsToSelector: @selector(client:shouldFollowRedirectToIRI:statusCode:request:response:)])
        return [_forwardDelegate client: client shouldFollowRedirectToIRI: IRI statusCode: statusCode request: request response: response];

    if (request.method == OFHTTPRequestMethodGet or request.method == OFHTTPRequestMethodHead)
        return true;

    return (statusCode == 303);
}

@end

@implementation OFHTTPClient (FutureAdditions)

- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request onScheduler: (AsyncScheduler *)scheduler
{
    return [self futurePerformRequest: request redirects: asyncHTTPDefaultRedirects onScheduler: scheduler cancelOnTaskCancellation: true];
}

- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler
{
    return [self futurePerformRequest: request redirects: redirects onScheduler: scheduler cancelOnTaskCancellation: true];
}

- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFHTTPRequest *nillable)request == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<OFHTTPResponse *> *resolver = [[FutureResolver alloc] init];
    OFHTTPClient *client = [[OFHTTPClient alloc] init];
    client.allowsInsecureRedirects = self.allowsInsecureRedirects;

    AsyncHTTPClientFutureBridge *bridge = [[AsyncHTTPClientFutureBridge alloc] initWithClient: client forwardDelegate: self.delegate request: request redirects: redirects scheduler: scheduler resolver: resolver];
    OFDate *fireDate = [[OFDate alloc] initWithTimeIntervalSinceNow: 0];
    OFTimer *timer = [[OFTimer alloc] initWithFireDate: fireDate interval: 0 target: bridge selector: @selector(start) repeats: false];

    RetainAsyncHTTPBridge(bridge);

    if (cancelOnTaskCancellation)
        [resolver.future _setPendingCancellationCallback: ^{ [bridge cancel]; }];

    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return resolver.future;
}

@end

void async_link_objfw_ofhttpclient_future_category(void) {}

#pragma clang assume_nonnull end
