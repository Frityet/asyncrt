#import <OWebObjFWHTTPServer.h>

@interface OWebObjFWHTTPServer () {
    OWebRouter *_router;
    OFString *_host;
    uint16_t _configuredPort;
    uint16_t _actualPort;
    bool _isRunning;
    OFHTTPServer *_server;
    OWebHTTPServerExceptionHandler _exceptionHandler;
}

- (bool)requestHasCanonicalOversizedContentLength:
    (OFHTTPRequest *)request [[direct]];
- (OFData *nillable)readBoundedBodyFromStream: (OFStream *nillable)stream
    [[direct]];
- (OFString *)pathAndQueryForRequest: (OFHTTPRequest *)request [[direct]];
- (void)sendOWebResponse: (OWebHTTPResponse *)OWebResponse
               forMethod: (OFHTTPRequestMethod)method
                response: (OFHTTPResponse *)response [[direct]];
- (void)sendSanitizedStatus: (unsigned short)statusCode
                          text: (OFString *)text
                     forMethod: (OFHTTPRequestMethod)method
                      response: (OFHTTPResponse *)response [[direct]];
- (void)reportException: (id nillable)exception [[direct]];
- (bool)isValidHeaderName: (OFString *)name [[direct]];
- (bool)isValidHeaderValue: (OFString *)value [[direct]];
- (size_t)byteCountForData: (OFData *)data [[direct]];

@end


@implementation OWebObjFWHTTPServer

- (instancetype)initWithRouter: (OWebRouter *)router
{
    return [self initWithRouter: router host: @"127.0.0.1" port: 0];
}

- (instancetype)initWithRouter: (OWebRouter *)router
                           host: (OFString *)host
                           port: (uint16_t)port
{
    self = [super init];

    if (router == nilptr || host.length == 0 ||
        [host rangeOfCharacterFromSet: OFCharacterSet.newlineCharacterSet]
                .location != OFNotFound)
        @throw [OFInvalidArgumentException exception];

    _router = router;
    _host = [host copy];
    _configuredPort = port;
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (OWebRouter *)router
{
    return _router;
}

- (OFString *)host
{
    return _host;
}

- (uint16_t)configuredPort
{
    return _configuredPort;
}

- (uint16_t)actualPort
{
    return _actualPort;
}

- (bool)isRunning
{
    return _isRunning;
}

@synthesize exceptionHandler = _exceptionHandler;

- (void)start
{
    if (_isRunning)
        @throw [OFAlreadyOpenException exceptionWithObject: self];

    auto server = [OFHTTPServer server];
    server.host = _host;
    server.port = _configuredPort;
#ifdef OF_HAVE_THREADS
    server.numberOfThreads = 1;
#endif
    server.delegate = self;

    @try {
        [server start];
    } @catch (id exception) {
        server.delegate = nilptr;
        [server stop];
        @throw exception;
    }

    _server = server;
    _actualPort = server.port;
    _isRunning = true;
}

- (void)stop
{
    if (!_isRunning)
        return;

    _server.delegate = nilptr;
    [_server stop];
    _server = nilptr;
    _actualPort = 0;
    _isRunning = false;
}

- (bool)requestHasCanonicalOversizedContentLength: (OFHTTPRequest *)request
{
    OFDictionary<OFString *, OFString *> *headers = request.headers;
    OFString *nillable contentLength = nilptr;
    for (OFString *name in headers) {
        if ([name caseInsensitiveCompare: @"Content-Length"] == OFOrderedSame) {
            contentLength = headers[name];
            break;
        }
    }
    if (contentLength == nilptr)
        return false;

    auto value = $as_nonnil(contentLength);
    if (value.length == 0 || (value.length > 1 &&
        [value characterAtIndex: 0] == '0'))
        return false;
    for (size_t index = 0; index < value.length; index++) {
        OFUnichar character = [value characterAtIndex: index];
        if (character < '0' || character > '9')
            return false;
    }

    size_t maximum = _router.maximumBodyBytes;
    size_t parsed = 0;
    for (size_t index = 0; index < value.length; index++) {
        size_t digit = (size_t)([value characterAtIndex: index] - '0');
        if (parsed > maximum / 10 ||
            (parsed == maximum / 10 && digit > maximum % 10))
            return true;
        parsed = parsed * 10 + digit;
    }
    return false;
}

- (OFData *nillable)readBoundedBodyFromStream: (OFStream *nillable)stream
{
    if (stream == nilptr)
        return [OFData data];

    size_t maximum = _router.maximumBodyBytes;
    size_t initialCapacity = (maximum < 16 * 1024 ? maximum : 16 * 1024);
    auto body = [OFMutableData dataWithCapacity: initialCapacity];
    unsigned char buffer[16 * 1024];
    unsigned int consecutiveEmptyReads = 0;

    while (!stream.atEndOfStream) {
        size_t remaining = maximum - body.count;
        size_t requested = sizeof(buffer);
        if (remaining < sizeof(buffer))
            requested = remaining + 1;

        size_t count = [stream readIntoBuffer: buffer length: requested];
        if (count == 0) {
            if (stream.atEndOfStream)
                break;
            if (++consecutiveEmptyReads > 8)
                @throw [OFInvalidFormatException exception];
            continue;
        }
        consecutiveEmptyReads = 0;
        if (count > remaining)
            return nilptr;

        [body addItems: buffer count: count];
    }

    [body makeImmutable];
    return body;
}

- (OFString *)pathAndQueryForRequest: (OFHTTPRequest *)request
{
    auto path = request.IRI.percentEncodedPath;
    auto query = request.IRI.percentEncodedQuery;
    if (query != nilptr)
        return [path stringByAppendingFormat: @"?%@", query];
    return path;
}

- (bool)isValidHeaderName: (OFString *)name
{
    if (name.length == 0)
        return false;

    for (size_t index = 0; index < name.length; index++) {
        OFUnichar character = [name characterAtIndex: index];
        if ((character >= 'a' && character <= 'z') ||
            (character >= 'A' && character <= 'Z') ||
            (character >= '0' && character <= '9'))
            continue;

        switch (character) {
        case '!': case '#': case '$': case '%': case '&': case '\'':
        case '*': case '+': case '-': case '.': case '^': case '_':
        case '`': case '|': case '~':
            continue;
        default:
            return false;
        }
    }

    return true;
}

- (size_t)byteCountForData: (OFData *)data
{
    if (data.itemSize != 0 && data.count > SIZE_MAX / data.itemSize)
        @throw [OFOutOfRangeException exception];
    return data.count * data.itemSize;
}

- (bool)isValidHeaderValue: (OFString *)value
{
    for (size_t index = 0; index < value.length; index++) {
        OFUnichar character = [value characterAtIndex: index];
        if ((character < 0x20 && character != '\t') || character == 0x7F)
            return false;
    }
    return true;
}

- (void)sendOWebResponse: (OWebHTTPResponse *)OWebResponse
               forMethod: (OFHTTPRequestMethod)method
                response: (OFHTTPResponse *)response
{
    if (OWebResponse.statusCode < 100 || OWebResponse.statusCode > 599)
        @throw [OFInvalidArgumentException exception];

    auto headers = [OWebResponse.headers mutableCopy];
    auto keysToRemove = [OFMutableArray<OFString *> array];
    for (OFString *key in headers) {
        OFString *value = headers[key];
        if (![self isValidHeaderName: key] ||
            ![self isValidHeaderValue: value])
            @throw [OFInvalidArgumentException exception];

        if ([key caseInsensitiveCompare: @"Content-Length"] == OFOrderedSame ||
            [key caseInsensitiveCompare: @"Transfer-Encoding"] == OFOrderedSame ||
            [key caseInsensitiveCompare: @"Connection"] == OFOrderedSame)
            [keysToRemove addObject: key];
    }
    for (OFString *key in keysToRemove)
        [headers removeObjectForKey: key];

    size_t bodyBytes = [self byteCountForData: OWebResponse.body];
    bool statusPermitsBody = !((OWebResponse.statusCode >= 100 &&
        OWebResponse.statusCode < 200) || OWebResponse.statusCode == 204 ||
        OWebResponse.statusCode == 304);
    if (statusPermitsBody)
        headers[@"Content-Length"] = [OFString stringWithFormat: @"%zu",
            bodyBytes];
    headers[@"Connection"] = @"close";
    [headers makeImmutable];

    response.statusCode = OWebResponse.statusCode;
    response.headers = headers;
    if (method != OFHTTPRequestMethodHead && statusPermitsBody && bodyBytes > 0)
        [response writeData: OWebResponse.body];
    [response close];
}

- (void)sendSanitizedStatus: (unsigned short)statusCode
                          text: (OFString *)text
                     forMethod: (OFHTTPRequestMethod)method
                      response: (OFHTTPResponse *)response
{
    @try {
        auto body = [text dataWithEncoding: OFStringEncodingUTF8];
        response.statusCode = statusCode;
        response.headers = @{
            @"Connection": @"close",
            @"Content-Type": @"text/plain; charset=utf-8",
            @"Content-Length": [OFString stringWithFormat: @"%zu",
                body.count * body.itemSize]
        };
        if (method != OFHTTPRequestMethodHead)
            [response writeData: body];
        [response close];
    } @catch (id exception) {
        [self reportException: exception];
    }
}

- (void)reportException: (id nillable)exception
{
    auto handler = _exceptionHandler;
    if (handler == nilptr || exception == nilptr)
        return;

    @try {
        handler($as_nonnil(exception));
    } @catch (id ignoredException) {
        (void)ignoredException;
    }
}

-      (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)request
        requestBody: (OFStream *nillable)requestBody
           response: (OFHTTPResponse *)response
{
    (void)server;

    if ([self requestHasCanonicalOversizedContentLength: request]) {
        [self sendSanitizedStatus: 413
                              text: @"Payload Too Large"
                         forMethod: request.method
                          response: response];
        return;
    }

    OFData *body;
    @try {
        body = [self readBoundedBodyFromStream: requestBody];
        if (body == nilptr) {
            [self sendSanitizedStatus: 413
                                  text: @"Payload Too Large"
                             forMethod: request.method
                              response: response];
            return;
        }
    } @catch (id exception) {
        [self reportException: exception];
        [self sendSanitizedStatus: 400
                              text: @"Bad Request"
                         forMethod: request.method
                          response: response];
        return;
    }

    @try {
        auto headers = request.headers;
        if (headers == nilptr)
            headers = @{};
        auto OWebRequest = [[OWebHTTPRequest alloc]
            initWithMethod: request.method
                      path: [self pathAndQueryForRequest: request]
                   headers: $assert_nonnil(headers)
                      body: body];
        auto OWebResponse = [_router dispatchRequest: OWebRequest];
        [self sendOWebResponse: OWebResponse
                     forMethod: request.method
                      response: response];
    } @catch (id exception) {
        [self reportException: exception];
        [self sendSanitizedStatus: 500
                              text: @"Internal Server Error"
                         forMethod: request.method
                          response: response];
    }
}

-           (void)server: (OFHTTPServer *)server
  didEncounterException: (id)exception
                 request: (OFHTTPRequest *nillable)request
                response: (OFHTTPResponse *nillable)response
{
    (void)server;
    (void)request;
    (void)response;
    [self reportException: exception];
}

@end
