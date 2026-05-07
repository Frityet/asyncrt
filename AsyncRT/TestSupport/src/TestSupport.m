#import "TestSupport.h"
#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

static unsigned int const async_runtime_test_default_http_redirects = 10;
static OFOnceControl async_runtime_test_http_bridge_once = OFOnceControlInitValue;
static OFMutex *nillable async_runtime_test_http_bridge_lock;
static OFMutableSet<id> *nillable async_runtime_test_inflight_http_bridges;

[[gnu::constructor]]
static void AsyncRuntimeEnsureObjFWTLSBindingsLoadedForTests(void)
{
    volatile int objfwTLSReference = _ObjFWTLS_reference;
    (void)objfwTLSReference;
}

[[subclassing_restricted]]
@interface AsyncRuntimeTestHTTPRequestCancelledException : OFException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithRequest: (OFHTTPRequest *)request [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncRuntimeTestHTTPClientTaskBridge : OFObject<OFHTTPClientDelegate>

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
+ (void)retainInflightBridge: (AsyncRuntimeTestHTTPClientTaskBridge *)bridge;
+ (void)releaseInflightBridge: (AsyncRuntimeTestHTTPClientTaskBridge *)bridge;

@end

@namespace_implementation(AsyncRuntimeTestSupport)

+ (Task<OFString *> *)timerResolvedStringForScheduler: (AsyncScheduler *)scheduler
                                              seconds: (OFTimeInterval)seconds
                                                value: (OFString *)value
{
    auto completionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: seconds]
                                          interval: 0
                                            target: completionSource
                                          selector: @selector(fulfill:)
                                            object: value
                                           repeats: false];
    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return completionSource.task;
}

+ (Task<OFString *> *)timerRejectedStringForScheduler: (AsyncScheduler *)scheduler
                                              seconds: (OFTimeInterval)seconds
                                            exception: (OFException *)exception
{
    auto completionSource = [[AsyncCompletionSource<OFString *> alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: seconds]
                                          interval: 0
                                            target: completionSource
                                          selector: @selector(reject:)
                                            object: exception
                                           repeats: false];
    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return completionSource.task;
}

+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                         onScheduler: (AsyncScheduler *)scheduler
{
    return [self taskToPerformHTTPRequest: request
                           withHTTPClient: client
                                redirects: async_runtime_test_default_http_redirects
                              onScheduler: scheduler
                 cancelOnTaskCancellation: true];
}

+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                           redirects: (unsigned int)redirects
                                         onScheduler: (AsyncScheduler *)scheduler
{
    return [self taskToPerformHTTPRequest: request
                           withHTTPClient: client
                                redirects: redirects
                              onScheduler: scheduler
                 cancelOnTaskCancellation: true];
}

+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                           redirects: (unsigned int)redirects
                                         onScheduler: (AsyncScheduler *)scheduler
                            cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto completionSource = [[AsyncCompletionSource<OFHTTPResponse *> alloc] init];
    auto requestClient = [[OFHTTPClient alloc] init];
    requestClient.allowsInsecureRedirects = client.allowsInsecureRedirects;

    auto bridge = [[AsyncRuntimeTestHTTPClientTaskBridge alloc] initWithRequestClient: requestClient
                                                                        forwardDelegate: client.delegate
                                                                                request: request
                                                                              redirects: redirects
                                                                              scheduler: scheduler
                                                                       completionSource: completionSource];

    [AsyncRuntimeTestHTTPClientTaskBridge retainInflightBridge: bridge];

    if (cancelOnTaskCancellation)
        completionSource.pendingTaskCancellationHandler = ^{ [bridge cancel]; };

    [bridge start];
    return completionSource.task;
}

+ (AsyncTaskSnapshot *nillable)findTaskSnapshotNamed: (OFString *)name inSnapshot: (AsyncSchedulerSnapshot *)snapshot
{
    for (AsyncTaskSnapshot *task_snapshot in snapshot.tasks) {
        if ([task_snapshot.name isEqual: name])
            return task_snapshot;
    }

    return nilptr;
}

+ (uintptr_t)pointerValueFromBytes: (const void *)bytes
{
    uintptr_t value = 0;
    memcpy(&value, bytes, sizeof(value));
    return value;
}

@end

@implementation TestRejectionException @end

static void AsyncRuntimeInitialiseHTTPBridgeState(void)
{
    async_runtime_test_http_bridge_lock = [OFMutex mutex];
    async_runtime_test_inflight_http_bridges = [OFMutableSet set];
}

@implementation AsyncRuntimeTestHTTPRequestCancelledException

- (instancetype)initWithRequest: (OFHTTPRequest *)request
{
    self = [super init];
    _request = request;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncRuntimeTestHTTPRequestCancelledException: cancelled request %@", self.request];
}

@end

@implementation AsyncRuntimeTestHTTPClientTaskBridge {
    OFMutex *_lock;
    bool _didComplete;
    bool _didCleanup;
}

+ (void)retainInflightBridge: (AsyncRuntimeTestHTTPClientTaskBridge *)bridge
{
    OFOnce(&async_runtime_test_http_bridge_once, AsyncRuntimeInitialiseHTTPBridgeState);

    [async_runtime_test_http_bridge_lock lock];
    @try {
        [async_runtime_test_inflight_http_bridges addObject: bridge];
    } @finally {
        [async_runtime_test_http_bridge_lock unlock];
    }
}

+ (void)releaseInflightBridge: (AsyncRuntimeTestHTTPClientTaskBridge *)bridge
{
    OFOnce(&async_runtime_test_http_bridge_once, AsyncRuntimeInitialiseHTTPBridgeState);

    [async_runtime_test_http_bridge_lock lock];
    @try {
        [async_runtime_test_inflight_http_bridges removeObject: bridge];
    } @finally {
        [async_runtime_test_http_bridge_lock unlock];
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
        shouldComplete = (not _didComplete);
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
        shouldCleanup = (not _didCleanup);
        if (shouldCleanup)
            _didCleanup = true;
    } @finally {
        [_lock unlock];
    }

    return shouldCleanup;
}

- (void)_cleanup
{
    if (not [self _markCleanupOnce])
        return;

    _requestClient.delegate = nilptr;

    @try {
        [_requestClient close];
    } @catch (OFException *) {
    }

    [AsyncRuntimeTestHTTPClientTaskBridge releaseInflightBridge: self];
}

- (void)_finishWithResponse: (OFHTTPResponse *nillable)response exception: (OFException *nillable)exception
{
    bool shouldComplete = [self _markCompletedOnce];

    @try {
        if (shouldComplete) {
            if (response != nilptr)
                [_completionSource fulfill: $assert_nonnil(response)];
            else if (exception != nilptr)
                [_completionSource reject: $assert_nonnil(exception)];
            else
                [_completionSource reject: [OFInvalidArgumentException exception]];

            if (_forwardDelegate != nilptr)
                [_forwardDelegate client: _requestClient didPerformRequest: _request response: response exception: exception];
        }
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
        [_completionSource reject: [[AsyncRuntimeTestHTTPRequestCancelledException alloc] initWithRequest: _request]];
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

@implementation CrossThreadResolverThread {
    AsyncCompletionSource<OFString *> *_resolver;
    OFString *_value;
    OFTimeInterval _delay;
}

- (instancetype)initWithResolver: (AsyncCompletionSource<OFString *> *)resolver value: (OFString *)value delay: (OFTimeInterval)delay
{
    self = [super init];
    _resolver = resolver;
    _value = value;
    _delay = delay;
    return self;
}

- (id nillable)main
{
    [OFThread sleepForTimeInterval: _delay];
    [_resolver fulfill: _value];
    return nilptr;
}

@end

@implementation TaskCancellationThread {
    Task *_task;
    OFTimeInterval _delay;
    atomic_t(bool) *_cancelIssuedFlag;
}

- (instancetype)initWithTask: (Task *)task delay: (OFTimeInterval)delay cancelIssuedFlag: (atomic_t(bool) *)cancelIssuedFlag
{
    self = [super init];
    _task = task;
    _delay = delay;
    _cancelIssuedFlag = cancelIssuedFlag;
    return self;
}

- (id nillable)main
{
    [OFThread sleepForTimeInterval: _delay];
    [_task cancel];

    if (_cancelIssuedFlag != nullptr)
        atomic_store_explicit(_cancelIssuedFlag, true, memory_order_release);

    return nilptr;
}

@end

@implementation LocalHTTPTestServer {
    OFTCPSocket *_listener;
    OFThread *nillable _acceptThread;
    OFMutex *_lock;
    OFMutableArray<OFThread *> *_handlerThreads;
    bool _stopping;
}

- (instancetype)init
{
    self = [super init];
    _listener = [[OFTCPSocket alloc] init];
    _lock = [OFMutex mutex];
    _handlerThreads = [OFMutableArray array];
    _stopping = false;

    OFSocketAddress boundAddress = [_listener bindToHost: @"127.0.0.1" port: 0];
    [_listener listen];
    _port = OFSocketAddressIPPort(&boundAddress);
    return self;
}

- (void)start
{
    unretained LocalHTTPTestServer *unsafeSelf = self;

    _acceptThread = [[OFThread alloc] initWithBlock: ^{
        [unsafeSelf _acceptLoop];
        return nilptr;
    }];
    [_acceptThread start];
}

- (void)stop
{
    OFArray<OFThread *> *handlerThreads;
    OFTCPSocket *wakeSocket;

    [_lock lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
        handlerThreads = [_handlerThreads copy];
    } @finally {
        [_lock unlock];
    }

    @try {
        wakeSocket = [[OFTCPSocket alloc] init];
        [wakeSocket connectToHost: @"127.0.0.1" port: self.port];
        [wakeSocket close];
    } @catch (OFException *) {
    }

    if (_acceptThread != nilptr)
        (void)[_acceptThread join];

    @try {
        [_listener close];
    } @catch (OFException *) {
    }

    for (OFThread *thread in handlerThreads)
        (void)[thread join];
}

- (OFIRI *)IRIForPath: (OFString *)path
{
    auto iri_string = [OFString stringWithFormat: @"http://127.0.0.1:%u%@", self.port, path];
    return [[OFIRI alloc] initWithString: iri_string];
}

- (void)_acceptLoop
{
    unretained LocalHTTPTestServer *unsafeSelf = self;

    while (true) {
        OFTCPSocket *acceptedSocket;
        OFThread *thread;

        @try {
            acceptedSocket = (OFTCPSocket *)[_listener accept];
        } @catch (OFException *exception) {
            [_lock lock];
            @try {
                if (_stopping)
                    return;
            } @finally {
                [_lock unlock];
            }

            @throw exception;
        }

        [_lock lock];
        @try {
            if (_stopping) {
                @try {
                    [acceptedSocket close];
                } @catch (OFException *) {
                }

                return;
            }
        } @finally {
            [_lock unlock];
        }

        thread = [[OFThread alloc] initWithBlock: ^{
            [unsafeSelf _handleAcceptedSocket: acceptedSocket];
            return nilptr;
        }];

        [_lock lock];
        @try {
            [_handlerThreads addObject: thread];
        } @finally {
            [_lock unlock];
        }

        [thread start];
    }
}

- (void)_handleAcceptedSocket: (OFTCPSocket *)acceptedSocket
{
    @try {
        OFString *requestLine = acceptedSocket.readLine;

        if (requestLine == nilptr)
            return;

        while (true) {
            OFString *headerLine = acceptedSocket.readLine;

            if (headerLine == nilptr or headerLine.length == 0)
                break;
        }

        OFString *path = [self _pathFromRequestLine: requestLine];
        OFTimeInterval delay = [path containsString: @"slow"] ? 0.20 : 0.01;
        [OFThread sleepForTimeInterval: delay];

        OFString *body = (path.length > 1 ? [path substringFromIndex: 1] : @"root");
        const char *bodyUTF8String = body.UTF8String;
        OFString *response = [OFString stringWithFormat: @"HTTP/1.1 200 OK\r\nContent-Length: %zu\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\n%@",
                                                       strlen(bodyUTF8String),
                                                       body];
        [acceptedSocket writeString: response];
    } @catch (OFException *) {
    } @finally {
        @try {
            [acceptedSocket close];
        } @catch (OFException *) {
        }
    }
}

- (OFString *)_pathFromRequestLine: (OFString *)requestLine
{
    OFArray<OFString *> *parts = [requestLine componentsSeparatedByString: @" "];

    if (parts.count < 2)
        return @"/invalid";

    return parts[1];
}

@end

#pragma clang assume_nonnull end
