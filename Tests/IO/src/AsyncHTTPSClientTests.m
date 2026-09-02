#import <IO.h>
#import <ObjFWTest/ObjFWTest.h>

#include <stdatomic.h>
#include <stdlib.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSTestServerDelegate: OFObject <OFHTTPServerDelegate>
@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSTestServerThread: OFThread

@property(readonly, nonatomic) uint16_t port;

- (instancetype)initWithCertificatePath: (OFString *)certificatePath
                             privateKeyPath: (OFString *)privateKeyPath;
- (instancetype)init [[clang::unavailable]];
- (void)waitUntilReady;
- (void)stopAndJoin;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSTestTLSStallThread: OFThread

@property(readonly, nonatomic) uint16_t port;

- (void)waitUntilReady;
- (void)stopAndJoin;

@end


@implementation AsyncHTTPSTestServerDelegate

- (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)request
        requestBody: (OFStream *nillable)requestBody
           response: (OFHTTPResponse *)response
{
    (void)server;
    (void)requestBody;

    @try {
        if ([request.IRI.path isEqual: @"/ok"]) {
            const char bytes[] = "bounded-https";
            response.statusCode = 200;
            response.headers = @{
                @"Content-Length": @"13",
                @"Content-Type": @"text/plain",
                @"X-AsyncRT-Test": @"yes"
            };
            [response writeBuffer: bytes length: sizeof(bytes) - 1];
            [response close];
            return;
        }

        if ([request.IRI.path isEqual: @"/body-limit"]) {
            char bytes[128];
            memset(bytes, 'b', sizeof(bytes));
            response.statusCode = 200;
            response.headers = @{
                @"Content-Length": @"128",
                @"Content-Type": @"application/octet-stream"
            };
            [response writeBuffer: bytes length: sizeof(bytes)];
            [response close];
            return;
        }

        if ([request.IRI.path isEqual: @"/header-limit"]) {
            auto headers = [OFMutableDictionary dictionary];
            auto value = [OFMutableString string];
            while (value.length < 1024)
                [value appendString: @"hhhhhhhhhhhhhhhh"];
            for (size_t index = 0; index < 80; index++)
                headers[[OFString stringWithFormat: @"X-Large-%zu", index]] =
                    value;
            headers[@"Content-Length"] = @"0";
            response.statusCode = 200;
            response.headers = headers;
            [response close];
            return;
        }

        if ([request.IRI.path isEqual: @"/slow"]) {
            [OFThread sleepForTimeInterval: 0.5];
            const char bytes[] = "late";
            response.statusCode = 200;
            response.headers = @{ @"Content-Length": @"4" };
            [response writeBuffer: bytes length: sizeof(bytes) - 1];
            [response close];
            return;
        }

        if ([request.IRI.path isEqual: @"/redirect"]) {
            response.statusCode = 302;
            response.headers = @{
                @"Content-Length": @"0",
                @"Location": @"/ok"
            };
            [response close];
            return;
        }

        response.statusCode = 404;
        response.headers = @{ @"Content-Length": @"0" };
        [response close];
    } @catch (OFException *exception) {
        (void)exception;
    }
}

- (void)server: (OFHTTPServer *)server
  didEncounterException: (id)exception
                request: (OFHTTPRequest *nillable)request
               response: (OFHTTPResponse *nillable)response
{
    (void)server;
    (void)exception;
    (void)request;
    (void)response;
}

@end

@implementation AsyncHTTPSTestServerThread {
    OFString *_certificatePath;
    OFString *_privateKeyPath;
    OFCondition *_condition;
    bool _ready;
    bool _stopping;
    uint16_t _port;
    OFException *nillable _startupError;
}

- (instancetype)initWithCertificatePath: (OFString *)certificatePath
                             privateKeyPath: (OFString *)privateKeyPath
{
    self = [super init];
    _certificatePath = [certificatePath copy];
    _privateKeyPath = [privateKeyPath copy];
    _condition = [OFCondition condition];
    self.supportsSockets = true;
    return self;
}

- (uint16_t)port
{
    [_condition lock];
    @try {
        return _port;
    } @finally {
        [_condition unlock];
    }
}

- (id nillable)main
{
    OFHTTPServer *nillable server = nilptr;

    @try {
        auto certificateIRI = [OFIRI fileIRIWithPath: _certificatePath];
        auto privateKeyIRI = [OFIRI fileIRIWithPath: _privateKeyPath];
        auto certificateChain = [OFX509Certificate
            certificateChainFromPEMFileAtIRI: certificateIRI
            privateKeyIRI: privateKeyIRI];
        auto delegate = [[AsyncHTTPSTestServerDelegate alloc] init];
        server = [OFHTTPServer server];
        server.host = @"127.0.0.1";
        server.port = 0;
        server.numberOfThreads = 1;
        server.usesTLS = true;
        server.certificateChain = certificateChain;
        server.delegate = delegate;
        [server start];

        [_condition lock];
        @try {
            _port = server.port;
            _ready = true;
            [_condition broadcast];
        } @finally {
            [_condition unlock];
        }

        while (true) {
            [_condition lock];
            @try {
                if (_stopping)
                    break;
            } @finally {
                [_condition unlock];
            }

            [OFRunLoop.currentRunLoop runMode: OFDefaultRunLoopMode
                beforeDate: [OFDate dateWithTimeIntervalSinceNow: 0.01]];
        }

        [server stop];
    } @catch (OFException *exception) {
        [_condition lock];
        @try {
            _startupError = exception;
            _ready = true;
            [_condition broadcast];
        } @finally {
            [_condition unlock];
        }

        if (server != nilptr)
            [server stop];
    }

    return nilptr;
}

- (void)waitUntilReady
{
    [_condition lock];
    @try {
        while (!_ready)
            [_condition wait];
        if (_startupError != nilptr)
            @throw $assert_nonnil(_startupError);
    } @finally {
        [_condition unlock];
    }
}

- (void)stopAndJoin
{
    [_condition lock];
    @try {
        _stopping = true;
    } @finally {
        [_condition unlock];
    }
    [self join];
}

@end


@implementation AsyncHTTPSTestTLSStallThread {
    OFCondition *_condition;
    OFTCPSocket *nillable _listener;
    OFTCPSocket *nillable _accepted;
    uint16_t _port;
    bool _ready;
    bool _stopping;
    OFException *nillable _startupError;
}

- (instancetype)init
{
    self = [super init];
    _condition = [OFCondition condition];
    self.supportsSockets = true;
    return self;
}

- (uint16_t)port
{
    [_condition lock];
    @try {
        return _port;
    } @finally {
        [_condition unlock];
    }
}

- (id nillable)main
{
    @try {
        auto listener = [OFTCPSocket socket];
        OFSocketAddress address = [listener bindToHost: @"127.0.0.1"
            port: 0];
        [listener listen];

        [_condition lock];
        @try {
            _listener = listener;
            _port = OFSocketAddressIPPort(&address);
            _ready = true;
            [_condition broadcast];
        } @finally {
            [_condition unlock];
        }

        OFTCPSocket *accepted = [listener accept];
        [_condition lock];
        @try {
            _accepted = accepted;
            while (!_stopping)
                [_condition wait];
        } @finally {
            [_condition unlock];
        }
    } @catch (OFException *exception) {
        [_condition lock];
        @try {
            if (!_ready) {
                _startupError = exception;
                _ready = true;
                [_condition broadcast];
            }
        } @finally {
            [_condition unlock];
        }
    }

    return nilptr;
}

- (void)waitUntilReady
{
    [_condition lock];
    @try {
        while (!_ready)
            [_condition wait];
        if (_startupError != nilptr)
            @throw $assert_nonnil(_startupError);
    } @finally {
        [_condition unlock];
    }
}

- (void)stopAndJoin
{
    [_condition lock];
    @try {
        _stopping = true;
        [_condition broadcast];
        if (_accepted != nilptr)
            [$assert_nonnil(_accepted) close];
        if (_listener != nilptr)
            [$assert_nonnil(_listener) close];
    } @finally {
        [_condition unlock];
    }
    [self join];
}

@end


@interface AsyncHTTPSClientTests: OTTestCase

- (OFString *)certificatePEM;
- (OFString *)privateKeyPEM;
- (void)removeTLSFixtures;
- (OFIRI *)IRIWithPath: (OFString *)path;
- (void)assertPath: (OFString *)path
          bodyLimit: (size_t)bodyLimit
       failsWithCode: (enum AsyncHTTPSClientErrorCode)code;

@end

@implementation AsyncHTTPSClientTests {
    AsyncHTTPSClient *_client;
    AsyncHTTPSTestServerThread *_serverThread;
    OFString *_certificatePath;
    OFString *_privateKeyPath;
    OFDictionary<OFString *, OFArray<OFString *> *> *_savedStaticHosts;
    OFTimeInterval _savedResolverConfigReloadInterval;
    OFString *nillable _savedSSLCertificateFile;
    bool _serverThreadStarted;
}

- (void)setUp
{
    [super setUp];
    OFString *identifier = OFUUID.UUID.UUIDString;
    auto temporaryDirectoryIRI = $assert_nonnil(
        OFSystemInfo.temporaryDirectoryIRI);
    _certificatePath = [[temporaryDirectoryIRI IRIByAppendingPathComponent:
        [OFString stringWithFormat: @"AsyncRT-HTTPS-%@-certificate.pem",
            identifier]].fileSystemRepresentation copy];
    _privateKeyPath = [[temporaryDirectoryIRI IRIByAppendingPathComponent:
        [OFString stringWithFormat: @"AsyncRT-HTTPS-%@-private-key.pem",
            identifier]].fileSystemRepresentation copy];

    @try {
        [[self.certificatePEM dataWithEncoding: OFStringEncodingUTF8]
            writeToFile: _certificatePath];
        [[self.privateKeyPEM dataWithEncoding: OFStringEncodingUTF8]
            writeToFile: _privateKeyPath];

        const char *nillable oldSSLCertificateFile =
            getenv("SSL_CERT_FILE");
        if (oldSSLCertificateFile != nullptr)
            _savedSSLCertificateFile = [OFString stringWithUTF8String:
                (const char *nonnil)oldSSLCertificateFile];
        setenv("SSL_CERT_FILE", _certificatePath.UTF8String, 1);

        auto resolver = OFThread.DNSResolver;
        _savedStaticHosts = [resolver.staticHosts copy];
        _savedResolverConfigReloadInterval = resolver.configReloadInterval;
        resolver.configReloadInterval = 0;
        auto staticHosts = $assert_nonnil(
            [resolver.staticHosts mutableCopy]);
        staticHosts[@"search.test"] = @[@"127.0.0.1"];
        staticHosts[@"other.test"] = @[@"127.0.0.1"];
        resolver.staticHosts = staticHosts;

        _serverThread = [[AsyncHTTPSTestServerThread alloc]
            initWithCertificatePath: _certificatePath
                      privateKeyPath: _privateKeyPath];
        [_serverThread start];
        _serverThreadStarted = true;
        [_serverThread waitUntilReady];
        _client = [[AsyncHTTPSClient alloc] init];
    } @catch (id exception) {
        if (_serverThreadStarted)
            [_serverThread stopAndJoin];
        [self removeTLSFixtures];
        @throw exception;
    }
}

- (void)tearDown
{
    @try {
        if (_serverThreadStarted)
            [_serverThread stopAndJoin];
    } @finally {
        auto resolver = OFThread.DNSResolver;
        if (_savedStaticHosts != nilptr)
            resolver.staticHosts = _savedStaticHosts;
        resolver.configReloadInterval = _savedResolverConfigReloadInterval;
        if (_savedSSLCertificateFile == nilptr)
            unsetenv("SSL_CERT_FILE");
        else
            setenv("SSL_CERT_FILE",
                $assert_nonnil(_savedSSLCertificateFile).UTF8String, 1);
        [self removeTLSFixtures];
        [super tearDown];
    }
}

- (void)removeTLSFixtures
{
    auto manager = OFFileManager.defaultManager;
    if (_certificatePath != nilptr
        && [manager fileExistsAtPath: _certificatePath])
        [manager removeItemAtPath: _certificatePath];
    if (_privateKeyPath != nilptr
        && [manager fileExistsAtPath: _privateKeyPath])
        [manager removeItemAtPath: _privateKeyPath];
}

- (OFIRI *)IRIWithPath: (OFString *)path
{
    return [OFIRI IRIWithString: [OFString stringWithFormat:
        @"https://search.test:%u%@", _serverThread.port, path]];
}

- (void)assertPath: (OFString *)path
          bodyLimit: (size_t)bodyLimit
       failsWithCode: (enum AsyncHTTPSClientErrorCode)code
{
    bool didThrow = false;
    @try {
        (void)[_client performGETToIRI: [self IRIWithPath: path]
            headers: @{}
            wallTimeout: 1
            maximumResponseBodyBytes: bodyLimit
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code, code,
            @"the bounded HTTPS request must report its safe error category");
    }
    OTAssertTrue(didThrow, @"the bounded HTTPS request must fail");
}

- (void)testSuccessfulVerifiedGETPreservesBoundedResponse
{
    const char *nillable oldHTTPSProxy = getenv("HTTPS_PROXY");
    const char *nillable oldAllProxy = getenv("ALL_PROXY");
    OFString *nillable savedHTTPSProxy = oldHTTPSProxy == nullptr ? nilptr
        : [OFString stringWithUTF8String:
            (const char *nonnil)oldHTTPSProxy];
    OFString *nillable savedAllProxy = oldAllProxy == nullptr ? nilptr
        : [OFString stringWithUTF8String:
            (const char *nonnil)oldAllProxy];
    AsyncHTTPSResponse *result;

    setenv("HTTPS_PROXY", "http://127.0.0.1:1", 1);
    setenv("ALL_PROXY", "http://127.0.0.1:1", 1);
    @try {
        result = [_client performGETToIRI: [self IRIWithPath: @"/ok"]
            headers: @{ @"Accept": @"text/plain" }
            wallTimeout: 1
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @finally {
        if (savedHTTPSProxy == nilptr)
            unsetenv("HTTPS_PROXY");
        else
            setenv("HTTPS_PROXY", savedHTTPSProxy.UTF8String, 1);
        if (savedAllProxy == nilptr)
            unsetenv("ALL_PROXY");
        else
            setenv("ALL_PROXY", savedAllProxy.UTF8String, 1);
    }
    const char expectedBytes[] = "bounded-https";
    auto expected = [OFData dataWithItems: expectedBytes
        count: sizeof(expectedBytes) - 1];

    OTAssertEqual(result.statusCode, (unsigned short)200,
        @"the verified HTTPS request must preserve the response status");
    OTAssertEqualObjects(result.body, expected,
        @"the verified HTTPS request must return the complete bounded body");
    OTAssertTrue(result.headerData.count > 0,
        @"the verified HTTPS request must retain bounded raw headers");
}

- (void)testRedirectsAreNotFollowed
{
    auto result = [_client performGETToIRI:
        [self IRIWithPath: @"/redirect"]
        headers: @{}
        wallTimeout: 1
        maximumResponseBodyBytes: 64
        isCancellationRequested: ^bool { return false; }];

    OTAssertEqual(result.statusCode, (unsigned short)302,
        @"the HTTPS client must return redirects without following them");
    OTAssertEqual(result.body.count, (size_t)0,
        @"the redirect target body must not be fetched");
}

- (void)testOneClientSupportsConcurrentIndependentRequests
{
    auto results = [OFMutableArray<OFData *> array];
    auto failures = [OFMutableArray<OFException *> array];
    auto threads = [OFMutableArray<OFThread *> array];
    OFIRI *IRI = [self IRIWithPath: @"/ok"];

    for (size_t index = 0; index < 6; index++) {
        auto thread = [OFThread threadWithBlock: ^id nillable {
            @try {
                auto resolver = OFThread.DNSResolver;
                resolver.configReloadInterval = 0;
                auto staticHosts = $assert_nonnil(
                    [resolver.staticHosts mutableCopy]);
                staticHosts[@"search.test"] = @[@"127.0.0.1"];
                resolver.staticHosts = staticHosts;
                auto response = [_client performGETToIRI: IRI
                    headers: @{} wallTimeout: 2
                    maximumResponseBodyBytes: 64
                    isCancellationRequested: ^bool { return false; }];
                @synchronized (results) {
                    [results addObject: response.body];
                }
            } @catch (OFException *exception) {
                @synchronized (failures) {
                    [failures addObject: exception];
                }
            }
            return nilptr;
        }];
        thread.supportsSockets = true;
        [threads addObject: thread];
        [thread start];
    }
    for (OFThread *thread in threads)
        [thread join];

    OTAssertEqual(failures.count, (size_t)0, @"%@", failures);
    OTAssertEqual(results.count, (size_t)6,
        @"every provider lane must own an independent OFHTTPClient request");
}

- (void)testBodyLimitIsEnforcedInTheWriteCallback
{
    [self assertPath: @"/body-limit" bodyLimit: 32
        failsWithCode: AsyncHTTPSClientErrorCode_BODY_TOO_LARGE];
}

- (void)testAggregateHeaderLimitIsEnforced
{
    [self assertPath: @"/header-limit" bodyLimit: 1
        failsWithCode: AsyncHTTPSClientErrorCode_HEADER_TOO_LARGE];
}

- (void)testDeadlineStopsAStalledResponseAfterConnection
{
    OFDate *startedAt = OFDate.date;
    bool didThrow = false;
    @try {
        (void)[_client performGETToIRI: [self IRIWithPath: @"/slow"]
            headers: @{}
            wallTimeout: 0.08
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code,
            AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED,
            @"a stalled HTTPS response must report a deadline error");
    }

    OFTimeInterval elapsed = -startedAt.timeIntervalSinceNow;
    OTAssertTrue(didThrow, @"a stalled HTTPS response must fail");
    OTAssertTrue(elapsed < 0.3,
        @"the response-phase deadline must cancel the live transport promptly");
}

- (void)testDeadlineCancelsAStalledTLSHandshake
{
    auto stallThread = [[AsyncHTTPSTestTLSStallThread alloc] init];
    [stallThread start];
    [stallThread waitUntilReady];

    auto IRI = [OFIRI IRIWithString: [OFString stringWithFormat:
        @"https://search.test:%u/", stallThread.port]];
    OFDate *startedAt = OFDate.date;
    bool didThrow = false;

    @try {
        (void)[_client performGETToIRI: IRI
            headers: @{}
            wallTimeout: 0.08
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code,
            AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED,
            @"a stalled TLS handshake must report a deadline error");
    } @finally {
        [stallThread stopAndJoin];
    }

    OFTimeInterval elapsed = -startedAt.timeIntervalSinceNow;
    OTAssertTrue(didThrow, @"a stalled TLS handshake must fail");
    OTAssertTrue(elapsed < 0.3,
        @"the ObjFW client must cancel a TLS handshake before its peer responds");
}

- (void)testCancellationStopsAStalledResponse
{
    block_reference atomic_t(bool) cancelled = false;
    auto cancellationThread = [OFThread threadWithBlock: ^id nillable {
        [OFThread sleepForTimeInterval: 0.05];
        atomic_store_explicit(&cancelled, true, memory_order_release);
        return nilptr;
    }];
    [cancellationThread start];

    bool didThrow = false;
    @try {
        (void)[_client performGETToIRI: [self IRIWithPath: @"/slow"]
            headers: @{}
            wallTimeout: 1
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool {
                return atomic_load_explicit(&cancelled,
                    memory_order_acquire);
            }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code, AsyncHTTPSClientErrorCode_CANCELLED,
            @"an externally cancelled HTTPS request must report cancellation");
    } @finally {
        [cancellationThread join];
    }
    OTAssertTrue(didThrow, @"an externally cancelled request must fail");
}

- (void)testPeerVerificationCannotBeDisabledByProductionCallers
{
    auto IRI = [OFIRI IRIWithString: [OFString stringWithFormat:
        @"https://other.test:%u/ok", _serverThread.port]];
    bool didThrow = false;
    @try {
        (void)[_client performGETToIRI: IRI
            headers: @{}
            wallTimeout: 1
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code, AsyncHTTPSClientErrorCode_TLS_FAILED,
            @"an untrusted peer must fail closed");
    }
    OTAssertTrue(didThrow, @"an untrusted peer must never be accepted");
}

- (void)testPreconnectionDeadlineLimitationIsExplicit
{
    OTAssertFalse(AsyncHTTPSClient.isPreconnectionDeadlineHard,
        @"OFHTTPClient does not expose cancellable DNS or TCP-connect state");
}

- (void)testInvalidInputsAreRejectedWithoutSensitiveDiagnostics
{
    auto sensitiveIRI = [OFIRI IRIWithString:
        @"https://user:password@search.test/private?token=secret"];
    bool didThrow = false;
    @try {
        (void)[_client performGETToIRI: sensitiveIRI
            headers: @{}
            wallTimeout: 1
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code,
            AsyncHTTPSClientErrorCode_INVALID_REQUEST,
            @"embedded user information must be rejected");
        OTAssertEqual([exception.description rangeOfString: @"password"]
            .location, OFNotFound,
            @"safe diagnostics must not contain URL credentials");
        OTAssertEqual([exception.description rangeOfString: @"secret"]
            .location, OFNotFound,
            @"safe diagnostics must not contain query data");
    }
    OTAssertTrue(didThrow, @"embedded user information must fail");

    didThrow = false;
    @try {
        (void)[_client performGETToIRI:
            [OFIRI IRIWithString: @"http://search.test/"]
            headers: @{ @"X-Test": @"value\r\ninjected: yes" }
            wallTimeout: 1
            maximumResponseBodyBytes: 64
            isCancellationRequested: ^bool { return false; }];
    } @catch (AsyncHTTPSClientException *exception) {
        didThrow = true;
        OTAssertEqual(exception.code,
            AsyncHTTPSClientErrorCode_INVALID_REQUEST,
            @"non-HTTPS or injected-header input must be rejected");
    }
    OTAssertTrue(didThrow, @"non-HTTPS input must fail");
}

- (OFString *)certificatePEM
{
    return @"-----BEGIN CERTIFICATE-----\n"
        @"MIIDJTCCAg2gAwIBAgIUF6IFHKx7DuhSSut0/uN55rbv6/4wDQYJKoZIhvcNAQEL\n"
        @"BQAwFjEUMBIGA1UEAwwLc2VhcmNoLnRlc3QwHhcNMjYwOTAyMDUxNDA4WhcNMzYw\n"
        @"ODMwMDUxNDA4WjAWMRQwEgYDVQQDDAtzZWFyY2gudGVzdDCCASIwDQYJKoZIhvcN\n"
        @"AQEBBQADggEPADCCAQoCggEBAMPGmtEJcTaZ/Lo40oJt2SjS7dnXIKTmZm5ELZM0\n"
        @"N2UeNmgP01UwrqA8aTC+oZT4306h09YCkqJye0K0bCiRVl3x0q1zrmN+P9buSAX4\n"
        @"OCEbmwrWM6TdocSfEbq92+CI6SPuaMQHnDKAquZbcCDxCsI4I1tUYWuo256m4OP+\n"
        @"t6hwTIl5GNaYyf3+NBv1EzrkHdD2B5Kps5+stiJdfZ+r3X81Es+YQFKMscHIWy2J\n"
        @"SYpf5FTWbv8KpfQrv+1NnR13sl9KLEPXvRegx7bRU2g208+UoHOlgxX10m8KNR+h\n"
        @"ayu97qc7mLJ/VAmXlbWxMuCZyOQht59veyMLjzPiRmkItYkCAwEAAaNrMGkwHQYD\n"
        @"VR0OBBYEFAKNcV2jsA7O7zxk+Szye8geGMDIMB8GA1UdIwQYMBaAFAKNcV2jsA7O\n"
        @"7zxk+Szye8geGMDIMBYGA1UdEQQPMA2CC3NlYXJjaC50ZXN0MA8GA1UdEwEB/wQF\n"
        @"MAMBAf8wDQYJKoZIhvcNAQELBQADggEBABsipIpVKWi3C5BlamyUl8CMRWHuP/jr\n"
        @"q9eQmcHiYmRXTFSvdSCEobK3686+SgMkUGqKT/EQAdOUXVcD8dQ9QY3DxIn7xzFM\n"
        @"wT2e4cHcv0etuiJ5iG7cR4nxKrH3Gy5zqyeFeAjYWzKOk01XWnJAou/9u8j7c9fP\n"
        @"eLkeRZjPnvu+5XdUdyaQoHZ+49yhiyd96Lmi6aZ3yG5+EReh7uTrhdBzaSQ+Uj0V\n"
        @"roakOHK+u4l24JVWgXF7O35OopUInVnY57MytA+TvY8804N5mAq9YohjzYB+/5Z6\n"
        @"KINQTICZHrzACQE68H964ftk39UV16v+od4X/VEcbrx62JFZZYOihqk=\n"
        @"-----END CERTIFICATE-----\n";
}

- (OFString *)privateKeyPEM
{
    return @"-----BEGIN PRIVATE KEY-----\n"
        @"MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDDxprRCXE2mfy6\n"
        @"ONKCbdko0u3Z1yCk5mZuRC2TNDdlHjZoD9NVMK6gPGkwvqGU+N9OodPWApKicntC\n"
        @"tGwokVZd8dKtc65jfj/W7kgF+DghG5sK1jOk3aHEnxG6vdvgiOkj7mjEB5wygKrm\n"
        @"W3Ag8QrCOCNbVGFrqNuepuDj/reocEyJeRjWmMn9/jQb9RM65B3Q9geSqbOfrLYi\n"
        @"XX2fq91/NRLPmEBSjLHByFstiUmKX+RU1m7/CqX0K7/tTZ0dd7JfSixD170XoMe2\n"
        @"0VNoNtPPlKBzpYMV9dJvCjUfoWsrve6nO5iyf1QJl5W1sTLgmcjkIbefb3sjC48z\n"
        @"4kZpCLWJAgMBAAECggEAC9DrXC2BN0XxAn5WekfOARBGCc1Zq4o6aXJU+9r9cu1x\n"
        @"ZDN8Ulp3V7V9tdLzpq2ksLbEtdh+6C4XsW15T7OB7naffBeM0XV3ve2wzCdwn9Lu\n"
        @"Nye5gzxbPKZLKCW4ZSNuStxjV12MOGIarn+bU2mo+BLyU1tS6/ALnVY+IZSomhJe\n"
        @"Dg3Rq057uTEk7OFtBVR5ws0b3vDfmZZ7yidF3TugjzGScfXtPoEf9fjFD1CCv7Sb\n"
        @"u7ndrS3EgdcZGM4jQs0OETSzjkBFWxJvBY46N0T7foo7YN7mmgVLGTTiBxcYu4PP\n"
        @"kK+iLHDnRJ0l5lET7ZCrPQhnyrJ7m4rvVAPa2t5lhwKBgQDf7JzIgVvbUeDzCpG4\n"
        @"ntrDc8dR2+cVysgI4kWnGdYm2nVMiu6lQ4KdXufofc3hUPu11doFgj3pk6qY8hsz\n"
        @"F2THCeUDA2bFnX0+iNBYANR/9JXNZhsIFylY7kN/0Wr4P3BskCD+MeNc81/niaLL\n"
        @"Pz+A1/pd/zYLiWeEm98oAN3xfwKBgQDf0ccBqFxqqh3UPVe18fwk63IKM+FrrRXG\n"
        @"WlVBkb5tfTqi7dEKDtqLh47dyuju/Vck/i/OWcozIZb/1Pbuo5T7j7kNv7Epe8U7\n"
        @"lMNZ3OcdrvBVGeJnhQjqV6XZABZsinnFfxBSdtTfdn5zaJpxbRXBcvwICic62gjR\n"
        @"nG8D9E1M9wKBgB/JP6w6qKZmZg86Bdt2OUmbasTU+WWfhmu0avzAbyTOx+3Ynu24\n"
        @"upbKPRNEoHAGheSW+b7kcRNyEbpqS7Ah9v1GC0s1NWaB56Bz3VdQrtmHB6jDgLzS\n"
        @"RN1J3S0MtimNH9FZWEWdIVA1f/ynDgPZ85K/ldu3+Z0DoT0yvye3j8nTAoGAUb0M\n"
        @"zoAr8BBcgGw+ogXTrbAGn88+ndJCR4Qp6p5NSzMWvPXZB7FRAu/orvsxgkYnEy15\n"
        @"TATioTW9LYUbAR/ggtaEII9HJf07lHzJswHHrcF7p7iiRGgDT4He4Zb0mYMg4Y17\n"
        @"6oHXUBy4JXGoJZBPB6z0egMrPITv/4z/xhPsPxUCgYBXVrRBOp6PK8A9tGtHuASb\n"
        @"mQcizCjUk6ftse3i5CcrWE73TVNwQIJivhLFy/IqwQXataqNEY0N4xiIp/gNrWkY\n"
        @"7TllEQq93nLjl4s3ybrSMQhpSRev0ffACem+korsAFSUaZ4ucV439FiKSHNx2fNn\n"
        @"NMG+iWoXiJ4vy5OX2To+gg==\n"
        @"-----END PRIVATE KEY-----\n";
}

@end

#pragma clang assume_nonnull end
