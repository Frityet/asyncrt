#import <objc/runtime.h>

#import "Component.h"

static constexpr char AsyncWebUIComponentJavaScriptTemplate[] = {
#embed "Component.js"
    , 0
};

static char AsyncWebUIComponentObservedPropertiesKey;
static char AsyncWebUIComponentDefinitionJavaScriptKey;

@interface AsyncWebUIComponent ()

+ (OFArray<OFString *> *)_uncachedObservedProperties;
+ (OFString *)_uncachedDefinitionJavaScript;
- (OFString *)_actionResponseJSON;
- (id)_jsonCompatibleValueForPropertyValue: (id)value;
- (void)_invokeSelectorNamed: (OFString *)selectorName eventPayload: (id nillable)eventPayload;

@end

@implementation AsyncWebUIComponentException

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"%@: %@", self.className, self.reason];
}

@end

@implementation AsyncWebUIComponent {
    OFString *nillable _componentID;
    AsyncWebUIView *nillable _webView;
}

+ (OFString *)invokeActionName
{ return @"component.invoke"; }

+ (OFString *)updateEventName
{ return @"asyncrt_component_update"; }

+ (OFString *)identifier
{ return [OFString stringWithFormat: @"awuic-%@", self.className.lowercaseString]; }

+ (OFString *)layout
{ return @$raw(<div />); }

+ (OFString *)styling
{ return @""; }

- (OFString *nillable)componentID
{ return _componentID; }

- (AsyncWebUIView *nillable)webView
{ return _webView; }

- (void)mountToWebView: (AsyncWebUIView *)webView componentID: (OFString *)componentID
{
    _webView = webView;
    _componentID = [componentID copy];
    [self onMountToWebView: webView];
}

- (void)onMountToWebView: (AsyncWebUIView *)_
{}

+ (OFArray<OFString *> *)observedProperties
{
    id nillable cachedProperties = objc_getAssociatedObject(self, &AsyncWebUIComponentObservedPropertiesKey);
    if (cachedProperties != nilptr)
        return (OFArray<OFString *> *)$assert_nonnil(cachedProperties);

    auto properties = self._uncachedObservedProperties;
    objc_setAssociatedObject(self,
                             &AsyncWebUIComponentObservedPropertiesKey,
                             properties,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return properties;
}

+ (OFArray<OFString *> *)_uncachedObservedProperties
{
    unsigned int count = 0;
    objc_property_t *props = class_copyPropertyList(self, &count);
    auto result = [OFMutableArray<OFString *> arrayWithCapacity: count];

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t prop = props[i];
        const char *nameString = property_getName(prop);
        if (nameString == nullptr)
            continue;

        [result addObject: [OFString stringWithUTF8String: nameString]];
    }

    [result makeImmutable];
    if (props != nullptr)
        free(props);

    return result;
}

+ (OFString *)definitionJavaScript
{
    id nillable cachedDefinition = objc_getAssociatedObject(self, &AsyncWebUIComponentDefinitionJavaScriptKey);
    if (cachedDefinition != nilptr)
        return (OFString *)$assert_nonnil(cachedDefinition);

    auto definition = [self _uncachedDefinitionJavaScript];
    objc_setAssociatedObject(self,
                             &AsyncWebUIComponentDefinitionJavaScriptKey,
                             definition,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return definition;
}

+ (OFString *)_uncachedDefinitionJavaScript
{
    auto javaScript = [OFMutableString stringWithUTF8String: AsyncWebUIComponentJavaScriptTemplate];

    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_TAG_NAME__"
                                withString: self.identifier.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_STYLE_TEXT__"
                                withString: self.styling.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_LAYOUT_HTML__"
                                withString: self.layout.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_PROPERTY_NAMES__"
                                withString: self.observedProperties.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_INVOKE_ACTION_NAME__"
                                withString: self.invokeActionName.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_UPDATE_EVENT_NAME__"
                                withString: self.updateEventName.JSONRepresentation];

    [javaScript makeImmutable];
    return javaScript;
}

+ (AsyncTask *)taskToRegisterOnWebView: (AsyncWebUIView *)webView
{
    return [webView taskToEvaluateJavaScript: self.definitionJavaScript];
}

- (OFDictionary<OFString *, id> *)propertyState
{
    auto result = [OFMutableDictionary<OFString *, id> dictionary];

    for (OFString *propertyName in self.class.observedProperties) {
        id nillable value = [self valueForKey: propertyName];
        if (value == nilptr)
            continue;

        [result setObject: [self _jsonCompatibleValueForPropertyValue: $assert_nonnil(value)] forKey: propertyName];
    }

    [result makeImmutable];
    return result;
}

- (OFString *)propertyStateJSON
{
    return self.propertyState.JSONRepresentation;
}

- (OFString *)elementHTML
{
    OFString *componentID = (_componentID != nilptr ? $assert_nonnil(_componentID) : @"");

    return [OFString stringWithFormat: @"<%@ data-async-webui-id=\"%@\" data-async-webui-state=\"%@\"></%@>",
                                      self.class.identifier,
                                      componentID.stringByXMLEscaping,
                                      self.propertyStateJSON.stringByXMLEscaping,
                                      self.class.identifier];
}

- (AsyncTask<AsyncUnit *> *)taskToRender
{
    if (_webView == nilptr or _componentID == nilptr)
        return [AsyncTask resolved: AsyncUnit.unit];

    auto payload = [OFMutableDictionary<OFString *, id> dictionary];
    [payload setObject: $assert_nonnil(_componentID) forKey: @"componentID"];
    [payload setObject: self.propertyState forKey: @"state"];
    [payload makeImmutable];

    return [$assert_nonnil(_webView) taskToEvaluateJavaScript:
        [AsyncWebUIView javaScriptToDispatchEventNamed: self.class.updateEventName
                                           payloadJSON: payload.JSONRepresentation]];
}

- (AsyncTask<OFString *> *)taskToHandleActionRequest: (AsyncWebUIRequest)request
{
    @try {
        id nillable payloadObject = (request.payloadJSON != nilptr ? $assert_nonnil(request.payloadJSON).objectByParsingJSON : nilptr);
        if (![payloadObject isKindOfClass: OFDictionary.class])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action payload must be a JSON object"];

        auto payload = (OFDictionary<OFString *, id> *)payloadObject;
        id nillable componentIDObject = [payload objectForKey: @"componentID"];
        id nillable selectorObject = [payload objectForKey: @"selector"];
        id nillable eventPayload = [payload objectForKey: @"event"];

        if (![componentIDObject isKindOfClass: OFString.class])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action payload is missing componentID"];
        if (![selectorObject isKindOfClass: OFString.class])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action payload is missing selector"];
        if (_componentID == nilptr)
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component has not been mounted"];
        if (![(OFString *)componentIDObject isEqual: $assert_nonnil(_componentID)])
            @throw [[AsyncWebUIComponentException alloc] initWithReason: @"Component action was delivered to the wrong component"];

        [self _invokeSelectorNamed: (OFString *)selectorObject eventPayload: eventPayload];
        return [AsyncTask resolved: [self _actionResponseJSON]];
    } @catch (OFException *exception) {
        return [AsyncTask rejected: exception];
    }
}

- (OFString *)_actionResponseJSON
{
    auto response = [OFMutableDictionary<OFString *, id> dictionary];
    [response setObject: (_componentID != nilptr ? $assert_nonnil(_componentID) : @"") forKey: @"componentID"];
    [response setObject: self.propertyState forKey: @"state"];
    [response makeImmutable];

    return response.JSONRepresentation;
}

- (id)_jsonCompatibleValueForPropertyValue: (id)value
{
    if ([value conformsToProtocol: @protocol(OFJSONRepresentation)])
        return value;

    return [value description];
}

- (void)_invokeSelectorNamed: (OFString *)selectorName eventPayload: (id nillable)eventPayload
{
    if (selectorName.length == 0 or [selectorName hasPrefix: @"_"])
        @throw [[AsyncWebUIComponentException alloc] initWithReason:
            [OFString stringWithFormat: @"Refusing to invoke component selector %@", selectorName.JSONRepresentation]];

    unsigned int argumentCount = 0;
    const char *selectorUTF8String = selectorName.UTF8String;
    for (size_t i = 0; selectorUTF8String[i] != '\0'; i++)
        if (selectorUTF8String[i] == ':')
            argumentCount++;

    if (argumentCount > 1)
        @throw [[AsyncWebUIComponentException alloc] initWithReason:
            [OFString stringWithFormat: @"Component selector %@ has too many arguments", selectorName.JSONRepresentation]];

    SEL selector = sel_registerName(selectorUTF8String);
    if (![self respondsToSelector: selector])
        @throw [[AsyncWebUIComponentException alloc] initWithReason:
            [OFString stringWithFormat: @"Component %@ does not respond to selector %@",
                                      self.className,
                                      selectorName.JSONRepresentation]];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (argumentCount == 0)
        (void)[self performSelector: selector];
    else
        (void)[self performSelector: selector withObject: eventPayload];
#pragma clang diagnostic pop
}

@end
