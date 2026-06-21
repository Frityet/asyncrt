#import <AsyncRT/Application/UI/Surface/Web/DOM.h>

#pragma clang assume_nonnull begin

@namespace(AsyncWebUIDOMScript)

+ (OFString *)scriptExpressionForSelector: (OFString *)selector property: (OFString *)property;
+ (OFString *)scriptForMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations;
+ (OFString *)statementForMutation: (AsyncWebUIDOMMutation *)mutation index: (size_t)index;

@end

@namespace_implementation(AsyncWebUIDOMScript)

+ (OFString *)scriptExpressionForSelector: (OFString *)selector property: (OFString *)property
{
    return [OFString stringWithFormat: @"(() => { const el = document.querySelector(%@); return el ? el.%@ : null; })()",
                                      selector.JSONRepresentation,
                                      property];
}

+ (OFString *)scriptForMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations
{
    auto script = [OFMutableString stringWithString: @"(() => {\nconst results = [];\n"];

    for (size_t index = 0; index < mutations.count; index++)
        [script appendString: [self statementForMutation: [mutations objectAtIndex: index] index: index]];

    [script appendString: @"return results;\n})()"];
    [script makeImmutable];
    return script;
}

+ (OFString *)statementForMutation: (AsyncWebUIDOMMutation *)mutation index: (size_t)index
{
    OFString *selectorJSON = mutation.selector.JSONRepresentation;
    OFString *nameJSON = (mutation.name != nilptr ? $assert_nonnil(mutation.name).JSONRepresentation : @"null");
    OFString *valueJSON = (mutation.value != nilptr ? $assert_nonnil(mutation.value).JSONRepresentation : @"null");
    OFString *flagJSON = (mutation.flag ? @"true" : @"false");

    OFString *body = nilptr;
    switch (mutation.kind) {
        case AsyncWebUIDOMMutationKindSetText:
            body = [OFString stringWithFormat: @"el.textContent = %@; return true;", valueJSON];
            break;
        case AsyncWebUIDOMMutationKindSetHTML:
            body = [OFString stringWithFormat: @"el.innerHTML = %@; return true;", valueJSON];
            break;
        case AsyncWebUIDOMMutationKindSetAttribute:
            body = [OFString stringWithFormat: @"el.setAttribute(%@, %@); return true;", nameJSON, valueJSON];
            break;
        case AsyncWebUIDOMMutationKindRemoveAttribute:
            body = [OFString stringWithFormat: @"el.removeAttribute(%@); return true;", nameJSON];
            break;
        case AsyncWebUIDOMMutationKindSetStyleProperty:
            body = [OFString stringWithFormat: @"el.style.setProperty(%@, %@); return true;", nameJSON, valueJSON];
            break;
        case AsyncWebUIDOMMutationKindAddClass:
            body = [OFString stringWithFormat: @"el.classList.add(%@); return true;", nameJSON];
            break;
        case AsyncWebUIDOMMutationKindRemoveClass:
            body = [OFString stringWithFormat: @"el.classList.remove(%@); return true;", nameJSON];
            break;
        case AsyncWebUIDOMMutationKindToggleClass:
            body = [OFString stringWithFormat: @"el.classList.toggle(%@, %@); return true;", nameJSON, flagJSON];
            break;
    }

    return [OFString stringWithFormat:
        @"{ const el = document.querySelector(%@); results[%zu] = el ? (() => { %@ })() : false; }\n",
        selectorJSON,
        index,
        body];
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
        [OFString stringWithFormat: @"document.querySelector(%@) !== null", _selector.JSONRepresentation]];
}

- (AsyncTask<OFString *> *)taskToReadText
{
    return (AsyncTask<OFString *> *)[_document taskToEvaluateExpression:
        [AsyncWebUIDOMScript scriptExpressionForSelector: _selector property: @"textContent"]];
}

- (AsyncTask<OFDictionary<OFString *, id> *> *)taskToMeasure
{
    return (AsyncTask<OFDictionary<OFString *, id> *> *)[_document taskToEvaluateExpression:
        [OFString stringWithFormat: @$raw(
            (() => {
                const el = document.querySelector(%@);
                if (!el) return null;
                const r = el.getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
            })()
        ), _selector.JSONRepresentation]];
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
