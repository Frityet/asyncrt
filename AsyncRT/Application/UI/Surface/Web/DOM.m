#import <AsyncRT/Application/UI/Surface/Web/DOM.h>

#pragma clang assume_nonnull begin

@namespace(AsyncWebUIDOMScript)

+ (OFString *)scriptToCheckElementExistsForSelector: (OFString *)selector;
+ (OFString *)scriptToReadTextForSelector: (OFString *)selector;
+ (OFString *)scriptToMeasureElementForSelector: (OFString *)selector;
+ (OFString *)scriptForMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations;
+ (void)appendMutation: (AsyncWebUIDOMMutation *)mutation toJSON: (OFMutableString *)json;
+ (void)appendNullableString: (OFString *nillable)value toJSON: (OFMutableString *)json;

@end

@namespace_implementation(AsyncWebUIDOMScript)

+ (OFString *)scriptToCheckElementExistsForSelector: (OFString *)selector
{
    return [OFString stringWithFormat: @"window.AsyncRT.__dom.exists(%@)", selector.JSONRepresentation];
}

+ (OFString *)scriptToReadTextForSelector: (OFString *)selector
{
    return [OFString stringWithFormat: @"window.AsyncRT.__dom.readText(%@)", selector.JSONRepresentation];
}

+ (OFString *)scriptToMeasureElementForSelector: (OFString *)selector
{
    return [OFString stringWithFormat: @"window.AsyncRT.__dom.measure(%@)", selector.JSONRepresentation];
}

+ (OFString *)scriptForMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations
{
    auto json = [OFMutableString string];
    [json appendString: @"window.AsyncRT.__dom.applyMutations(["];

    bool isFirst = true;
    for (AsyncWebUIDOMMutation *mutation in mutations) {
        if (not isFirst)
            [json appendString: @","];
        isFirst = false;

        [self appendMutation: mutation toJSON: json];
    }

    [json appendString: @"])"];
    [json makeImmutable];
    return json;
}

+ (void)appendMutation: (AsyncWebUIDOMMutation *)mutation toJSON: (OFMutableString *)json
{
    [json appendFormat: @"[%d,%@,",
                        (int)mutation.kind,
                        mutation.selector.JSONRepresentation];
    [self appendNullableString: mutation.name toJSON: json];
    [json appendString: @","];
    [self appendNullableString: mutation.value toJSON: json];
    [json appendString: (mutation.flag ? @",true]" : @",false]")];
}

+ (void)appendNullableString: (OFString *nillable)value toJSON: (OFMutableString *)json
{
    [json appendString: (value != nilptr ? $assert_nonnil(value).JSONRepresentation : @"null")];
}

@end

@implementation AsyncWebUIDOMMutation

+ (instancetype)setText: (OFString *)text selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindSetText selector: selector name: nilptr value: text flag: false]; }

+ (instancetype)setHTML: (OFString *)HTML selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindSetHTML selector: selector name: nilptr value: HTML flag: false]; }

+ (instancetype)setAttribute: (OFString *)name value: (OFString *)value selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindSetAttribute selector: selector name: name value: value flag: false]; }

+ (instancetype)removeAttribute: (OFString *)name selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindRemoveAttribute selector: selector name: name value: nilptr flag: false]; }

+ (instancetype)setStyleProperty: (OFString *)name value: (OFString *)value selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindSetStyleProperty selector: selector name: name value: value flag: false]; }

+ (instancetype)addClass: (OFString *)className selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindAddClass selector: selector name: className value: nilptr flag: false]; }

+ (instancetype)removeClass: (OFString *)className selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindRemoveClass selector: selector name: className value: nilptr flag: false]; }

+ (instancetype)toggleClass: (OFString *)className enabled: (bool)enabled selector: (OFString *)selector
{ return [[self alloc] initWithKind: AsyncWebUIDOMMutationKindToggleClass selector: selector name: className value: nilptr flag: enabled]; }

- (instancetype)initWithKind: (enum AsyncWebUIDOMMutationKind)kind
                    selector: (OFString *)selector
                        name: (OFString *nillable)name
                       value: (OFString *nillable)value
                        flag: (bool)flag
{
    self = [super init];
    _kind = kind;
    _selector = [selector copy];
    _name = [name copy];
    _value = [value copy];
    _flag = flag;
    return self;
}

@end

@implementation AsyncWebUIDocument {
    AsyncWebUIView *_webView;
}

- (instancetype)initWithWebView: (AsyncWebUIView *)webView
{
    self = [super init];
    _webView = webView;
    return self;
}

- (AsyncWebUIView *)webView
{ return _webView; }

- (AsyncWebUIElement *)elementMatchingSelector: (OFString *)selector
{
    return [[AsyncWebUIElement alloc] initWithDocument: self selector: selector];
}

- (AsyncTask<id> *)taskToEvaluateExpression: (OFString *)javaScriptExpression
{
    return [_webView taskToEvaluateJavaScriptReturningValue: javaScriptExpression];
}

- (AsyncTask<OFArray<id> *> *)taskToApplyMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations
{
    if (mutations.count == 0)
        return [AsyncTask resolved: [OFArray array]];

    return (AsyncTask<OFArray<id> *> *)[_webView taskToEvaluateJavaScriptReturningValue:
        [AsyncWebUIDOMScript scriptForMutations: mutations]];
}

@end

@implementation AsyncWebUIElement {
    AsyncWebUIDocument *_document;
    OFString *_selector;
}

- (instancetype)initWithDocument: (AsyncWebUIDocument *)document
                        selector: (OFString *)selector
{
    self = [super init];
    _document = document;
    _selector = [selector copy];
    return self;
}

- (AsyncWebUIDocument *)document
{ return _document; }

- (OFString *)selector
{ return _selector; }

- (AsyncTask<OFNumber *> *)taskToExists
{
    return (AsyncTask<OFNumber *> *)[_document taskToEvaluateExpression:
        [AsyncWebUIDOMScript scriptToCheckElementExistsForSelector: _selector]];
}

- (AsyncTask<OFString *> *)taskToReadText
{
    return (AsyncTask<OFString *> *)[_document taskToEvaluateExpression:
        [AsyncWebUIDOMScript scriptToReadTextForSelector: _selector]];
}

- (AsyncTask<OFDictionary<OFString *, id> *> *)taskToMeasure
{
    return (AsyncTask<OFDictionary<OFString *, id> *> *)[_document taskToEvaluateExpression:
        [AsyncWebUIDOMScript scriptToMeasureElementForSelector: _selector]];
}

- (AsyncTask<OFArray<id> *> *)taskToApplyMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations
{
    return [_document taskToApplyMutations: mutations];
}

- (AsyncTask<OFArray<id> *> *)taskToSetText: (OFString *)text
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation setText: text selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToSetHTML: (OFString *)HTML
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation setHTML: HTML selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToSetAttribute: (OFString *)name value: (OFString *)value
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation setAttribute: name value: value selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToRemoveAttribute: (OFString *)name
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation removeAttribute: name selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToSetStyleProperty: (OFString *)name value: (OFString *)value
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation setStyleProperty: name value: value selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToAddClass: (OFString *)className
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation addClass: className selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToRemoveClass: (OFString *)className
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation removeClass: className selector: _selector]]]; }

- (AsyncTask<OFArray<id> *> *)taskToToggleClass: (OFString *)className enabled: (bool)enabled
{ return [self taskToApplyMutations: [OFArray arrayWithObject: [AsyncWebUIDOMMutation toggleClass: className enabled: enabled selector: _selector]]]; }

@end

#pragma clang assume_nonnull end
