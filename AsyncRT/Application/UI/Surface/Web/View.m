#import <AsyncRT/Application/UI/Surface/Web/View.h>
#import <AsyncRT/Application/UI/Surface/Web/DOM.h>

#if defined(__APPLE__)
#import <AsyncRT/Application/UI/Surface/Web/Platform/WKWebKit/View.h>
#endif

#pragma clang assume_nonnull begin

@implementation AsyncWebUIView {
    AsyncUIWindowConfiguration *_configuration;
    AsyncWebUIDocument *_document;
    OFMutableDictionary<OFString *, AsyncWebUIActionHandler> *_actionHandlers;
    OFString *nillable _loadedHTML;
    OFIRI *nillable _loadedIRI;
    bool _closed;
}

+ (instancetype)alloc
{
    if (self == AsyncWebUIView.class) {
#if defined(__APPLE__)
        return [AsyncWKWebKitView alloc];
#else
        @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
#endif
    }

    return [super alloc];
}

+ (OFString *)javaScriptToDispatchEventNamed: (OFString *)name
                                  payloadJSON: (OFString *nillable)payloadJSON
{
    OFString *detailJSON = (payloadJSON != nilptr ? $assert_nonnil(payloadJSON) : @"null");

    return [OFString stringWithFormat: @"window.dispatchEvent(new CustomEvent(%@, { detail: %@ }));", name.JSONRepresentation, detailJSON];
}

+ (OFString *)javaScriptToResolveRequestID: (OFString *)requestID
                               responseJSON: (OFString *nillable)responseJSON
{
    return [self javaScriptToDispatchEventNamed: [OFString stringWithFormat: @"asyncrt_response_%@", requestID] payloadJSON: responseJSON];
}

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
{
    self = [super init];
    _configuration = [configuration copy];
    _document = [[AsyncWebUIDocument alloc] initWithWebView: self];
    _actionHandlers = [OFMutableDictionary dictionary];
    _loadedHTML = nilptr;
    _loadedIRI = nilptr;
    _closed = false;
    return self;
}

- (AsyncUIWindowConfiguration *)configuration
{
    return _configuration;
}

- (AsyncWebUIDocument *)document
{
    return _document;
}

- (OFString *nillable)loadedHTML
{
    return _loadedHTML;
}

- (OFIRI *nillable)loadedIRI
{
    return _loadedIRI;
}

- (bool)isClosed
{
    return _closed;
}

- (void)loadHTML: (OFString *)html
{
    _loadedHTML = [html copy];
    _loadedIRI = nilptr;
}

- (void)loadIRI: (OFIRI *)IRI
{
    _loadedIRI = [IRI copy];
    _loadedHTML = nilptr;
}

- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler
{
    [_actionHandlers setObject: [handler copy] forKey: name];
}

- (void)unbindActionNamed: (OFString *)name
{
    [_actionHandlers removeObjectForKey: name];
}

- (AsyncTask<OFString *> *)taskToHandleRequest: (AsyncWebUIRequest)request
{
    if (request.action == nilptr)
        return [AsyncTask resolved: @"null"];

    AsyncWebUIActionHandler nillable handler = [_actionHandlers objectForKey: $assert_nonnil(request.action)];
    if (handler == nilptr)
        return [AsyncTask resolved: @"null"];

    return handler(request);
}

- (AsyncTask<id> *)taskToEvaluateJavaScriptReturningValue: (OFString *)javaScript
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript
{
    return (AsyncTask<AsyncUnit *> *)[[self taskToEvaluateJavaScriptReturningValue: javaScript] map: ^id(id) {
        return AsyncUnit.unit;
    }];
}

- (void)emitEvent: (OFString *)name withJSONPayload: (OFString *nillable)payloadJSON
{
    [self taskToEvaluateJavaScript: [AsyncWebUIView javaScriptToDispatchEventNamed: name payloadJSON: payloadJSON]];
}

- (void)pollEvents
{
}

- (void)close
{
    _closed = true;
}

@end

#pragma clang assume_nonnull end
