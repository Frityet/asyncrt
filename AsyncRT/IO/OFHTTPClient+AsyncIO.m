#import "OFHTTPClient+AsyncIO.h"

#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

int AsyncRT_OFHTTPClient_AsyncIO_anchor = 0;

static int *const forceObjFWTLS __attribute__((used)) = &_ObjFWTLS_reference;

[[subclassing_restricted, direct_members]]
@interface OFHTTPClientTaskOperation : OFObject <OFHTTPClientDelegate>

@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) AsyncTask<OFHTTPResponse *> *task;

- (instancetype)initWithClient: (OFHTTPClient *)client request: (OFHTTPRequest *)request redirects: (unsigned int)redirects;
- (instancetype)init [[unavailable]];
- (void)start;
- (void)_complete;
- (void)_rejectWithObject: (id nillable)exception;
- (OFException *)_exceptionFromObject: (id nillable)exception;

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

@implementation OFHTTPResponse(AsyncIO)

- (AsyncTask<OFData *> *)taskToReadBody
{
    return [self taskToReadUntilEnd];
}

@end

@implementation OFHTTPClient(AsyncIO)

- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request
{
    return [self taskToPerformRequest: request redirects: 10];
}

- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects
{
    auto operation = [[OFHTTPClientTaskOperation alloc] initWithClient: self request: [request copy] redirects: redirects];
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

@end

@implementation OFHTTPClientTaskOperation {
    unsigned int _redirects;
    AsyncTaskCompletionSource<OFHTTPResponse *> *_source;
    unretained OFObject<OFHTTPClientDelegate> *nillable _delegate;
    OFHTTPClientTaskOperation *nillable _retainedSelf;
}

- (instancetype)initWithClient: (OFHTTPClient *)client request: (OFHTTPRequest *)request redirects: (unsigned int)redirects
{
    self = [super init];
    _client = client;
    _request = request;
    _redirects = redirects;
    _source = [[AsyncTaskCompletionSource<OFHTTPResponse *> alloc] init];
    return self;
}

- (AsyncTask<OFHTTPResponse *> *)task
{
    return _source.task;
}

- (void)start
{
    _retainedSelf = self;
    _delegate = _client.delegate;
    _client.delegate = self;

    @try {
        [_client asyncPerformRequest: _request redirects: _redirects];
    } @catch (OFException *exception) {
        [_source rejectWithError: exception];
        [self _complete];
    }
}

- (void)client: (OFHTTPClient *)client didPerformRequest: (OFHTTPRequest *)request response: (OFHTTPResponse *nillable)response exception: (id nillable)exception
{
    if (_delegate != nilptr)
        [_delegate client: client didPerformRequest: request response: response exception: exception];

    if (exception != nilptr) {
        [self _rejectWithObject: exception];
        [self _complete];
        return;
    }

    if (response == nilptr) {
        [_source rejectWithError: [[AsyncHTTPMissingResponseException alloc] initWithRequest: request]];
        [self _complete];
        return;
    }

    [_source resolveWithResult: $assert_nonnil(response)];
    [self _complete];
}

- (void)client: (OFHTTPClient *)client didCreateTCPSocket: (OFTCPSocket *)TCPSocket request: (OFHTTPRequest *)request
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:didCreateTCPSocket:request:)])
        [_delegate client: client didCreateTCPSocket: TCPSocket request: request];
}

- (void)client: (OFHTTPClient *)client didCreateTLSStream: (OFTLSStream *)TLSStream request: (OFHTTPRequest *)request
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:didCreateTLSStream:request:)])
        [_delegate client: client didCreateTLSStream: TLSStream request: request];
}

- (void)client: (OFHTTPClient *)client wantsRequestBody: (OFStream *)requestBody request: (OFHTTPRequest *)request
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:wantsRequestBody:request:)])
        [_delegate client: client wantsRequestBody: requestBody request: request];
}

- (void)client: (OFHTTPClient *)client didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers statusCode: (short)statusCode request: (OFHTTPRequest *)request
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:didReceiveHeaders:statusCode:request:)])
        [_delegate client: client didReceiveHeaders: headers statusCode: statusCode request: request];
}

- (bool)client: (OFHTTPClient *)client shouldFollowRedirectToIRI: (OFIRI *)IRI statusCode: (short)statusCode request: (OFHTTPRequest *)request response: (OFHTTPResponse *)response
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:shouldFollowRedirectToIRI:statusCode:request:response:)])
        return [_delegate client: client shouldFollowRedirectToIRI: IRI statusCode: statusCode request: request response: response];
    return true;
}

- (void)_complete
{
    auto retainedSelf = _retainedSelf;
    if (_client.delegate == self)
        _client.delegate = _delegate;
    if (retainedSelf == nilptr)
        return;
    _retainedSelf = nilptr;
}

- (void)_rejectWithObject: (id nillable)exception
{
    [_source rejectWithError: [self _exceptionFromObject: exception]];
}

- (OFException *)_exceptionFromObject: (id nillable)exception
{
    if (exception != nilptr and [exception isKindOfClass: OFException.class])
        return (OFException *nonnil)exception;

    return [OFException exception];
}

@end

#pragma clang assume_nonnull end
