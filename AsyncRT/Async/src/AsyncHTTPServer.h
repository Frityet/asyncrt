#pragma once

#import "AsyncScheduler.h"
#import "Task.h"

#pragma clang assume_nonnull begin

@class HTTPRequest;
@class HTTPResponse;
@class HTTPRoute;
@class AsyncHTTPServer;
@class AsyncUnit;

typedef Task<HTTPResponse *> *_Nonnull (^HTTPRouteHandler)(HTTPRequest *request);

@protocol HTTPController <OFObject>
+ (OFArray<HTTPRoute *> *)routes;
@end

@protocol HTTPResponseEncodable <OFObject>

@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *HTTPResponseHeaders;

- (Task<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)HTTPResponse
                                      forRequest: (HTTPRequest *)request;

@end

[[subclassing_restricted, direct_members]]
@interface HTTPRequest : OFObject

@property(readonly, nonatomic) OFHTTPRequest *HTTPRequest;
@property(readonly, nonatomic) OFStream *nillable bodyStream;
@property(readonly, nonatomic) OFHTTPRequestMethod method;
@property(readonly, nonatomic) OFIRI *IRI;
@property(readonly, nonatomic) OFString *path;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) OFDictionary<OFString *, id> *queryParameters;
@property(readonly, nonatomic) OFArray<OFString *> *pathParameters;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *pathParametersByName;
@property(readonly, nonatomic) AsyncScheduler *scheduler;

- (instancetype)initWithHTTPRequest: (OFHTTPRequest *)HTTPRequest
                          bodyStream: (OFStream *nillable)bodyStream
                      pathParameters: (OFArray<OFString *> *)pathParameters
                pathParametersByName: (OFDictionary<OFString *, OFString *> *)pathParametersByName
                            scheduler: (AsyncScheduler *)scheduler [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (OFString *)methodString;
- (Task<OFData *> *)taskToReadBodyWithMaximumLength: (size_t)maximumLength;

@end

[[subclassing_restricted, direct_members]]
@interface HTTPResponse : OFObject

@property(readonly, nonatomic) short statusCode;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) id<HTTPResponseEncodable> body;

+ (instancetype)from: (id<HTTPResponseEncodable>)body
          statusCode: (short)statusCode
        extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders;
+ (instancetype)from: (id<HTTPResponseEncodable>)body;
- (instancetype)initWithBody: (id<HTTPResponseEncodable>)body
                  statusCode: (short)statusCode
                extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFData (HTTPResponseEncodable) <HTTPResponseEncodable>
@end

@interface OFString (HTTPResponseEncodable) <HTTPResponseEncodable>
@end

@interface OFArray (HTTPResponseEncodable) <HTTPResponseEncodable>
@end

@interface OFDictionary (HTTPResponseEncodable) <HTTPResponseEncodable>
@end

@interface OFIRI (HTTPResponseEncodable) <HTTPResponseEncodable>
@end

[[direct_members]]
@interface HTTPRoute : OFObject

@property(readonly, copy, nonatomic) OFString *methodString;
@property(readonly, copy, nonatomic) OFString *pathPattern;
@property(readonly, copy, nonatomic) HTTPRouteHandler nillable handler;
@property(readonly, nonatomic) SEL nillable handledSelector;

+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                  handledByBlock: (HTTPRouteHandler)handler;
+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                 handledByMethod: (SEL)selector;
- (instancetype)initWithMethodString: (OFString *)methodString
                                path: (OFString *)path
                      handledByBlock: (HTTPRouteHandler nillable)handler
                     handledSelector: (SEL nillable)selector [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (HTTPRoute *)routeBoundToController: (id)controller;

@end

[[subclassing_restricted, direct_members]]
@interface HTTPGETRoute : HTTPRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (HTTPRouteHandler)handler;
+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector;

@end

[[subclassing_restricted, direct_members]]
@interface HTTPPOSTRoute : HTTPRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (HTTPRouteHandler)handler;
+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector;

@end

[[subclassing_restricted, direct_members]]
@interface HTTPStatusException : OFException

@property(readonly, nonatomic) HTTPResponse *response;

+ (instancetype)exceptionWithResponse: (HTTPResponse *)response;
- (instancetype)initWithResponse: (HTTPResponse *)response [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPServer : OFObject

@property(copy, nonatomic) OFString *nillable host;
@property(nonatomic) uint16_t port;
@property(copy, nonatomic) OFString *nillable name;
@property(nonatomic) OFTimeInterval requestTimeout;
@property(copy, nonatomic) HTTPResponse * (^nillable exceptionHandler)(HTTPRequest *nillable request, id exception);
@property(readonly, nonatomic) bool isRunning;

#ifdef OF_HAVE_THREADS
@property(nonatomic) size_t numberOfThreads;
#endif

+ (instancetype)serverWithHost: (OFString *nillable)host port: (uint16_t)port;
- (instancetype)initWithHost: (OFString *nillable)host port: (uint16_t)port [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (void)addRoute: (HTTPRoute *)route;
- (void)addRoutes: (OFArray<HTTPRoute *> *)routes;
- (void)registerController: (id<HTTPController>)controller;
- (void)start;
- (void)stop;

@end

#pragma clang assume_nonnull end
