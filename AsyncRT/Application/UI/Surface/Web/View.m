#import <AsyncRT/Application/UI/Surface/Web/View.h>
#import <AsyncRT/Application/UI/Surface/Web/DOM.h>
#import <AsyncRT/Application/UI/Surface/Web/Platform/HTTPServer/View.h>

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
        return [AsyncWebHTTPServerView alloc];
    }

    return [super alloc];
}

+ (OFString *)javaScriptToDispatchEventNamed: (OFString *)name
                                      payload: (id nillable)payload
{
    OFString *detailJSON = @"null";
    if (payload != nilptr and payload != OFNull.null) {
        id nonnullPayload = $assert_nonnil(payload);
        if (![nonnullPayload conformsToProtocol: @protocol(OFJSONRepresentation)])
            @throw [OFInvalidArgumentException exception];

        detailJSON = ((id<OFJSONRepresentation>)nonnullPayload).JSONRepresentation;
    }

    return [OFString stringWithFormat: @"window.AsyncRT.__emit(%@, %@);", name.JSONRepresentation, detailJSON];
}

+ (OFString *)javaScriptToResolveRequestID: (OFString *)requestID
                               responseJSON: (OFString *nillable)responseJSON
{
    return [OFString stringWithFormat: @"window.AsyncRT.__resolve(%@, %@);",
                                      requestID.JSONRepresentation,
                                      (responseJSON != nilptr ? $assert_nonnil(responseJSON) : @"null")];
}

+ (OFString *)javaScriptToUpdateComponentID: (OFString *)componentID
                                  stateJSON: (OFString *)stateJSON
{
    return [OFString stringWithFormat: @"window.AsyncRT.__components.update(%@, %@);",
                                      componentID.JSONRepresentation,
                                      stateJSON];
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

- (OFIRI *nillable)serverIRI
{
    return nilptr;
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

- (void)emitEvent: (OFString *)name withPayload: (id nillable)payload
{
    [self taskToEvaluateJavaScript: [AsyncWebUIView javaScriptToDispatchEventNamed: name payload: payload]];
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
