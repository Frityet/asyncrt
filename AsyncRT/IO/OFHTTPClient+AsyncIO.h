#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/AsyncTask.h>
#import <AsyncRT/IO/OFStream+AsyncIO.h>

#pragma clang assume_nonnull begin

extern int AsyncRT_OFHTTPClient_AsyncIO_anchor;
static int *const AsyncRT_OFHTTPClient_AsyncIO_anchor_reference __attribute__((used)) = &AsyncRT_OFHTTPClient_AsyncIO_anchor;

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPMissingResponseException : OFException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithRequest: (OFHTTPRequest *)request;
- (instancetype)init [[clang::unavailable]];

@end

@interface OFHTTPResponse(AsyncIO)

- (AsyncTask<OFData *> *)taskToReadBody;

@end

@interface OFHTTPClient(AsyncIO)

- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request;
- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects;
- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request body: (OFData *)body;
- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects body: (OFData *)body;
- (AsyncTask<OFData *> *)taskToReadBodyForRequest: (OFHTTPRequest *)request;

@end

#pragma clang assume_nonnull end
