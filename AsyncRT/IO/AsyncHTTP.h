#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/AsyncTask.h>
#import <AsyncRT/IO/AsyncStream.h>

#pragma clang assume_nonnull begin

@class AsyncHTTPClient;
@class AsyncHTTPRequest;
@class AsyncHTTPResponse;

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPMissingResponseException : OFException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithRequest: (OFHTTPRequest *)request;
- (instancetype)init [[unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPRequest : OFObject

@property(readonly, nonatomic) OFHTTPRequest *rawRequest;
@property(copy, nonatomic) OFIRI *IRI;
@property(nonatomic) OFHTTPRequestMethod method;
@property(copy, nonatomic) OFDictionary<OFString *, OFString *> *nillable headers;

+ (instancetype)requestWithIRI: (OFIRI *)IRI;
+ (instancetype)requestWithRawRequest: (OFHTTPRequest *)request;
- (instancetype)initWithIRI: (OFIRI *)IRI;
- (instancetype)initWithRawRequest: (OFHTTPRequest *)request;
- (instancetype)init [[unavailable]];
- (OFHTTPRequest *)copyRawRequest;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPResponse : OFObject

@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFHTTPResponse *rawResponse;
@property(readonly, nonatomic) OFHTTPClient *rawClient;
@property(readonly, nonatomic) short statusCode;
@property(readonly, nonatomic) OFDictionary<OFString *, OFString *> *headers;
@property(readonly, nonatomic) AsyncStream *bodyStream;

- (instancetype)initWithRequest: (OFHTTPRequest *)request response: (OFHTTPResponse *)response client: (OFHTTPClient *)client;
- (instancetype)init [[unavailable]];
- (AsyncTask<OFData *> *)taskToReadBody;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPClient : OFObject

@property(nonatomic) bool allowsInsecureRedirects;
@property(assign, nonatomic) OFObject<OFHTTPClientDelegate> *nillable delegate;

+ (instancetype)client;
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (AsyncHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRawRequest: (OFHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (AsyncHTTPRequest *)request redirects: (unsigned int)redirects;
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRawRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects;
- (AsyncTask<OFData *> *)taskToReadBodyForRequest: (AsyncHTTPRequest *)request;
- (AsyncTask<OFData *> *)taskToReadBodyForRawRequest: (OFHTTPRequest *)request;

@end

#pragma clang assume_nonnull end
