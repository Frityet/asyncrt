#import <AsyncRT/Application/UI/Surface/Web/Application.h>
#import <AsyncRT/Application/UI/Surface/Web/Internal/Component+Private.h>

#pragma clang assume_nonnull begin

@interface AsyncWebUIDefaultRootComponent : AsyncWebUIComponent

@end

@implementation AsyncWebUIDefaultRootComponent

+ (OFString *)layout
{
    return @$raw(
        <div class="root">
            <h1>Welcome to AsyncRT Web UI!</h1>
            <p>This is the default root component. Override createRootComponent to provide your own component tree.</p>
        </div>
    );
}

+ (OFString *)styling
{
    return @$raw(
        .root {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            color: #333;
        }
    );
}

@end

@interface AsyncWebUIApplication ()

- (OFString *)_componentIDForComponent: (AsyncWebUIComponent *)component index: (size_t)index;
- (OFString *)_childComponentIDForParentID: (OFString *)parentID
                                  slotName: (OFString *)slotName
                                     index: (size_t)index;
- (void)_mountComponent: (AsyncWebUIComponent *)component
                webView: (AsyncWebUIView *)webView
            componentID: (OFString *)componentID
      mountedComponents: (OFMutableDictionary<OFString *, AsyncWebUIComponent *> *)mountedComponents
          allComponents: (OFMutableArray<AsyncWebUIComponent *> *)allComponents;
- (OFString *)_definitionJavaScriptForComponents: (OFArray<AsyncWebUIComponent *> *)components;
- (OFString *)_bodyHTMLForComponents: (OFArray<AsyncWebUIComponent *> *)components;
- (AsyncTask<OFString *> *)_taskToHandleComponentActionRequest: (AsyncWebUIRequest)request;

@end

@implementation AsyncWebUIApplication {
    AsyncWebUIView *nillable _webView;
    AsyncWebUIComponent *nillable _rootComponent;
    OFDictionary<OFString *, AsyncWebUIComponent *> *nillable _mountedComponents;
}

- (bool)shouldTerminateAfterLaunchTaskCompletes
{ return false; }

- (AsyncWebUIView *nillable)webView
{ return _webView; }

- (AsyncWebUIComponent *nillable)rootComponent
{ return _rootComponent; }

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
{
    (void)notification;

    auto webView = [[AsyncWebUIView alloc] initWithConfiguration: $assert_nonnil(self.windowConfiguration)];
    _webView = webView;

    auto rootComponent = self.createRootComponent;
    if (![rootComponent isKindOfClass: AsyncWebUIComponent.class])
        @throw [OFInvalidArgumentException exception];

    _rootComponent = rootComponent;

    auto topLevelComponents = [OFMutableArray<AsyncWebUIComponent *> array];
    [topLevelComponents addObject: rootComponent];

    auto allComponents = [OFMutableArray<AsyncWebUIComponent *> array];
    auto mountedComponents = [OFMutableDictionary<OFString *, AsyncWebUIComponent *> dictionary];
    for (size_t i = 0; i < topLevelComponents.count; i++) {
        auto component = [topLevelComponents objectAtIndex: i];
        if (![component isKindOfClass: AsyncWebUIComponent.class])
            @throw [OFInvalidArgumentException exception];

        OFString *componentID = [self _componentIDForComponent: component index: i];
        [self _mountComponent: component
                      webView: webView
                  componentID: componentID
            mountedComponents: mountedComponents
                allComponents: allComponents];
    }

    [mountedComponents makeImmutable];
    [topLevelComponents makeImmutable];
    [allComponents makeImmutable];
    _mountedComponents = mountedComponents;

    [webView bindAction: [AsyncWebUIComponent _asyncWebUIInvokeActionName]
               toHandler: ^AsyncTask<OFString *> *(AsyncWebUIRequest request) {
                   return [self _taskToHandleComponentActionRequest: request];
               }];

    [webView loadHTML: [OFString stringWithFormat: @$raw(
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>%@</style>
            <script>%@</script>
        </head>
        <body>
            %@
        </body>
        </html>
    ), self.documentStyle, [self _definitionJavaScriptForComponents: allComponents], [self _bodyHTMLForComponents: topLevelComponents]]];

    [self applicationDidStartWithWebView: webView];
    while (not webView.isClosed) {
        [[AsyncRuntime sleepForTimeInterval: (1.0 / 60.0)] await];
        [webView pollEvents];
    }
    return @0;
}

- (AsyncUIWindowConfiguration *)windowConfiguration
{
    auto configuration = super.windowConfiguration;
    configuration.title = @"AsyncRT Web UI";
    configuration.initialSize = (AsyncUISize){ .width = 800.0f, .height = 600.0f };
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (AsyncWebUIComponent *)createRootComponent
{ return [[AsyncWebUIDefaultRootComponent alloc] init]; }

- (OFString *)documentStyle
{
    return @$raw(
        * { box-sizing: border-box; }
        html, body {
            margin: 0;
            min-height: 100%;
        }
        body {
            min-height: 100vh;
        }
    );
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
{
    (void)webView;
}

- (void)asyncApplicationWillTerminate: (OFNotification *)notification
{
    (void)notification;

    AsyncWebUIView *nillable webView = _webView;
    if (webView != nilptr)
        [$assert_nonnil(webView) close];

    _webView = nilptr;
    _rootComponent = nilptr;
    _mountedComponents = nilptr;
}

- (OFString *)_componentIDForComponent: (AsyncWebUIComponent *)component index: (size_t)index
{
    if (index == 0)
        return @"root";

    return [OFString stringWithFormat: @"%@-%zu", [[component class] identifier], index];
}

- (OFString *)_childComponentIDForParentID: (OFString *)parentID
                                  slotName: (OFString *)slotName
                                     index: (size_t)index
{
    return [OFString stringWithFormat: @"%@-%@-%zu", parentID, slotName, index];
}

- (void)_mountComponent: (AsyncWebUIComponent *)component
                webView: (AsyncWebUIView *)webView
            componentID: (OFString *)componentID
      mountedComponents: (OFMutableDictionary<OFString *, AsyncWebUIComponent *> *)mountedComponents
          allComponents: (OFMutableArray<AsyncWebUIComponent *> *)allComponents
{
    if ([mountedComponents objectForKey: componentID] != nilptr)
        @throw [OFInvalidArgumentException exception];

    [component _asyncWebUIMountToWebView: webView componentID: componentID];
    [mountedComponents setObject: component forKey: componentID];
    [allComponents addObject: component];

    auto children = component._asyncWebUIChildComponentEntries;
    for (size_t i = 0; i < children.count; i++) {
        auto childEntry = [children objectAtIndex: i];
        auto childComponent = childEntry.component;
        if (![childComponent isKindOfClass: AsyncWebUIComponent.class])
            @throw [OFInvalidArgumentException exception];

        [self _mountComponent: childComponent
                      webView: webView
                  componentID: [self _childComponentIDForParentID: componentID
                                                         slotName: childEntry.slotName
                                                            index: i]
            mountedComponents: mountedComponents
                allComponents: allComponents];
    }
}

- (OFString *)_definitionJavaScriptForComponents: (OFArray<AsyncWebUIComponent *> *)components
{
    auto definitions = [OFMutableString string];
    auto registeredIdentifiers = [OFMutableArray<OFString *> arrayWithCapacity: components.count];

    for (AsyncWebUIComponent *component in components) {
        Class componentClass = component.class;
        if (![componentClass isSubclassOfClass: AsyncWebUIComponent.class])
            @throw [OFInvalidArgumentException exception];

        OFString *identifier = [componentClass identifier];
        if ([registeredIdentifiers containsObject: identifier])
            continue;

        [registeredIdentifiers addObject: identifier];
        [definitions appendString: [componentClass _asyncWebUIDefinitionJavaScript]];
        [definitions appendString: @"\n"];
    }

    [definitions makeImmutable];
    return definitions;
}

- (OFString *)_bodyHTMLForComponents: (OFArray<AsyncWebUIComponent *> *)components
{
    auto bodyHTML = [OFMutableString string];

    for (AsyncWebUIComponent *component in components) {
        [bodyHTML appendString: [component _asyncWebUIElementHTMLWithSlotName: nilptr]];
        [bodyHTML appendString: @"\n"];
    }

    [bodyHTML makeImmutable];
    return bodyHTML;
}

- (AsyncTask<OFString *> *)_taskToHandleComponentActionRequest: (AsyncWebUIRequest)request
{
    @try {
        id nillable payloadCandidate = request.payload;
        if (![payloadCandidate isKindOfClass: OFArray.class])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action payload must be a compact array"];

        id payload = $assert_nonnil(payloadCandidate);
        id nillable componentIDObject = (((OFArray *)payload).count > 0 ? [(OFArray *)payload objectAtIndex: 0] : nilptr);

        if (![componentIDObject isKindOfClass: OFString.class])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action payload is missing componentID"];

        if (_mountedComponents == nilptr)
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"No mounted components are available"];

        AsyncWebUIComponent *nillable component = [$assert_nonnil(_mountedComponents) objectForKey: (OFString *)componentIDObject];
        if (component == nilptr)
            @throw [[AsyncWebUIComponentException alloc] initWithReason:
                [OFString stringWithFormat: @"No mounted component exists for componentID %@",
                                          ((OFString *)componentIDObject).JSONRepresentation]];

        return [$assert_nonnil(component) _asyncWebUIHandleActionPayload: payload];
    } @catch (OFException *exception) {
        return [AsyncTask rejected: exception];
    }
}

@end

#pragma clang assume_nonnull end
