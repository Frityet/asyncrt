#import "AsyncHTTPServer.h"
#import "AsyncRuntime.h"
#import "AsyncStreamTasks.h"

#import <ObjFW/OFIRI.h>
#import <ObjFW/OFString+PathAdditions.h>

#include <limits.h>

#pragma clang assume_nonnull begin

static OFTimeInterval const AsyncHTTPServerDefaultRequestTimeout = 30;

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPRouteMatch : OFObject

@property(readonly, nonatomic) HTTPRoute *route;
@property(readonly, copy, nonatomic) OFArray<OFString *> *pathParameters;
@property(readonly, copy, nonatomic) OFDictionary<OFString *, OFString *> *pathParametersByName;

- (instancetype)initWithRoute: (HTTPRoute *)route
               pathParameters: (OFArray<OFString *> *)pathParameters
         pathParametersByName: (OFDictionary<OFString *, OFString *> *)pathParametersByName [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncHTTPServer () <OFHTTPServerDelegate>
@end

@interface HTTPRoute (AsyncHTTPServerPrivate)
- (OFArray<OFString *> *)_pathComponents;
@end

@interface HTTPResponse (AsyncHTTPServerPrivate)
- (Task<AsyncUnit *> *)_taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                       forRequest: (HTTPRequest *)request;
@end

@namespace(HTTPResponseEncoding)

+ (OFData *)dataForJSONRepresentation: (id<OFJSONRepresentation>)object;
+ (OFData *)dataForString: (OFString *)string;
+ (OFString *)contentLengthHeaderForData: (OFData *)data;
+ (OFString *)contentTypeForFileIRI: (OFIRI *)IRI;
+ (Task<AsyncUnit *> *)taskToWriteData: (OFData *)data
                          HTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                            forRequest: (HTTPRequest *)request;

@end

@implementation HTTPRequest

- (instancetype)initWithHTTPRequest: (OFHTTPRequest *)HTTPRequest
                          bodyStream: (OFStream *nillable)bodyStream
                      pathParameters: (OFArray<OFString *> *)pathParameters
                pathParametersByName: (OFDictionary<OFString *, OFString *> *)pathParametersByName
                            scheduler: (AsyncScheduler *)scheduler
{
    self = [super init];
    _HTTPRequest = HTTPRequest;
    _bodyStream = bodyStream;
    _method = HTTPRequest.method;
    _IRI = HTTPRequest.IRI;
    _path = (_IRI.path.length > 0 ? _IRI.path : @"/");
    _headers = (HTTPRequest.headers != nilptr ? HTTPRequest.headers : @{});
    _queryParameters = [[self _queryParametersFromIRI: _IRI] copy];
    _pathParameters = [pathParameters copy];
    _pathParametersByName = [pathParametersByName copy];
    _scheduler = scheduler;
    return self;
}

- (OFDictionary<OFString *, id> *)_queryParametersFromIRI: (OFIRI *)IRI
{
    OFArray<OFPair<OFString *, OFString *> *> *nillable queryItems = IRI.queryItems;

    if (queryItems == nilptr)
        return @{};

    auto queryParameters = [OFMutableDictionary<OFString *, id> dictionary];

    for (OFPair<OFString *, OFString *> *queryItem in queryItems) {
        OFString *nillable key = queryItem.firstObject;

        if (key == nilptr)
            continue;

        queryParameters[$assert_nonnil(key)] = (queryItem.secondObject != nilptr
            ? $assert_nonnil(queryItem.secondObject)
            : OFNull.null);
    }

    return queryParameters;
}

- (OFString *)methodString
{
    OFString *nillable methodString = OFHTTPRequestMethodString(self.method);

    if (methodString == nilptr)
        return [OFString stringWithFormat: @"%d", (int)self.method];

    return $assert_nonnil(methodString);
}

- (Task<OFData *> *)taskToReadBodyWithMaximumLength: (size_t)maximumLength
{
    if (self.bodyStream == nilptr)
        return [Task resolved: [OFData data]];

    AsyncRTLinkAsyncStreamTasks();
    return [$assert_nonnil(self.bodyStream) taskToReadUntilEndWithMaximumLength: maximumLength
                                                                    onScheduler: self.scheduler];
}

@end

@namespace_implementation(HTTPResponseEncoding)

+ (OFData *)dataForJSONRepresentation: (id<OFJSONRepresentation>)object
{
    return [object.JSONRepresentation dataWithEncoding: OFStringEncodingUTF8];
}

+ (OFData *)dataForString: (OFString *)string
{
    return [string dataWithEncoding: OFStringEncodingUTF8];
}

+ (OFString *)contentLengthHeaderForData: (OFData *)data
{
    return [OFString stringWithFormat: @"%zu", data.count * data.itemSize];
}

+ (OFString *)contentTypeForFileIRI: (OFIRI *)IRI
{
    OFString *extension = IRI.pathExtension.lowercaseString;

    if ([extension isEqual: @"html"] or [extension isEqual: @"htm"])
        return @"text/html; charset=utf-8";
    if ([extension isEqual: @"css"])
        return @"text/css; charset=utf-8";
    if ([extension isEqual: @"js"])
        return @"application/javascript; charset=utf-8";
    if ([extension isEqual: @"json"])
        return @"application/json; charset=utf-8";
    if ([extension isEqual: @"txt"])
        return @"text/plain; charset=utf-8";

    return @"application/octet-stream";
}

+ (Task<AsyncUnit *> *)taskToWriteData: (OFData *)data
                        HTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                          forRequest: (HTTPRequest *)request
{
    if (request.method == OFHTTPRequestMethodHead or data.count == 0)
        return [Task resolved: AsyncUnit.unit];

    @try {
        [rawHTTPResponse writeData: data];
        return [Task resolved: AsyncUnit.unit];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }
}

@end

@implementation HTTPResponse

+ (instancetype)from: (id<HTTPResponseEncodable>)body
          statusCode: (short)statusCode
        extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders
{
    return [[self alloc] initWithBody: body statusCode: statusCode extraHeaders: extraHeaders];
}

+ (instancetype)from: (id<HTTPResponseEncodable>)body
{
    return [self from: body statusCode: 200 extraHeaders: @{}];
}

- (instancetype)initWithBody: (id<HTTPResponseEncodable>)body
                  statusCode: (short)statusCode
                extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders
{
    auto headers = [OFMutableDictionary<OFString *, OFString *> dictionaryWithDictionary: body.HTTPResponseHeaders];

    for (OFString *key in extraHeaders)
        headers[key] = extraHeaders[key];

    self = [super init];
    _body = body;
    _statusCode = statusCode;
    _headers = [headers copy];
    return self;
}

- (Task<AsyncUnit *> *)_taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                       forRequest: (HTTPRequest *)request
{
    rawHTTPResponse.statusCode = self.statusCode;
    rawHTTPResponse.headers = self.headers;

    if (request.method == OFHTTPRequestMethodHead)
        return [Task resolved: AsyncUnit.unit];

    return [self.body taskToWriteToHTTPResponse: rawHTTPResponse forRequest: request];
}

@end

@implementation OFData (HTTPResponseEncodable)

- (OFDictionary<OFString *, OFString *> *)HTTPResponseHeaders
{
    return @{@"Content-Length": [HTTPResponseEncoding contentLengthHeaderForData: self]};
}

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                      forRequest: (HTTPRequest *)request
{
    return [HTTPResponseEncoding taskToWriteData: self
                                    HTTPResponse: rawHTTPResponse
                                      forRequest: request];
}

@end

@implementation OFString (HTTPResponseEncodable)

- (OFDictionary<OFString *, OFString *> *)HTTPResponseHeaders
{
    OFData *data = [HTTPResponseEncoding dataForString: self];

    return @{
        @"Content-Type": @"text/plain; charset=utf-8",
        @"Content-Length": [HTTPResponseEncoding contentLengthHeaderForData: data]
    };
}

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                      forRequest: (HTTPRequest *)request
{
    return [HTTPResponseEncoding taskToWriteData: [HTTPResponseEncoding dataForString: self]
                                    HTTPResponse: rawHTTPResponse
                                      forRequest: request];
}

@end

@implementation OFArray (HTTPResponseEncodable)

- (OFDictionary<OFString *, OFString *> *)HTTPResponseHeaders
{
    OFData *data = [HTTPResponseEncoding dataForJSONRepresentation: (id<OFJSONRepresentation>)self];

    return @{
        @"Content-Type": @"application/json; charset=utf-8",
        @"Content-Length": [HTTPResponseEncoding contentLengthHeaderForData: data]
    };
}

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                      forRequest: (HTTPRequest *)request
{
    OFData *data = [HTTPResponseEncoding dataForJSONRepresentation: (id<OFJSONRepresentation>)self];

    return [HTTPResponseEncoding taskToWriteData: data
                                    HTTPResponse: rawHTTPResponse
                                      forRequest: request];
}

@end

@implementation OFDictionary (HTTPResponseEncodable)

- (OFDictionary<OFString *, OFString *> *)HTTPResponseHeaders
{
    OFData *data = [HTTPResponseEncoding dataForJSONRepresentation: (id<OFJSONRepresentation>)self];

    return @{
        @"Content-Type": @"application/json; charset=utf-8",
        @"Content-Length": [HTTPResponseEncoding contentLengthHeaderForData: data]
    };
}

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                      forRequest: (HTTPRequest *)request
{
    OFData *data = [HTTPResponseEncoding dataForJSONRepresentation: (id<OFJSONRepresentation>)self];

    return [HTTPResponseEncoding taskToWriteData: data
                                    HTTPResponse: rawHTTPResponse
                                      forRequest: request];
}

@end

@implementation OFIRI (HTTPResponseEncodable)

- (OFData *)_HTTPResponseFileData
{
    if (not [self.scheme isEqual: @"file"])
        @throw [OFInvalidArgumentException exception];

    return [OFData dataWithContentsOfIRI: self];
}

- (OFDictionary<OFString *, OFString *> *)HTTPResponseHeaders
{
    OFData *data = self._HTTPResponseFileData;

    return @{
        @"Content-Type": [HTTPResponseEncoding contentTypeForFileIRI: self],
        @"Content-Length": [HTTPResponseEncoding contentLengthHeaderForData: data]
    };
}

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)rawHTTPResponse
                                      forRequest: (HTTPRequest *)request
{
    return [HTTPResponseEncoding taskToWriteData: self._HTTPResponseFileData
                                    HTTPResponse: rawHTTPResponse
                                      forRequest: request];
}

@end

@implementation HTTPRoute {
    OFArray<OFString *> *_pathComponents;
}

+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                  handledByBlock: (HTTPRouteHandler)handler
{
    return [[self alloc] initWithMethodString: methodString
                                         path: path
                              handledByBlock: handler
                             handledSelector: (SEL nillable)nullptr];
}

+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                 handledByMethod: (SEL)selector
{
    return [[self alloc] initWithMethodString: methodString
                                         path: path
                               handledByBlock: nilptr
                              handledSelector: selector];
}

- (instancetype)initWithMethodString: (OFString *)methodString
                                path: (OFString *)path
                      handledByBlock: (HTTPRouteHandler nillable)handler
                     handledSelector: (SEL nillable)selector
{
    self = [super init];
    _methodString = [methodString copy];
    _pathPattern = [path copy];
    _handler = [handler copy];
    _handledSelector = selector;
    _pathComponents = [[self class] _componentsForPath: path];
    return self;
}

+ (OFArray<OFString *> *)_componentsForPath: (OFString *)path
{
    auto components = [OFMutableArray<OFString *> array];

    for (OFString *component in [path componentsSeparatedByString: @"/"]) {
        if (component.length == 0)
            continue;

        [components addObject: component];
    }

    return components;
}

- (OFArray<OFString *> *)_pathComponents
{
    return _pathComponents;
}

- (HTTPRoute *)routeBoundToController: (id)controller
{
    if (self.handler != nilptr)
        return self;
    if (self.handledSelector == (SEL nillable)nullptr)
        @throw [OFInvalidArgumentException exception];

    SEL selector = $assert_nonnil(self.handledSelector);
    HTTPRouteHandler handler = ^Task<HTTPResponse *> *(HTTPRequest *request) {
        IMP implementation = [controller methodForSelector: selector];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
        auto typedImplementation = (Task<HTTPResponse *> *(*)(id, SEL, HTTPRequest *))implementation;
        #pragma clang diagnostic pop
        return typedImplementation(controller, selector, request);
    };

    return [[HTTPRoute alloc] initWithMethodString: self.methodString
                                             path: self.pathPattern
                                   handledByBlock: handler
                                  handledSelector: (SEL nillable)nullptr];
}

@end

@implementation HTTPGETRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (HTTPRouteHandler)handler
{
    return [[self alloc] initWithMethodString: @"GET"
                                         path: path
                               handledByBlock: handler
                              handledSelector: (SEL nillable)nullptr];
}

+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector
{
    return [[self alloc] initWithMethodString: @"GET"
                                         path: path
                               handledByBlock: nilptr
                              handledSelector: selector];
}

@end

@implementation HTTPPOSTRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (HTTPRouteHandler)handler
{
    return [[self alloc] initWithMethodString: @"POST"
                                         path: path
                               handledByBlock: handler
                              handledSelector: (SEL nillable)nullptr];
}

+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector
{
    return [[self alloc] initWithMethodString: @"POST"
                                         path: path
                               handledByBlock: nilptr
                              handledSelector: selector];
}

@end

@implementation HTTPStatusException

+ (instancetype)exceptionWithResponse: (HTTPResponse *)response
{
    return [[self alloc] initWithResponse: response];
}

- (instancetype)initWithResponse: (HTTPResponse *)response
{
    self = [super init];
    _response = response;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"HTTPStatusException: %d %@", self.response.statusCode, OFHTTPStatusCodeString(self.response.statusCode)];
}

@end

@implementation AsyncHTTPRouteMatch

- (instancetype)initWithRoute: (HTTPRoute *)route
               pathParameters: (OFArray<OFString *> *)pathParameters
         pathParametersByName: (OFDictionary<OFString *, OFString *> *)pathParametersByName
{
    self = [super init];
    _route = route;
    _pathParameters = [pathParameters copy];
    _pathParametersByName = [pathParametersByName copy];
    return self;
}

@end

@implementation AsyncHTTPServer {
    OFHTTPServer *_HTTPServer;
    OFMutex *_routesLock;
    OFMutableArray<HTTPRoute *> *_routes;
    bool _isRunning;
}

+ (instancetype)serverWithHost: (OFString *nillable)host port: (uint16_t)port
{
    return [[self alloc] initWithHost: host port: port];
}

- (instancetype)initWithHost: (OFString *nillable)host port: (uint16_t)port
{
    self = [super init];
    _HTTPServer = OFHTTPServer.server;
    _HTTPServer.delegate = self;
    _host = [host copy];
    _port = port;
    _requestTimeout = AsyncHTTPServerDefaultRequestTimeout;
    _routesLock = [OFMutex mutex];
    _routes = [OFMutableArray array];
    _isRunning = false;
#ifdef OF_HAVE_THREADS
    _numberOfThreads = 1;
#endif
    return self;
}

- (void)addRoute: (HTTPRoute *)route
{
    [_routesLock lock];
    @try {
        [_routes addObject: route];
    } @finally {
        [_routesLock unlock];
    }
}

- (void)addRoutes: (OFArray<HTTPRoute *> *)routes
{
    for (HTTPRoute *route in routes)
        [self addRoute: route];
}

- (void)registerController: (id<HTTPController>)controller
{
    for (HTTPRoute *route in [[controller class] routes])
        [self addRoute: [route routeBoundToController: controller]];
}

- (void)start
{
    _HTTPServer.host = self.host;
    _HTTPServer.port = self.port;
    _HTTPServer.name = self.name;

#ifdef OF_HAVE_THREADS
    _HTTPServer.numberOfThreads = self.numberOfThreads;
#endif

    [_HTTPServer start];
    _port = _HTTPServer.port;
    _isRunning = true;
}

- (void)stop
{
    [_HTTPServer stop];
    _isRunning = false;
}

- (OFString *)_stringForMethod: (OFHTTPRequestMethod)method
{
    OFString *nillable methodString = OFHTTPRequestMethodString(method);

    if (methodString == nilptr)
        return [OFString stringWithFormat: @"%d", (int)method];

    return $assert_nonnil(methodString);
}

- (AsyncHTTPRouteMatch *nillable)_matchRoute: (HTTPRoute *)route
                                  requestPath: (OFString *)requestPath
                                 methodString: (OFString *)methodString
{
    if (not [route.methodString isEqual: methodString]) {
        if (not ([methodString isEqual: @"HEAD"] and [route.methodString isEqual: @"GET"]))
            return nilptr;
    }

    OFArray<OFString *> *requestComponents = [HTTPRoute _componentsForPath: requestPath];
    OFArray<OFString *> *routeComponents = route._pathComponents;

    if (requestComponents.count != routeComponents.count)
        return nilptr;

    auto pathParameters = [OFMutableArray<OFString *> array];
    auto pathParametersByName = [OFMutableDictionary<OFString *, OFString *> dictionary];

    for (size_t index = 0; index < requestComponents.count; index++) {
        OFString *routeComponent = routeComponents[index];
        OFString *requestComponent = requestComponents[index];

        if ([routeComponent hasPrefix: @":"]) {
            OFString *name = [routeComponent substringFromIndex: 1];
            [pathParameters addObject: requestComponent];
            pathParametersByName[name] = requestComponent;
            continue;
        }

        if (not [routeComponent isEqual: requestComponent])
            return nilptr;
    }

    return [[AsyncHTTPRouteMatch alloc] initWithRoute: route
                                      pathParameters: pathParameters
                                pathParametersByName: pathParametersByName];
}

- (AsyncHTTPRouteMatch *nillable)_routeMatchForRequestPath: (OFString *)path
                                               methodString: (OFString *)methodString
{
    [_routesLock lock];
    @try {
        for (HTTPRoute *route in _routes) {
            AsyncHTTPRouteMatch *nillable match = [self _matchRoute: route
                                                        requestPath: path
                                                       methodString: methodString];
            if (match != nilptr)
                return match;
        }
    } @finally {
        [_routesLock unlock];
    }

    return nilptr;
}

- (OFArray<OFString *> *)_allowedMethodsForPath: (OFString *)path
{
    auto allowedMethods = [OFMutableSet<OFString *> set];

    [_routesLock lock];
    @try {
        for (HTTPRoute *route in _routes) {
            if ([self _matchRoute: route requestPath: path methodString: route.methodString] == nilptr)
                continue;

            [allowedMethods addObject: route.methodString];
            if ([route.methodString isEqual: @"GET"])
                [allowedMethods addObject: @"HEAD"];
        }
    } @finally {
        [_routesLock unlock];
    }

    auto sortedMethods = [OFMutableArray<OFString *> array];
    for (OFString *method in allowedMethods.allObjects)
        [sortedMethods addObject: method];

    [sortedMethods sort];
    return sortedMethods;
}

- (HTTPResponse *)_unhandledResponseForRequest: (HTTPRequest *)request
{
    auto allowedMethods = [self _allowedMethodsForPath: request.path];

    if (allowedMethods.count > 0) {
        return [HTTPResponse from: @"method not allowed\n"
                          statusCode: 405
                        extraHeaders: @{@"Allow": [allowedMethods componentsJoinedByString: @", "]}];
    }

    return [HTTPResponse from: @"not found\n" statusCode: 404 extraHeaders: @{}];
}

- (HTTPResponse *)_defaultExceptionResponseForRequest: (HTTPRequest *nillable)request
                                            exception: (id)exception
{
    (void)request;

    if ([exception isKindOfClass: HTTPStatusException.class])
        return ((HTTPStatusException *)exception).response;

    if ([exception isKindOfClass: AsyncTaskGroupTimeoutException.class]) {
        return [HTTPResponse from: @"request timed out\n" statusCode: 504 extraHeaders: @{}];
    }

    return [HTTPResponse from: @"internal server error\n" statusCode: 500 extraHeaders: @{}];
}

- (HTTPResponse *)_exceptionResponseForRequest: (HTTPRequest *nillable)request
                                     exception: (id)exception
{
    auto exceptionHandler = self.exceptionHandler;

    if (exceptionHandler == nilptr)
        return [self _defaultExceptionResponseForRequest: request exception: exception];

    @try {
        HTTPResponse *nillable response = exceptionHandler(request, exception);

        if (response != nilptr)
            return $assert_nonnil(response);
    } @catch (id) {
    }

    return [self _defaultExceptionResponseForRequest: request exception: exception];
}

- (HTTPResponse *)_responseForRouteMatch: (AsyncHTTPRouteMatch *)match
                                 request: (HTTPRequest *)request
{
    HTTPRouteHandler nillable handler = match.route.handler;

    if (handler == nilptr)
        @throw [OFInvalidArgumentException exception];

    Task<HTTPResponse *> *responseTask = handler(request);
    HTTPResponse *nillable response = responseTask.await;

    if (response == nilptr)
        @throw [OFInvalidArgumentException exception];

    return $assert_nonnil(response);
}

- (void)_writeResponse: (HTTPResponse *)response
            forRequest: (HTTPRequest *)request
          HTTPResponse: (OFHTTPResponse *)rawHTTPResponse
           onScheduler: (AsyncScheduler *)scheduler
{
    auto task = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return [response _taskToWriteToHTTPResponse: rawHTTPResponse forRequest: request].await;
    }];

    [scheduler runUntilTaskCompletes: task];
}

- (void)_serveRequest: (HTTPRequest *)request
                match: (AsyncHTTPRouteMatch *nillable)match
         HTTPResponse: (OFHTTPResponse *)rawHTTPResponse
          onScheduler: (AsyncScheduler *)scheduler
{
    OFTimeInterval requestTimeout = self.requestTimeout;
    auto task = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *rootTaskGroup) {
        if (match == nilptr) {
            HTTPResponse *response = [self _unhandledResponseForRequest: request];
            return [response _taskToWriteToHTTPResponse: rawHTTPResponse
                                             forRequest: request].await;
        }

        id (^serveMatchedRoute)(AsyncTaskGroup *) = ^id(AsyncTaskGroup *) {
            HTTPResponse *response = [self _responseForRouteMatch: $assert_nonnil(match)
                                                          request: request];
            return [response _taskToWriteToHTTPResponse: rawHTTPResponse
                                             forRequest: request].await;
        };

        if (requestTimeout > 0)
            return [rootTaskGroup performWithTimeout: requestTimeout block: serveMatchedRoute];

        return serveMatchedRoute(rootTaskGroup);
    }];

    [scheduler runUntilTaskCompletes: task];

    if (task.status != AsyncTaskStatus_REJECTED)
        return;

    HTTPResponse *exceptionResponse = [self _exceptionResponseForRequest: request
                                                               exception: task.failureException];

    auto exceptionTask = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *taskGroup) {
        (void)taskGroup;
        return [exceptionResponse _taskToWriteToHTTPResponse: rawHTTPResponse forRequest: request].await;
    }];
    [scheduler runUntilTaskCompletes: exceptionTask];
}

-      (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)rawHTTPRequest
        requestBody: (OFStream *nillable)requestBody
           response: (OFHTTPResponse *)rawHTTPResponse
{
    (void)server;

    auto scheduler = AsyncScheduler.defaultScheduler;
    OFString *path = (rawHTTPRequest.IRI.path.length > 0 ? rawHTTPRequest.IRI.path : @"/");
    OFString *methodString = [self _stringForMethod: rawHTTPRequest.method];
    AsyncHTTPRouteMatch *nillable match = [self _routeMatchForRequestPath: path
                                                               methodString: methodString];
    auto request = [[HTTPRequest alloc] initWithHTTPRequest: rawHTTPRequest
                                                 bodyStream: requestBody
                                             pathParameters: (match != nilptr ? match.pathParameters : @[])
                                       pathParametersByName: (match != nilptr ? match.pathParametersByName : @{})
                                                   scheduler: scheduler];

    [self _serveRequest: request
                  match: match
           HTTPResponse: rawHTTPResponse
            onScheduler: scheduler];
}

-       (void)server: (OFHTTPServer *)server
  didEncounterException: (id)exception
             request: (OFHTTPRequest *nillable)request
            response: (OFHTTPResponse *nillable)response
{
    (void)server;
    (void)request;
    (void)response;

    [OFStdErr writeFormat: @"HTTP server error: %@\n", exception];
}

@end

#pragma clang assume_nonnull end
