#import <Common.h>

#pragma clang assume_nonnull begin

@class OWebHTTPRequest;
@class OWebHTTPResponse;

typedef OWebHTTPResponse *nillable (^OWebRouteHandler)(OWebHTTPRequest *request);
typedef OWebHTTPResponse *nillable (^OWebHTTPNext)(OWebHTTPRequest *request);
typedef OWebHTTPResponse *nillable (^OWebHTTPMiddleware)(
    OWebHTTPRequest *request, OWebHTTPNext next);

[[subclassing_restricted, direct_members]]
@interface OWebHTTPRequest : OFObject

@property(readonly, nonatomic) OFHTTPRequestMethod method;
@property(readonly, nonatomic) OFString *path;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) OFData *body;
@property(readonly, nonatomic) size_t bodyByteCount;
@property(readonly, nonatomic)
    OFDictionary<OFString *, OFArray<OFString *> *> *queryParameters;
@property(readonly, nonatomic)
    OFDictionary<OFString *, OFString *> *routeParameters;

- (instancetype)initWithMethod: (OFHTTPRequestMethod)method
                           path: (OFString *)path
                        headers: (OFDictionary<OFString *, OFString *> *)headers
                           body: (OFData *)body;
- (instancetype)init OF_UNAVAILABLE;

- (OFString *nillable)firstQueryValueForName: (OFString *)name;
- (OFString *nillable)headerForName: (OFString *)name;

@end

[[subclassing_restricted, direct_members]]
@interface OWebHTTPResponse : OFObject

@property(nonatomic) unsigned short statusCode;
@property(copy, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(copy, nonatomic) OFData *body;

+ (instancetype)responseWithStatusCode: (unsigned short)statusCode;
+ (instancetype)textResponse: (OFString *)text
                    statusCode: (unsigned short)statusCode;
+ (instancetype)JSONResponse: (id <OFJSONRepresentation>)object
                    statusCode: (unsigned short)statusCode;
+ (instancetype)dataResponse: (OFData *)data
                     MIMEType: (OFString *)MIMEType
                   statusCode: (unsigned short)statusCode;

- (instancetype)initWithStatusCode: (unsigned short)statusCode
                            headers:
                                (OFDictionary<OFString *, OFString *> *)headers
                               body: (OFData *)body;

@end

[[subclassing_restricted, direct_members]]
@interface OWebRoute : OFObject

@property(readonly, nonatomic) OFHTTPRequestMethod method;
@property(readonly, nonatomic) OFString *pattern;

- (instancetype)initWithMethod: (OFHTTPRequestMethod)method
                        pattern: (OFString *)pattern
                        handler: (OWebRouteHandler)handler;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface OWebRouter : OFObject

@property(readonly, nonatomic) size_t maximumBodyBytes;

- (instancetype)initWithMaximumBodyBytes: (size_t)maximumBodyBytes;
- (instancetype)init OF_UNAVAILABLE;

- (void)useMiddleware: (OWebHTTPMiddleware)middleware;
- (void)addRouteWithMethod: (OFHTTPRequestMethod)method
                    pattern: (OFString *)pattern
                    handler: (OWebRouteHandler)handler;
- (void)get: (OFString *)pattern handler: (OWebRouteHandler)handler;
- (void)post: (OFString *)pattern handler: (OWebRouteHandler)handler;
- (OWebHTTPResponse *)dispatchRequest: (OWebHTTPRequest *)request;

@end

[[subclassing_restricted, direct_members]]
@interface OWebRouteException : OFException

@property(readonly, nonatomic) OFString *reason;

+ (instancetype)exceptionWithReason: (OFString *)reason;
- (instancetype)initWithReason: (OFString *)reason;
- (instancetype)init OF_UNAVAILABLE;

@end


#pragma clang assume_nonnull end
