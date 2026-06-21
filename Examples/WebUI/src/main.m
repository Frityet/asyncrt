#import <AsyncRT/Application/UI/Surface/Web/Web.h>

#pragma clang assume_nonnull begin

@interface RootComponent : AsyncWebUIComponent

@property(nonatomic) OFString *message;
@property(nonatomic) int counter;

@end

@implementation RootComponent

- (instancetype)init
{
    self = [super init];
    _message = @"Hello, AsyncRT WebUI!";
    _counter = 0;
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <div class="container">
            <h1>{{message}}</h1>
            <p>Counter: {{counter}}</p>
            <button onclick="[self onIncrementClick:]">Increment Counter</button>
        </div>
    );
}

+ (OFString *)styling
{
    return @$raw(
        .container {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            color: #333;
        }
        button {
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
        }
    );
}

- (void)onIncrementClick: (id)sender
{
    self.counter += 1;
}

@end

[[subclassing_restricted]]
@interface AsyncWebUIExampleApplication : AsyncWebUIApplication
@end

@implementation AsyncWebUIExampleApplication {
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (AsyncUIWindowConfiguration *)windowConfiguration
{
    auto configuration = super.windowConfiguration;
    configuration.title = @"AsyncRT WebUI Example";
    configuration.initialSize = (AsyncUISize){ .width = 980.0f, .height = 720.0f };
    configuration.isResizable = true;
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView taskGroup: (AsyncTaskGroup *)_
{
    (void)webView;
}

- (Class)rootComponentClass
{ return RootComponent.class; }

@end

AsyncWebUI_APPLICATION_MAIN(AsyncWebUIExampleApplication)

#pragma clang assume_nonnull end
