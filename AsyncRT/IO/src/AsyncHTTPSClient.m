#import <AsyncHTTPSClient.h>

#import <ObjFWTLS/ObjFWTLS.h>

#include <math.h>
#include <string.h>
#include <time.h>

#pragma clang assume_nonnull begin

constexpr size_t AsyncHTTPSMaximumResponseHeaderBytes = 64 * 1024;
constexpr size_t AsyncHTTPSBodyReadBufferBytes = 16 * 1024;
constexpr OFTimeInterval AsyncHTTPSRunLoopSlice = 0.05;

/*
 * ObjFW 1.5.x exposed HTTP status codes as `short`; current ObjFW uses
 * `unsigned short`. Deriving the delegate argument from OFHTTPResponse keeps
 * the wrapper source-compatible with both public APIs without changing the
 * Objective-C ABI (HTTP status codes are always positive and fit either).
 */
typedef __typeof__(((OFHTTPResponse *)nilptr).statusCode)
    AsyncHTTPSObjFWStatusCode;

static int *const forceObjFWTLS __attribute__((used)) = &_ObjFWTLS_reference;
static const OFRunLoopMode AsyncHTTPSRequestRunLoopMode =
    @"AsyncHTTPSClientRequestRunLoopMode";
static const OFRunLoopMode AsyncHTTPSBodyRunLoopMode =
    @"AsyncHTTPSClientBodyRunLoopMode";

@interface AsyncHTTPSResponse()

- (instancetype)initWithStatusCode: (unsigned short)statusCode
                          headerData: (OFData *)headerData
                                body: (OFData *)body;

@end


[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSClock: OFObject

+ (uint64_t)monotonicNanoseconds;
+ (uint64_t)deadlineForTimeout: (OFTimeInterval)timeout;
+ (bool)isDeadline: (uint64_t)deadline reachedAt: (uint64_t)now;

@end


@interface AsyncHTTPSClient()

+ (OFData *)_headerDataForHeaders:
    (OFDictionary<OFString *, OFString *> *)headers;
+ (enum AsyncHTTPSClientErrorCode)_errorCodeForObject: (id nillable)object;
+ (bool)_isValidHeaderName: (OFString *)name;
+ (bool)_isValidHeaderValue: (OFString *)value;
+ (bool)_isCancellationRequested: (bool (^)(void))cancellation;
+ (void)_validateIRI: (OFIRI *)IRI
              headers: (OFDictionary<OFString *, OFString *> *)headers
          wallTimeout: (OFTimeInterval)wallTimeout;
+ (OFData *)_readBodyFromResponse: (OFHTTPResponse *)response
                         deadline: (uint64_t)deadline
              maximumResponseBytes: (size_t)maximumResponseBytes
           isCancellationRequested: (bool (^)(void))cancellation;

@end


@interface AsyncHTTPSRequestOperation: OFObject <OFHTTPClientDelegate>

@property(readonly, nonatomic) bool isDone;
@property(readonly, nonatomic) bool hasAbort;
@property(readonly, nonatomic) enum AsyncHTTPSClientErrorCode abortCode;
@property(readonly, nonatomic) OFHTTPResponse *nillable response;
@property(readonly, nonatomic) OFData *nillable headerData;
@property(readonly, nonatomic) id nillable exception;

- (instancetype)initWithClient: (OFHTTPClient *)client;
- (instancetype)init [[clang::unavailable]];
- (void)startRequest: (OFHTTPRequest *)request;
- (void)requestAbortWithCode: (enum AsyncHTTPSClientErrorCode)code;

@end


@implementation AsyncHTTPSClientException

- (instancetype)initWithCode: (enum AsyncHTTPSClientErrorCode)code
{
    self = [super init];
    _code = code;
    return self;
}

- (OFString *)description
{
    OFString *message;

    switch (_code) {
        case AsyncHTTPSClientErrorCode_UNAVAILABLE:
            message = @"required HTTPS transport features are unavailable";
            break;
        case AsyncHTTPSClientErrorCode_INVALID_REQUEST:
            message = @"HTTPS request is invalid";
            break;
        case AsyncHTTPSClientErrorCode_CANCELLED:
            message = @"HTTPS request was cancelled";
            break;
        case AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED:
            message = @"HTTPS request exceeded its deadline";
            break;
        case AsyncHTTPSClientErrorCode_HEADER_TOO_LARGE:
            message = @"HTTPS response headers exceeded their limit";
            break;
        case AsyncHTTPSClientErrorCode_BODY_TOO_LARGE:
            message = @"HTTPS response body exceeded its limit";
            break;
        case AsyncHTTPSClientErrorCode_NAME_RESOLUTION_FAILED:
            message = @"HTTPS name resolution failed";
            break;
        case AsyncHTTPSClientErrorCode_CONNECTION_FAILED:
            message = @"HTTPS connection failed";
            break;
        case AsyncHTTPSClientErrorCode_TLS_FAILED:
            message = @"HTTPS authentication failed";
            break;
        case AsyncHTTPSClientErrorCode_TRANSFER_FAILED:
            message = @"HTTPS transfer failed";
            break;
        case AsyncHTTPSClientErrorCode_INTERNAL_ERROR:
            message = @"HTTPS transport encountered an internal error";
            break;
        default:
            message = @"HTTPS transport failed";
            break;
    }

    return [OFString stringWithFormat: @"%@: %@", self.className, message];
}

@end


@implementation AsyncHTTPSResponse

- (instancetype)initWithStatusCode: (unsigned short)statusCode
                          headerData: (OFData *)headerData
                                body: (OFData *)body
{
    self = [super init];
    _statusCode = statusCode;
    _headerData = [headerData copy];
    _body = [body copy];
    return self;
}

@end


@implementation AsyncHTTPSClock

+ (uint64_t)monotonicNanoseconds
{
    struct timespec time;
    if (clock_gettime(CLOCK_MONOTONIC, &time) != 0
        || (uint64_t)time.tv_sec > UINT64_MAX / UINT64_C(1000000000))
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INTERNAL_ERROR];

    return (uint64_t)time.tv_sec * UINT64_C(1000000000)
        + (uint64_t)time.tv_nsec;
}

+ (uint64_t)deadlineForTimeout: (OFTimeInterval)timeout
{
    double nanosecondsDouble = ceil(timeout * 1000000000.0);
    uint64_t now = self.monotonicNanoseconds;
    if (!(nanosecondsDouble >= 1.0)
        || nanosecondsDouble > (double)(UINT64_MAX - now))
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INVALID_REQUEST];

    return now + (uint64_t)nanosecondsDouble;
}

+ (bool)isDeadline: (uint64_t)deadline reachedAt: (uint64_t)now
{ return now >= deadline; }

@end


@implementation AsyncHTTPSRequestOperation {
    OFHTTPClient *_client;
    OFTCPSocket *nillable _TCPSocket;
    OFTLSStream *nillable _TLSStream;
    OFHTTPResponse *nillable _response;
    OFData *nillable _headerData;
    id nillable _exception;
    bool _isDone;
    bool _hasAbort;
    enum AsyncHTTPSClientErrorCode _abortCode;
}

- (instancetype)initWithClient: (OFHTTPClient *)client
{
    self = [super init];
    _client = client;
    _client.delegate = self;
    return self;
}

- (bool)isDone
{ return _isDone; }

- (bool)hasAbort
{ return _hasAbort; }

- (enum AsyncHTTPSClientErrorCode)abortCode
{ return _abortCode; }

- (OFHTTPResponse *nillable)response
{ return _response; }

- (OFData *nillable)headerData
{ return _headerData; }

- (id nillable)exception
{ return _exception; }

- (void)startRequest: (OFHTTPRequest *)request
{
    [_client asyncPerformRequest: request
                       redirects: 0
                     runLoopMode: AsyncHTTPSRequestRunLoopMode];
}

- (bool)_closeActiveTransport
{
    auto TCPSocket = _TCPSocket;
    auto TLSStream = _TLSStream;
    if (TCPSocket == nilptr && TLSStream == nilptr)
        return false;

    if (TLSStream != nilptr) {
        [TLSStream cancelAsyncRequests];
        @try {
            [TLSStream close];
        } @catch (OFNotOpenException *exception) {
            (void)exception;
        }
    }
    if (TCPSocket != nilptr) {
        [TCPSocket cancelAsyncRequests];
        @try {
            [TCPSocket close];
        } @catch (OFNotOpenException *exception) {
            (void)exception;
        }
    }
    _TLSStream = nilptr;
    _TCPSocket = nilptr;
    return true;
}

- (void)requestAbortWithCode: (enum AsyncHTTPSClientErrorCode)code
{
    if (_hasAbort)
        return;

    _hasAbort = true;
    _abortCode = code;
    if ([self _closeActiveTransport]) {
        _client.delegate = nilptr;
        _isDone = true;
    }
}

- (void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
               request: (OFHTTPRequest *)request
{
    (void)client;
    (void)request;
    _TCPSocket = TCPSocket;
    if (_hasAbort && [self _closeActiveTransport]) {
        _client.delegate = nilptr;
        _isDone = true;
    }
}

- (void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)TLSStream
               request: (OFHTTPRequest *)request
{
    (void)client;
    (void)request;
    TLSStream.verifiesCertificates = true;
    _TLSStream = TLSStream;
    if (_hasAbort && [self _closeActiveTransport]) {
        _client.delegate = nilptr;
        _isDone = true;
    }
}

- (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers
             statusCode: (AsyncHTTPSObjFWStatusCode)statusCode
                request: (OFHTTPRequest *)request
{
    (void)client;
    (void)statusCode;
    (void)request;
    _headerData = [AsyncHTTPSClient _headerDataForHeaders: headers];
}

- (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
             response: (OFHTTPResponse *nillable)response
            exception: (id nillable)exception
{
    (void)client;
    (void)request;
    _response = response;
    _exception = exception;
    _TLSStream = nilptr;
    _TCPSocket = nilptr;
    _isDone = true;
}

@end


@implementation AsyncHTTPSClient

+ (size_t)maximumResponseHeaderBytes
{ return AsyncHTTPSMaximumResponseHeaderBytes; }

+ (bool)isPreconnectionDeadlineHard
{ return false; }

+ (bool)_isValidHeaderName: (OFString *)name
{
    if (name.length == 0)
        return false;

    const char *bytes;
    @try {
        bytes = [name cStringWithEncoding: OFStringEncodingASCII];
    } @catch (OFException *exception) {
        (void)exception;
        return false;
    }

    if (strlen(bytes) !=
        [name cStringLengthWithEncoding: OFStringEncodingASCII])
        return false;

    for (size_t index = 0; bytes[index] != '\0'; index++) {
        unsigned char byte = (unsigned char)bytes[index];
        bool isAlphaNumeric = (byte >= 'a' && byte <= 'z')
            || (byte >= 'A' && byte <= 'Z')
            || (byte >= '0' && byte <= '9');
        bool isPunctuation = strchr("!#$%&'*+-.^_`|~", byte) != nullptr;
        if (!isAlphaNumeric && !isPunctuation)
            return false;
    }

    return true;
}

+ (bool)_isValidHeaderValue: (OFString *)value
{
    const char *bytes = value.UTF8String;
    return strlen(bytes) == value.UTF8StringLength
        && [value rangeOfString: @"\r"].location == OFNotFound
        && [value rangeOfString: @"\n"].location == OFNotFound;
}

+ (void)_validateIRI: (OFIRI *)IRI
              headers: (OFDictionary<OFString *, OFString *> *)headers
          wallTimeout: (OFTimeInterval)wallTimeout
{
    if (![IRI.scheme.lowercaseString isEqual: @"https"]
        || IRI.host == nilptr || $assert_nonnil(IRI.host).length == 0
        || IRI.user != nilptr || IRI.password != nilptr
        || !(wallTimeout > 0) || !isfinite(wallTimeout))
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INVALID_REQUEST];

    for (id nameObject in headers) {
        id nillable valueObject = headers[nameObject];
        if (![nameObject isKindOfClass: OFString.class]
            || ![valueObject isKindOfClass: OFString.class]
            || ![self _isValidHeaderName: nameObject]
            || ![self _isValidHeaderValue:
                (OFString *)$assert_nonnil(valueObject)])
            @throw [[AsyncHTTPSClientException alloc]
                initWithCode: AsyncHTTPSClientErrorCode_INVALID_REQUEST];
    }
}

+ (bool)_isCancellationRequested: (bool (^)(void))cancellation
{
    @try {
        return cancellation();
    } @catch (id exception) {
        (void)exception;
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INTERNAL_ERROR];
    }
}

+ (OFData *)_headerDataForHeaders:
    (OFDictionary<OFString *, OFString *> *)headers
{
    auto result = [OFMutableData data];
    for (OFString *name in headers) {
        auto line = [OFString stringWithFormat: @"%@: %@\r\n", name,
            headers[name]];
        auto data = [line dataWithEncoding: OFStringEncodingUTF8];
        if (result.count > AsyncHTTPSMaximumResponseHeaderBytes
            || data.count >
                AsyncHTTPSMaximumResponseHeaderBytes - result.count)
            @throw [[AsyncHTTPSClientException alloc]
                initWithCode: AsyncHTTPSClientErrorCode_HEADER_TOO_LARGE];
        const void *nillable items = data.items;
        if (items == nullptr && data.count > 0)
            @throw [[AsyncHTTPSClientException alloc]
                initWithCode: AsyncHTTPSClientErrorCode_INTERNAL_ERROR];
        [result addItems: (const void *nonnil)items count: data.count];
    }
    return [result copy];
}

+ (enum AsyncHTTPSClientErrorCode)_errorCodeForObject: (id nillable)object
{
    if ([object isKindOfClass: AsyncHTTPSClientException.class])
        return ((AsyncHTTPSClientException *)object).code;
    if ([object isKindOfClass: OFResolveHostFailedException.class]
        || [object isKindOfClass: OFDNSQueryFailedException.class])
        return AsyncHTTPSClientErrorCode_NAME_RESOLUTION_FAILED;
    if ([object isKindOfClass: OFConnectIPSocketFailedException.class])
        return AsyncHTTPSClientErrorCode_CONNECTION_FAILED;
    if ([object isKindOfClass: OFTLSHandshakeFailedException.class])
        return AsyncHTTPSClientErrorCode_TLS_FAILED;
    if ([object isKindOfClass: OFUnsupportedProtocolException.class]
        || [object isKindOfClass: OFNotImplementedException.class])
        return AsyncHTTPSClientErrorCode_UNAVAILABLE;
    if ([object isKindOfClass: OFInvalidArgumentException.class])
        return AsyncHTTPSClientErrorCode_INVALID_REQUEST;
    return AsyncHTTPSClientErrorCode_TRANSFER_FAILED;
}

+ (OFData *)_readBodyFromResponse: (OFHTTPResponse *)response
                         deadline: (uint64_t)deadline
              maximumResponseBytes: (size_t)maximumResponseBytes
           isCancellationRequested: (bool (^)(void))cancellation
{
    auto contentLength = response.headers[@"Content-Length"];
    if (contentLength != nilptr) {
        @try {
            if (contentLength.unsignedLongLongValue > maximumResponseBytes)
                @throw [[AsyncHTTPSClientException alloc]
                    initWithCode: AsyncHTTPSClientErrorCode_BODY_TOO_LARGE];
        } @catch (AsyncHTTPSClientException *exception) {
            @throw exception;
        } @catch (OFException *exception) {
            (void)exception;
            @throw [[AsyncHTTPSClientException alloc]
                initWithCode: AsyncHTTPSClientErrorCode_TRANSFER_FAILED];
        }
    }

    size_t bufferLength = AsyncHTTPSBodyReadBufferBytes;
    if (maximumResponseBytes < bufferLength)
        bufferLength = maximumResponseBytes == SIZE_MAX
            ? AsyncHTTPSBodyReadBufferBytes
            : maximumResponseBytes + 1;
    if (bufferLength == 0)
        bufferLength = 1;

    auto readBuffer = [OFMutableData dataWithCapacity: bufferLength];
    [readBuffer increaseCountBy: bufferLength];
    OFData *retainedReadBuffer = readBuffer;
    void *nillable mutableItems = readBuffer.mutableItems;
    if (mutableItems == nullptr)
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INTERNAL_ERROR];
    auto body = [OFMutableData data];
    block_reference bool isDone = false;
    block_reference id nillable readException = nilptr;

    @try {
        [response asyncReadIntoBuffer: (void *nonnil)mutableItems
            length: bufferLength
            runLoopMode: AsyncHTTPSBodyRunLoopMode
            handler: ^bool(OFStream *stream, void *buffer, size_t bytesRead,
                id nillable exception) {
                (void)retainedReadBuffer;
                if (exception != nilptr) {
                    readException = exception;
                    isDone = true;
                    return false;
                }
                if (body.count > maximumResponseBytes
                    || bytesRead > maximumResponseBytes - body.count) {
                    readException = [[AsyncHTTPSClientException alloc]
                        initWithCode: AsyncHTTPSClientErrorCode_BODY_TOO_LARGE];
                    isDone = true;
                    return false;
                }
                if (bytesRead > 0)
                    [body addItems: buffer count: bytesRead];
                if (stream.atEndOfStream) {
                    isDone = true;
                    return false;
                }
                return true;
            }];

        auto runLoop = OFRunLoop.currentRunLoop;
        while (!isDone) {
            if ([self _isCancellationRequested: cancellation])
                @throw [[AsyncHTTPSClientException alloc]
                    initWithCode: AsyncHTTPSClientErrorCode_CANCELLED];
            if ([AsyncHTTPSClock isDeadline: deadline
                reachedAt: AsyncHTTPSClock.monotonicNanoseconds])
                @throw [[AsyncHTTPSClientException alloc]
                    initWithCode: AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED];

            [runLoop runMode: AsyncHTTPSBodyRunLoopMode
                beforeDate: [OFDate dateWithTimeIntervalSinceNow:
                    AsyncHTTPSRunLoopSlice]];
        }

        if (readException != nilptr)
            @throw [[AsyncHTTPSClientException alloc] initWithCode:
                [self _errorCodeForObject: readException]];
        return [body copy];
    } @finally {
        [response cancelAsyncRequests];
        @try {
            [response close];
        } @catch (OFNotOpenException *exception) {
            (void)exception;
        }
    }
}

- (AsyncHTTPSResponse *)performGETToIRI: (OFIRI *)IRI
                                      headers: (OFDictionary<OFString *, OFString *> *)headers
                                  wallTimeout: (OFTimeInterval)wallTimeout
                     maximumResponseBodyBytes: (size_t)maximumResponseBodyBytes
                                isCancellationRequested: (bool (^)(void))cancellation
{
    if (cancellation == nilptr)
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_INVALID_REQUEST];
    [AsyncHTTPSClient _validateIRI: IRI headers: headers
        wallTimeout: wallTimeout];
    if ([AsyncHTTPSClient _isCancellationRequested: cancellation])
        @throw [[AsyncHTTPSClientException alloc]
            initWithCode: AsyncHTTPSClientErrorCode_CANCELLED];

    uint64_t deadline = [AsyncHTTPSClock deadlineForTimeout: wallTimeout];
    auto requestHeaders = [headers mutableCopy];
    requestHeaders[@"Accept-Encoding"] = @"identity";
    requestHeaders[@"Connection"] = @"close";
    auto request = [OFHTTPRequest requestWithIRI: IRI];
    request.method = OFHTTPRequestMethodGet;
    request.headers = requestHeaders;

    auto client = [OFHTTPClient client];
    auto operation = [[AsyncHTTPSRequestOperation alloc]
        initWithClient: client];
    @try {
        [operation startRequest: request];
        auto runLoop = OFRunLoop.currentRunLoop;
        while (!operation.isDone) {
            if ([AsyncHTTPSClient _isCancellationRequested: cancellation])
                [operation requestAbortWithCode:
                    AsyncHTTPSClientErrorCode_CANCELLED];
            else if ([AsyncHTTPSClock isDeadline: deadline
                reachedAt: AsyncHTTPSClock.monotonicNanoseconds])
                [operation requestAbortWithCode:
                    AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED];

            [runLoop runMode: AsyncHTTPSRequestRunLoopMode
                beforeDate: [OFDate dateWithTimeIntervalSinceNow:
                    AsyncHTTPSRunLoopSlice]];
        }
        [runLoop runMode: AsyncHTTPSRequestRunLoopMode
            beforeDate: OFDate.date];

        if (operation.hasAbort)
            @throw [[AsyncHTTPSClientException alloc]
                initWithCode: operation.abortCode];
        auto response = operation.response;
        if (response == nilptr)
            @throw [[AsyncHTTPSClientException alloc] initWithCode:
                [AsyncHTTPSClient _errorCodeForObject: operation.exception]];
        auto body = [AsyncHTTPSClient
            _readBodyFromResponse: $assert_nonnil(response)
            deadline: deadline
            maximumResponseBytes: maximumResponseBodyBytes
            isCancellationRequested: cancellation];
        return [[AsyncHTTPSResponse alloc]
            initWithStatusCode: $assert_nonnil(response).statusCode
            headerData: $assert_nonnil(operation.headerData)
            body: body];
    } @catch (AsyncHTTPSClientException *exception) {
        @throw exception;
    } @catch (id exception) {
        @throw [[AsyncHTTPSClientException alloc] initWithCode:
            [AsyncHTTPSClient _errorCodeForObject: exception]];
    } @finally {
        [client close];
    }
}

@end


#pragma clang assume_nonnull end
