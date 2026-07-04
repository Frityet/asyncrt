#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/AsyncTask.h>
#import <AsyncRT/IO/AsyncStream.h>

#pragma clang assume_nonnull begin

@class AsyncHTTPClient;
@class AsyncHTTPResponse;

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPMissingResponseException : OFException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithRequest: (OFHTTPRequest *)request;
- (instancetype)init [[unavailable]];

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
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects;
- (AsyncTask<OFData *> *)taskToReadBodyForRequest: (OFHTTPRequest *)request;

@end

#pragma clang assume_nonnull end
