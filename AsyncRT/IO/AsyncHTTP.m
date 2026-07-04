#import "AsyncHTTP.h"

#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

static int *const forceObjFWTLS __attribute__((used)) = &_ObjFWTLS_reference;

@class AsyncHTTPClientOperation;

@interface AsyncHTTPClient ()
- (void)_operationDidFinish: (AsyncHTTPClientOperation *)operation;
@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPClientOperation : OFObject <OFHTTPClientDelegate>
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) AsyncTask<AsyncHTTPResponse *> *task;
- (instancetype)initWithOwner: (AsyncHTTPClient *)owner request: (OFHTTPRequest *)request redirects: (unsigned int)redirects;
- (instancetype)init [[unavailable]];
- (void)start;
@end

@implementation AsyncHTTPMissingResponseException

- (instancetype)initWithRequest: (OFHTTPRequest *)request
{
    self = [super init];
    _request = request;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"%@: missing HTTP response for %@", self.className, _request.IRI.string];
}

@end

@implementation AsyncHTTPResponse

- (instancetype)initWithRequest: (OFHTTPRequest *)request response: (OFHTTPResponse *)response client: (OFHTTPClient *)client
{
    self = [super init];
    _request = request;
    _rawResponse = response;
    _rawClient = client;
    _bodyStream = [AsyncStream streamWithStream: response];
    return self;
}

- (short)statusCode
{
    return _rawResponse.statusCode;
}

- (OFDictionary<OFString *, OFString *> *)headers
{
    return _rawResponse.headers;
}

- (AsyncTask<OFData *> *)taskToReadBody
{
    return [_bodyStream taskToReadUntilEnd];
}

@end

@implementation AsyncHTTPClient {
    OFMutableArray<AsyncHTTPClientOperation *> *_activeOperations;
}

+ (instancetype)client
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    _activeOperations = [OFMutableArray<AsyncHTTPClientOperation *> array];
    return self;
}

- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request
{
    return [self taskToPerformRequest: request redirects: 10];
}

- (AsyncTask<AsyncHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects
{
    auto operation = [[AsyncHTTPClientOperation alloc] initWithOwner: self request: [request copy] redirects: redirects];
    [_activeOperations addObject: operation];
    [operation start];
    return operation.task;
}

- (AsyncTask<OFData *> *)taskToReadBodyForRequest: (OFHTTPRequest *)request
{
    return [AsyncTask<OFData *> spawn: ^OFData *{
        auto response = [[self taskToPerformRequest: request] await];
        return [[response taskToReadBody] await];
    }];
}

- (void)_operationDidFinish: (AsyncHTTPClientOperation *)operation
{
    [_activeOperations removeObjectIdenticalTo: operation];
}

@end

@implementation AsyncHTTPClientOperation {
    AsyncHTTPClient *_owner;
    unsigned int _redirects;
    AsyncTaskCompletionSource<AsyncHTTPResponse *> *_source;
}

- (instancetype)initWithOwner: (AsyncHTTPClient *)owner request: (OFHTTPRequest *)request redirects: (unsigned int)redirects
{
    self = [super init];
    _owner = owner;
    _request = request;
    _redirects = redirects;
    _client = [OFHTTPClient client];
    _client.delegate = self;
    _client.allowsInsecureRedirects = owner.allowsInsecureRedirects;
    _source = [[AsyncTaskCompletionSource<AsyncHTTPResponse *> alloc] init];
    return self;
}

- (AsyncTask<AsyncHTTPResponse *> *)task
{
    return _source.task;
}

- (void)start
{
    @try {
        [_client asyncPerformRequest: _request redirects: _redirects];
    } @catch (OFException *exception) {
        [_source rejectWithError: exception];
        [_owner _operationDidFinish: self];
    }
}

- (void)client: (OFHTTPClient *)client didPerformRequest: (OFHTTPRequest *)request response: (OFHTTPResponse *nillable)response exception: (id nillable)exception
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr)
        [delegate client: client didPerformRequest: request response: response exception: exception];

    if (exception != nilptr) {
        [_source rejectWithError: [self _exceptionFromObject: exception]];
        [_owner _operationDidFinish: self];
        return;
    }

    if (response == nilptr) {
        [_source rejectWithError: [[AsyncHTTPMissingResponseException alloc] initWithRequest: request]];
        [_owner _operationDidFinish: self];
        return;
    }

    [_source resolveWithResult: [[AsyncHTTPResponse alloc] initWithRequest: request response: $assert_nonnil(response) client: client]];
    [_owner _operationDidFinish: self];
}

- (void)client: (OFHTTPClient *)client didCreateTCPSocket: (OFTCPSocket *)TCPSocket request: (OFHTTPRequest *)request
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr and [delegate respondsToSelector: @selector(client:didCreateTCPSocket:request:)])
        [delegate client: client didCreateTCPSocket: TCPSocket request: request];
}

- (void)client: (OFHTTPClient *)client didCreateTLSStream: (OFTLSStream *)TLSStream request: (OFHTTPRequest *)request
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr and [delegate respondsToSelector: @selector(client:didCreateTLSStream:request:)])
        [delegate client: client didCreateTLSStream: TLSStream request: request];
}

- (void)client: (OFHTTPClient *)client wantsRequestBody: (OFStream *)requestBody request: (OFHTTPRequest *)request
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr and [delegate respondsToSelector: @selector(client:wantsRequestBody:request:)])
        [delegate client: client wantsRequestBody: requestBody request: request];
}

- (void)client: (OFHTTPClient *)client didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers statusCode: (short)statusCode request: (OFHTTPRequest *)request
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr and [delegate respondsToSelector: @selector(client:didReceiveHeaders:statusCode:request:)])
        [delegate client: client didReceiveHeaders: headers statusCode: statusCode request: request];
}

- (bool)client: (OFHTTPClient *)client shouldFollowRedirectToIRI: (OFIRI *)IRI statusCode: (short)statusCode request: (OFHTTPRequest *)request response: (OFHTTPResponse *)response
{
    auto delegate = _owner.delegate;
    if (delegate != nilptr and [delegate respondsToSelector: @selector(client:shouldFollowRedirectToIRI:statusCode:request:response:)])
        return [delegate client: client shouldFollowRedirectToIRI: IRI statusCode: statusCode request: request response: response];
    return true;
}

- (OFException *)_exceptionFromObject: (id nillable)exception [[direct]]
{
    if (exception != nilptr and [exception isKindOfClass: OFException.class])
        return (OFException *nonnil)exception;

    return [OFException exception];
}

@end

#pragma clang assume_nonnull end
