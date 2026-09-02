#import <OWebTemplate.h>

#import "OWebReflectionInternal.h"

#import <ObjFW/OFString+XMLEscaping.h>

#include <limits.h>

#pragma clang assume_nonnull begin

static const size_t OWebMaximumTemplateBytes = 256 * 1024;
static const size_t OWebMaximumTemplateNodes = 4096;
static const size_t OWebMaximumAttributesPerElement = 64;

[[subclassing_restricted, direct_members]]
@interface OWebTemplateParserDelegate : OFObject <OFXMLParserDelegate>

@property(nonatomic, readonly) OWebCompiledTemplate *compiledTemplate;

- (instancetype)initWithComponentClass: (Class)componentClass;

@end


@interface OWebCompiledTemplate ()

- (instancetype)initWithMarkup: (OFString *)markup
           elementIdentifiersByID:
    (OFDictionary<OFString *, OFNumber *> *)elementIdentifiersByID
          templateIdentifiersByID:
    (OFDictionary<OFString *, OFNumber *> *)templateIdentifiersByID
              actionsByIdentifier:
    (OFDictionary<OFNumber *, OWebActionDefinition *> *)actionsByIdentifier
           tagNamesByElementIdentifier:
    (OFDictionary<OFNumber *, OFString *> *)tagNamesByElementIdentifier
      rootTagNamesByTemplateIdentifier:
    (OFDictionary<OFNumber *, OFString *> *)rootTagNamesByTemplateIdentifier
 elementIdentifiersContainingStaticCapabilities:
    (OFSet<OFNumber *> *)elementIdentifiersContainingStaticCapabilities
            maximumStaticIdentifier: (uint64_t)maximumStaticIdentifier
    OF_DESIGNATED_INITIALIZER;

@end


@implementation OWebCompiledTemplate

- (instancetype)initWithMarkup: (OFString *)markup
           elementIdentifiersByID:
    (OFDictionary<OFString *, OFNumber *> *)elementIdentifiersByID
          templateIdentifiersByID:
    (OFDictionary<OFString *, OFNumber *> *)templateIdentifiersByID
              actionsByIdentifier:
    (OFDictionary<OFNumber *, OWebActionDefinition *> *)actionsByIdentifier
           tagNamesByElementIdentifier:
    (OFDictionary<OFNumber *, OFString *> *)tagNamesByElementIdentifier
      rootTagNamesByTemplateIdentifier:
    (OFDictionary<OFNumber *, OFString *> *)rootTagNamesByTemplateIdentifier
 elementIdentifiersContainingStaticCapabilities:
    (OFSet<OFNumber *> *)elementIdentifiersContainingStaticCapabilities
            maximumStaticIdentifier: (uint64_t)maximumStaticIdentifier
{
    self = [super init];
    _markup = [markup copy];
    _elementIdentifiersByID = [elementIdentifiersByID copy];
    _templateIdentifiersByID = [templateIdentifiersByID copy];
    _actionsByIdentifier = [actionsByIdentifier copy];
    _tagNamesByElementIdentifier = [tagNamesByElementIdentifier copy];
    _rootTagNamesByTemplateIdentifier =
        [rootTagNamesByTemplateIdentifier copy];
    _elementIdentifiersContainingStaticCapabilities =
        [elementIdentifiersContainingStaticCapabilities copy];
    _maximumStaticIdentifier = maximumStaticIdentifier;
    return self;
}

@end


@implementation OWebTemplateParserDelegate {
    Class _componentClass;
    OFMutableString *_markup;
    OFMutableDictionary<OFString *, OFNumber *> *_elementIdentifiersByID;
    OFMutableDictionary<OFString *, OFNumber *> *_templateIdentifiersByID;
    OFMutableDictionary<OFNumber *, OWebActionDefinition *> *_actionsByIdentifier;
    OFMutableDictionary<OFNumber *, OFString *> *_tagNamesByElementIdentifier;
    OFMutableDictionary<OFNumber *, OFString *>
        *_rootTagNamesByTemplateIdentifier;
    OFMutableSet<OFNumber *>
        *_elementIdentifiersContainingStaticCapabilities;
    OFMutableArray<OFNumber *> *_openCapabilityIdentifiers;
    OFMutableSet<OFString *> *_allLogicalIdentifiers;
    size_t _depth;
    size_t _templateDepth;
    size_t _activeTemplateDepth;
    size_t _activeTemplateRootCount;
    size_t _nodeCount;
    uint64_t _nextElementIdentifier;
    uint64_t _nextActionIdentifier;
    uint64_t _activeTemplateIdentifier;
}

- (instancetype)initWithComponentClass: (Class)componentClass
{
    self = [super init];
    _componentClass = componentClass;
    _markup = [[OFMutableString alloc] init];
    _elementIdentifiersByID = [[OFMutableDictionary alloc] init];
    _templateIdentifiersByID = [[OFMutableDictionary alloc] init];
    _actionsByIdentifier = [[OFMutableDictionary alloc] init];
    _tagNamesByElementIdentifier = [[OFMutableDictionary alloc] init];
    _rootTagNamesByTemplateIdentifier = [[OFMutableDictionary alloc] init];
    _elementIdentifiersContainingStaticCapabilities =
        [[OFMutableSet alloc] init];
    _openCapabilityIdentifiers = [[OFMutableArray alloc] init];
    _allLogicalIdentifiers = [[OFMutableSet alloc] init];
    _nextElementIdentifier = 1;
    _nextActionIdentifier = 1;
    return self;
}

- (void)raise: (OFString *)reason
{
    @throw [[OWebDefinitionException alloc] initWithReason: reason];
}

- (bool)isASCIINameCharacter: (OFUnichar)character first: (bool)first
{
    if (character >= 'a' && character <= 'z')
        return true;
    if (not first && character >= '0' && character <= '9')
        return true;
    return not first && (character == '-' || character == '_');
}

- (void)validateTagName: (OFString *)name
{
    if (name.length == 0 || not [name isEqual: name.lowercaseString])
        [self raise: [OFString stringWithFormat:
            @"Template tag '%@' must be lowercase ASCII", name]];

    for (size_t index = 0; index < name.length; index++)
        if (not [self isASCIINameCharacter: [name characterAtIndex: index]
                                           first: index == 0])
            [self raise: [OFString stringWithFormat:
                @"Template tag '%@' contains an unsupported character", name]];
}

- (bool)isForbiddenTag: (OFString *)name
{
    static OFSet<OFString *> *forbidden = nilptr;
    if (forbidden == nilptr)
        forbidden = [[OFSet alloc] initWithObjects:
            @"script", @"style", @"iframe", @"object", @"embed",
            @"link", @"meta", @"base", nilptr];
    return [forbidden containsObject: name];
}

- (bool)isVoidTag: (OFString *)name
{
    static OFSet<OFString *> *voidTags = nilptr;
    if (voidTags == nilptr)
        voidTags = [[OFSet alloc] initWithObjects:
            @"area", @"base", @"br", @"col", @"embed", @"hr", @"img",
            @"input", @"link", @"meta", @"param", @"source", @"track",
            @"wbr", nilptr];
    return [voidTags containsObject: name];
}

- (bool)isEventNameAllowed: (OFString *)eventName
{
    static OFSet<OFString *> *events = nilptr;
    if (events == nilptr)
        events = [[OFSet alloc] initWithObjects:
            @"click", @"dblclick", @"input", @"change", @"submit",
            @"keydown", @"keyup", @"keypress", @"focus", @"blur",
            @"pointerdown", @"pointerup", @"pointermove", @"pointercancel",
            @"mousedown", @"mouseup", @"mousemove", @"mouseenter",
            @"mouseleave", @"touchstart", @"touchend", @"touchmove",
            @"dragstart", @"dragend", @"drop", nilptr];
    return [events containsObject: eventName];
}

- (bool)isSelectorNameSyntacticallySafe: (OFString *)selectorName
{
    if (selectorName.length < 2 ||
        [selectorName characterAtIndex: selectorName.length - 1] != ':')
        return false;

    for (size_t index = 0; index + 1 < selectorName.length; index++) {
        OFUnichar character = [selectorName characterAtIndex: index];
        bool valid = (character >= 'a' && character <= 'z') ||
            (character >= 'A' && character <= 'Z') ||
            (index > 0 && character >= '0' && character <= '9') ||
            (index > 0 && character == '_');
        if (not valid)
            return false;
    }
    return true;
}

- (Method nillable)declaredMethodForSelector: (SEL)selector
{
    for (Class current = _componentClass;
         current != Nil && current != [OWebComponent class];
         current = class_getSuperclass(current)) {
        unsigned int count = 0;
        Method *methods = class_copyMethodList(current, &count);
        Method result = nullptr;
        for (unsigned int index = 0; index < count; index++) {
            if (method_getName(methods[index]) == selector) {
                result = methods[index];
                break;
            }
        }
        free(methods);
        if (result != nullptr)
            return result;
    }
    return nullptr;
}

- (void)validateActionMethod: (OFString *)selectorName
{
    if (not [self isSelectorNameSyntacticallySafe: selectorName])
        [self raise: [OFString stringWithFormat:
            @"Event action '%@' is not a one-argument selector", selectorName]];

    SEL selector = sel_registerName(selectorName.UTF8String);
    Method method = [self declaredMethodForSelector: selector];
    if (method == nullptr)
        [self raise: [OFString stringWithFormat:
            @"Event action '%@' is not declared by %@",
            selectorName,
            [OFString stringWithUTF8String: class_getName(_componentClass)]]];

    char returnType[8] = { 0 };
    char argumentType[8] = { 0 };
    method_getReturnType(method, returnType, sizeof(returnType));
    method_getArgumentType(method, 2, argumentType, sizeof(argumentType));
    if (method_getNumberOfArguments(method) != 3 || returnType[0] != 'v' ||
        argumentType[0] != '@')
        [self raise: [OFString stringWithFormat:
            @"Event action '%@' must have signature void action:(OWebEvent *)",
            selectorName]];
}

- (OFString *)compiledEventAttributeForName: (OFString *)attributeName
                                             value: (OFString *)value
                                  targetIdentifier: (uint64_t)targetIdentifier
{
    OFString *eventName = [attributeName substringFromIndex: 2];
    if (eventName.length == 0 || not [self isEventNameAllowed: eventName])
        [self raise: [OFString stringWithFormat:
            @"Event attribute '%@' is not allowlisted", attributeName]];
    [self validateActionMethod: value];

    uint64_t identifier = _nextActionIdentifier++;
    auto action = [[OWebActionDefinition alloc]
        initWithIdentifier: identifier targetIdentifier: targetIdentifier
        eventName: eventName selectorName: value];
    _actionsByIdentifier[@(identifier)] = action;
    return [OFString stringWithFormat: @"data-oweb-on-%@", eventName];
}

- (uint64_t)recordLogicalIdentifier: (OFString *)logicalIdentifier
                               forTag: (OFString *)tagName
{
    if (logicalIdentifier.length == 0 || logicalIdentifier.length > 128)
        [self raise: @"Template IDs must contain between 1 and 128 characters"];
    for (size_t index = 0; index < logicalIdentifier.length; index++) {
        OFUnichar character = [logicalIdentifier characterAtIndex: index];
        if (character <= 0x20 || character == 0x7F || character == '"' ||
            character == '\'' || character == '<' || character == '>')
            [self raise: [OFString stringWithFormat:
                @"Template ID '%@' contains an unsafe character",
                logicalIdentifier]];
    }
    if ([_allLogicalIdentifiers containsObject: logicalIdentifier])
        [self raise: [OFString stringWithFormat:
            @"Duplicate template ID '%@'", logicalIdentifier]];
    [_allLogicalIdentifiers addObject: logicalIdentifier];

    uint64_t numericIdentifier = _nextElementIdentifier++;
    auto identifier = @(numericIdentifier);
    if ([tagName isEqual: @"template"])
        _templateIdentifiersByID[logicalIdentifier] = identifier;
    else
        _elementIdentifiersByID[logicalIdentifier] = identifier;
    return numericIdentifier;
}

- (void)parser: (OFXMLParser *)parser
  didStartElement: (OFString *)name
           prefix: (OFString *nillable)prefix
        namespace: (OFString *nillable)nameSpace
       attributes: (OFArray<OFXMLAttribute *> *nillable)attributes
{
    (void)parser;
    if (_depth++ == 0) {
        if (not [name isEqual: @"oweb-internal-root"])
            [self raise: @"Internal template wrapper was not parsed"];
        return;
    }

    if (++_nodeCount > OWebMaximumTemplateNodes)
        [self raise: @"Template node limit exceeded"];
    if (_templateDepth > 0 && _depth == _activeTemplateDepth + 1 &&
        ++_activeTemplateRootCount > 1)
        [self raise:
            @"A cloneable <template> must contain exactly one element root"];
    if (prefix != nilptr || nameSpace != nilptr)
        [self raise: @"XML namespaces are not supported in component templates"];
    [self validateTagName: name];
    if ([self isForbiddenTag: name])
        [self raise: [OFString stringWithFormat:
            @"Element <%@> is forbidden in component templates", name]];
    if (attributes.count > OWebMaximumAttributesPerElement)
        [self raise: @"Template attribute limit exceeded"];

    OFString *logicalIdentifier = nilptr;
    bool hasEventBinding = false;
    for (OFXMLAttribute *attribute in attributes) {
        if ([attribute.name isEqual: @"id"])
            logicalIdentifier = attribute.stringValue;
        if ([attribute.name hasPrefix: @"on"])
            hasEventBinding = true;
    }
    if ([name isEqual: @"template"] && logicalIdentifier == nilptr)
        [self raise: @"Every <template> must declare an id"];
    if (logicalIdentifier != nilptr && _templateDepth > 0)
        [self raise: @"Elements inside <template> may not declare IDs"];

    uint64_t elementIdentifier = 0;
    if (logicalIdentifier != nilptr)
        elementIdentifier = [self recordLogicalIdentifier: logicalIdentifier
                                                    forTag: name];
    else if (hasEventBinding)
        elementIdentifier = _nextElementIdentifier++;

    if (_templateDepth > 0 && _depth == _activeTemplateDepth + 1)
        _rootTagNamesByTemplateIdentifier[@(_activeTemplateIdentifier)] = name;

    if (elementIdentifier != 0) {
        for (OFNumber *ancestor in _openCapabilityIdentifiers)
            if (ancestor.unsignedLongLongValue != 0 &&
                _tagNamesByElementIdentifier[ancestor] != nilptr)
                [_elementIdentifiersContainingStaticCapabilities
                    addObject: ancestor];
        if (not [name isEqual: @"template"])
            _tagNamesByElementIdentifier[@(elementIdentifier)] = name;
    }

    auto compiledAttributes = [OFMutableArray<OFString *> array];
    for (OFXMLAttribute *attribute in attributes) {
        OFString *attributeName = attribute.name;
        OFString *attributeValue = attribute.stringValue;
        if (attribute.namespace != nilptr)
            [self raise: @"Namespaced attributes are not supported"];
        if (not [attributeName isEqual: attributeName.lowercaseString])
            [self raise: [OFString stringWithFormat:
                @"Attribute '%@' must be lowercase", attributeName]];

        if ([attributeName hasPrefix: @"data-oweb-"])
            [self raise: [OFString stringWithFormat:
                @"Attribute '%@' is reserved by OWeb", attributeName]];

        OFString *outputName = attributeName;
        OFString *outputValue = attributeValue;
        if ([attributeName hasPrefix: @"on"]) {
            if ([name isEqual: @"template"] || _templateDepth > 0)
                [self raise:
                    @"Event bindings inside <template> are unsupported in v1"];
            outputName = [self compiledEventAttributeForName: attributeName
                                                       value: attributeValue
                                            targetIdentifier: elementIdentifier];
            auto actionID = @(_nextActionIdentifier - 1);
            outputValue = actionID.stringValue;
        } else if (not [attributeName isEqual: @"id"] &&
            not [OWebTemplateCompiler
            isRuntimeAttributeNameSafe: attributeName value: attributeValue])
            [self raise: [OFString stringWithFormat:
                @"Attribute '%@' has an unsafe name or value", attributeName]];

        [compiledAttributes addObject: [OFString stringWithFormat: @"%@=\"%@\"",
            outputName, outputValue.stringByXMLEscaping]];
    }

    if (logicalIdentifier != nilptr) {
        OFString *mappingName = [name isEqual: @"template"]
            ? @"data-oweb-template-id" : @"data-oweb-id";
        [compiledAttributes addObject: [OFString stringWithFormat: @"%@=\"%@\"",
            mappingName, @(elementIdentifier).stringValue]];
    } else if (hasEventBinding) {
        [compiledAttributes addObject: [OFString stringWithFormat:
            @"data-oweb-id=\"%@\"", @(elementIdentifier).stringValue]];
    }

    [_markup appendFormat: @"<%@", name];
    for (OFString *compiledAttribute in compiledAttributes)
        [_markup appendFormat: @" %@", compiledAttribute];
    [_markup appendString: @">"];

    if ([name isEqual: @"template"]) {
        _activeTemplateDepth = _depth;
        _activeTemplateRootCount = 0;
        _activeTemplateIdentifier = elementIdentifier;
        _templateDepth++;
    }
    [_openCapabilityIdentifiers addObject: @(elementIdentifier)];
}

- (void)parser: (OFXMLParser *)parser
    didEndElement: (OFString *)name
           prefix: (OFString *nillable)prefix
        namespace: (OFString *nillable)nameSpace
{
    (void)parser;
    (void)prefix;
    (void)nameSpace;
    if (--_depth == 0)
        return;

    if ([name isEqual: @"template"]) {
        if (_activeTemplateRootCount != 1)
            [self raise:
                @"A cloneable <template> must contain exactly one element root"];
        _templateDepth--;
        _activeTemplateDepth = 0;
        _activeTemplateRootCount = 0;
        _activeTemplateIdentifier = 0;
    }
    [_openCapabilityIdentifiers removeLastObject];
    if (not [self isVoidTag: name])
        [_markup appendFormat: @"</%@>", name];
}

- (void)parser: (OFXMLParser *)parser foundCharacters: (OFString *)characters
{
    (void)parser;
    if (_depth > 1) {
        if (++_nodeCount > OWebMaximumTemplateNodes)
            [self raise: @"Template node limit exceeded"];
        if (_templateDepth > 0 && _depth == _activeTemplateDepth &&
            characters.stringByDeletingEnclosingWhitespaces.length > 0)
            [self raise:
                @"A cloneable <template> cannot contain direct text"];
        [_markup appendString: characters.stringByXMLEscaping];
    } else if (characters.stringByDeletingEnclosingWhitespaces.length > 0)
        [self raise: @"Template content escaped the internal root"];
}

- (void)parser: (OFXMLParser *)parser foundCDATA: (OFString *)CDATA
{
    (void)parser;
    (void)CDATA;
    [self raise: @"CDATA is not supported in component templates"];
}

- (void)parser: (OFXMLParser *)parser foundComment: (OFString *)comment
{
    (void)parser;
    (void)comment;
    [self raise: @"Comments are not supported in component templates"];
}

- (void)parser: (OFXMLParser *)parser
  foundProcessingInstructionWithTarget: (OFString *)target
                                  text: (OFString *nillable)text
{
    (void)parser;
    (void)target;
    (void)text;
    [self raise: @"Processing instructions are not supported"];
}

- (OWebCompiledTemplate *)compiledTemplate
{
    return [[OWebCompiledTemplate alloc]
        initWithMarkup: _markup
        elementIdentifiersByID: _elementIdentifiersByID
        templateIdentifiersByID: _templateIdentifiersByID
        actionsByIdentifier: _actionsByIdentifier
        tagNamesByElementIdentifier: _tagNamesByElementIdentifier
        rootTagNamesByTemplateIdentifier:
            _rootTagNamesByTemplateIdentifier
        elementIdentifiersContainingStaticCapabilities:
            _elementIdentifiersContainingStaticCapabilities
        maximumStaticIdentifier: _nextElementIdentifier - 1];
}

@end


@implementation OWebTemplateCompiler

+ (bool)containsControlCharacter: (OFString *)string
{
    for (size_t index = 0; index < string.length; index++) {
        OFUnichar character = [string characterAtIndex: index];
        if (character == 0 || character < 0x20 || character == 0x7F)
            return true;
    }
    return false;
}

+ (bool)isAttributeNameSyntacticallySafe: (OFString *)name
{
    if (name.length == 0 || name.length > 128 ||
        not [name isEqual: name.lowercaseString])
        return false;

    for (size_t index = 0; index < name.length; index++) {
        OFUnichar character = [name characterAtIndex: index];
        bool valid = (character >= 'a' && character <= 'z') ||
            (index > 0 && character >= '0' && character <= '9') ||
            (index > 0 && (character == '-' || character == '_' ||
                character == '.'));
        if (not valid)
            return false;
    }
    return true;
}

+ (bool)isSafeURL: (OFString *)value forAttribute: (OFString *)name
{
    OFString *trimmed = value.stringByDeletingEnclosingWhitespaces;
    if (trimmed.length == 0 || [self containsControlCharacter: trimmed])
        return false;
    for (size_t index = 0; index < trimmed.length; index++) {
        OFUnichar character = [trimmed characterAtIndex: index];
        if (character == '\\' || character == ' ')
            return false;
    }

    OFString *lowercase = trimmed.lowercaseString;
    if ([lowercase hasPrefix: @"//"])
        return false;
    if ([lowercase hasPrefix: @"https://"])
        return true;
    if ([name isEqual: @"href"] &&
        ([lowercase hasPrefix: @"mailto:"] ||
         [lowercase hasPrefix: @"tel:"]))
        return true;
    if ([lowercase hasPrefix: @"#"] || [lowercase hasPrefix: @"/"] ||
        [lowercase hasPrefix: @"./"] || [lowercase hasPrefix: @"../"] ||
        [lowercase hasPrefix: @"?"])
        return true;
    return not [lowercase containsString: @":"];
}

+ (bool)isRuntimeAttributeNameSafe: (OFString *)name
                                 value: (OFString *nillable)value
{
    if (not [self isAttributeNameSyntacticallySafe: name] ||
        [name hasPrefix: @"on"] || [name hasPrefix: @"data-oweb-"] ||
        [name isEqual: @"style"] || [name isEqual: @"srcdoc"] ||
        [name isEqual: @"srcset"] || [name isEqual: @"ping"] ||
        [name isEqual: @"is"] || [name isEqual: @"xmlns"])
        return false;
    if (value != nilptr &&
        [self containsControlCharacter: $assert_nonnil(value)])
        return false;

    static OFSet<OFString *> *URLAttributes = nilptr;
    if (URLAttributes == nilptr)
        URLAttributes = [[OFSet alloc] initWithObjects:
            @"href", @"src", @"action", @"formaction", @"poster", @"cite",
            @"background", nilptr];
    if ([URLAttributes containsObject: name])
        return value != nilptr && [self isSafeURL: $assert_nonnil(value)
                                           forAttribute: name];
    return true;
}

+ (OWebCompiledTemplate *)compileLayout: (OFString *)layout
                         forComponentClass: (Class)componentClass
{
    if (layout.UTF8StringLength > OWebMaximumTemplateBytes)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Template byte limit exceeded"];
    OFString *lowercase = layout.lowercaseString;
    if ([lowercase containsString: @"<!doctype"] ||
        [lowercase containsString: @"<!entity"] ||
        [lowercase containsString: @"<?"] ||
        [lowercase containsString: @"xmlns="] ||
        [lowercase containsString: @"xmlns:"])
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Template contains forbidden XML syntax"];

    auto delegate = [[OWebTemplateParserDelegate alloc]
        initWithComponentClass: componentClass];
    auto parser = [OFXMLParser parser];
    parser.depthLimit = 64;
    parser.delegate = delegate;
    OFString *wrapped = [OFString stringWithFormat:
        @"<oweb-internal-root>%@</oweb-internal-root>", layout];
    @try {
        [parser parseString: wrapped];
    } @catch (OWebDefinitionException *exception) {
        @throw exception;
    } @catch (OFException *exception) {
        (void)exception;
        @throw [[OWebDefinitionException alloc]
            initWithReason: [OFString stringWithFormat:
                @"Template is not well-formed XML near line %zu",
                parser.lineNumber]];
    }
    if (not parser.finishedParsing)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Template parser did not consume the whole layout"];
    return delegate.compiledTemplate;
}

+ (void)validateStyle: (OFString *)style
{
    if (style.UTF8StringLength > 256 * 1024)
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Component style byte limit exceeded"];
    if ([self containsControlCharacter: style])
        @throw [[OWebDefinitionException alloc]
            initWithReason: @"Component style contains a control character"];
    OFString *lowercase = style.lowercaseString;
    static OFArray<OFString *> *forbidden = nilptr;
    if (forbidden == nilptr)
        forbidden = [[OFArray alloc] initWithObjects:
            @"</style", @"@import", @"url(", @"expression(", nilptr];
    for (OFString *needle in forbidden)
        if ([lowercase containsString: needle])
            @throw [[OWebDefinitionException alloc]
                initWithReason: [OFString stringWithFormat:
                    @"Component style contains forbidden token '%@'", needle]];
}

@end

#pragma clang assume_nonnull end
