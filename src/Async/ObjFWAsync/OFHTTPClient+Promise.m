#import "Async/AsyncRuntimeInternal.h"
#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

@class AsyncHTTPClientPromiseBridge;

static unsigned int const asyncHTTPDefaultRedirects = 10;
static OFOnceControl asyncHTTPBridgeOnce = OFOnceControlInitValue;
static OFMutex *nillable asyncHTTPBridgeLock;
static OFMutableSet<AsyncHTTPClientPromiseBridge *> *nillable asyncHTTPInflightBridges;

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


static void RetainAsyncHTTPBridge(AsyncHTTPClientPromiseBridge *bridge)
{
    OFOnce(&asyncHTTPBridgeOnce, InitaliseAsyncHTTPBridgeState);

    [asyncHTTPBridgeLock lock];
    @try {
        [asyncHTTPInflightBridges addObject: bridge];
    } @finally {
        [asyncHTTPBridgeLock unlock];
    }
}

static void ReleaseAsyncHTTPBridge(AsyncHTTPClientPromiseBridge *bridge)
{
    OFOnce(&asyncHTTPBridgeOnce, InitaliseAsyncHTTPBridgeState);

    [asyncHTTPBridgeLock lock];
    @try {
        [asyncHTTPInflightBridges removeObject: bridge];
    } @finally {
        [asyncHTTPBridgeLock unlock];
    }
}

@interface AsyncHTTPClientPromiseBridge : OFObject<OFHTTPClientDelegate>

@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) OFObject<OFHTTPClientDelegate> *nillable forwardDelegate;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) unsigned int redirects;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) PromiseResolver<OFHTTPResponse *> *resolver;

- (instancetype)initWithClient: (OFHTTPClient *)client forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate request: (OFHTTPRequest *)request redirects: (unsigned int)redirects scheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<OFHTTPResponse *> *)resolver OF_DESIGNATED_INITIALIZER;
- (void)start;
- (void)cancel;

@end

@implementation PromiseHTTPClientInvalidCompletionException

- (instancetype)initWithPromise: (Promise *)future client: (OFHTTPClient *)client request: (OFHTTPRequest *)request reason: (OFString *)reason
{
    self = [super initWithPromise: future];
    _client = client;
    _request = request;
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseHTTPClientInvalidCompletionException: %@ received an invalid completion for request %@ on %@: %@", DescribePromise(self.future), self.request, self.client, self.reason];
}

@end

@implementation PromiseHTTPClientCancelledException

@synthesize request = _request;

- (instancetype)initWithPromise: (Promise *)future request: (OFHTTPRequest *)request
{
    self = [super initWithPromise: future];
    _request = request;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"PromiseHTTPClientCancelledException: %@ cancelled request %@", DescribePromise(self.future), self.request];
}

@end

@implementation AsyncHTTPClientPromiseBridge {
    OFMutex *_lock;
    bool _completed, _started, _cleanedUp;
}

- (instancetype)initWithClient: (OFHTTPClient *)client forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate request: (OFHTTPRequest *)request redirects: (unsigned int)redirects scheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<OFHTTPResponse *> *)resolver
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
    } @catch (OFException *) {
    }

    ReleaseAsyncHTTPBridge(self);
}

- (void)_finishWithResponse: (OFHTTPResponse *nillable)response exception: (OFException *nillable)exception
{
    [[clang::objc_precise_lifetime]] AsyncHTTPClientPromiseBridge *retainedSelf = self;
    (void)retainedSelf;

    @try {
        if ([self _markCompletedOnce]) {
            if (response != nilptr) {
                [_resolver resolve: $assert_nonnil(response)];
            } else if (exception != nilptr) {
                [_resolver reject: $assert_nonnil(exception)];
            } else {
                [_resolver reject: [[PromiseHTTPClientInvalidCompletionException alloc] initWithPromise: _resolver.future client: _client request: _request reason: @"ObjFW completed the request without a response or exception"]];
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
    [[clang::objc_precise_lifetime]] AsyncHTTPClientPromiseBridge *retainedSelf = self;
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
    [[clang::objc_precise_lifetime]] AsyncHTTPClientPromiseBridge *retainedSelf = self;
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

    [_resolver reject: [[PromiseHTTPClientCancelledException alloc] initWithPromise: _resolver.future request: _request]];

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

@implementation OFHTTPClient (PromiseAdditions)

- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToPerformRequest: request redirects: asyncHTTPDefaultRedirects onScheduler: scheduler cancelOnTaskCancellation: true];
}

- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToPerformRequest: request redirects: redirects onScheduler: scheduler cancelOnTaskCancellation: true];
}

- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto client = [[OFHTTPClient alloc] init];
    client.allowsInsecureRedirects = self.allowsInsecureRedirects;

    auto bridge = [[AsyncHTTPClientPromiseBridge alloc] initWithClient: client forwardDelegate: self.delegate request: request redirects: redirects scheduler: scheduler resolver: resolver];
    auto fireDate = [[OFDate alloc] initWithTimeIntervalSinceNow: 0];
    auto timer = [[OFTimer alloc] initWithFireDate: fireDate interval: 0 target: bridge selector: @selector(start) repeats: false];

    RetainAsyncHTTPBridge(bridge);

    if (cancelOnTaskCancellation)
        [resolver.future _setPendingCancellationCallback: ^{ [bridge cancel]; }];

    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return resolver.future;
}

@end

void async_link_objfw_ofhttpclient_promise_category(void) {}

#pragma clang assume_nonnull end
