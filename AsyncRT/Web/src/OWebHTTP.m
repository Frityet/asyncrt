#import <OWebHTTP.h>

@interface OWebHTTPRequest () {
    OFHTTPRequestMethod _method;
    OFString *_path;
    OFDictionary<OFString *, OFString *> *_headers;
    OFData *_body;
    size_t _bodyByteCount;
    OFDictionary<OFString *, OFArray<OFString *> *> *_queryParameters;
    OFDictionary<OFString *, OFString *> *_routeParameters;
}

- (void)setRouteParameters:
    (OFDictionary<OFString *, OFString *> *)routeParameters;

@end


@interface OWebRoute () {
    OFHTTPRequestMethod _method;
    OFString *_pattern;
    OFArray<OFString *> *_segments;
    OWebRouteHandler _handler;
}

- (OFDictionary<OFString *, OFString *> *nillable)
    parametersForPath: (OFString *)path;
- (OWebHTTPResponse *nillable)handleRequest: (OWebHTTPRequest *)request;

@end


@interface OWebRouter () {
    size_t _maximumBodyBytes;
    OFMutableArray<OWebRoute *> *_routes;
    OFMutableArray<OWebHTTPMiddleware> *_middleware;
}

- (OWebHTTPResponse *nillable)dispatchRouteForRequest:
    (OWebHTTPRequest *)request;
- (OWebHTTPResponse *nillable)invokeMiddlewareAtIndex: (size_t)index
                                                  request:
                                                      (OWebHTTPRequest *)request;

@end


@implementation OWebHTTPRequest

- (instancetype)initWithMethod: (OFHTTPRequestMethod)method
                           path: (OFString *)path
                        headers: (OFDictionary<OFString *, OFString *> *)headers
                           body: (OFData *)body
{
    self = [super init];

    if (path.length == 0 || ![path hasPrefix: @"/"] ||
        [path containsString: @"#"])
        @throw [OWebRouteException exceptionWithReason: @"invalid request path"];

    _method = method;
    _headers = [headers copy];
    _body = [body copy];
    if (_body.itemSize != 0 && _body.count > SIZE_MAX / _body.itemSize)
        @throw [OWebRouteException exceptionWithReason:
            @"request body byte count overflow"];
    _bodyByteCount = _body.count * _body.itemSize;
    _routeParameters = [[OFDictionary alloc] init];

    auto pieces = [path componentsSeparatedByString: @"?"];
    if (pieces.count > 2)
        @throw [OWebRouteException exceptionWithReason: @"invalid request query"];
    _path = [pieces[0] copy];

    auto query = [OFMutableDictionary<OFString *, OFMutableArray<OFString *> *>
        dictionary];
    if (pieces.count == 2 && [pieces[1] length] > 0) {
        for (OFString *pair in [pieces[1] componentsSeparatedByString: @"&"]) {
            auto components = [pair componentsSeparatedByString: @"="];
            if (components.count > 2 || [components[0] length] == 0)
                @throw [OWebRouteException exceptionWithReason:
                    @"invalid request query"];

            OFString *name = [components[0] stringByRemovingPercentEncoding];
            OFString *value = (components.count == 2 ?
                [components[1] stringByRemovingPercentEncoding] : @"");
            auto values = query[name];
            if (values == nilptr) {
                values = [OFMutableArray array];
                query[name] = values;
            }
            [values addObject: value];
        }
    }

    auto immutableQuery =
        [OFMutableDictionary<OFString *, OFArray<OFString *> *> dictionary];
    for (OFString *name in query)
        immutableQuery[name] = [query[name] copy];
    [immutableQuery makeImmutable];
    _queryParameters = [immutableQuery copy];

    return self;
}

- (OFHTTPRequestMethod)method
{
    return _method;
}

- (OFString *)path
{
    return _path;
}

- (OFDictionary<OFString *, OFString *> *)headers
{
    return _headers;
}

- (OFData *)body
{
    return _body;
}

- (size_t)bodyByteCount
{
    return _bodyByteCount;
}

- (OFDictionary<OFString *, OFArray<OFString *> *> *)queryParameters
{
    return _queryParameters;
}

- (OFDictionary<OFString *, OFString *> *)routeParameters
{
    return _routeParameters;
}

- (void)setRouteParameters:
    (OFDictionary<OFString *, OFString *> *)routeParameters
{
    _routeParameters = [routeParameters copy];
}

- (OFString *nillable)firstQueryValueForName: (OFString *)name
{
    auto values = _queryParameters[name];
    return (values.count == 0 ? nilptr : values[0]);
}

- (OFString *nillable)headerForName: (OFString *)name
{
    for (OFString *candidate in _headers)
        if ([candidate caseInsensitiveCompare: name] == OFOrderedSame)
            return _headers[candidate];
    return nilptr;
}

@end


@implementation OWebHTTPResponse

+ (instancetype)responseWithStatusCode: (unsigned short)statusCode
{
    return [[self alloc] initWithStatusCode: statusCode
                                    headers: @{}
                                       body: [OFData data]];
}

+ (instancetype)textResponse: (OFString *)text
                    statusCode: (unsigned short)statusCode
{
    return [[self alloc] initWithStatusCode: statusCode
                                    headers: @{
                                        @"Content-Type":
                                            @"text/plain; charset=utf-8"
                                    }
                                       body: [text dataWithEncoding:
                                           OFStringEncodingUTF8]];
}

+ (instancetype)JSONResponse: (id <OFJSONRepresentation>)object
                    statusCode: (unsigned short)statusCode
{
    auto JSON = [object JSONRepresentationWithOptions:
        OFJSONRepresentationOptionSorted];
    return [[self alloc] initWithStatusCode: statusCode
                                    headers: @{
                                        @"Content-Type":
                                            @"application/json; charset=utf-8"
                                    }
                                       body: [JSON dataWithEncoding:
                                           OFStringEncodingUTF8]];
}

+ (instancetype)dataResponse: (OFData *)data
                     MIMEType: (OFString *)MIMEType
                   statusCode: (unsigned short)statusCode
{
    return [[self alloc] initWithStatusCode: statusCode
                                    headers: @{ @"Content-Type": MIMEType }
                                       body: data];
}

- (instancetype)initWithStatusCode: (unsigned short)statusCode
                            headers:
                                (OFDictionary<OFString *, OFString *> *)headers
                               body: (OFData *)body
{
    self = [super init];
    _statusCode = statusCode;
    _headers = [headers copy];
    _body = [body copy];
    return self;
}

@synthesize statusCode = _statusCode;
@synthesize headers = _headers;
@synthesize body = _body;

@end


@implementation OWebRoute

- (instancetype)initWithMethod: (OFHTTPRequestMethod)method
                        pattern: (OFString *)pattern
                        handler: (OWebRouteHandler)handler
{
    self = [super init];

    if (pattern.length == 0 || ![pattern hasPrefix: @"/"] ||
        [pattern containsString: @"?"] || [pattern containsString: @"#"])
        @throw [OWebRouteException exceptionWithReason: @"invalid route pattern"];

    _method = method;
    _pattern = [pattern copy];
    _handler = [handler copy];

    auto segments = [OFMutableArray<OFString *> array];
    auto rawSegments = [pattern componentsSeparatedByString: @"/"];
    for (size_t index = 1; index < rawSegments.count; index++) {
        OFString *segment = rawSegments[index];
        if (segment.length == 0 && index + 1 < rawSegments.count)
            @throw [OWebRouteException exceptionWithReason:
                @"route contains an empty segment"];
        if ([segment hasPrefix: @":"] && segment.length == 1)
            @throw [OWebRouteException exceptionWithReason:
                @"route parameter has no name"];
        if ([segment hasPrefix: @"*"])
            @throw [OWebRouteException exceptionWithReason:
                @"wildcard routes are not supported"];
        [segments addObject: segment];
    }
    _segments = [segments copy];

    return self;
}

- (OFHTTPRequestMethod)method
{
    return _method;
}

- (OFString *)pattern
{
    return _pattern;
}

- (OFDictionary<OFString *, OFString *> *nillable)
    parametersForPath: (OFString *)path
{
    auto rawSegments = [path componentsSeparatedByString: @"/"];
    if (rawSegments.count == 0 || ![rawSegments[0] isEqual: @""])
        return nilptr;

    auto pathSegments = [OFMutableArray<OFString *> array];
    for (size_t index = 1; index < rawSegments.count; index++) {
        OFString *segment = rawSegments[index];
        if (segment.length == 0 && index + 1 == rawSegments.count &&
            _segments.count + 1 == rawSegments.count)
            [pathSegments addObject: segment];
        else if (segment.length == 0)
            return nilptr;
        else {
            OFString *decoded = [segment stringByRemovingPercentEncoding];
            if ([decoded containsString: @"/"] || [decoded containsString: @"\\"])
                return nilptr;
            [pathSegments addObject: decoded];
        }
    }

    if (pathSegments.count != _segments.count)
        return nilptr;

    auto parameters = [OFMutableDictionary<OFString *, OFString *> dictionary];
    for (size_t index = 0; index < _segments.count; index++) {
        OFString *expected = _segments[index];
        OFString *actual = pathSegments[index];
        if ([expected hasPrefix: @":"]) {
            OFString *name = [expected substringFromIndex: 1];
            if (parameters[name] != nilptr)
                @throw [OWebRouteException exceptionWithReason:
                    @"route repeats a parameter name"];
            parameters[name] = actual;
        } else if (![expected isEqual: actual])
            return nilptr;
    }
    [parameters makeImmutable];
    return parameters;
}

- (OWebHTTPResponse *nillable)handleRequest: (OWebHTTPRequest *)request
{
    if (request.method != _method)
        return nilptr;
    auto parameters = [self parametersForPath: request.path];
    if (parameters == nilptr)
        return nilptr;
    [request setRouteParameters: parameters];
    return _handler(request);
}

@end


@implementation OWebRouter

- (instancetype)initWithMaximumBodyBytes: (size_t)maximumBodyBytes
{
    self = [super init];
    if (maximumBodyBytes == 0)
        @throw [OFInvalidArgumentException exception];
    _maximumBodyBytes = maximumBodyBytes;
    _routes = [[OFMutableArray alloc] init];
    _middleware = [[OFMutableArray alloc] init];
    return self;
}

- (size_t)maximumBodyBytes
{
    return _maximumBodyBytes;
}

- (void)useMiddleware: (OWebHTTPMiddleware)middleware
{
    [_middleware addObject: [middleware copy]];
}

- (void)addRouteWithMethod: (OFHTTPRequestMethod)method
                    pattern: (OFString *)pattern
                    handler: (OWebRouteHandler)handler
{
    auto route = [[OWebRoute alloc] initWithMethod: method
                                           pattern: pattern
                                           handler: handler];
    [_routes addObject: route];
}

- (void)get: (OFString *)pattern handler: (OWebRouteHandler)handler
{
    [self addRouteWithMethod: OFHTTPRequestMethodGet
                     pattern: pattern
                     handler: handler];
}

- (void)post: (OFString *)pattern handler: (OWebRouteHandler)handler
{
    [self addRouteWithMethod: OFHTTPRequestMethodPost
                     pattern: pattern
                     handler: handler];
}

- (OWebHTTPResponse *nillable)dispatchRouteForRequest:
    (OWebHTTPRequest *)request
{
    for (OWebRoute *route in _routes) {
        auto response = [route handleRequest: request];
        if (response != nilptr)
            return response;
    }
    return nilptr;
}

- (OWebHTTPResponse *nillable)invokeMiddlewareAtIndex: (size_t)index
                                                  request:
                                                      (OWebHTTPRequest *)request
{
    if (index == _middleware.count)
        return [self dispatchRouteForRequest: request];

    OWebHTTPMiddleware middleware = _middleware[index];
    return middleware(request, ^OWebHTTPResponse *(OWebHTTPRequest *nextRequest) {
        return [self invokeMiddlewareAtIndex: index + 1 request: nextRequest];
    });
}

- (OWebHTTPResponse *)dispatchRequest: (OWebHTTPRequest *)request
{
    if (request.bodyByteCount > _maximumBodyBytes)
        return [OWebHTTPResponse textResponse: @"Payload Too Large"
                                       statusCode: 413];

    auto response = [self invokeMiddlewareAtIndex: 0 request: request];
    if (response == nilptr)
        response = [OWebHTTPResponse textResponse: @"Not Found" statusCode: 404];
    return $assert_nonnil(response);
}

@end


@implementation OWebRouteException

+ (instancetype)exceptionWithReason: (OFString *)reason
{
    return [[self alloc] initWithReason: reason];
}

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"OWeb route error: %@", _reason];
}

@end
