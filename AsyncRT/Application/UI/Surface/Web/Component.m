#import <objc/runtime.h>
#import <string.h>

#import "Component.h"
#import "Internal/Component+Private.h"

static constexpr char AsyncWebUIComponentJavaScriptTemplate[] = {
#embed "Component.js"
    , 0
};

static char AsyncWebUIComponentObservedPropertiesKey;
static char AsyncWebUIComponentDefinitionJavaScriptKey;
static char AsyncWebUIComponentChildStoragesKey;

@interface AsyncWebUIComponent ()

+ (OFArray<OFString *> *)_uncachedObservedProperties;
+ (OFString *)_uncachedDefinitionJavaScript;
+ (Class nillable)_classFromQuotedObjectEncoding: (const char *nillable)encoding;
+ (OFArray *)_asyncWebUIChildStorages;
+ (OFArray *)_uncachedAsyncWebUIChildStorages;
+ (void)_appendAsyncWebUIChildStoragesForClass: (Class)cls toArray: (OFMutableArray *)result;
+ (OFString *nillable)_asyncWebUISlotNameForIvarName: (const char *nillable)name;
- (OFString *)_stateJSONString;
- (OFString *)_actionResponseJSON;
- (id)_jsonCompatibleValueForPropertyValue: (id)value;
- (void)_invokeSelectorNamed: (OFString *)selectorName eventPayload: (id nillable)eventPayload;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIComponentChildStorage : OFObject

@property(readonly, nonatomic) Ivar ivar;
@property(readonly, copy, nonatomic) OFString *slotName;

- (instancetype)initWithIvar: (Ivar)ivar slotName: (OFString *)slotName [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncWebUIComponentChildEntry {
    AsyncWebUIComponent *_component;
    OFString *_slotName;
}

- (instancetype)initWithComponent: (AsyncWebUIComponent *)component
                         slotName: (OFString *)slotName
{
    self = [super init];
    _component = component;
    _slotName = [slotName copy];
    return self;
}

- (AsyncWebUIComponent *)component
{ return _component; }

- (OFString *)slotName
{ return _slotName; }

@end

@implementation AsyncWebUIComponentChildStorage {
    Ivar _ivar;
    OFString *_slotName;
}

- (instancetype)initWithIvar: (Ivar)ivar slotName: (OFString *)slotName
{
    self = [super init];
    _ivar = ivar;
    _slotName = [slotName copy];
    return self;
}

- (Ivar)ivar
{ return _ivar; }

- (OFString *)slotName
{ return _slotName; }

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

+ (OFString *)_asyncWebUIInvokeActionName
{ return @"component.invoke"; }

+ (OFString *)_asyncWebUIUpdateEventName
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

- (void)_asyncWebUIMountToWebView: (AsyncWebUIView *)webView componentID: (OFString *)componentID
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

+ (OFString *)_asyncWebUIDefinitionJavaScript
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
                                withString: self._asyncWebUIInvokeActionName.JSONRepresentation];
    [javaScript replaceOccurrencesOfString: @"__ASYNC_WEBUI_UPDATE_EVENT_NAME__"
                                withString: self._asyncWebUIUpdateEventName.JSONRepresentation];

    [javaScript makeImmutable];
    return javaScript;
}

+ (Class nillable)_classFromQuotedObjectEncoding: (const char *nillable)encoding
{
    if (encoding == nullptr or encoding[0] != '@' or encoding[1] != '"')
        return nullptr;

    const char *start = encoding + 2;
    const char *end = strchr(start, '"');
    if (end == nullptr or start == end)
        return nullptr;

    OFString *className = [OFString stringWithCString: start encoding: OFStringEncodingUTF8 length: (size_t)(end - start)];
    return objc_lookUpClass(className.UTF8String);
}

+ (OFArray *)_asyncWebUIChildStorages
{
    id nillable cachedStorages = objc_getAssociatedObject(self, &AsyncWebUIComponentChildStoragesKey);
    if (cachedStorages != nilptr)
        return (OFArray *)$assert_nonnil(cachedStorages);

    auto storages = self._uncachedAsyncWebUIChildStorages;
    objc_setAssociatedObject(self,
                             &AsyncWebUIComponentChildStoragesKey,
                             storages,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return storages;
}

+ (OFArray *)_uncachedAsyncWebUIChildStorages
{
    auto result = [OFMutableArray array];
    [self _appendAsyncWebUIChildStoragesForClass: self toArray: result];
    [result makeImmutable];
    return result;
}

+ (void)_appendAsyncWebUIChildStoragesForClass: (Class)cls toArray: (OFMutableArray *)result
{
    Class superclass = class_getSuperclass(cls);
    if (superclass != Nil and superclass != AsyncWebUIComponent.class)
        [self _appendAsyncWebUIChildStoragesForClass: superclass toArray: result];

    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(cls, &count);
    @try {
        for (unsigned int i = 0; i < count; i++) {
            Ivar ivar = ivars[i];
            const char *encoding = ivar_getTypeEncoding(ivar);
            if (encoding == nullptr or encoding[0] != '@')
                continue;

            Class nillable ivarClass = [self _classFromQuotedObjectEncoding: encoding];
            if (ivarClass != nullptr and ![ivarClass isSubclassOfClass: AsyncWebUIComponent.class])
                continue;

            OFString *nillable slotName = [self _asyncWebUISlotNameForIvarName: ivar_getName(ivar)];
            if (slotName == nilptr)
                continue;

            [result addObject: [[AsyncWebUIComponentChildStorage alloc] initWithIvar: ivar
                                                                            slotName: $assert_nonnil(slotName)]];
        }
    } @finally {
        if (ivars != nullptr)
            free(ivars);
    }
}

+ (OFString *nillable)_asyncWebUISlotNameForIvarName: (const char *nillable)name
{
    if (name == nullptr or name[0] == '\0')
        return nilptr;

    auto slotName = [OFString stringWithUTF8String: $assert_nonnil(name)];
    if ([slotName hasPrefix: @"_"] and slotName.length > 1)
        slotName = [slotName substringFromIndex: 1];

    return (slotName.length > 0 ? slotName : nilptr);
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

- (OFString *)_stateJSONString
{
    return self.propertyState.JSONRepresentation;
}

- (OFArray<AsyncWebUIComponentChildEntry *> *)_asyncWebUIChildComponentEntries
{
    auto entries = [OFMutableArray<AsyncWebUIComponentChildEntry *> array];
    auto seenComponents = [OFMutableSet<AsyncWebUIComponent *> set];

    for (AsyncWebUIComponentChildStorage *storage in self.class._asyncWebUIChildStorages) {
        id nillable value = object_getIvar(self, storage.ivar);
        if (![value isKindOfClass: AsyncWebUIComponent.class])
            continue;

        auto component = (AsyncWebUIComponent *)value;
        if ([seenComponents containsObject: component])
            continue;

        [seenComponents addObject: component];
        [entries addObject: [[AsyncWebUIComponentChildEntry alloc] initWithComponent: component
                                                                            slotName: storage.slotName]];
    }

    [entries makeImmutable];
    return entries;
}

- (OFString *)_asyncWebUIElementHTMLWithSlotName: (OFString *nillable)slotName
{
    OFString *componentID = (_componentID != nilptr ? $assert_nonnil(_componentID) : @"");
    OFString *slotAttribute = @"";
    if (slotName != nilptr)
        slotAttribute = [OFString stringWithFormat: @" slot=\"%@\"", $assert_nonnil(slotName).stringByXMLEscaping];

    auto childHTML = [OFMutableString string];
    for (AsyncWebUIComponentChildEntry *entry in self._asyncWebUIChildComponentEntries) {
        [childHTML appendString: [entry.component _asyncWebUIElementHTMLWithSlotName: entry.slotName]];
        [childHTML appendString: @"\n"];
    }

    [childHTML makeImmutable];

    return [OFString stringWithFormat: @"<%@%@ data-async-webui-id=\"%@\" data-async-webui-state=\"%@\">%@</%@>",
                                      self.class.identifier,
                                      slotAttribute,
                                      componentID.stringByXMLEscaping,
                                      self._stateJSONString.stringByXMLEscaping,
                                      childHTML,
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
        [AsyncWebUIView javaScriptToDispatchEventNamed: self.class._asyncWebUIUpdateEventName
                                           payloadJSON: payload.JSONRepresentation]];
}

- (AsyncTask<AsyncUnit *> *)taskToRenderTree
{
    return (AsyncTask<AsyncUnit *> *)[AsyncRuntime spawnNamed: @"webui-render-tree" block: ^id {
        (void)[[self taskToRender] await];
        for (AsyncWebUIComponentChildEntry *entry in self._asyncWebUIChildComponentEntries)
            (void)[[entry.component taskToRenderTree] await];
        return AsyncUnit.unit;
    }];
}

- (AsyncTask<OFString *> *)_asyncWebUIHandleActionPayload: (OFDictionary<OFString *, id> *)payload
{
    @try {
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
