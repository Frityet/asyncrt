#import "TestSupport.h"
#import "Async/ObjFWAsync/ObjFWAsync.h"
#import "Async/ObjFWAsync/OFHTTPClient+Promise.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncObjFWTimerTarget : OFObject

- (instancetype)initWithBlock: (void (^)(void))block [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)fire;

@end

[[subclassing_restricted]]
@interface AsyncDNSResolverQueryPromiseDelegate : OFObject<OFDNSResolverQueryDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge
                      resolver: (OFDNSResolver *)resolver
                         query: (OFDNSQuery *)query [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncDNSResolverHostPromiseDelegate : OFObject<OFDNSResolverHostDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge
                      resolver: (OFDNSResolver *)resolver
                          host: (OFString *)host [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTLSStreamPromiseDelegate : OFObject<OFTLSStreamDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge
                        stream: (OFTLSStream *)stream
               forwardDelegate: (id<OFTLSStreamDelegate> nillable)forwardDelegate
                          host: (OFString *nillable)host
        performsClientHandshake: (bool)performsClientHandshake [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;

@end

[[subclassing_restricted]]
@interface AsyncHTTPClientPromiseBridge : OFObject<OFHTTPClientDelegate>

- (instancetype)initWithClient: (OFHTTPClient *)client
               forwardDelegate: (OFObject<OFHTTPClientDelegate> *nillable)forwardDelegate
                       request: (OFHTTPRequest *)request
                     redirects: (unsigned int)redirects
                     scheduler: (AsyncScheduler *)scheduler
                      resolver: (PromiseResolver<OFHTTPResponse *> *)resolver [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;

@end

[[subclassing_restricted]]
@interface CoverageScheduledTarget : OFObject

@property(nonatomic) bool fired;
- (void)markFired;

@end

@implementation CoverageScheduledTarget

@synthesize fired = _fired;

- (void)markFired
{
    _fired = true;
}

@end

[[subclassing_restricted]]
@interface CoverageTLSStreamHarness : OFObject

@property(assign, nonatomic) id<OFTLSStreamDelegate> nillable delegate;
@property(readonly, nonatomic) OFString *nillable clientHandshakeHost;
@property(readonly, nonatomic) OFRunLoopMode nillable clientRunLoopMode;
@property(readonly, nonatomic) OFRunLoopMode nillable serverRunLoopMode;
@property(readonly, nonatomic) size_t cancelCallCount;
@property(nonatomic) bool throwOnClientHandshakeStart;
@property(nonatomic) bool throwOnServerHandshakeStart;

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
                                runLoopMode: (OFRunLoopMode)runLoopMode;
- (void)asyncPerformServerHandshakeWithRunLoopMode: (OFRunLoopMode)runLoopMode;
- (void)cancelAsyncRequests;

@end

@implementation CoverageTLSStreamHarness {
    OFString *_clientHandshakeHost;
    OFRunLoopMode _clientRunLoopMode;
    OFRunLoopMode _serverRunLoopMode;
    size_t _cancelCallCount;
    bool _throwOnClientHandshakeStart;
    bool _throwOnServerHandshakeStart;
}

@synthesize delegate = _delegate;
@synthesize clientHandshakeHost = _clientHandshakeHost;
@synthesize clientRunLoopMode = _clientRunLoopMode;
@synthesize serverRunLoopMode = _serverRunLoopMode;
@synthesize cancelCallCount = _cancelCallCount;
@synthesize throwOnClientHandshakeStart = _throwOnClientHandshakeStart;
@synthesize throwOnServerHandshakeStart = _throwOnServerHandshakeStart;

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
                                runLoopMode: (OFRunLoopMode)runLoopMode
{
    if (_throwOnClientHandshakeStart)
        @throw [[TestRejectionException alloc] init];

    _clientHandshakeHost = [host copy];
    _clientRunLoopMode = [runLoopMode copy];
}

- (void)asyncPerformServerHandshakeWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
    if (_throwOnServerHandshakeStart)
        @throw [[TestRejectionException alloc] init];

    _serverRunLoopMode = [runLoopMode copy];
}

- (void)cancelAsyncRequests
{
    _cancelCallCount++;
}

@end

[[subclassing_restricted]]
@interface CoverageTLSForwardDelegate : OFObject<OFTLSStreamDelegate>

@property(readonly, nonatomic) size_t clientHandshakeCallbackCount;
@property(readonly, nonatomic) size_t serverHandshakeCallbackCount;
@property(readonly, nonatomic) OFString *nillable lastClientHandshakeHost;
@property(readonly, nonatomic) OFException *nillable lastClientHandshakeException;
@property(readonly, nonatomic) OFException *nillable lastServerHandshakeException;
@property(readonly, nonatomic) bool readBufferForwarded;
@property(readonly, nonatomic) bool readStringForwarded;
@property(readonly, nonatomic) bool readLineForwarded;
@property(readonly, nonatomic) bool writeDataForwarded;
@property(readonly, nonatomic) bool writeStringForwarded;
@property(readonly, nonatomic) OFData *writeDataResult;
@property(readonly, nonatomic) OFString *writeStringResult;

@end

@implementation CoverageTLSForwardDelegate {
    size_t _clientHandshakeCallbackCount;
    size_t _serverHandshakeCallbackCount;
    OFString *_lastClientHandshakeHost;
    OFException *_lastClientHandshakeException;
    OFException *_lastServerHandshakeException;
    bool _readBufferForwarded;
    bool _readStringForwarded;
    bool _readLineForwarded;
    bool _writeDataForwarded;
    bool _writeStringForwarded;
    OFData *_writeDataResult;
    OFString *_writeStringResult;
}

@synthesize clientHandshakeCallbackCount = _clientHandshakeCallbackCount;
@synthesize serverHandshakeCallbackCount = _serverHandshakeCallbackCount;
@synthesize lastClientHandshakeHost = _lastClientHandshakeHost;
@synthesize lastClientHandshakeException = _lastClientHandshakeException;
@synthesize lastServerHandshakeException = _lastServerHandshakeException;
@synthesize readBufferForwarded = _readBufferForwarded;
@synthesize readStringForwarded = _readStringForwarded;
@synthesize readLineForwarded = _readLineForwarded;
@synthesize writeDataForwarded = _writeDataForwarded;
@synthesize writeStringForwarded = _writeStringForwarded;
@synthesize writeDataResult = _writeDataResult;
@synthesize writeStringResult = _writeStringResult;

- (instancetype)init
{
    self = [super init];
    _writeDataResult = [[OFData alloc] initWithItems: "ok" count: 2];
    _writeStringResult = @"tail";
    return self;
}

- (bool)stream: (OFStream *)stream didReadIntoBuffer: (void *)buffer length: (size_t)length exception: (id nillable)exception
{
    (void)stream;
    (void)buffer;
    (void)length;
    (void)exception;
    _readBufferForwarded = true;
    return true;
}

- (bool)stream: (OFStream *)stream didReadString: (OFString *nillable)string exception: (id nillable)exception
{
    (void)stream;
    (void)string;
    (void)exception;
    _readStringForwarded = true;
    return true;
}

- (bool)stream: (OFStream *)stream didReadLine: (OFString *nillable)line exception: (id nillable)exception
{
    (void)stream;
    (void)line;
    (void)exception;
    _readLineForwarded = true;
    return true;
}

- (OFData *nillable)stream: (OFStream *)stream didWriteData: (OFData *)data bytesWritten: (size_t)bytesWritten exception: (id nillable)exception
{
    (void)stream;
    (void)data;
    (void)bytesWritten;
    (void)exception;
    _writeDataForwarded = true;
    return _writeDataResult;
}

- (OFString *nillable)stream: (OFStream *)stream didWriteString: (OFString *)string encoding: (OFStringEncoding)encoding bytesWritten: (size_t)bytesWritten exception: (id nillable)exception
{
    (void)stream;
    (void)string;
    (void)encoding;
    (void)bytesWritten;
    (void)exception;
    _writeStringForwarded = true;
    return _writeStringResult;
}

- (void)stream: (OFTLSStream *)stream didPerformClientHandshakeWithHost: (OFString *)host exception: (id nillable)exception
{
    (void)stream;
    _clientHandshakeCallbackCount++;
    _lastClientHandshakeHost = [host copy];
    _lastClientHandshakeException = exception;
}

- (void)streamDidPerformServerHandshake: (OFTLSStream *)stream exception: (id nillable)exception
{
    (void)stream;
    _serverHandshakeCallbackCount++;
    _lastServerHandshakeException = exception;
}

@end

[[subclassing_restricted]]
@interface CoverageHTTPClientHarness : OFObject

@property(assign, nonatomic) OFObject<OFHTTPClientDelegate> *nillable delegate;
@property(readonly, nonatomic) OFHTTPRequest *nillable lastRequest;
@property(readonly, nonatomic) unsigned int lastRedirects;
@property(readonly, nonatomic) OFRunLoopMode nillable lastRunLoopMode;
@property(readonly, nonatomic) size_t asyncPerformRequestCount;
@property(readonly, nonatomic) size_t closeCallCount;
@property(nonatomic) bool throwOnStart;

- (void)asyncPerformRequest: (OFHTTPRequest *)request
                  redirects: (unsigned int)redirects
                runLoopMode: (OFRunLoopMode)runLoopMode;
- (void)close;

@end

@implementation CoverageHTTPClientHarness {
    OFHTTPRequest *_lastRequest;
    unsigned int _lastRedirects;
    OFRunLoopMode _lastRunLoopMode;
    size_t _asyncPerformRequestCount;
    size_t _closeCallCount;
    bool _throwOnStart;
}

@synthesize delegate = _delegate;
@synthesize lastRequest = _lastRequest;
@synthesize lastRedirects = _lastRedirects;
@synthesize lastRunLoopMode = _lastRunLoopMode;
@synthesize asyncPerformRequestCount = _asyncPerformRequestCount;
@synthesize closeCallCount = _closeCallCount;
@synthesize throwOnStart = _throwOnStart;

- (void)asyncPerformRequest: (OFHTTPRequest *)request
                  redirects: (unsigned int)redirects
                runLoopMode: (OFRunLoopMode)runLoopMode
{
    _asyncPerformRequestCount++;
    _lastRequest = request;
    _lastRedirects = redirects;
    _lastRunLoopMode = [runLoopMode copy];

    if (_throwOnStart)
        @throw [[TestRejectionException alloc] init];
}

- (void)close
{
    _closeCallCount++;
}

@end

[[subclassing_restricted]]
@interface CoverageHTTPForwardDelegate : OFObject<OFHTTPClientDelegate>

@property(readonly, nonatomic) size_t performedRequestCallbackCount;
@property(readonly, nonatomic) size_t createdTCPSocketCallbackCount;
@property(readonly, nonatomic) size_t createdTLSStreamCallbackCount;
@property(readonly, nonatomic) size_t wantsRequestBodyCallbackCount;
@property(readonly, nonatomic) size_t receivedHeadersCallbackCount;
@property(readonly, nonatomic) OFHTTPResponse *nillable lastResponse;
@property(readonly, nonatomic) OFException *nillable lastException;
@property(nonatomic) bool redirectDecision;

@end

@implementation CoverageHTTPForwardDelegate {
    size_t _performedRequestCallbackCount;
    size_t _createdTCPSocketCallbackCount;
    size_t _createdTLSStreamCallbackCount;
    size_t _wantsRequestBodyCallbackCount;
    size_t _receivedHeadersCallbackCount;
    OFHTTPResponse *_lastResponse;
    OFException *_lastException;
    bool _redirectDecision;
}

@synthesize performedRequestCallbackCount = _performedRequestCallbackCount;
@synthesize createdTCPSocketCallbackCount = _createdTCPSocketCallbackCount;
@synthesize createdTLSStreamCallbackCount = _createdTLSStreamCallbackCount;
@synthesize wantsRequestBodyCallbackCount = _wantsRequestBodyCallbackCount;
@synthesize receivedHeadersCallbackCount = _receivedHeadersCallbackCount;
@synthesize lastResponse = _lastResponse;
@synthesize lastException = _lastException;
@synthesize redirectDecision = _redirectDecision;

- (instancetype)init
{
    self = [super init];
    _redirectDecision = false;
    return self;
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
           response: (OFHTTPResponse *nillable)response
          exception: (id nillable)exception
{
    (void)client;
    (void)request;
    _performedRequestCallbackCount++;
    _lastResponse = response;
    _lastException = exception;
}

-   (void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
             request: (OFHTTPRequest *)request
{
    (void)client;
    (void)TCPSocket;
    (void)request;
    _createdTCPSocketCallbackCount++;
}

-   (void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
             request: (OFHTTPRequest *)request
{
    (void)client;
    (void)TLSStream;
    (void)request;
    _createdTLSStreamCallbackCount++;
}

-      (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)requestBody
           request: (OFHTTPRequest *)request
{
    (void)client;
    (void)requestBody;
    (void)request;
    _wantsRequestBodyCallbackCount++;
}

-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers
         statusCode: (short)statusCode
            request: (OFHTTPRequest *)request
{
    (void)client;
    (void)headers;
    (void)statusCode;
    (void)request;
    _receivedHeadersCallbackCount++;
}

-       (bool)client: (OFHTTPClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)IRI
                 statusCode: (short)statusCode
                    request: (OFHTTPRequest *)request
                   response: (OFHTTPResponse *)response
{
    (void)client;
    (void)IRI;
    (void)statusCode;
    (void)request;
    (void)response;
    return _redirectDecision;
}

@end

static void pump_scheduler_until(AsyncScheduler *scheduler, bool (^condition)(void))
{
    for (size_t iteration = 0; iteration < 200 and not condition(); iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }
}

static OFHTTPRequest *CoverageRequest(OFString *IRIString, OFHTTPRequestMethod method)
{
    auto request = [[OFHTTPRequest alloc] initWithIRI: [OFIRI IRIWithString: IRIString]];
    request.method = method;
    return request;
}

static void objfw_support_and_dns_internal_branches(void)
{
    AsyncScheduler *scheduler = AsyncScheduler.defaultScheduler;
    auto scheduledTarget = [[CoverageScheduledTarget alloc] init];
    auto baseResolver = [[PromiseResolver<id> alloc] init];
    block_reference size_t timerFireCount = 0;
    block_reference size_t startedBridgeStartCount = 0;
    block_reference size_t startedBridgeCancelCount = 0;
    OFSocketAddress address = OFSocketAddressParseIPv4(@"127.0.0.1", 4242);
    const char buffer[] = "abc";
    auto timerTarget = [[AsyncObjFWTimerTarget alloc] initWithBlock: ^{
        timerFireCount++;
    }];
    auto operationException = [[PromiseObjFWOperationException alloc]
        initWithPromise: baseResolver.promise
                 object: @"socket"
              operation: @"read"];
    auto invalidCompletionException = [[PromiseObjFWInvalidCompletionException alloc]
        initWithPromise: baseResolver.promise
                 object: @"socket"
              operation: @"read"
                 reason: @"bad state"];
    auto cancelledException = [[PromiseObjFWOperationCancelledException alloc]
        initWithPromise: baseResolver.promise
                 object: @"socket"
              operation: @"read"];
    auto cancelResolver = [[PromiseResolver<id> alloc] init];
    auto cancelBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"cancel-before-start"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)cancelResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: ^(AsyncObjFWPromiseBridge *) {
            }];
    auto startedResolver = [[PromiseResolver<id> alloc] init];
    auto startedBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"cancel-after-start"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)startedResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
                startedBridgeStartCount++;
            }
           cancelBlock: ^(AsyncObjFWPromiseBridge *) {
                startedBridgeCancelCount++;
            }];
    auto throwingResolver = [[PromiseResolver<id> alloc] init];
    auto throwingBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"throwing-start"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)throwingResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
                @throw [[TestRejectionException alloc] init];
            }
           cancelBlock: nilptr];
    auto resolvedResolver = [[PromiseResolver<id> alloc] init];
    auto resolvedBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"resolve"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)resolvedResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto invalidResolver = [[PromiseResolver<id> alloc] init];
    auto invalidBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"invalid"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)invalidResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto attachResolver = [[PromiseResolver<id> alloc] init];
    auto attachBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"socket"
             operation: @"attached"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)attachResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: ^(AsyncObjFWPromiseBridge *) {
            }];
    auto bufferResult = [[AsyncBufferReadResult alloc] initWithBuffer: buffer length: 3];
    auto datagramResult = [[AsyncDatagramReceiveResult alloc] initWithBuffer: buffer length: 3 sender: &address];
    auto query = [OFDNSQuery queryWithDomainName: @"coverage.example"
                                        DNSClass: OFDNSClassIN
                                      recordType: OFDNSRecordTypeTXT];
    auto response = [OFDNSResponse responseWithDomainName: @"coverage.example"
                                             answerRecords: @{}
                                          authorityRecords: @{}
                                         additionalRecords: @{}];
    auto addresses = [OFData dataWithItems: &address count: sizeof(address)];
    id resolverToken = [[OFObject alloc] init];
    id otherResolverToken = [[OFObject alloc] init];
    auto dnsSuccessResolver = [[PromiseResolver<id> alloc] init];
    auto dnsSuccessBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"query"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)dnsSuccessResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto dnsMismatchResolver = [[PromiseResolver<id> alloc] init];
    auto dnsMismatchBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"query"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)dnsMismatchResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto dnsExceptionResolver = [[PromiseResolver<id> alloc] init];
    auto dnsExceptionBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"query"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)dnsExceptionResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto dnsNilResponseResolver = [[PromiseResolver<id> alloc] init];
    auto dnsNilResponseBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"query"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)dnsNilResponseResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto dnsQueryDelegate = [[AsyncDNSResolverQueryPromiseDelegate alloc]
        initWithBridge: dnsSuccessBridge
              resolver: (OFDNSResolver *)resolverToken
                 query: query];
    auto dnsMismatchDelegate = [[AsyncDNSResolverQueryPromiseDelegate alloc]
        initWithBridge: dnsMismatchBridge
              resolver: (OFDNSResolver *)resolverToken
                 query: query];
    auto dnsExceptionDelegate = [[AsyncDNSResolverQueryPromiseDelegate alloc]
        initWithBridge: dnsExceptionBridge
              resolver: (OFDNSResolver *)resolverToken
                 query: query];
    auto dnsNilResponseDelegate = [[AsyncDNSResolverQueryPromiseDelegate alloc]
        initWithBridge: dnsNilResponseBridge
              resolver: (OFDNSResolver *)resolverToken
                 query: query];
    auto hostSuccessResolver = [[PromiseResolver<id> alloc] init];
    auto hostSuccessBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"host"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)hostSuccessResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto hostMismatchResolver = [[PromiseResolver<id> alloc] init];
    auto hostMismatchBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"host"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)hostMismatchResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto hostExceptionResolver = [[PromiseResolver<id> alloc] init];
    auto hostExceptionBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"host"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)hostExceptionResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto hostNilAddressResolver = [[PromiseResolver<id> alloc] init];
    auto hostNilAddressBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: @"dns"
             operation: @"host"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)hostNilAddressResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto hostSuccessDelegate = [[AsyncDNSResolverHostPromiseDelegate alloc]
        initWithBridge: hostSuccessBridge
              resolver: (OFDNSResolver *)resolverToken
                  host: @"coverage.example"];
    auto hostMismatchDelegate = [[AsyncDNSResolverHostPromiseDelegate alloc]
        initWithBridge: hostMismatchBridge
              resolver: (OFDNSResolver *)resolverToken
                  host: @"coverage.example"];
    auto hostExceptionDelegate = [[AsyncDNSResolverHostPromiseDelegate alloc]
        initWithBridge: hostExceptionBridge
              resolver: (OFDNSResolver *)resolverToken
                  host: @"coverage.example"];
    auto hostNilAddressDelegate = [[AsyncDNSResolverHostPromiseDelegate alloc]
        initWithBridge: hostNilAddressBridge
              resolver: (OFDNSResolver *)resolverToken
                  host: @"coverage.example"];

    [AsyncObjFWSupport scheduleOnScheduler: scheduler
                                    target: scheduledTarget
                                  selector: @selector(markFired)];
    pump_scheduler_until(scheduler, ^bool {
        return scheduledTarget.fired;
    });

    [timerTarget fire];
    [timerTarget fire];

    [cancelBridge cancel];
    [cancelBridge cancel];
    [cancelBridge start];

    [startedBridge start];
    [startedBridge start];
    [startedBridge cancel];

    [throwingBridge start];
    [resolvedBridge resolve: @"resolved"];
    [resolvedBridge resolve: @"ignored"];
    [resolvedBridge reject: [[TestRejectionException alloc] init]];
    [invalidBridge rejectInvalidCompletionWithReason: @"bad state"];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: attachResolver.promise
                               cancelOnTaskCancellation: true
                                                 bridge: attachBridge];
    [AsyncObjFWSupport attachCancellationBridgeToPromise: attachResolver.promise
                               cancelOnTaskCancellation: false
                                                 bridge: attachBridge];

    async_link_objfw_promise_categories();

    [dnsQueryDelegate resolver: (OFDNSResolver *)resolverToken
               didPerformQuery: query
                      response: response
                     exception: nilptr];
    [dnsMismatchDelegate resolver: (OFDNSResolver *)otherResolverToken
                  didPerformQuery: query
                         response: response
                        exception: nilptr];
    [dnsExceptionDelegate resolver: (OFDNSResolver *)resolverToken
                   didPerformQuery: query
                          response: nilptr
                         exception: [[TestRejectionException alloc] init]];
    [dnsNilResponseDelegate resolver: (OFDNSResolver *)resolverToken
                     didPerformQuery: query
                            response: nilptr
                           exception: nilptr];

    [hostSuccessDelegate resolver: (OFDNSResolver *)resolverToken
                   didResolveHost: @"coverage.example"
                         addresses: addresses
                         exception: nilptr];
    [hostMismatchDelegate resolver: (OFDNSResolver *)otherResolverToken
                    didResolveHost: @"coverage.example"
                          addresses: addresses
                          exception: nilptr];
    [hostExceptionDelegate resolver: (OFDNSResolver *)resolverToken
                     didResolveHost: @"coverage.example"
                           addresses: nilptr
                           exception: [[TestRejectionException alloc] init]];
    [hostNilAddressDelegate resolver: (OFDNSResolver *)resolverToken
                      didResolveHost: @"coverage.example"
                            addresses: nilptr
                            exception: nilptr];

    [AsyncRuntimeTestSupport assertCondition: (scheduledTarget.fired)
                                     message: (@"AsyncObjFWSupport should schedule selectors on the provided scheduler")];
    [AsyncRuntimeTestSupport assertCondition: (timerFireCount == 1)
                                     message: (@"AsyncObjFWTimerTarget should clear its block after firing once")];

    [AsyncRuntimeTestSupport assertCondition: ([operationException.description containsString: @"read on socket"])
                                     message: (@"PromiseObjFWOperationException should describe the object and operation")];
    [AsyncRuntimeTestSupport assertCondition: ([invalidCompletionException.description containsString: @"bad state"])
                                     message: (@"PromiseObjFWInvalidCompletionException should include its reason")];
    [AsyncRuntimeTestSupport assertCondition: ([cancelledException.description containsString: @"cancelled read on socket"])
                                     message: (@"PromiseObjFWOperationCancelledException should describe the cancelled operation")];

    [AsyncRuntimeTestSupport assertCondition: ([cancelResolver.promise.rejectionException isKindOfClass: PromiseObjFWOperationCancelledException.class])
                                     message: (@"Cancelling an ObjFW bridge before start should reject with a cancellation exception")];
    [AsyncRuntimeTestSupport assertCondition: (startedBridgeStartCount == 1 and startedBridgeCancelCount == 1)
                                     message: (@"AsyncObjFWPromiseBridge should only start and cancel once")];
    [AsyncRuntimeTestSupport assertCondition: (startedResolver.promise.status == PromiseStatus_REJECTED)
                                     message: (@"Cancelling an already started ObjFW bridge should reject its promise")];
    [AsyncRuntimeTestSupport assertCondition: ([throwingResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"AsyncObjFWPromiseBridge should reject when its start block throws")];
    [AsyncRuntimeTestSupport assertCondition: ([resolvedResolver.promise.value isEqual: @"resolved"])
                                     message: (@"AsyncObjFWPromiseBridge should resolve at most once")];
    [AsyncRuntimeTestSupport assertCondition: ([invalidResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"AsyncObjFWPromiseBridge should surface invalid completions as typed exceptions")];

    [AsyncRuntimeTestSupport assertCondition: (bufferResult.buffer == buffer and bufferResult.length == 3)
                                     message: (@"AsyncBufferReadResult should retain the provided buffer metadata")];
    [AsyncRuntimeTestSupport assertCondition: (OFSocketAddressIPPort(datagramResult.sender) == 4242)
                                     message: (@"AsyncDatagramReceiveResult should preserve sender socket metadata")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncObjFWSupport copySocketAddressData: &address] != nilptr)
                                     message: (@"AsyncObjFWSupport should copy socket address data into OFData")];

    [AsyncRuntimeTestSupport assertCondition: (dnsSuccessResolver.promise.value == response)
                                     message: (@"DNS query delegates should resolve matching responses")];
    [AsyncRuntimeTestSupport assertCondition: ([dnsMismatchResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"DNS query delegates should reject mismatched metadata")];
    [AsyncRuntimeTestSupport assertCondition: ([dnsExceptionResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"DNS query delegates should reject propagated exceptions")];
    [AsyncRuntimeTestSupport assertCondition: ([dnsNilResponseResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"DNS query delegates should reject nil response completions")];

    [AsyncRuntimeTestSupport assertCondition: ([hostSuccessResolver.promise.value isEqual: addresses])
                                     message: (@"Host resolution delegates should resolve matching address sets")];
    [AsyncRuntimeTestSupport assertCondition: ([hostMismatchResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Host resolution delegates should reject mismatched metadata")];
    [AsyncRuntimeTestSupport assertCondition: ([hostExceptionResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Host resolution delegates should reject propagated exceptions")];
    [AsyncRuntimeTestSupport assertCondition: ([hostNilAddressResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Host resolution delegates should reject missing address completions")];
}

static void objfw_tls_and_http_internal_branches(void)
{
    AsyncScheduler *scheduler = AsyncScheduler.defaultScheduler;
    char scratch[4] = {0};
    auto tlsForwardDelegate = [[CoverageTLSForwardDelegate alloc] init];
    auto tlsSuccessStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsSuccessResolver = [[PromiseResolver<id> alloc] init];
    auto tlsSuccessBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsSuccessStream
             operation: @"tls-client"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsSuccessResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsSuccessDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsSuccessBridge
                stream: (OFTLSStream *)tlsSuccessStream
       forwardDelegate: tlsForwardDelegate
                  host: @"coverage.example"
performsClientHandshake: true];
    auto tlsMismatchStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsMismatchResolver = [[PromiseResolver<id> alloc] init];
    auto tlsMismatchBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsMismatchStream
             operation: @"tls-client"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsMismatchResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsMismatchDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsMismatchBridge
                stream: (OFTLSStream *)tlsMismatchStream
       forwardDelegate: tlsForwardDelegate
                  host: @"coverage.example"
performsClientHandshake: true];
    auto tlsExceptionStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsExceptionResolver = [[PromiseResolver<id> alloc] init];
    auto tlsExceptionBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsExceptionStream
             operation: @"tls-client"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsExceptionResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsExceptionDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsExceptionBridge
                stream: (OFTLSStream *)tlsExceptionStream
       forwardDelegate: tlsForwardDelegate
                  host: @"coverage.example"
performsClientHandshake: true];
    auto tlsCancelStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsCancelResolver = [[PromiseResolver<id> alloc] init];
    auto tlsCancelBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsCancelStream
             operation: @"tls-client"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsCancelResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsCancelDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsCancelBridge
                stream: (OFTLSStream *)tlsCancelStream
       forwardDelegate: tlsForwardDelegate
                  host: @"coverage.example"
performsClientHandshake: true];
    auto tlsThrowingStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsThrowingResolver = [[PromiseResolver<id> alloc] init];
    auto tlsThrowingBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsThrowingStream
             operation: @"tls-client"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsThrowingResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsThrowingDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsThrowingBridge
                stream: (OFTLSStream *)tlsThrowingStream
       forwardDelegate: tlsForwardDelegate
                  host: @"coverage.example"
performsClientHandshake: true];
    auto tlsServerStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsServerResolver = [[PromiseResolver<id> alloc] init];
    auto tlsServerBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsServerStream
             operation: @"tls-server"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsServerResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsServerDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsServerBridge
                stream: (OFTLSStream *)tlsServerStream
       forwardDelegate: tlsForwardDelegate
                  host: nilptr
performsClientHandshake: false];
    auto tlsServerMismatchStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsServerMismatchResolver = [[PromiseResolver<id> alloc] init];
    auto tlsServerMismatchBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsServerMismatchStream
             operation: @"tls-server"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsServerMismatchResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsServerMismatchDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsServerMismatchBridge
                stream: (OFTLSStream *)tlsServerMismatchStream
       forwardDelegate: tlsForwardDelegate
                  host: nilptr
performsClientHandshake: false];
    auto tlsServerExceptionStream = [[CoverageTLSStreamHarness alloc] init];
    auto tlsServerExceptionResolver = [[PromiseResolver<id> alloc] init];
    auto tlsServerExceptionBridge = [[AsyncObjFWPromiseBridge alloc]
        initWithObject: tlsServerExceptionStream
             operation: @"tls-server"
             scheduler: scheduler
              resolver: (PromiseResolver<id> *)tlsServerExceptionResolver
            startBlock: ^(AsyncObjFWPromiseBridge *) {
            }
           cancelBlock: nilptr];
    auto tlsServerExceptionDelegate = [[AsyncTLSStreamPromiseDelegate alloc]
        initWithBridge: tlsServerExceptionBridge
                stream: (OFTLSStream *)tlsServerExceptionStream
       forwardDelegate: tlsForwardDelegate
                  host: nilptr
performsClientHandshake: false];
    auto successRequest = CoverageRequest(@"https://example.com/success", OFHTTPRequestMethodGet);
    auto successResponse = [[OFHTTPResponse alloc] init];
    auto requestBodyToken = [[OFObject alloc] init];
    auto httpForwardDelegate = [[CoverageHTTPForwardDelegate alloc] init];
    auto httpClient = [[CoverageHTTPClientHarness alloc] init];
    auto httpResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)httpClient
       forwardDelegate: httpForwardDelegate
               request: successRequest
             redirects: 3
             scheduler: scheduler
              resolver: httpResolver];
    auto httpInvalidResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpInvalidBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)[[CoverageHTTPClientHarness alloc] init]
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/invalid", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: httpInvalidResolver];
    auto httpExceptionResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpExceptionBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)[[CoverageHTTPClientHarness alloc] init]
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/exception", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: httpExceptionResolver];
    auto httpThrowingClient = [[CoverageHTTPClientHarness alloc] init];
    httpThrowingClient.throwOnStart = true;
    auto httpThrowingResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpThrowingBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)httpThrowingClient
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/start-failure", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: httpThrowingResolver];
    auto httpCancelBeforeStartClient = [[CoverageHTTPClientHarness alloc] init];
    auto httpCancelBeforeStartResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpCancelBeforeStartBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)httpCancelBeforeStartClient
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/cancel-before-start", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: httpCancelBeforeStartResolver];
    auto httpCancelAfterStartClient = [[CoverageHTTPClientHarness alloc] init];
    auto httpCancelAfterStartResolver = [[PromiseResolver<OFHTTPResponse *> alloc] init];
    auto httpCancelAfterStartBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)httpCancelAfterStartClient
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/cancel-after-start", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: httpCancelAfterStartResolver];
    auto httpRedirectBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)[[CoverageHTTPClientHarness alloc] init]
       forwardDelegate: nilptr
               request: CoverageRequest(@"https://example.com/redirect-get", OFHTTPRequestMethodGet)
             redirects: 1
             scheduler: scheduler
              resolver: [[PromiseResolver<OFHTTPResponse *> alloc] init]];
    auto httpForwardRedirectBridge = [[AsyncHTTPClientPromiseBridge alloc]
        initWithClient: (OFHTTPClient *)[[CoverageHTTPClientHarness alloc] init]
       forwardDelegate: httpForwardDelegate
               request: CoverageRequest(@"https://example.com/redirect-forward", OFHTTPRequestMethodPost)
             redirects: 1
             scheduler: scheduler
              resolver: [[PromiseResolver<OFHTTPResponse *> alloc] init]];
    auto invalidCompletionException = [[PromiseHTTPClientInvalidCompletionException alloc]
        initWithPromise: httpResolver.promise
                 client: (OFHTTPClient *)httpClient
                request: successRequest
                 reason: @"invalid"];
    auto cancelledException = [[PromiseHTTPClientCancelledException alloc]
        initWithPromise: httpResolver.promise
                request: successRequest];
    bool caughtTLSStartThrow = false;

    [tlsSuccessDelegate start];
    (void)[tlsSuccessDelegate stream: (OFStream *)tlsSuccessStream
                   didReadIntoBuffer: scratch
                              length: sizeof(scratch)
                           exception: nilptr];
    (void)[tlsSuccessDelegate stream: (OFStream *)tlsSuccessStream
                       didReadString: @"value"
                           exception: nilptr];
    (void)[tlsSuccessDelegate stream: (OFStream *)tlsSuccessStream
                         didReadLine: @"line"
                           exception: nilptr];
    (void)[tlsSuccessDelegate stream: (OFStream *)tlsSuccessStream
                        didWriteData: [OFData dataWithItems: "xy" count: 2]
                         bytesWritten: 2
                            exception: nilptr];
    (void)[tlsSuccessDelegate stream: (OFStream *)tlsSuccessStream
                      didWriteString: @"hello"
                            encoding: OFStringEncodingUTF8
                        bytesWritten: 5
                           exception: nilptr];
    [tlsSuccessDelegate stream: (OFTLSStream *)tlsSuccessStream
      didPerformClientHandshakeWithHost: @"coverage.example"
                              exception: nilptr];

    [tlsMismatchDelegate stream: (OFTLSStream *)[[CoverageTLSStreamHarness alloc] init]
       didPerformClientHandshakeWithHost: @"wrong.example"
                               exception: nilptr];

    [tlsExceptionDelegate stream: (OFTLSStream *)tlsExceptionStream
        didPerformClientHandshakeWithHost: @"coverage.example"
                                exception: [[TestRejectionException alloc] init]];

    [tlsCancelDelegate start];
    [tlsCancelDelegate cancel];

    tlsThrowingStream.throwOnClientHandshakeStart = true;
    @try {
        [tlsThrowingDelegate start];
    } @catch (TestRejectionException *) {
        caughtTLSStartThrow = true;
    }

    [tlsServerDelegate start];
    [tlsServerDelegate streamDidPerformServerHandshake: (OFTLSStream *)tlsServerStream exception: nilptr];
    [tlsServerMismatchDelegate streamDidPerformServerHandshake: (OFTLSStream *)[[CoverageTLSStreamHarness alloc] init] exception: nilptr];
    [tlsServerExceptionDelegate streamDidPerformServerHandshake: (OFTLSStream *)tlsServerExceptionStream exception: [[TestRejectionException alloc] init]];

    [httpBridge start];
    [httpBridge client: (OFHTTPClient *)httpClient
      didCreateTCPSocket: [[OFTCPSocket alloc] init]
                 request: successRequest];
    [httpBridge client: (OFHTTPClient *)httpClient
      didCreateTLSStream: (OFTLSStream *)tlsSuccessStream
                 request: successRequest];
    [httpBridge client: (OFHTTPClient *)httpClient
      wantsRequestBody: (OFStream *)requestBodyToken
               request: successRequest];
    [httpBridge client: (OFHTTPClient *)httpClient
      didReceiveHeaders: @{@"X-Test": @"1"}
             statusCode: 200
                request: successRequest];
    [httpBridge client: (OFHTTPClient *)httpClient
     didPerformRequest: successRequest
              response: successResponse
             exception: nilptr];
    [httpBridge client: (OFHTTPClient *)httpClient
     didPerformRequest: successRequest
              response: successResponse
             exception: nilptr];

    [httpInvalidBridge start];
    [httpInvalidBridge client: (OFHTTPClient *)httpInvalidBridge
            didPerformRequest: CoverageRequest(@"https://example.com/invalid", OFHTTPRequestMethodGet)
                     response: nilptr
                    exception: nilptr];

    [httpExceptionBridge start];
    [httpExceptionBridge client: (OFHTTPClient *)httpExceptionBridge
              didPerformRequest: CoverageRequest(@"https://example.com/exception", OFHTTPRequestMethodGet)
                       response: nilptr
                      exception: [[TestRejectionException alloc] init]];

    [httpThrowingBridge start];
    [httpCancelBeforeStartBridge cancel];
    [httpCancelBeforeStartBridge start];
    [httpCancelAfterStartBridge start];
    [httpCancelAfterStartBridge cancel];
    [httpCancelAfterStartBridge client: (OFHTTPClient *)httpCancelAfterStartClient
                  didPerformRequest: CoverageRequest(@"https://example.com/cancel-after-start", OFHTTPRequestMethodGet)
                           response: nilptr
                          exception: nilptr];

    httpForwardDelegate.redirectDecision = false;

    [AsyncRuntimeTestSupport assertCondition: ([invalidCompletionException.description containsString: @"invalid"])
                                     message: (@"PromiseHTTPClientInvalidCompletionException should include its invalid completion reason")];
    [AsyncRuntimeTestSupport assertCondition: ([cancelledException.description containsString: @"cancelled request"])
                                     message: (@"PromiseHTTPClientCancelledException should describe the cancelled request")];

    [AsyncRuntimeTestSupport assertCondition: ([(id)tlsSuccessStream.delegate isEqual: tlsForwardDelegate]
        and [tlsSuccessStream.clientHandshakeHost isEqual: @"coverage.example"])
                                     message: (@"TLS promise delegates should restore the forward delegate after a successful client handshake")];
    [AsyncRuntimeTestSupport assertCondition: (tlsForwardDelegate.readBufferForwarded
        and tlsForwardDelegate.readStringForwarded
        and tlsForwardDelegate.readLineForwarded
        and tlsForwardDelegate.writeDataForwarded
        and tlsForwardDelegate.writeStringForwarded)
                                     message: (@"TLS promise delegates should forward stream delegate callbacks when available")];
    [AsyncRuntimeTestSupport assertCondition: (tlsSuccessResolver.promise.value == (id)tlsSuccessStream)
                                     message: (@"TLS client handshake delegates should resolve the originating stream on success")];
    [AsyncRuntimeTestSupport assertCondition: ([tlsMismatchResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"TLS client handshake delegates should reject mismatched metadata")];
    [AsyncRuntimeTestSupport assertCondition: ([tlsExceptionResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"TLS client handshake delegates should reject propagated exceptions")];
    [AsyncRuntimeTestSupport assertCondition: (tlsCancelStream.cancelCallCount == 1 and tlsCancelStream.delegate == tlsForwardDelegate)
                                     message: (@"Cancelling TLS promise delegates should restore the forward delegate and cancel ObjFW requests")];
    [AsyncRuntimeTestSupport assertCondition: (caughtTLSStartThrow and tlsThrowingStream.delegate == tlsForwardDelegate)
                                     message: (@"TLS delegate start failures should clean up delegate state before rethrowing")];
    [AsyncRuntimeTestSupport assertCondition: ([tlsServerResolver.promise.value isEqual: (id)tlsServerStream])
                                     message: (@"TLS server handshake delegates should resolve the originating stream on success")];
    [AsyncRuntimeTestSupport assertCondition: ([tlsServerMismatchResolver.promise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"TLS server handshake delegates should reject mismatched stream completions")];
    [AsyncRuntimeTestSupport assertCondition: ([tlsServerExceptionResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"TLS server handshake delegates should reject propagated exceptions")];
    [AsyncRuntimeTestSupport assertCondition: (tlsForwardDelegate.clientHandshakeCallbackCount >= 3
        and tlsForwardDelegate.serverHandshakeCallbackCount >= 3)
                                     message: (@"TLS delegates should still forward handshake completion callbacks after resolving the promise")];

    [AsyncRuntimeTestSupport assertCondition: (httpClient.asyncPerformRequestCount == 1
        and httpClient.closeCallCount >= 1
        and httpForwardDelegate.createdTCPSocketCallbackCount == 1
        and httpForwardDelegate.createdTLSStreamCallbackCount == 1
        and httpForwardDelegate.wantsRequestBodyCallbackCount == 1
        and httpForwardDelegate.receivedHeadersCallbackCount == 1)
                                     message: (@"HTTP promise bridges should start requests and forward optional client delegate callbacks")];
    [AsyncRuntimeTestSupport assertCondition: (httpResolver.promise.value == successResponse
        and httpClient.delegate == nilptr)
                                     message: (@"HTTP promise bridges should resolve responses once and clean up the client delegate afterwards")];
    [AsyncRuntimeTestSupport assertCondition: ([httpInvalidResolver.promise.rejectionException isKindOfClass: PromiseHTTPClientInvalidCompletionException.class])
                                     message: (@"HTTP promise bridges should reject invalid nil/nil completions")];
    [AsyncRuntimeTestSupport assertCondition: ([httpExceptionResolver.promise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"HTTP promise bridges should reject propagated request exceptions")];
    [AsyncRuntimeTestSupport assertCondition: ([httpThrowingResolver.promise.rejectionException isKindOfClass: TestRejectionException.class]
        and httpThrowingClient.closeCallCount == 1)
                                     message: (@"HTTP promise bridges should reject and clean up when starting the request throws")];
    [AsyncRuntimeTestSupport assertCondition: ([httpCancelBeforeStartResolver.promise.rejectionException isKindOfClass: PromiseHTTPClientCancelledException.class]
        and httpCancelBeforeStartClient.closeCallCount >= 1)
                                     message: (@"Cancelling HTTP promise bridges before start should reject and clean up immediately")];
    [AsyncRuntimeTestSupport assertCondition: ([httpCancelAfterStartResolver.promise.rejectionException isKindOfClass: PromiseHTTPClientCancelledException.class]
        and httpCancelAfterStartClient.closeCallCount == 1)
                                     message: (@"Cancelling HTTP promise bridges after start should defer cleanup until the client finishes")];

    [AsyncRuntimeTestSupport assertCondition: ([httpRedirectBridge client: (OFHTTPClient *)httpClient
                                shouldFollowRedirectToIRI: [OFIRI IRIWithString: @"https://example.com/redirect"]
                                               statusCode: 302
                                                  request: CoverageRequest(@"https://example.com/get", OFHTTPRequestMethodGet)
                                                 response: successResponse])
                                     message: (@"HTTP redirect helpers should allow GET redirects when no forward delegate is installed")];
    [AsyncRuntimeTestSupport assertCondition: ([httpRedirectBridge client: (OFHTTPClient *)httpClient
                                shouldFollowRedirectToIRI: [OFIRI IRIWithString: @"https://example.com/head"]
                                               statusCode: 302
                                                  request: CoverageRequest(@"https://example.com/head", OFHTTPRequestMethodHead)
                                                 response: successResponse])
                                     message: (@"HTTP redirect helpers should allow HEAD redirects when no forward delegate is installed")];
    [AsyncRuntimeTestSupport assertCondition: ([httpRedirectBridge client: (OFHTTPClient *)httpClient
                                shouldFollowRedirectToIRI: [OFIRI IRIWithString: @"https://example.com/post-303"]
                                               statusCode: 303
                                                  request: CoverageRequest(@"https://example.com/post", OFHTTPRequestMethodPost)
                                                 response: successResponse])
                                     message: (@"HTTP redirect helpers should allow POST redirects on 303 when no forward delegate is installed")];
    [AsyncRuntimeTestSupport assertCondition: (not [httpRedirectBridge client: (OFHTTPClient *)httpClient
                                     shouldFollowRedirectToIRI: [OFIRI IRIWithString: @"https://example.com/post-302"]
                                                    statusCode: 302
                                                       request: CoverageRequest(@"https://example.com/post", OFHTTPRequestMethodPost)
                                                      response: successResponse])
                                     message: (@"HTTP redirect helpers should reject non-303 POST redirects by default")];
    [AsyncRuntimeTestSupport assertCondition: (not [httpForwardRedirectBridge client: (OFHTTPClient *)httpClient
                                          shouldFollowRedirectToIRI: [OFIRI IRIWithString: @"https://example.com/forwarded"]
                                                         statusCode: 302
                                                            request: CoverageRequest(@"https://example.com/post", OFHTTPRequestMethodPost)
                                                           response: successResponse])
                                     message: (@"HTTP redirect helpers should defer to the forward delegate when present")];
}

ASYNC_RUNTIME_SYNC_TEST(objfw_support_and_dns_internal_branches)
ASYNC_RUNTIME_SYNC_TEST(objfw_tls_and_http_internal_branches)

#pragma clang assume_nonnull end
