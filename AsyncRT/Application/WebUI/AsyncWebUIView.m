#import "AsyncWebUIView.h"

#if defined(__APPLE__)
#import "Backends/WKWebView/AsyncWKWebViewBackend.h"
#endif

@implementation AsyncWebUIView

+ (instancetype)alloc
{
    if (self == [AsyncWebUIView class]) {
#if defined(__APPLE__)
        return [AsyncWKWebViewBackend alloc];
#else
        @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
#endif
    }
    return [super alloc];
}

- (instancetype)initWithConfiguration: (AsyncWebUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler
{
    self = [super init];
    if (self) {
        _configuration = [configuration copy];
        _scheduler = scheduler;
    }
    return self;
}

- (void)loadHTML: (OFString *)html
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)loadIRI: (OFIRI *)IRI
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)emitEvent: (OFString *)name withJSONPayload: (OFString *)payloadJSON
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)close
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

@end
