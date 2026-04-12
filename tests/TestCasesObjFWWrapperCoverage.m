#import "TestSupport.h"
#import "Async/ObjFWAsync/ObjFWAsync.h"
#import <objc/runtime.h>

#pragma clang assume_nonnull begin

@interface CoverageDNSResolverHarness : OFObject

@property(retain, nonatomic) id<OFDNSResolverQueryDelegate> nillable queryDelegate;
@property(retain, nonatomic) id<OFDNSResolverHostDelegate> nillable hostDelegate;
@property(readonly, nonatomic) size_t closeCallCount;

- (void)asyncPerformQuery: (OFDNSQuery *)query
              runLoopMode: (OFRunLoopMode)runLoopMode
                 delegate: (id<OFDNSResolverQueryDelegate>)delegate;
- (void)asyncResolveAddressesForHost: (OFString *)host
                       addressFamily: (OFSocketAddressFamily)addressFamily
                         runLoopMode: (OFRunLoopMode)runLoopMode
                            delegate: (id<OFDNSResolverHostDelegate>)delegate;
- (void)close;

@end

@implementation CoverageDNSResolverHarness {
    id<OFDNSResolverQueryDelegate> _queryDelegate;
    id<OFDNSResolverHostDelegate> _hostDelegate;
    size_t _closeCallCount;
}

@synthesize queryDelegate = _queryDelegate;
@synthesize hostDelegate = _hostDelegate;
@synthesize closeCallCount = _closeCallCount;

- (void)asyncPerformQuery: (OFDNSQuery *)query
              runLoopMode: (OFRunLoopMode)runLoopMode
                 delegate: (id<OFDNSResolverQueryDelegate>)delegate
{
    (void)query;
    (void)runLoopMode;
    _queryDelegate = delegate;
}

- (void)asyncResolveAddressesForHost: (OFString *)host
                       addressFamily: (OFSocketAddressFamily)addressFamily
                         runLoopMode: (OFRunLoopMode)runLoopMode
                            delegate: (id<OFDNSResolverHostDelegate>)delegate
{
    (void)host;
    (void)addressFamily;
    (void)runLoopMode;
    _hostDelegate = delegate;
}

- (void)close
{
    _closeCallCount++;
}

@end

@interface CoverageDatagramSocketHarness : OFObject

@property(copy, nonatomic) bool (^nillable receiveHandler)(OFDatagramSocket *, void *, size_t, const OFSocketAddress *, id nillable);
@property(copy, nonatomic) OFData *nillable (^sendHandler)(OFDatagramSocket *, OFData *, const OFSocketAddress *, id nillable);
@property(readonly, nonatomic) size_t cancelCallCount;

- (void)asyncReceiveIntoBuffer: (void *)buffer
                        length: (size_t)length
                   runLoopMode: (OFRunLoopMode)runLoopMode
                       handler: (bool (^)(OFDatagramSocket *, void *, size_t, const OFSocketAddress *, id nillable))handler;
- (void)asyncSendData: (OFData *)data
                receiver: (const OFSocketAddress *)receiver
             runLoopMode: (OFRunLoopMode)runLoopMode
                 handler: (OFData *nillable (^)(OFDatagramSocket *, OFData *, const OFSocketAddress *, id nillable))handler;
- (void)cancelAsyncRequests;

@end

@implementation CoverageDatagramSocketHarness {
    bool (^_receiveHandler)(OFDatagramSocket *, void *, size_t, const OFSocketAddress *, id nillable);
    OFData *nillable (^_sendHandler)(OFDatagramSocket *, OFData *, const OFSocketAddress *, id nillable);
    size_t _cancelCallCount;
}

@synthesize receiveHandler = _receiveHandler;
@synthesize sendHandler = _sendHandler;
@synthesize cancelCallCount = _cancelCallCount;

- (void)asyncReceiveIntoBuffer: (void *)buffer
                        length: (size_t)length
                   runLoopMode: (OFRunLoopMode)runLoopMode
                       handler: (bool (^)(OFDatagramSocket *, void *, size_t, const OFSocketAddress *, id nillable))handler
{
    (void)buffer;
    (void)length;
    (void)runLoopMode;
    _receiveHandler = [handler copy];
}

- (void)asyncSendData: (OFData *)data
                receiver: (const OFSocketAddress *)receiver
             runLoopMode: (OFRunLoopMode)runLoopMode
                 handler: (OFData *nillable (^)(OFDatagramSocket *, OFData *, const OFSocketAddress *, id nillable))handler
{
    (void)data;
    (void)receiver;
    (void)runLoopMode;
    _sendHandler = [handler copy];
}

- (void)cancelAsyncRequests
{
    _cancelCallCount++;
}

@end

@interface CoverageStreamSocketHarness : OFObject

@property(copy, nonatomic) bool (^nillable acceptHandler)(OFStreamSocket *, OFStreamSocket *nillable, id nillable);
@property(readonly, nonatomic) size_t cancelCallCount;

- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
                           handler: (bool (^)(OFStreamSocket *, OFStreamSocket *nillable, id nillable))handler;
- (void)cancelAsyncRequests;

@end

@implementation CoverageStreamSocketHarness {
    bool (^_acceptHandler)(OFStreamSocket *, OFStreamSocket *nillable, id nillable);
    size_t _cancelCallCount;
}

@synthesize acceptHandler = _acceptHandler;
@synthesize cancelCallCount = _cancelCallCount;

- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
                           handler: (bool (^)(OFStreamSocket *, OFStreamSocket *nillable, id nillable))handler
{
    (void)runLoopMode;
    _acceptHandler = [handler copy];
}

- (void)cancelAsyncRequests
{
    _cancelCallCount++;
}

@end

@interface CoverageTCPSocketHarness : OFObject

@property(copy, nonatomic) void (^nillable connectHandler)(OFTCPSocket *, OFString *, uint16_t, id nillable);
@property(readonly, nonatomic) size_t cancelCallCount;

- (void)asyncConnectToHost: (OFString *)host
                      port: (uint16_t)port
               runLoopMode: (OFRunLoopMode)runLoopMode
                   handler: (void (^)(OFTCPSocket *, OFString *, uint16_t, id nillable))handler;
- (void)cancelAsyncRequests;

@end

@implementation CoverageTCPSocketHarness {
    void (^_connectHandler)(OFTCPSocket *, OFString *, uint16_t, id nillable);
    size_t _cancelCallCount;
}

@synthesize connectHandler = _connectHandler;
@synthesize cancelCallCount = _cancelCallCount;

- (void)asyncConnectToHost: (OFString *)host
                      port: (uint16_t)port
               runLoopMode: (OFRunLoopMode)runLoopMode
                   handler: (void (^)(OFTCPSocket *, OFString *, uint16_t, id nillable))handler
{
    (void)host;
    (void)port;
    (void)runLoopMode;
    _connectHandler = [handler copy];
}

- (void)cancelAsyncRequests
{
    _cancelCallCount++;
}

@end

@interface CoverageStreamHarness : OFObject

@property(nonatomic) OFStringEncoding encoding;
@property(copy, nonatomic) bool (^nillable readHandler)(OFStream *, void *, size_t, id nillable);
@property(copy, nonatomic) bool (^nillable stringHandler)(OFStream *, OFString *nillable, id nillable);
@property(copy, nonatomic) bool (^nillable lineHandler)(OFStream *, OFString *nillable, id nillable);
@property(copy, nonatomic) OFData *nillable (^writeDataHandler)(OFStream *, OFData *, size_t, id nillable);
@property(copy, nonatomic) OFString *nillable (^writeStringHandler)(OFStream *, OFString *, OFStringEncoding, size_t, id nillable);
@property(readonly, nonatomic) size_t cancelCallCount;

- (void)asyncReadIntoBuffer: (void *)buffer
                     length: (size_t)length
                runLoopMode: (OFRunLoopMode)runLoopMode
                    handler: (bool (^)(OFStream *, void *, size_t, id nillable))handler;
- (void)asyncReadIntoBuffer: (void *)buffer
                exactLength: (size_t)length
                runLoopMode: (OFRunLoopMode)runLoopMode
                    handler: (bool (^)(OFStream *, void *, size_t, id nillable))handler;
- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
                        runLoopMode: (OFRunLoopMode)runLoopMode
                            handler: (bool (^)(OFStream *, OFString *nillable, id nillable))handler;
- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
                      runLoopMode: (OFRunLoopMode)runLoopMode
                          handler: (bool (^)(OFStream *, OFString *nillable, id nillable))handler;
- (void)asyncWriteData: (OFData *)data
                runLoopMode: (OFRunLoopMode)runLoopMode
                    handler: (OFData *nillable (^)(OFStream *, OFData *, size_t, id nillable))handler;
- (void)asyncWriteString: (OFString *)string
                  encoding: (OFStringEncoding)encoding
               runLoopMode: (OFRunLoopMode)runLoopMode
                   handler: (OFString *nillable (^)(OFStream *, OFString *, OFStringEncoding, size_t, id nillable))handler;
- (void)cancelAsyncRequests;

@end

@implementation CoverageStreamHarness {
    OFStringEncoding _encoding;
    bool (^_readHandler)(OFStream *, void *, size_t, id nillable);
    bool (^_stringHandler)(OFStream *, OFString *nillable, id nillable);
    bool (^_lineHandler)(OFStream *, OFString *nillable, id nillable);
    OFData *nillable (^_writeDataHandler)(OFStream *, OFData *, size_t, id nillable);
    OFString *nillable (^_writeStringHandler)(OFStream *, OFString *, OFStringEncoding, size_t, id nillable);
    size_t _cancelCallCount;
}

@synthesize encoding = _encoding;
@synthesize readHandler = _readHandler;
@synthesize stringHandler = _stringHandler;
@synthesize lineHandler = _lineHandler;
@synthesize writeDataHandler = _writeDataHandler;
@synthesize writeStringHandler = _writeStringHandler;
@synthesize cancelCallCount = _cancelCallCount;

- (instancetype)init
{
    self = [super init];
    _encoding = OFStringEncodingUTF8;
    return self;
}

- (void)asyncReadIntoBuffer: (void *)buffer
                     length: (size_t)length
                runLoopMode: (OFRunLoopMode)runLoopMode
                    handler: (bool (^)(OFStream *, void *, size_t, id nillable))handler
{
    (void)buffer;
    (void)length;
    (void)runLoopMode;
    _readHandler = [handler copy];
}

- (void)asyncReadIntoBuffer: (void *)buffer
                exactLength: (size_t)length
                runLoopMode: (OFRunLoopMode)runLoopMode
                    handler: (bool (^)(OFStream *, void *, size_t, id nillable))handler
{
    (void)buffer;
    (void)length;
    (void)runLoopMode;
    _readHandler = [handler copy];
}

- (void)asyncReadStringWithEncoding: (OFStringEncoding)encoding
                        runLoopMode: (OFRunLoopMode)runLoopMode
                            handler: (bool (^)(OFStream *, OFString *nillable, id nillable))handler
{
    (void)encoding;
    (void)runLoopMode;
    _stringHandler = [handler copy];
}

- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
                      runLoopMode: (OFRunLoopMode)runLoopMode
                          handler: (bool (^)(OFStream *, OFString *nillable, id nillable))handler
{
    (void)encoding;
    (void)runLoopMode;
    _lineHandler = [handler copy];
}

- (void)asyncWriteData: (OFData *)data
             runLoopMode: (OFRunLoopMode)runLoopMode
                 handler: (OFData *nillable (^)(OFStream *, OFData *, size_t, id nillable))handler
{
    (void)data;
    (void)runLoopMode;
    _writeDataHandler = [handler copy];
}

- (void)asyncWriteString: (OFString *)string
                  encoding: (OFStringEncoding)encoding
               runLoopMode: (OFRunLoopMode)runLoopMode
                   handler: (OFString *nillable (^)(OFStream *, OFString *, OFStringEncoding, size_t, id nillable))handler
{
    (void)string;
    (void)encoding;
    (void)runLoopMode;
    _writeStringHandler = [handler copy];
}

- (void)cancelAsyncRequests
{
    _cancelCallCount++;
}

@end

static void install_wrapper_method(Class sourceClass, Class targetClass, SEL selector)
{
    Method method = class_getInstanceMethod(sourceClass, selector);

    [AsyncRuntimeTestSupport assertCondition: (method != NULL)
                                     message: (@"Expected ObjFW wrapper selector to exist before installing the harness shim")];
    class_addMethod(targetClass, selector, method_getImplementation(method), method_getTypeEncoding(method));
}

static void install_objfw_wrapper_methods_if_needed(void)
{
    static bool installed = false;

    if (installed)
        return;

    installed = true;

    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToPerformQuery:onScheduler:));
    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToPerformQuery:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToResolveAddressesForHost:onScheduler:));
    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToResolveAddressesForHost:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToResolveAddressesForHost:addressFamily:onScheduler:));
    install_wrapper_method(OFDNSResolver.class, CoverageDNSResolverHarness.class, @selector(promiseToResolveAddressesForHost:addressFamily:onScheduler:cancelOnTaskCancellation:));

    install_wrapper_method(OFDatagramSocket.class, CoverageDatagramSocketHarness.class, @selector(promiseToReceiveIntoBuffer:length:onScheduler:));
    install_wrapper_method(OFDatagramSocket.class, CoverageDatagramSocketHarness.class, @selector(promiseToReceiveIntoBuffer:length:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFDatagramSocket.class, CoverageDatagramSocketHarness.class, @selector(promiseToSendData:receiver:onScheduler:));
    install_wrapper_method(OFDatagramSocket.class, CoverageDatagramSocketHarness.class, @selector(promiseToSendData:receiver:onScheduler:cancelOnTaskCancellation:));

    install_wrapper_method(OFStreamSocket.class, CoverageStreamSocketHarness.class, @selector(promiseToAcceptOnScheduler:));
    install_wrapper_method(OFStreamSocket.class, CoverageStreamSocketHarness.class, @selector(promiseToAcceptOnScheduler:cancelOnTaskCancellation:));

    install_wrapper_method(OFTCPSocket.class, CoverageTCPSocketHarness.class, @selector(promiseToConnectToHost:port:onScheduler:));
    install_wrapper_method(OFTCPSocket.class, CoverageTCPSocketHarness.class, @selector(promiseToConnectToHost:port:onScheduler:cancelOnTaskCancellation:));

    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadIntoBuffer:length:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadIntoBuffer:length:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadIntoBuffer:exactLength:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadIntoBuffer:exactLength:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadStringOnScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadStringOnScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadStringWithEncoding:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadStringWithEncoding:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadLineOnScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadLineOnScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadLineWithEncoding:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToReadLineWithEncoding:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteData:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteData:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteString:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteString:onScheduler:cancelOnTaskCancellation:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteString:encoding:onScheduler:));
    install_wrapper_method(OFStream.class, CoverageStreamHarness.class, @selector(promiseToWriteString:encoding:onScheduler:cancelOnTaskCancellation:));
}

static void pump_scheduler_until(AsyncScheduler *scheduler, bool (^condition)(void))
{
    for (size_t iteration = 0; iteration < 200 and not condition(); iteration++) {
        auto deadline = [[OFDate alloc] initWithTimeIntervalSinceNow: 0.01];
        [scheduler.runLoop runMode: scheduler.mode beforeDate: deadline];
    }
}

static void assert_wrapper_timeout_triggers_cancellation(AsyncScope *rootScope,
                                                         Promise * (^makePromise)(void),
                                                         bool (^didStart)(void),
                                                         size_t (^cancelCallCount)(void),
                                                         OFString *message)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    Promise *promise = makePromise();
    bool caughtTimeout = false;

    while (not didStart())
        [[scheduler sleepForTimeInterval: 0.001] await];

    @try {
        (void)[rootScope withTimeout: 0.01 block: ^id(AsyncScope *scope) {
            (void)scope;
            (void)promise.await;
            return AsyncUnit.unit;
        }];
    } @catch (AsyncTimeoutException *) {
        caughtTimeout = true;
    }

    [[scheduler sleepForTimeInterval: 0.001] await];

    [AsyncRuntimeTestSupport assertCondition: (caughtTimeout and cancelCallCount() == 1)
                                     message: message];
}

static void objfw_socket_and_stream_wrapper_error_branches(void)
{
    install_objfw_wrapper_methods_if_needed();

    auto scheduler = [[AsyncScheduler alloc] initWithRunLoop: $assert_nonnil(OFRunLoop.currentRunLoop)];
    OFSocketAddress receiverAddress = OFSocketAddressParseIPv4(@"127.0.0.1", 4242);
    OFSocketAddress otherAddress = OFSocketAddressParseIPv4(@"127.0.0.1", 4343);
    char streamBuffer[4] = {0};
    char otherStreamBuffer[4] = {0};
    char datagramBuffer[4] = {0};
    char otherDatagramBuffer[4] = {0};
    auto query = [OFDNSQuery queryWithDomainName: @"coverage.example"
                                        DNSClass: OFDNSClassIN
                                      recordType: OFDNSRecordTypeTXT];
    auto response = [OFDNSResponse responseWithDomainName: @"coverage.example"
                                             answerRecords: @{}
                                          authorityRecords: @{}
                                         additionalRecords: @{}];
    auto dnsResolver = [[CoverageDNSResolverHarness alloc] init];
    auto datagramSocket = [[CoverageDatagramSocketHarness alloc] init];
    auto streamSocket = [[CoverageStreamSocketHarness alloc] init];
    auto tcpSocket = [[CoverageTCPSocketHarness alloc] init];
    auto stream = [[CoverageStreamHarness alloc] init];
    auto data = [OFData dataWithItems: "xy" count: 2];
    auto dnsQueryExceptionPromise = [(id)dnsResolver promiseToPerformQuery: query onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return dnsResolver.queryDelegate != nilptr; });
    [dnsResolver.queryDelegate resolver: (OFDNSResolver *)dnsResolver
                        didPerformQuery: query
                               response: nilptr
                              exception: [[TestRejectionException alloc] init]];
    [AsyncRuntimeTestSupport assertCondition: ([dnsQueryExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"DNS query wrappers should reject propagated exceptions")];

    dnsResolver.queryDelegate = nilptr;
    auto dnsQueryMismatchPromise = [(id)dnsResolver promiseToPerformQuery: query onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return dnsResolver.queryDelegate != nilptr; });
    [dnsResolver.queryDelegate resolver: (OFDNSResolver *)[[CoverageDNSResolverHarness alloc] init]
                        didPerformQuery: query
                               response: response
                              exception: nilptr];
    [AsyncRuntimeTestSupport assertCondition: ([dnsQueryMismatchPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"DNS query wrappers should reject mismatched metadata")];

    dnsResolver.queryDelegate = nilptr;
    auto dnsQueryNilResponsePromise = [(id)dnsResolver promiseToPerformQuery: query onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return dnsResolver.queryDelegate != nilptr; });
    [dnsResolver.queryDelegate resolver: (OFDNSResolver *)dnsResolver
                        didPerformQuery: query
                               response: nilptr
                              exception: nilptr];
    [AsyncRuntimeTestSupport assertCondition: ([dnsQueryNilResponsePromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"DNS query wrappers should reject nil-response completions")];

    auto datagramReceiveExceptionPromise = [(id)datagramSocket promiseToReceiveIntoBuffer: datagramBuffer length: sizeof(datagramBuffer) onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return datagramSocket.receiveHandler != nilptr; });
    (void)datagramSocket.receiveHandler((OFDatagramSocket *)datagramSocket, datagramBuffer, 1, &receiverAddress, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([datagramReceiveExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Datagram receive wrappers should reject propagated exceptions")];

    datagramSocket.receiveHandler = nilptr;
    auto datagramReceiveMismatchPromise = [(id)datagramSocket promiseToReceiveIntoBuffer: datagramBuffer length: sizeof(datagramBuffer) onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return datagramSocket.receiveHandler != nilptr; });
    (void)datagramSocket.receiveHandler((OFDatagramSocket *)datagramSocket, otherDatagramBuffer, 1, &receiverAddress, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([datagramReceiveMismatchPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Datagram receive wrappers should reject buffer mismatches")];

    auto datagramSendExceptionPromise = [(id)datagramSocket promiseToSendData: data receiver: &receiverAddress onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return datagramSocket.sendHandler != nilptr; });
    (void)datagramSocket.sendHandler((OFDatagramSocket *)datagramSocket, data, &receiverAddress, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([datagramSendExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Datagram send wrappers should reject propagated exceptions")];

    datagramSocket.sendHandler = nilptr;
    auto datagramSendMismatchPromise = [(id)datagramSocket promiseToSendData: data receiver: &receiverAddress onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return datagramSocket.sendHandler != nilptr; });
    (void)datagramSocket.sendHandler((OFDatagramSocket *)datagramSocket, data, &otherAddress, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([datagramSendMismatchPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Datagram send wrappers should reject receiver mismatches")];

    auto acceptExceptionPromise = [(id)streamSocket promiseToAcceptOnScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return streamSocket.acceptHandler != nilptr; });
    (void)streamSocket.acceptHandler((OFStreamSocket *)streamSocket, nilptr, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([acceptExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Stream socket accept wrappers should reject propagated exceptions")];

    streamSocket.acceptHandler = nilptr;
    auto acceptNilSocketPromise = [(id)streamSocket promiseToAcceptOnScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return streamSocket.acceptHandler != nilptr; });
    (void)streamSocket.acceptHandler((OFStreamSocket *)streamSocket, nilptr, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([acceptNilSocketPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Stream socket accept wrappers should reject nil-socket completions")];

    auto connectExceptionPromise = [(id)tcpSocket promiseToConnectToHost: @"coverage.example" port: 443 onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return tcpSocket.connectHandler != nilptr; });
    tcpSocket.connectHandler((OFTCPSocket *)tcpSocket, @"coverage.example", 443, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([connectExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"TCP connect wrappers should reject propagated exceptions")];

    tcpSocket.connectHandler = nilptr;
    auto connectMismatchPromise = [(id)tcpSocket promiseToConnectToHost: @"coverage.example" port: 443 onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return tcpSocket.connectHandler != nilptr; });
    tcpSocket.connectHandler((OFTCPSocket *)[[CoverageTCPSocketHarness alloc] init], @"wrong.example", 80, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([connectMismatchPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"TCP connect wrappers should reject mismatched metadata")];

    auto readExceptionPromise = [(id)stream promiseToReadIntoBuffer: streamBuffer length: sizeof(streamBuffer) onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.readHandler != nilptr; });
    (void)stream.readHandler((OFStream *)stream, streamBuffer, 1, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([readExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Stream read wrappers should reject propagated exceptions")];

    stream.readHandler = nilptr;
    auto readMismatchPromise = [(id)stream promiseToReadIntoBuffer: streamBuffer exactLength: sizeof(streamBuffer) onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.readHandler != nilptr; });
    (void)stream.readHandler((OFStream *)stream, otherStreamBuffer, 1, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([readMismatchPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Stream read wrappers should reject buffer mismatches")];

    auto readStringExceptionPromise = [(id)stream promiseToReadStringOnScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.stringHandler != nilptr; });
    (void)stream.stringHandler((OFStream *)stream, nilptr, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([readStringExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Stream string wrappers should reject propagated exceptions")];

    auto writeDataExceptionPromise = [(id)stream promiseToWriteData: data onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.writeDataHandler != nilptr; });
    (void)stream.writeDataHandler((OFStream *)stream, data, data.count * data.itemSize, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([writeDataExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Stream data writers should reject propagated exceptions")];

    stream.writeDataHandler = nilptr;
    auto writeDataPartialPromise = [(id)stream promiseToWriteData: data onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.writeDataHandler != nilptr; });
    (void)stream.writeDataHandler((OFStream *)stream, data, 1, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([writeDataPartialPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Stream data writers should reject partial writes without exceptions")];

    auto writeStringExceptionPromise = [(id)stream promiseToWriteString: @"hello" onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.writeStringHandler != nilptr; });
    (void)stream.writeStringHandler((OFStream *)stream, @"hello", OFStringEncodingUTF8, 5, [[TestRejectionException alloc] init]);
    [AsyncRuntimeTestSupport assertCondition: ([writeStringExceptionPromise.rejectionException isKindOfClass: TestRejectionException.class])
                                     message: (@"Stream string writers should reject propagated exceptions")];

    stream.writeStringHandler = nilptr;
    auto writeStringEncodingPromise = [(id)stream promiseToWriteString: @"hello" encoding: OFStringEncodingUTF8 onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.writeStringHandler != nilptr; });
    (void)stream.writeStringHandler((OFStream *)stream, @"hello", OFStringEncodingASCII, 5, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([writeStringEncodingPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Stream string writers should reject encoding mismatches")];

    stream.writeStringHandler = nilptr;
    auto writeStringPartialPromise = [(id)stream promiseToWriteString: @"hello" onScheduler: scheduler];
    pump_scheduler_until(scheduler, ^bool { return stream.writeStringHandler != nilptr; });
    (void)stream.writeStringHandler((OFStream *)stream, @"hello", OFStringEncodingUTF8, 1, nilptr);
    [AsyncRuntimeTestSupport assertCondition: ([writeStringPartialPromise.rejectionException isKindOfClass: PromiseObjFWInvalidCompletionException.class])
                                     message: (@"Stream string writers should reject partial writes")];

    [scheduler shutdown];
}

ASYNC_RUNTIME_SYNC_TEST(objfw_socket_and_stream_wrapper_error_branches)

static void objfw_wrapper_cancellation_branches(AsyncScope *rootScope)
{
    install_objfw_wrapper_methods_if_needed();

    AsyncScheduler *scheduler = rootScope.scheduler;
    OFSocketAddress receiverAddress = OFSocketAddressParseIPv4(@"127.0.0.1", 4242);
    char datagramBuffer[4] = {0};
    char streamBuffer[4] = {0};
    void *datagramBufferPointer = datagramBuffer;
    void *streamBufferPointer = streamBuffer;
    auto query = [OFDNSQuery queryWithDomainName: @"coverage.example"
                                        DNSClass: OFDNSClassIN
                                      recordType: OFDNSRecordTypeTXT];
    auto data = [OFData dataWithItems: "xy" count: 2];

    {
        auto resolver = [[CoverageDNSResolverHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)resolver promiseToPerformQuery: query onScheduler: scheduler cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return resolver.queryDelegate != nilptr;
                                                     },
                                                     ^size_t {
                                                         return resolver.closeCallCount;
                                                     },
                                                     @"DNS query promise cancellation should close the resolver after the async query starts");
    }

    {
        auto resolver = [[CoverageDNSResolverHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)resolver promiseToResolveAddressesForHost: @"coverage.example"
                                                                                                  onScheduler: scheduler
                                                                                       cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return resolver.hostDelegate != nilptr;
                                                     },
                                                     ^size_t {
                                                         return resolver.closeCallCount;
                                                     },
                                                     @"DNS host resolution cancellation should close the resolver after the async lookup starts");
    }

    {
        auto socket = [[CoverageDatagramSocketHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)socket promiseToReceiveIntoBuffer: datagramBufferPointer
                                                                                               length: sizeof(datagramBuffer)
                                                                                          onScheduler: scheduler
                                                                               cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return socket.receiveHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return socket.cancelCallCount;
                                                     },
                                                     @"Datagram receive cancellation should cancel the underlying ObjFW request");
    }

    {
        auto socket = [[CoverageDatagramSocketHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)socket promiseToSendData: data
                                                                                     receiver: &receiverAddress
                                                                                  onScheduler: scheduler
                                                                       cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return socket.sendHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return socket.cancelCallCount;
                                                     },
                                                     @"Datagram send cancellation should cancel the underlying ObjFW request");
    }

    {
        auto socket = [[CoverageStreamSocketHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)socket promiseToAcceptOnScheduler: scheduler cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return socket.acceptHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return socket.cancelCallCount;
                                                     },
                                                     @"Stream accept cancellation should cancel the underlying ObjFW request");
    }

    {
        auto socket = [[CoverageTCPSocketHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)socket promiseToConnectToHost: @"coverage.example"
                                                                                              port: 443
                                                                                       onScheduler: scheduler
                                                                            cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return socket.connectHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return socket.cancelCallCount;
                                                     },
                                                     @"TCP connect cancellation should cancel the underlying ObjFW request");
    }

    {
        auto stream = [[CoverageStreamHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)stream promiseToReadIntoBuffer: streamBufferPointer
                                                                                             length: sizeof(streamBuffer)
                                                                                        onScheduler: scheduler
                                                                             cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return stream.readHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return stream.cancelCallCount;
                                                     },
                                                     @"Stream read cancellation should cancel the underlying ObjFW request");
    }

    {
        auto stream = [[CoverageStreamHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)stream promiseToReadStringOnScheduler: scheduler cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return stream.stringHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return stream.cancelCallCount;
                                                     },
                                                     @"Stream string-read cancellation should cancel the underlying ObjFW request");
    }

    {
        auto stream = [[CoverageStreamHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)stream promiseToWriteData: data onScheduler: scheduler cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return stream.writeDataHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return stream.cancelCallCount;
                                                     },
                                                     @"Stream data-write cancellation should cancel the underlying ObjFW request");
    }

    {
        auto stream = [[CoverageStreamHarness alloc] init];
        assert_wrapper_timeout_triggers_cancellation(rootScope,
                                                     ^Promise * {
                                                         return [(id)stream promiseToWriteString: @"hello"
                                                                                   onScheduler: scheduler
                                                                        cancelOnTaskCancellation: true];
                                                     },
                                                     ^bool {
                                                         return stream.writeStringHandler != nilptr;
                                                     },
                                                     ^size_t {
                                                         return stream.cancelCallCount;
                                                     },
                                                     @"Stream string-write cancellation should cancel the underlying ObjFW request");
    }
}

ASYNC_RUNTIME_ASYNC_TEST(objfw_wrapper_cancellation_branches)

#pragma clang assume_nonnull end
