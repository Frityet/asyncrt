#import <AsyncRT/Networking/HTTP/AsyncHTTPClient.h>

#pragma clang assume_nonnull begin

extern int _ObjFWTLS_reference;

static unsigned int const AsyncHTTPClientDefaultRedirects = 10;
static OFOnceControl async_http_client_bridge_once = OFOnceControlInitValue;
static OFMutex *nillable async_http_client_bridge_lock;
static OFMutableSet<id> *nillable async_http_client_bridge_inflight_bridges;

[[gnu::constructor]]
static void AsyncHTTPClientEnsureObjFWTLSBindingsLoaded(void)
{
    volatile int objfwTLSReference = _ObjFWTLS_reference;
    (void)objfwTLSReference;
}

static void AsyncHTTPClientInitialiseState(void)
{
    async_http_client_bridge_lock = [OFMutex mutex];
    async_http_client_bridge_inflight_bridges = [OFMutableSet set];
}

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPClientTaskBridge : OFObject <OFHTTPClientDelegate>

@property(readonly, nonatomic) OFHTTPClient *requestClient;
@property(readonly, nonatomic) OFObject<OFHTTPClientDelegate> *nillable forwardDelegate;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) unsigned int redirects;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncCompletionSource<OFHTTPResponse *> *completionSource;

- (instancetype)initWithRequestClient: (OFHTTPClient *)requestClient
                      forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate
                              request: (OFHTTPRequest *)request
                            redirects: (unsigned int)redirects
                            scheduler: (AsyncScheduler *)scheduler
                     completionSource: (AsyncCompletionSource<OFHTTPResponse *> *)completionSource [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;
+ (void)retainInflightBridge: (AsyncHTTPClientTaskBridge *)bridge;
+ (void)releaseInflightBridge: (AsyncHTTPClientTaskBridge *)bridge;

@end

@implementation AsyncHTTPRequestCancelledException

- (instancetype)initWithRequest: (OFHTTPRequest *)request
{
    self = [super init];
    _request = request;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncHTTPRequestCancelledException: cancelled request %@", self.request.IRI];
}

@end

@implementation AsyncHTTPClientException

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncHTTPClientException: %@", self.reason];
}

@end

@implementation AsyncHTTPClientTaskBridge {
    OFMutex *_lock;
    bool _didComplete;
    bool _didCleanup;
}

+ (void)retainInflightBridge: (AsyncHTTPClientTaskBridge *)bridge
{
    OFOnce(&async_http_client_bridge_once, AsyncHTTPClientInitialiseState);

    [async_http_client_bridge_lock lock];
    @try {
        [async_http_client_bridge_inflight_bridges addObject: bridge];
    } @finally {
        [async_http_client_bridge_lock unlock];
    }
}

+ (void)releaseInflightBridge: (AsyncHTTPClientTaskBridge *)bridge
{
    OFOnce(&async_http_client_bridge_once, AsyncHTTPClientInitialiseState);

    [async_http_client_bridge_lock lock];
    @try {
        [async_http_client_bridge_inflight_bridges removeObject: bridge];
    } @finally {
        [async_http_client_bridge_lock unlock];
    }
}

- (instancetype)initWithRequestClient: (OFHTTPClient *)requestClient
                      forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate
                              request: (OFHTTPRequest *)request
                            redirects: (unsigned int)redirects
                            scheduler: (AsyncScheduler *)scheduler
                     completionSource: (AsyncCompletionSource<OFHTTPResponse *> *)completionSource
{
    self = [super init];
    _requestClient = requestClient;
    _forwardDelegate = forwardDelegate;
    _request = request;
    _redirects = redirects;
    _scheduler = scheduler;
    _completionSource = completionSource;
    _lock = [OFMutex mutex];
    _didComplete = false;
    _didCleanup = false;
    return self;
}

- (bool)_markCompletedOnce
{
    block_reference bool shouldComplete;

    [_lock lock];
    @try {
        shouldComplete = not _didComplete;
        if (shouldComplete)
            _didComplete = true;
    } @finally {
        [_lock unlock];
    }

    return shouldComplete;
}

- (bool)_markCleanupOnce
{
    block_reference bool shouldCleanup;

    [_lock lock];
    @try {
        shouldCleanup = not _didCleanup;
        if (shouldCleanup)
            _didCleanup = true;
    } @finally {
        [_lock unlock];
    }

    return shouldCleanup;
}

- (OFException *)_exceptionFromCallbackException: (id)exception
{
    if ([exception isKindOfClass: OFException.class])
        return (OFException *)exception;

    return [[AsyncHTTPClientException alloc] initWithReason: @"AsyncHTTP client failed with a non-OFException value"];
}

- (void)_cleanup
{
    if (not [self _markCleanupOnce])
        return;

    [self _restoreForwardDelegate];
    [AsyncHTTPClientTaskBridge releaseInflightBridge: self];
}

- (void)_restoreForwardDelegate
{
    if (_requestClient.delegate == self)
        _requestClient.delegate = _forwardDelegate;
}

- (void)_finishWithResponse: (OFHTTPResponse *nillable)response exception: (id nillable)exception
{
    if (not [self _markCompletedOnce]) {
        [self _cleanup];
        return;
    }

    @try {
        id nillable forwardedException = exception;

        if (exception != nilptr) {
            OFException *convertedException = [self _exceptionFromCallbackException: $assert_nonnil(exception)];
            [_completionSource reject: convertedException];
            [self _restoreForwardDelegate];
            if (_forwardDelegate != nilptr)
                [_forwardDelegate client: _requestClient
                       didPerformRequest: _request
                                response: response
                               exception: forwardedException];
            return;
        }

        if (response == nilptr) {
            auto missingResponseException = [[AsyncHTTPClientException alloc] initWithReason: @"AsyncHTTP client completed without a response"];
            [_completionSource reject: missingResponseException];
            [self _restoreForwardDelegate];
            if (_forwardDelegate != nilptr)
                [_forwardDelegate client: _requestClient
                       didPerformRequest: _request
                                response: nilptr
                               exception: missingResponseException];
            return;
        }

        [_completionSource fulfill: $as_nonnil(response)];
        [self _restoreForwardDelegate];
        if (_forwardDelegate != nilptr)
            [_forwardDelegate client: _requestClient
                   didPerformRequest: _request
                            response: response
                           exception: nilptr];
    } @finally {
        [self _cleanup];
    }
}

- (void)start
{
    @try {
        _requestClient.delegate = self;
        [_requestClient asyncPerformRequest: _request redirects: _redirects runLoopMode: _scheduler.mode];
    } @catch (OFException *exception) {
        [self _finishWithResponse: nilptr exception: exception];
    }
}

- (void)cancel
{
    if (not [self _markCompletedOnce])
        return;

    @try {
        [_completionSource reject: [[AsyncHTTPRequestCancelledException alloc] initWithRequest: _request]];
    } @finally {
        @try {
            [_requestClient close];
        } @catch (OFException *) {
        }
    }
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
           response: (OFHTTPResponse *nillable)response
          exception: (id nillable)exception
{
    (void)client;
    (void)request;
    [self _finishWithResponse: response exception: exception];
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

@implementation AsyncHTTPClient

+ (instancetype)client
{
    return [[self alloc] init];
}

- (AsyncTask<OFHTTPResponse *> *)performRequest: (OFHTTPRequest *)request
{
    return [self performRequest: request
                      redirects: AsyncHTTPClientDefaultRedirects];
}

- (AsyncTask<OFHTTPResponse *> *)performRequest: (OFHTTPRequest *)request
                                      redirects: (unsigned int)redirects
{
    auto completionSource = [[AsyncCompletionSource<OFHTTPResponse *> alloc] init];
    auto requestClient = [[OFHTTPClient alloc] init];
    requestClient.allowsInsecureRedirects = self.allowsInsecureRedirects;

    auto bridge = [[AsyncHTTPClientTaskBridge alloc] initWithRequestClient: requestClient
                                                            forwardDelegate: self.delegate
                                                                   request: request
                                                                 redirects: redirects
                                                                 scheduler: AsyncScheduler.sharedScheduler
                                                          completionSource: completionSource];

    [AsyncHTTPClientTaskBridge retainInflightBridge: bridge];
    completionSource.pendingTaskCancellationHandler = ^{ [bridge cancel]; };
    [bridge start];
    return completionSource.task;
}

@end

#pragma clang assume_nonnull end
