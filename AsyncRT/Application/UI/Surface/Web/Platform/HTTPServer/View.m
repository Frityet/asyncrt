#import <AsyncRT/Application/UI/Surface/Web/Platform/HTTPServer/View.h>

#import <AsyncRT/Networking/HTTP.h>

#pragma clang assume_nonnull begin

static OFString *const AsyncWebHTTPServerDefaultHost = @"127.0.0.1";
static uint16_t const AsyncWebHTTPServerDefaultPort = 8765;
static size_t const AsyncWebHTTPServerMaximumRequestBodyLength = 1024 * 1024;
static constexpr char AsyncWebHTTPServerBridgeJavaScript[] = {
#embed "Bridge.js"
    , 0
};

[[subclassing_restricted]]
@interface AsyncWebHTTPServerJavaScriptEvaluationException : OFException

@property(readonly, copy, nonatomic) OFString *reason;
@property(readonly, copy, nonatomic) OFString *javaScript;

- (instancetype)initWithJavaScript: (OFString *)javaScript;
- (instancetype)initWithJavaScript: (OFString *)javaScript reason: (OFString *)reason [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncWebHTTPServerView ()

- (AsyncHTTPServer *)_newServerWithPort: (uint16_t)port;
- (AsyncTask<AsyncHTTPResponse *> *)_taskToServeIndex: (AsyncHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)_taskToServeEvents: (AsyncHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)_taskToHandleInvoke: (AsyncHTTPRequest *)request;
- (AsyncTask<AsyncHTTPResponse *> *)_taskToHandleEvaluationResult: (AsyncHTTPRequest *)request;
- (void)_enqueueJavaScriptCommand: (OFString *)javaScript requestID: (OFString *nillable)requestID;
- (OFString *)_commandsJSONSinceCommandID: (uint64_t)commandID;
- (OFString *)_HTMLByInjectingBridgeIntoHTML: (OFString *)HTML;

@end

@namespace(AsyncWebHTTPServerSupport)

+ (OFString *)bridgeJavaScript;
+ (OFString *)scriptTagForBridgeJavaScript;
+ (OFString *)responseJSONForException: (OFException *)exception;
+ (AsyncHTTPResponse *)HTMLResponseForBody: (OFString *)body;
+ (AsyncHTTPResponse *)JSONResponseForBody: (OFString *)body;
+ (AsyncHTTPResponse *)redirectResponseForIRI: (OFIRI *)IRI;
+ (OFIRI *)serverIRIForHost: (OFString *)host port: (uint16_t)port;
+ (OFString *)configuredHost;
+ (uint16_t)configuredPort;

@end

@implementation AsyncWebHTTPServerJavaScriptEvaluationException

- (instancetype)initWithJavaScript: (OFString *)javaScript
{
    return [self initWithJavaScript: javaScript reason: @"The HTTP WebUI backend cannot evaluate JavaScript without a connected browser"];
}

- (instancetype)initWithJavaScript: (OFString *)javaScript reason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    _javaScript = [javaScript copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"%@: %@\nJavaScript:\n%@",
                                      self.className,
                                      self.reason,
                                      self.javaScript];
}

@end

@namespace_implementation(AsyncWebHTTPServerSupport)

+ (OFString *)bridgeJavaScript
{
    return [OFString stringWithUTF8String: AsyncWebHTTPServerBridgeJavaScript];
}

+ (OFString *)scriptTagForBridgeJavaScript
{
    return [OFString stringWithFormat: @"<script>%@</script>", self.bridgeJavaScript];
}

+ (OFString *)responseJSONForException: (OFException *)exception
{
    auto response = @{
        @"error": @{
            @"className": exception.className,
            @"description": exception.description
        }
    };

    return response.JSONRepresentation;
}

+ (AsyncHTTPResponse *)HTMLResponseForBody: (OFString *)body
{
    return [AsyncHTTPResponse from: body
                        statusCode: 200
                      extraHeaders: [OFDictionary dictionaryWithObject: @"text/html; charset=utf-8"
                                                                forKey: @"Content-Type"]];
}

+ (AsyncHTTPResponse *)JSONResponseForBody: (OFString *)body
{
    return [AsyncHTTPResponse from: body
                        statusCode: 200
                      extraHeaders: [OFDictionary dictionaryWithObject: @"application/json; charset=utf-8"
                                                                forKey: @"Content-Type"]];
}

+ (AsyncHTTPResponse *)redirectResponseForIRI: (OFIRI *)IRI
{
    return [AsyncHTTPResponse from: @""
                        statusCode: 302
                      extraHeaders: [OFDictionary dictionaryWithObject: IRI.string
                                                                forKey: @"Location"]];
}

+ (OFIRI *)serverIRIForHost: (OFString *)host port: (uint16_t)port
{
    return [OFIRI IRIWithString: [OFString stringWithFormat: @"http://%@:%u/", host, port]];
}

+ (OFString *)configuredHost
{
    OFString *nillable host = [OFApplication.environment objectForKey: @"ASYNCRT_WEBUI_HOST"];

    return (host != nilptr and $assert_nonnil(host).length > 0)
        ? $assert_nonnil(host)
        : AsyncWebHTTPServerDefaultHost;
}

+ (uint16_t)configuredPort
{
    OFString *nillable portString = [OFApplication.environment objectForKey: @"ASYNCRT_WEBUI_PORT"];
    if (portString == nilptr or $assert_nonnil(portString).length == 0)
        return AsyncWebHTTPServerDefaultPort;

    unsigned long long port = $assert_nonnil(portString).unsignedLongLongValue;
    if (port > UINT16_MAX)
        @throw [OFInvalidArgumentException exception];

    return (uint16_t)port;
}

@end

@implementation AsyncWebHTTPServerView {
    AsyncHTTPServer *_server;
    OFString *_host;
    OFMutex *_commandLock;
    OFMutableArray<OFDictionary<OFString *, id> *> *_commands;
    OFMutableDictionary<OFString *, AsyncCompletionSource<id> *> *_pendingJavaScriptResults;
    uint64_t _nextCommandID;
    uint64_t _nextRequestID;
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
{
    self = [super initWithConfiguration: configuration];
    _host = [AsyncWebHTTPServerSupport configuredHost];
    _commandLock = [OFMutex mutex];
    _commands = [OFMutableArray array];
    _pendingJavaScriptResults = [OFMutableDictionary dictionary];
    _nextCommandID = 1;
    _nextRequestID = 1;
    uint16_t port = [AsyncWebHTTPServerSupport configuredPort];
    _server = [self _newServerWithPort: port];

    @try {
        [_server start];
    } @catch (OFException *exception) {
        if (port == 0)
            @throw exception;

        _server = [self _newServerWithPort: 0];
        [_server start];
    }

    return self;
}

- (OFIRI *nillable)serverIRI
{
    if (self.isClosed)
        return nilptr;

    return [AsyncWebHTTPServerSupport serverIRIForHost: _host port: _server.port];
}

- (void)loadHTML: (OFString *)html
{
    [super loadHTML: [self _HTMLByInjectingBridgeIntoHTML: html]];
}

- (AsyncTask<id> *)taskToEvaluateJavaScriptReturningValue: (OFString *)javaScript
{
    if (self.isClosed) {
        return [AsyncTask rejected: [[AsyncWebHTTPServerJavaScriptEvaluationException alloc] initWithJavaScript: javaScript
                                                                                                        reason: @"The HTTP WebUI backend cannot evaluate JavaScript after the view is closed"]];
    }

    auto completionSource = [[AsyncCompletionSource<id> alloc] init];
    OFString *requestID;

    [_commandLock lock];
    @try {
        requestID = [OFString stringWithFormat: @"eval-%llu", (unsigned long long)_nextRequestID++];
        _pendingJavaScriptResults[requestID] = completionSource;
    } @finally {
        [_commandLock unlock];
    }

    [self _enqueueJavaScriptCommand: javaScript requestID: requestID];
    return completionSource.task;
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript
{
    [self _enqueueJavaScriptCommand: javaScript requestID: nilptr];
    return [AsyncTask resolved: AsyncUnit.unit];
}

- (void)close
{
    if (self.isClosed)
        return;

    [super close];
    if (_server.isRunning)
        [_server stop];

    [_commandLock lock];
    @try {
        auto exception = [[AsyncWebHTTPServerJavaScriptEvaluationException alloc] initWithJavaScript: @""
                                                                                              reason: @"The HTTP WebUI backend closed before the browser returned a JavaScript result"];
        for (OFString *requestID in _pendingJavaScriptResults)
            [[_pendingJavaScriptResults objectForKey: requestID] reject: exception];
        [_pendingJavaScriptResults removeAllObjects];
    } @finally {
        [_commandLock unlock];
    }
}

- (AsyncHTTPServer *)_newServerWithPort: (uint16_t)port
{
    AsyncHTTPServer *server = [AsyncHTTPServer serverWithHost: _host port: port];
    server.name = @"AsyncRT WebUI";
    [server addRoute: [AsyncHTTPGETRoute withPath: @"/" handledByBlock: ^AsyncTask<AsyncHTTPResponse *> *(AsyncHTTPRequest *request) {
        return [self _taskToServeIndex: request];
    }]];
    [server addRoute: [AsyncHTTPGETRoute withPath: @"/index.html" handledByBlock: ^(AsyncHTTPRequest *request) {
        return [self _taskToServeIndex: request];
    }]];
    [server addRoute: [AsyncHTTPGETRoute withPath: @"/__asyncrt/events" handledByBlock: ^(AsyncHTTPRequest *request) {
        return [self _taskToServeEvents: request];
    }]];
    [server addRoute: [AsyncHTTPPOSTRoute withPath: @"/__asyncrt/invoke" handledByBlock: ^(AsyncHTTPRequest *request) {
        return [self _taskToHandleInvoke: request];
    }]];
    [server addRoute: [AsyncHTTPPOSTRoute withPath: @"/__asyncrt/evaluate-result" handledByBlock: ^(AsyncHTTPRequest *request) {
        return [self _taskToHandleEvaluationResult: request];
    }]];
    return server;
}

- (AsyncTask<AsyncHTTPResponse *> *)_taskToServeIndex: (AsyncHTTPRequest *)request
{
    if (self.loadedHTML != nilptr)
        return [AsyncTask resolved: [AsyncWebHTTPServerSupport HTMLResponseForBody: $assert_nonnil(self.loadedHTML)]];

    if (self.loadedIRI != nilptr)
        return [AsyncTask resolved: [AsyncWebHTTPServerSupport redirectResponseForIRI: $assert_nonnil(self.loadedIRI)]];

    return [AsyncTask resolved: [AsyncWebHTTPServerSupport HTMLResponseForBody: @"<!doctype html><html><body></body></html>"]];
}

- (AsyncTask<AsyncHTTPResponse *> *)_taskToServeEvents: (AsyncHTTPRequest *)request
{
    id nillable sinceObject = [request.queryParameters objectForKey: @"since"];
    uint64_t commandID = 0;
    if ([sinceObject isKindOfClass: OFString.class])
        commandID = (uint64_t)((OFString *)sinceObject).unsignedLongLongValue;

    return [AsyncTask resolved: [AsyncWebHTTPServerSupport JSONResponseForBody: [self _commandsJSONSinceCommandID: commandID]]];
}

- (AsyncTask<AsyncHTTPResponse *> *)_taskToHandleInvoke: (AsyncHTTPRequest *)request
{
    return [[request taskToReadBodyWithMaximumLength: AsyncWebHTTPServerMaximumRequestBodyLength] flatMap: ^AsyncTask *(OFData *data) {
        OFString *body = [[OFString alloc] initWithData: data encoding: OFStringEncodingUTF8];
        id messageObject = body.objectByParsingJSON;
        if (not [messageObject isKindOfClass: OFArray.class])
            return [AsyncTask resolved: [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"]];

        auto array = (OFArray<id> *)messageObject;
        id nillable actionObject = (array.count > 0 ? array[0] : nilptr);
        id nillable requestIDObject = (array.count > 1 ? array[1] : nilptr);
        id nillable payload = (array.count > 2 ? array[2] : nilptr);

        if (not [actionObject isKindOfClass: OFString.class])
            return [AsyncTask resolved: [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"]];
        if (not [requestIDObject isKindOfClass: OFString.class])
            return [AsyncTask resolved: [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"]];

        AsyncWebUIRequest webRequest = (AsyncWebUIRequest){
            .action = (OFString *)actionObject,
            .payload = (payload != OFNull.null ? payload : nilptr),
            .requestID = (OFString *)requestIDObject
        };

        return [[[self taskToHandleRequest: webRequest] recover: ^(OFException *exception) {
            return [AsyncWebHTTPServerSupport responseJSONForException: exception];
        }] map: ^(OFString *responseJSON) {
            return [AsyncWebHTTPServerSupport JSONResponseForBody: responseJSON];
        }];
    }];
}

- (AsyncTask<AsyncHTTPResponse *> *)_taskToHandleEvaluationResult: (AsyncHTTPRequest *)request
{
    return [[request taskToReadBodyWithMaximumLength: AsyncWebHTTPServerMaximumRequestBodyLength] map: ^id(OFData *data) {
        OFString *body = [[OFString alloc] initWithData: data encoding: OFStringEncodingUTF8];
        id messageObject = body.objectByParsingJSON;
        if (not [messageObject isKindOfClass: OFArray.class])
            return [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"];

        auto array = (OFArray<id> *)messageObject;
        id nillable requestIDObject = (array.count > 0 ? array[0] : nilptr);
        id nillable okObject = (array.count > 1 ? array[1] : nilptr);
        id nillable payload = (array.count > 2 ? array[2] : nilptr);

        if (not [requestIDObject isKindOfClass: OFString.class] or not [okObject isKindOfClass: OFNumber.class])
            return [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"];

        AsyncCompletionSource<id> *nillable completionSource;
        [_commandLock lock];
        @try {
            completionSource = [_pendingJavaScriptResults objectForKey: (OFString *)requestIDObject];
            if (completionSource != nilptr)
                [_pendingJavaScriptResults removeObjectForKey: (OFString *)requestIDObject];
        } @finally {
            [_commandLock unlock];
        }

        if (completionSource == nilptr)
            return [AsyncWebHTTPServerSupport JSONResponseForBody: @"null"];

        if (((OFNumber *)okObject).boolValue) {
            [$assert_nonnil(completionSource) fulfill: (payload != nilptr ? $assert_nonnil(payload) : (id)OFNull.null)];
        } else {
            OFString *reason = @"Browser JavaScript evaluation failed";
            if ([payload isKindOfClass: OFDictionary.class]) {
                id nillable message = [(OFDictionary *)payload objectForKey: @"message"];
                if ([message isKindOfClass: OFString.class])
                    reason = (OFString *)message;
            } else if ([payload isKindOfClass: OFString.class]) {
                reason = (OFString *)payload;
            }

            [$assert_nonnil(completionSource) reject:
                [[AsyncWebHTTPServerJavaScriptEvaluationException alloc] initWithJavaScript: @""
                                                                                     reason: reason]];
        }

        return [AsyncWebHTTPServerSupport JSONResponseForBody: @"true"];
    }];
}

- (void)_enqueueJavaScriptCommand: (OFString *)javaScript requestID: (OFString *nillable)requestID
{
    if (self.isClosed)
        return;

    [_commandLock lock];
    @try {
        auto command = [OFMutableDictionary<OFString *, id> dictionary];
        [command setObject: [OFNumber numberWithUnsignedLongLong: _nextCommandID++] forKey: @"id"];
        [command setObject: [javaScript copy] forKey: @"script"];
        if (requestID != nilptr)
            [command setObject: $assert_nonnil(requestID) forKey: @"requestID"];
        [command makeImmutable];
        [_commands addObject: command];

        while (_commands.count > 256)
            [_commands removeObjectAtIndex: 0];
    } @finally {
        [_commandLock unlock];
    }
}

- (OFString *)_commandsJSONSinceCommandID: (uint64_t)commandID
{
    auto commands = [OFMutableArray<OFDictionary<OFString *, id> *> array];

    [_commandLock lock];
    @try {
        for (OFDictionary<OFString *, id> *command in _commands) {
            auto ID = (OFNumber *)[command objectForKey: @"id"];
            if (ID.unsignedLongLongValue > commandID)
                [commands addObject: command];
        }
    } @finally {
        [_commandLock unlock];
    }

    [commands makeImmutable];
    return commands.JSONRepresentation;
}

- (OFString *)_HTMLByInjectingBridgeIntoHTML: (OFString *)HTML
{
    OFString *scriptTag = AsyncWebHTTPServerSupport.scriptTagForBridgeJavaScript;
    OFRange headCloseRange = [HTML rangeOfString: @"</head>"];

    if (headCloseRange.location == OFNotFound)
        return [OFString stringWithFormat: @"%@\n%@", scriptTag, HTML];

    auto result = [OFMutableString string];
    [result appendString: [HTML substringToIndex: headCloseRange.location]];
    [result appendString: scriptTag];
    [result appendString: [HTML substringFromIndex: headCloseRange.location]];
    [result makeImmutable];
    return result;
}

@end

#pragma clang assume_nonnull end
