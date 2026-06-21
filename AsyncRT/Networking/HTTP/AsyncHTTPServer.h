#pragma once

#import <AsyncRT/Core.h>

#pragma clang assume_nonnull begin

@class AsyncHTTPRequest;
@class AsyncHTTPResponse;
@class AsyncHTTPRoute;
@class AsyncHTTPServer;
@class AsyncUnit;

typedef AsyncTask<AsyncHTTPResponse *> *_Nonnull (^AsyncHTTPRouteHandler)(AsyncHTTPRequest *request);

@protocol AsyncHTTPController <OFObject>
+ (OFArray<AsyncHTTPRoute *> *)routes;
@end

@protocol AsyncHTTPResponseEncodable <OFObject>

@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *AsyncHTTPResponseHeaders;

- (AsyncTask<AsyncUnit *> *)taskToWriteToHTTPResponse: (OFHTTPResponse *)AsyncHTTPResponse
                                      forRequest: (AsyncHTTPRequest *)request;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPRequest : OFObject

@property(readonly, nonatomic) OFHTTPRequest *rawHTTPRequest;
@property(readonly, nonatomic) OFStream *nillable bodyStream;
@property(readonly, nonatomic) OFHTTPRequestMethod method;
@property(readonly, nonatomic) OFIRI *IRI;
@property(readonly, nonatomic) OFString *path;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) OFDictionary<OFString *, id> *queryParameters;
@property(readonly, nonatomic) OFArray<OFString *> *pathParameters;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *pathParametersByName;

- (instancetype)initWithHTTPRequest: (OFHTTPRequest *)rawHTTPRequest
                          bodyStream: (OFStream *nillable)bodyStream
                      pathParameters: (OFArray<OFString *> *)pathParameters
                pathParametersByName: (OFDictionary<OFString *, OFString *> *)pathParametersByName [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (OFString *)methodString;
- (AsyncTask<OFData *> *)taskToReadBodyWithMaximumLength: (size_t)maximumLength;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPResponse : OFObject

@property(readonly, nonatomic) short statusCode;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) id<AsyncHTTPResponseEncodable> body;

+ (instancetype)from: (id<AsyncHTTPResponseEncodable>)body
          statusCode: (short)statusCode
        extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders;
+ (instancetype)from: (id<AsyncHTTPResponseEncodable>)body;
- (instancetype)initWithBody: (id<AsyncHTTPResponseEncodable>)body
                  statusCode: (short)statusCode
                extraHeaders: (OFDictionary<OFString *, OFString *> *)extraHeaders [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFData (AsyncHTTPResponseEncodable) <AsyncHTTPResponseEncodable>
@end

@interface OFString (AsyncHTTPResponseEncodable) <AsyncHTTPResponseEncodable>
@end

@interface OFArray (AsyncHTTPResponseEncodable) <AsyncHTTPResponseEncodable>
@end

@interface OFDictionary (AsyncHTTPResponseEncodable) <AsyncHTTPResponseEncodable>
@end

@interface OFIRI (AsyncHTTPResponseEncodable) <AsyncHTTPResponseEncodable>
@end

[[direct_members]]
@interface AsyncHTTPRoute : OFObject

@property(readonly, copy, nonatomic) OFString *methodString;
@property(readonly, copy, nonatomic) OFString *pathPattern;
@property(readonly, copy, nonatomic) AsyncHTTPRouteHandler nillable handler;
@property(readonly, nonatomic) SEL nillable handledSelector;

+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                  handledByBlock: (AsyncHTTPRouteHandler)handler;
+ (instancetype)withMethodString: (OFString *)methodString
                            path: (OFString *)path
                 handledByMethod: (SEL)selector;
- (instancetype)initWithMethodString: (OFString *)methodString
                                path: (OFString *)path
                      handledByBlock: (AsyncHTTPRouteHandler nillable)handler
                     handledSelector: (SEL nillable)selector [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (AsyncHTTPRoute *)routeBoundToController: (id)controller;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPGETRoute : AsyncHTTPRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (AsyncHTTPRouteHandler)handler;
+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPPOSTRoute : AsyncHTTPRoute

+ (instancetype)withPath: (OFString *)path handledByBlock: (AsyncHTTPRouteHandler)handler;
+ (instancetype)withPath: (OFString *)path handledByMethod: (SEL)selector;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPStatusException : OFException

@property(readonly, nonatomic) AsyncHTTPResponse *response;

+ (instancetype)exceptionWithResponse: (AsyncHTTPResponse *)response;
- (instancetype)initWithResponse: (AsyncHTTPResponse *)response [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPRequestTimeoutException : OFException

@property(readonly, nonatomic) OFTimeInterval timeout;

- (instancetype)initWithTimeout: (OFTimeInterval)timeout [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPServer : OFObject

@property(copy, nonatomic) OFString *nillable host;
@property(nonatomic) uint16_t port;
@property(copy, nonatomic) OFString *nillable name;
@property(nonatomic) OFTimeInterval requestTimeout;
@property(copy, nonatomic) AsyncHTTPResponse * (^nillable exceptionHandler)(AsyncHTTPRequest *nillable request, id exception);
@property(readonly, nonatomic) bool isRunning;

#ifdef OF_HAVE_THREADS
@property(nonatomic) size_t numberOfThreads;
#endif

+ (instancetype)serverWithHost: (OFString *nillable)host port: (uint16_t)port;
- (instancetype)initWithHost: (OFString *nillable)host port: (uint16_t)port [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (void)addRoute: (AsyncHTTPRoute *)route;
- (void)addRoutes: (OFArray<AsyncHTTPRoute *> *)routes;
- (void)registerController: (id<AsyncHTTPController>)controller;
- (void)start;
- (void)stop;

@end

#pragma clang assume_nonnull end
