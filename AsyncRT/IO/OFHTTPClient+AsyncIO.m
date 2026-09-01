#import "OFHTTPClient+AsyncIO.h"

#import <ObjFW/objfw-defs.h>
#import <ObjFWTLS/ObjFWTLS.h>

#pragma clang assume_nonnull begin

int AsyncRT_OFHTTPClient_AsyncIO_anchor = 0;

static int *const forceObjFWTLS __attribute__((used)) = &_ObjFWTLS_reference;

#if defined(OBJFW_VERSION_MAJOR) && \
    (OBJFW_VERSION_MAJOR > 1 || OBJFW_VERSION_MINOR >= 6)
typedef unsigned short AsyncRTHTTPStatusCode;
#else
typedef short AsyncRTHTTPStatusCode;
#endif

[[subclassing_restricted, direct_members]]
@interface OFHTTPClientTaskOperation : OFObject <OFHTTPClientDelegate>

@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) AsyncTask<OFHTTPResponse *> *task;
- (instancetype)initWithClient: (OFHTTPClient *)client
                        request: (OFHTTPRequest *)request
                      redirects: (unsigned int)redirects
                           body: (OFData *nillable)body;

- (instancetype)init [[clang::unavailable]];
- (void)start;
- (void)_complete;
- (AsyncTask<OFNumber *> *)_taskToCloseRequestBody: (OFStream *)requestBody;
- (void)_closeRequestBody;
- (void)_resolveWithResponse: (OFHTTPResponse *)response;
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
    auto operation = [[OFHTTPClientTaskOperation alloc]
        initWithClient: self request: [request copy] redirects: redirects body: nilptr];
    [operation start];
    return operation.task;
}

- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request body: (OFData *)body
{
    return [self taskToPerformRequest: request redirects: 10 body: body];
}

- (AsyncTask<OFHTTPResponse *> *)taskToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects body: (OFData *)body
{
    auto operation = [[OFHTTPClientTaskOperation alloc]
        initWithClient: self request: [request copy] redirects: redirects body: body];
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
    bool _sourceCompleted;
    unretained OFObject<OFHTTPClientDelegate> *nillable _delegate;
    OFData *nillable _body;
    AsyncTask<OFNumber *> *nillable _bodyWriteTask;
    OFStream *nillable _requestBody;
    AsyncTaskCompletionSource<OFNumber *> *nillable _bodyCloseSource;
    OFHTTPClientTaskOperation *nillable _retainedSelf;
}

- (instancetype)initWithClient: (OFHTTPClient *)client
                        request: (OFHTTPRequest *)request
                      redirects: (unsigned int)redirects
                           body: (OFData *nillable)body
{
    self = [super init];
    _client = client;

    if (body != nilptr && (body.count == 0 || body.itemSize == 0))
        body = nilptr;

    if (body != nilptr) {
        auto headers = [request.headers mutableCopy];
        if (headers == nilptr)
            headers = [OFMutableDictionary dictionary];

        if ([headers objectForKey: @"Content-Length"] == nilptr and
            [headers objectForKey: @"Transfer-Encoding"] == nilptr)
            [headers setObject: [OFString stringWithFormat: @"%zu",
                body.count * body.itemSize] forKey: @"Content-Length"];

        request.headers = headers;
    }

    _request = request;
    _redirects = redirects;
    _body = body;
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
        [self _rejectWithObject: exception];
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
        [self _rejectWithObject: [[AsyncHTTPMissingResponseException alloc] initWithRequest: request]];
        [self _complete];
        return;
    }

    [self _resolveWithResponse: $assert_nonnil(response)];
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
    if (_body != nilptr) {
        auto body = $assert_nonnil(_body);
        _bodyWriteTask = [AsyncTask<OFNumber *> spawn: ^OFNumber *{
            @try {
                auto bytesWritten = [[requestBody taskToWriteData: body] await];
                [[self _taskToCloseRequestBody: requestBody] await];
                return bytesWritten;
            } @catch (OFException *exception) {
                [self _rejectWithObject: exception];
                [self _complete];
                [_client close];
                @throw;
            }
        }];
        return;
    }

    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:wantsRequestBody:request:)])
        [_delegate client: client wantsRequestBody: requestBody request: request];
}

- (AsyncTask<OFNumber *> *)_taskToCloseRequestBody: (OFStream *)requestBody
{
    _requestBody = requestBody;
    _bodyCloseSource = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];

    auto timer = [OFTimer timerWithTimeInterval: 0
                                           target: self
                                         selector: @selector(_closeRequestBody)
                                          repeats: false];
    [[OFRunLoop currentRunLoop] addTimer: timer forMode: OFDefaultRunLoopMode];

    return [$assert_nonnil(_bodyCloseSource) task];
}

- (void)_closeRequestBody
{
    auto requestBody = $assert_nonnil(_requestBody);
    auto source = $assert_nonnil(_bodyCloseSource);

    @try {
        [requestBody close];
        [source resolveWithResult: @0];
    } @catch (id exception) {
        [source rejectWithError: [self _exceptionFromObject: exception]];
    }

    _requestBody = nilptr;
    _bodyCloseSource = nilptr;
}

- (void)client: (OFHTTPClient *)client didReceiveHeaders: (OFDictionary<OFString *, OFString *> *)headers statusCode: (AsyncRTHTTPStatusCode)statusCode request: (OFHTTPRequest *)request
{
    if (_delegate != nilptr and [_delegate respondsToSelector: @selector(client:didReceiveHeaders:statusCode:request:)])
        [_delegate client: client didReceiveHeaders: headers statusCode: statusCode request: request];
}

- (bool)client: (OFHTTPClient *)client shouldFollowRedirectToIRI: (OFIRI *)IRI statusCode: (AsyncRTHTTPStatusCode)statusCode request: (OFHTTPRequest *)request response: (OFHTTPResponse *)response
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

- (void)_resolveWithResponse: (OFHTTPResponse *)response
{
    if (_sourceCompleted)
        return;

    _sourceCompleted = true;
    [_source resolveWithResult: response];
}

- (void)_rejectWithObject: (id nillable)exception
{
    if (_sourceCompleted)
        return;

    _sourceCompleted = true;
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
