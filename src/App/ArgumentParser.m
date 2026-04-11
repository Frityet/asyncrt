#include "ArgumentParser.h"

#include <ObjFW/OFMutableDictionary.h>
#include <ObjFWRT/ObjFWRT.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#pragma clang assume_nonnull begin

@class CLICommandIntrospection;

@interface CLIOption () {
@public
    CLIOptionKind _kind;
    Class _valueClass;
    bool _required;
    OFString *nillable _longName;
    char _shortName;
    OFString *nillable _help;
    OFString *nillable _valueName;
    id nillable _defaultValue;
    bool _hasDefaultValue;
    id nillable _parsedValue;
    bool _hasParsedValue;
}
- (void)cli_reset;
- (void)cli_setParsedValue: (id)value;
@end

@interface CLIResolvedOption : OFObject {
@public
    OFString *_propertyName;
    CLIOption *_option;
    OFString *_longName;
    char _shortName;
    OFString *nillable _help;
    OFString *_valueName;
}
+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (CLIOption *)option;
- (bool)isPositional;
- (bool)isFlag;
- (bool)isRequired;
- (OFString *)usageLabel;
- (OFString *)helpSyntax;
@end

@interface CLIResolvedSubcommand : OFObject {
@public
    OFString *_propertyName;
    CLICommand *_command;
    OFString *_commandName;
    OFString *nillable _help;
}
+ (instancetype)subcommandWithPropertyName: (OFString *)propertyName
                                   command: (CLICommand *)command;
@end

@interface CLICommandSchema : OFObject {
@public
    CLICommand *_command;
    OFString *_commandName;
    OFString *nillable _commandDescription;
    OFArray<CLIResolvedOption *> *_namedOptions;
    OFArray<CLIResolvedOption *> *_positionals;
    OFArray<CLIResolvedOption *> *_flags;
    OFArray<CLIResolvedSubcommand *> *_subcommands;
    OFDictionary<OFString *, CLIResolvedOption *> *_optionsByLongName;
    OFDictionary<OFString *, CLIResolvedOption *> *_optionsByShortName;
    OFDictionary<OFString *, CLIResolvedSubcommand *> *_subcommandsByName;
}
- (void)resetValues;
- (OFString *)helpTextForCommandPath: (OFString *)commandPath;
@end

@interface CLINameTransform : OFObject
+ (OFString *)kebabCaseForString: (OFString *)string;
+ (OFString *)upperValueNameForPropertyName: (OFString *)propertyName;
+ (OFString *)className: (Class nillable)class_;
+ (OFString *)shortNameString: (char)shortName;
@end

@interface CLITypeInspector : OFObject
+ (Class nillable)propertyClassForProperty: (objc_property_t)property
                                    onClass: (Class)class_
                               propertyName: (OFString *)propertyName;
@end

@interface CLIValueCodec : OFObject
+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass;
@end

@interface CLICommandIntrospection : OFObject
+ (CLICommandSchema *)schemaForCommand: (CLICommand *)command;
@end

@interface CLICommandParserEngine : OFObject
+ (size_t)parseCommand: (CLICommand *)command
                 schema: (CLICommandSchema *)schema
              arguments: (OFArray<OFString *> *)arguments
             startIndex: (size_t)startIndex
            commandPath: (OFString *)commandPath;
@end

@implementation CLINameTransform

+ (OFString *)kebabCaseForString: (OFString *)string
{
    const char *utf8 = string.UTF8String;
    size_t length = string.UTF8StringLength;
    auto builder = [[OFMutableString alloc] init];
    bool previousWasDash = false;

    for (size_t index = 0; index < length; index++) {
        auto character = (unsigned char)utf8[index];

        if (character == '_') {
            if (builder.length > 0 and not previousWasDash) {
                [builder appendString: @"-"];
                previousWasDash = true;
            }
            continue;
        }

        if (isupper(character)) {
            if (index > 0
                and (islower((unsigned char)utf8[index - 1]) or isdigit((unsigned char)utf8[index - 1]))
                and not previousWasDash)
                [builder appendString: @"-"];
            character = (unsigned char)tolower(character);
        }

        [builder appendFormat: @"%c", character];
        previousWasDash = false;
    }

    return builder;
}

+ (OFString *)upperValueNameForPropertyName: (OFString *)propertyName
{
    return [[self kebabCaseForString: propertyName] uppercaseString];
}

+ (OFString *)className: (Class nillable)class
{
    if (class == nullptr)
        return @"<unknown>";

    const char *nillable classNameCString = class_getName(class);
    if (classNameCString == nullptr)
        return @"<unknown>";

    const char *className = classNameCString;
    return [OFString stringWithUTF8String: className];
}

+ (OFString *)shortNameString: (char)shortName
{
    char buffer[] = { shortName, '\0' };
    return [OFString stringWithUTF8String: buffer];
}

@end

@implementation CLIResolvedOption

+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (CLIOption *)option
{
    auto resolvedOption = [[self alloc] init];

    resolvedOption->_propertyName = [propertyName copy];
    resolvedOption->_option = option;
    resolvedOption->_longName = [(option.longName ?: [CLINameTransform kebabCaseForString: propertyName]) copy];
    resolvedOption->_shortName = option.shortName;
    resolvedOption->_help = [option.help copy];
    resolvedOption->_valueName = [(option.valueName ?: [CLINameTransform upperValueNameForPropertyName: propertyName]) copy];

    return resolvedOption;
}

- (bool)isPositional
{
    return _option.kind == CLIOptionKindPositional;
}

- (bool)isFlag
{
    return _option.kind == CLIOptionKindFlag;
}

- (bool)isRequired
{
    return _option.required;
}

- (OFString *)usageLabel
{
    if (self.isPositional) {
        if (self.isRequired)
            return [OFString stringWithFormat: @"<%@>", _valueName];

        return [OFString stringWithFormat: @"[<%@>]", _valueName];
    }

    if (self.isFlag)
        return @"";

    return [OFString stringWithFormat: @" <%@>", _valueName];
}

- (OFString *)helpSyntax
{
    if (self.isPositional)
        return self.usageLabel;

    if (self.isFlag) {
        if (_shortName != '\0')
            return [OFString stringWithFormat: @"-%c, --%@", _shortName, _longName];

        return [OFString stringWithFormat: @"--%@", _longName];
    }

    if (_shortName != '\0')
        return [OFString stringWithFormat: @"-%c, --%@%@",
                                             _shortName,
                                             _longName,
                                             self.usageLabel];

    return [OFString stringWithFormat: @"--%@%@", _longName, self.usageLabel];
}

@end

@implementation CLIResolvedSubcommand

+ (instancetype)subcommandWithPropertyName: (OFString *)propertyName
                                   command: (CLICommand *)command
{
    auto resolvedSubcommand = [[self alloc] init];

    resolvedSubcommand->_propertyName = [propertyName copy];
    resolvedSubcommand->_command = command;
    resolvedSubcommand->_commandName = [[CLINameTransform kebabCaseForString: propertyName] copy];
    resolvedSubcommand->_help = [[command.class cliCommandDescription] copy];

    return resolvedSubcommand;
}

@end

@implementation CLITypeInspector

+ (Class nillable)_classFromQuotedObjectEncoding: (const char *nillable)encoding
{
    if (encoding == (const char *nillable)nullptr
        or encoding[0] != '@'
        or encoding[1] != '"')
        return nullptr;

    const char *start = encoding + 2;
    const char *end = strchr(start, '"');
    if (end == nullptr or start == end)
        return nullptr;

    auto length = (size_t)(end - start);
    char *className = malloc(length + 1);
    if (className == nullptr)
        @throw [OFOutOfMemoryException exception];

    @try {
        memcpy(className, start, length);
        className[length] = '\0';

        char *protocolStart = strchr(className, '<');
        if (protocolStart != nullptr)
            *protocolStart = '\0';

        if (className[0] == '\0')
            return nullptr;

        return objc_lookUpClass(className);
    } @finally {
        free(className);
    }
}

+ (Class nillable)_classFromGetterEncoding: (const char *nillable)typeEncoding
{
    if (typeEncoding == nullptr or *typeEncoding == '\0')
        return nullptr;

    const char *methodTypes = typeEncoding;
    auto signature = [OFMethodSignature signatureWithObjCTypes: methodTypes];
    const char *returnType = signature.methodReturnType;

    while (*returnType == 'r' or *returnType == 'n' or *returnType == 'N' or
           *returnType == 'o' or *returnType == 'O' or *returnType == 'R' or
           *returnType == 'V')
        returnType++;

    return [self _classFromQuotedObjectEncoding: returnType];
}

+ (Class nillable)_classFromIvarsOnClass: (Class)class_
                            propertyName: (OFString *)propertyName
{
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(class_, &ivarCount);
    Class inferredClass = nullptr;
    auto underscoredPropertyName = [OFString stringWithFormat: @"_%@", propertyName];

    @try {
        for (unsigned int index = 0; index < ivarCount; index++) {
            auto ivarName = [OFString stringWithUTF8String: ivar_getName(ivars[index])];

            if (not [ivarName isEqual: propertyName]
                and not [ivarName isEqual: underscoredPropertyName])
                continue;

            inferredClass = [self _classFromQuotedObjectEncoding: ivar_getTypeEncoding(ivars[index])];
            break;
        }
    } @finally {
        free(ivars);
    }

    return inferredClass;
}

+ (Class nillable)propertyClassForProperty: (objc_property_t)property
                                    onClass: (Class)class_
                               propertyName: (OFString *)propertyName
{
    char *typeEncoding = property_copyAttributeValue(property, "T");
    Class propertyClass = nullptr;

    @try {
        propertyClass = [self _classFromGetterEncoding: typeEncoding];
    } @finally {
        free(typeEncoding);
    }

    if (propertyClass != nullptr)
        return propertyClass;

    return [self _classFromIvarsOnClass: class_ propertyName: propertyName];
}

@end

@implementation CLIValueCodec

+ (id)_invalidValueExceptionForToken: (OFString *)token
                           valueClass: (Class)valueClass
{
    return [[ArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Invalid %@ value '%@'",
                                                                                          [CLINameTransform className: valueClass],
                                                                                          token]
                                                      usage: nilptr];
}

+ (id)_parseNumberToken: (OFString *)token
{
    const char *string = token.UTF8String;
    char *end = nullptr;

    if (strchr(string, '.') != nullptr or strchr(string, 'e') != nullptr or strchr(string, 'E') != nullptr) {
        errno = 0;
        double value = strtod(string, &end);
        if (errno != 0 or end == string or *end != '\0')
            @throw [self _invalidValueExceptionForToken: token valueClass: OFNumber.class];

        return @(value);
    }

    if (token.UTF8StringLength > 0 and string[0] == '-') {
        errno = 0;
        long long value = strtoll(string, &end, 0);
        if (errno != 0 or end == string or *end != '\0')
            @throw [self _invalidValueExceptionForToken: token valueClass: OFNumber.class];

        return @(value);
    }

    errno = 0;
    unsigned long long value = strtoull(string, &end, 0);
    if (errno != 0 or end == string or *end != '\0')
        @throw [self _invalidValueExceptionForToken: token valueClass: OFNumber.class];

    return @(value);
}

+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass
{
    if (valueClass == nullptr)
        @throw [[ArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Missing value class for '%@'",
                                                                                              token]
                                                          usage: nilptr];

    if ([valueClass isSubclassOfClass: OFString.class])
        return [token copy];

    if ([valueClass isSubclassOfClass: OFNumber.class])
        return [self _parseNumberToken: token];

    if ([valueClass respondsToSelector: @selector(cliParseValue:)])
        return [valueClass cliParseValue: token];

    if ([valueClass instancesRespondToSelector: @selector(initWithString:)])
        return [[valueClass alloc] initWithString: token];

    @throw [[ArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Don't know how to parse '%@' as %@",
                                                                                          token, [CLINameTransform className: valueClass]]
                                                      usage: nilptr];
}

@end

@implementation CLICommandSchema

- (void)resetValues
{
    for (CLIResolvedOption *resolvedOption in _namedOptions)
        [resolvedOption->_option cli_reset];

    for (CLIResolvedOption *resolvedFlag in _flags)
        [resolvedFlag->_option cli_reset];

    for (CLIResolvedOption *resolvedPositional in _positionals)
        [resolvedPositional->_option cli_reset];

    for (CLIResolvedSubcommand *resolvedSubcommand in _subcommands)
        [[CLICommandIntrospection schemaForCommand: resolvedSubcommand->_command] resetValues];
}

- (OFString *)_usageLineForCommandPath: (OFString *)commandPath
{
    auto builder = [[OFMutableString alloc] init];

    [builder appendFormat: @"Usage: %@", commandPath];

    if (_namedOptions.count > 0 or _flags.count > 0)
        [builder appendString: @" [options]"];

    for (CLIResolvedOption *resolvedPositional in _positionals)
        [builder appendFormat: @" %@", resolvedPositional.usageLabel];

    if (_subcommands.count > 0)
        [builder appendString: @" [command]"];

    return builder;
}

- (void)_appendSectionNamed: (OFString *)title
                      lines: (OFArray<OFString *> *)lines
                   toString: (OFMutableString *)builder
{
    if (lines.count == 0)
        return;

    [builder appendFormat: @"\n%@:\n", title];
    for (OFString *line in lines)
        [builder appendFormat: @"%@\n", line];
}

- (OFString *)helpTextForCommandPath: (OFString *)commandPath
{
    auto builder = [[OFMutableString alloc] init];
    auto argumentLines = [OFMutableArray<OFString *> array],
         optionLines = [OFMutableArray<OFString *> array],
         commandLines = [OFMutableArray<OFString *> array];

    [builder appendFormat: @"%@\n", [self _usageLineForCommandPath: commandPath]];

    if (_commandDescription != nilptr)
        [builder appendFormat: @"\n%@\n", _commandDescription];

    for (CLIResolvedOption *resolvedPositional in _positionals) {
        if (resolvedPositional->_help != nilptr)
            [argumentLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                   resolvedPositional.helpSyntax,
                                                                   resolvedPositional->_help]];
        else
            [argumentLines addObject: [OFString stringWithFormat: @"  %@",
                                                                    resolvedPositional.helpSyntax]];
    }

    [optionLines addObject: @"  -h, --help\n    Show this help text"];

    for (CLIResolvedOption *resolvedFlag in _flags) {
        if (resolvedFlag->_help != nilptr)
            [optionLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                 resolvedFlag.helpSyntax,
                                                                 resolvedFlag->_help]];
        else
            [optionLines addObject: [OFString stringWithFormat: @"  %@", resolvedFlag.helpSyntax]];
    }

    for (CLIResolvedOption *resolvedOption in _namedOptions) {
        if (resolvedOption->_help != nilptr)
            [optionLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                 resolvedOption.helpSyntax,
                                                                 resolvedOption->_help]];
        else
            [optionLines addObject: [OFString stringWithFormat: @"  %@", resolvedOption.helpSyntax]];
    }

    for (CLIResolvedSubcommand *resolvedSubcommand in _subcommands) {
        if (resolvedSubcommand->_help != nilptr)
            [commandLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                  resolvedSubcommand->_commandName,
                                                                  resolvedSubcommand->_help]];
        else
            [commandLines addObject: [OFString stringWithFormat: @"  %@",
                                                                  resolvedSubcommand->_commandName]];
    }

    [self _appendSectionNamed: @"Arguments" lines: argumentLines toString: builder];
    [self _appendSectionNamed: @"Options" lines: optionLines toString: builder];
    [self _appendSectionNamed: @"Commands" lines: commandLines toString: builder];

    return builder;
}

@end

@implementation CLICommandIntrospection

+ (ArgumentParserException *)_schemaExceptionWithMessage: (OFString *)message
{
    return [[ArgumentParserException alloc] initWithMessage: message usage: nilptr];
}

+ (CLICommandSchema *)schemaForCommand: (CLICommand *)command
{
    auto schema = [[CLICommandSchema alloc] init];
    auto namedOptions = [OFMutableArray<CLIResolvedOption *> array],
         positionals = [OFMutableArray<CLIResolvedOption *> array],
         flags = [OFMutableArray<CLIResolvedOption *> array];

    auto subcommands = [OFMutableArray<CLIResolvedSubcommand *> array];
    auto optionsByLongName = [OFMutableDictionary<OFString *, CLIResolvedOption *> dictionary];
    auto optionsByShortName = [OFMutableDictionary<OFString *, CLIResolvedOption *> dictionary];
    auto subcommandsByName = [OFMutableDictionary<OFString *, CLIResolvedSubcommand *> dictionary];
    auto seenPropertyNames = [OFMutableSet<OFString *> set];

    schema->_command = command;
    schema->_commandName = [[command.class cliCommandName] copy];
    schema->_commandDescription = [[command.class cliCommandDescription] copy];

    for (Class currentClass = command.class;
         currentClass != nullptr and [currentClass isSubclassOfClass: CLICommand.class];
         currentClass = class_getSuperclass(currentClass)) {
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);

        @try {
            for (unsigned int propertyIndex = 0; propertyIndex < propertyCount; propertyIndex++) {
                objc_property_t property = properties[propertyIndex];
                auto propertyName = [OFString stringWithUTF8String: property_getName(property)];
                id currentValue;
                Class propertyClass;

                if ([seenPropertyNames containsObject: propertyName])
                    continue;
                [seenPropertyNames addObject: propertyName];

                currentValue = [command valueForKey: propertyName];
                propertyClass = [CLITypeInspector propertyClassForProperty: property
                                                                   onClass: currentClass
                                                              propertyName: propertyName];

                if (currentValue == nilptr) {
                    if ((propertyClass != nullptr and [propertyClass isSubclassOfClass: CLIOption.class])
                        or (propertyClass != nullptr and [propertyClass isSubclassOfClass: CLICommand.class]))
                        @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Property '%@' on %@ must be initialized in -init",
                                                                                                propertyName,
                                                                                                [CLINameTransform className: command.class]]];
                    continue;
                }

                if ([currentValue isKindOfClass: CLIOption.class]) {
                    CLIOption *option = currentValue;
                    auto resolvedOption = [CLIResolvedOption optionWithPropertyName: propertyName option: option];

                    if (option.kind == CLIOptionKindPositional) {
                        [positionals addObject: resolvedOption];
                    } else if (option.kind == CLIOptionKindFlag) {
                        if (optionsByLongName[resolvedOption->_longName] != nilptr)
                            @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate option name '--%@' on %@",
                                                                                                    resolvedOption->_longName,
                                                                                                    [CLINameTransform className: command.class]]];
                        optionsByLongName[resolvedOption->_longName] = resolvedOption;
                        if (resolvedOption->_shortName != '\0') {
                            OFString *shortKey = [CLINameTransform shortNameString: resolvedOption->_shortName];
                            if (optionsByShortName[shortKey] != nilptr)
                                @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate short option '-%c' on %@",
                                                                                                        resolvedOption->_shortName,
                                                                                                        [CLINameTransform className: command.class]]];;
                            optionsByShortName[shortKey] = resolvedOption;
                        }
                        [flags addObject: resolvedOption];
                    } else {
                        if (optionsByLongName[resolvedOption->_longName] != nilptr)
                            @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate option name '--%@' on %@",
                                                                                                    resolvedOption->_longName,
                                                                                                    [CLINameTransform className: command.class]]];

                        optionsByLongName[resolvedOption->_longName] = resolvedOption;
                        if (resolvedOption->_shortName != '\0') {
                            OFString *shortKey = [CLINameTransform shortNameString: resolvedOption->_shortName];
                            if (optionsByShortName[shortKey] != nilptr)
                                @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate short option '-%c' on %@",
                                                                                                        resolvedOption->_shortName, [CLINameTransform className: command.class]]];
                            optionsByShortName[shortKey] = resolvedOption;
                        }
                        [namedOptions addObject: resolvedOption];
                    }

                    continue;
                }

                if ([currentValue isKindOfClass: CLICommand.class]) {
                    auto resolvedSubcommand = [CLIResolvedSubcommand subcommandWithPropertyName: propertyName command: currentValue];

                    if (subcommandsByName[resolvedSubcommand->_commandName] != nilptr)
                        @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate subcommand name '%@' on %@",
                                                                                                resolvedSubcommand->_commandName, [CLINameTransform className: command.class]]];

                    subcommandsByName[resolvedSubcommand->_commandName] = resolvedSubcommand;
                    [subcommands addObject: resolvedSubcommand];
                }
            }
        } @finally {
            free(properties);
        }

        if (currentClass == CLICommand.class)
            break;
    }

    schema->_namedOptions = [namedOptions copy];
    schema->_positionals = [positionals copy];
    schema->_flags = [flags copy];
    schema->_subcommands = [subcommands copy];
    schema->_optionsByLongName = [optionsByLongName copy];
    schema->_optionsByShortName = [optionsByShortName copy];
    schema->_subcommandsByName = [subcommandsByName copy];

    return schema;
}

@end

@implementation CLICommandParserEngine

+ (ArgumentParserException *)usageErrorWithMessage: (OFString *)message
                                            schema: (CLICommandSchema *)schema
                                       commandPath: (OFString *)commandPath
{
    return [[ArgumentParserException alloc] initWithMessage: message
                                                      usage: [schema helpTextForCommandPath: commandPath]];
}

+ (ArgumentParserHelpException *)helpExceptionForSchema: (CLICommandSchema *)schema
                                            commandPath: (OFString *)commandPath
{
    return [[ArgumentParserHelpException alloc] initWithMessage: @"Help requested"
                                                          usage: [schema helpTextForCommandPath: commandPath]];
}

+ (void)assignToken: (OFString *)token
          toOption: (CLIResolvedOption *)resolvedOption
            schema: (CLICommandSchema *)schema
       commandPath: (OFString *)commandPath
{
    @try {
        [resolvedOption->_option cli_setParsedValue: [CLIValueCodec parseToken: token forValueClass: resolvedOption->_option.valueClass]];
    } @catch (ArgumentParserException *exception) {
        @throw [self usageErrorWithMessage: exception.message
                                    schema: schema
                               commandPath: commandPath];
    }
}

+ (bool)hasRemainingRequiredPositionalsInSchema: (CLICommandSchema *)schema
                                     fromIndex: (size_t)positionIndex
{
    for (size_t index = positionIndex; index < schema->_positionals.count; index++) {
        if (schema->_positionals[index].isRequired and not schema->_positionals[index]->_option.hasValue)
            return true;
    }

    return false;
}

+ (void)finalizeCommand: (CLICommand *)command
                 schema: (CLICommandSchema *)schema
            commandPath: (OFString *)commandPath
{
    (void)command;

    for (CLIResolvedOption *resolvedPositional in schema->_positionals) {
        if (resolvedPositional.isRequired and not resolvedPositional->_option.hasValue)
            @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Missing required argument %@", resolvedPositional.usageLabel]
                                        schema: schema
                                   commandPath: commandPath];
    }

    for (CLIResolvedOption *resolvedOption in schema->_namedOptions) {
        if (resolvedOption.isRequired and not resolvedOption->_option.hasValue)
            @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Missing required option '--%@'", resolvedOption->_longName]
                                        schema: schema
                                   commandPath: commandPath];
    }
}

+ (size_t)parseCommand: (CLICommand *)command
                 schema: (CLICommandSchema *)schema
              arguments: (OFArray<OFString *> *)arguments
             startIndex: (size_t)startIndex
            commandPath: (OFString *)commandPath
{
    size_t argumentIndex = startIndex;
    size_t positionalIndex = 0;
    bool optionsEnabled = true;

    (void)command;

    while (argumentIndex < arguments.count) {
        OFString *token = arguments[argumentIndex];

        if (optionsEnabled and [token isEqual: @"--"]) {
            optionsEnabled = false;
            argumentIndex++;
            continue;
        }

        if (optionsEnabled and ([token isEqual: @"--help"] or [token isEqual: @"-h"]))
            @throw [self helpExceptionForSchema: schema commandPath: commandPath];

        if (optionsEnabled and [token hasPrefix: @"--"] and token.UTF8StringLength > 2) {
            OFString *body = [token substringFromIndex: 2];
            OFRange equalsRange = [body rangeOfString: @"="];
            OFString *optionName = body;
            OFString *nillable explicitValue = nilptr;
            CLIResolvedOption *resolvedOption;

            if (equalsRange.location != OFNotFound) {
                optionName = [body substringToIndex: equalsRange.location];
                explicitValue = [body substringFromIndex: equalsRange.location + equalsRange.length];
            }

            resolvedOption = schema->_optionsByLongName[optionName];
            if (resolvedOption == nilptr)
                @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Unknown option '--%@'", optionName]
                                            schema: schema
                                       commandPath: commandPath];

            if (resolvedOption.isFlag) {
                if (explicitValue != nilptr)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Flag '--%@' does not take a value", optionName]
                                                schema: schema
                                           commandPath: commandPath];

                [resolvedOption->_option cli_setParsedValue: @true];
                argumentIndex++;
                continue;
            }

            if (explicitValue == nilptr) {
                argumentIndex++;
                if (argumentIndex >= arguments.count)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Option '--%@' requires a value", optionName]
                                                schema: schema
                                           commandPath: commandPath];
                explicitValue = arguments[argumentIndex];
            }

            [self assignToken: $assert_nonnil(explicitValue)
                     toOption: resolvedOption
                       schema: schema
                  commandPath: commandPath];
            argumentIndex++;
            continue;
        }

        if (optionsEnabled and [token hasPrefix: @"-"] and token.UTF8StringLength > 1) {
            const char *cluster = token.UTF8String + 1;
            size_t clusterLength = token.UTF8StringLength - 1;

            for (size_t clusterIndex = 0; clusterIndex < clusterLength; clusterIndex++) {
                OFString *shortKey = [CLINameTransform shortNameString: cluster[clusterIndex]];
                CLIResolvedOption *resolvedOption = schema->_optionsByShortName[shortKey];

                if (resolvedOption == nilptr)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Unknown option '-%c'", cluster[clusterIndex]]
                                                schema: schema
                                           commandPath: commandPath];

                if (resolvedOption.isFlag) {
                    [resolvedOption->_option cli_setParsedValue: @true];
                    continue;
                }

                OFString *nillable value = nilptr;

                if (clusterIndex + 1 < clusterLength) {
                    value = [OFString stringWithUTF8String: cluster + clusterIndex + 1];
                    clusterIndex = clusterLength;
                } else {
                    argumentIndex++;
                    if (argumentIndex >= arguments.count)
                        @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Option '-%c' requires a value", resolvedOption->_shortName]
                                                    schema: schema
                                               commandPath: commandPath];
                    value = arguments[argumentIndex];
                }

                [self assignToken: $assert_nonnil(value)
                         toOption: resolvedOption
                           schema: schema
                      commandPath: commandPath];
                break;
            }

            argumentIndex++;
            continue;
        }

        CLIResolvedSubcommand *resolvedSubcommand = schema->_subcommandsByName[token];
        if (optionsEnabled
            and resolvedSubcommand != nilptr
            and not [self hasRemainingRequiredPositionalsInSchema: schema fromIndex: positionalIndex]) {
            [self finalizeCommand: command schema: schema commandPath: commandPath];

            CLICommandSchema *subcommandSchema = [CLICommandIntrospection schemaForCommand: resolvedSubcommand->_command];
            auto subcommandPath = [OFString stringWithFormat: @"%@ %@", commandPath, token];
            return [self parseCommand: resolvedSubcommand->_command
                                schema: subcommandSchema
                             arguments: arguments
                            startIndex: argumentIndex + 1
                           commandPath: subcommandPath];
        }

        if (positionalIndex < schema->_positionals.count) {
            CLIResolvedOption *resolvedPositional =
                schema->_positionals[positionalIndex];
            [self assignToken: token
                     toOption: resolvedPositional
                       schema: schema
                  commandPath: commandPath];
            positionalIndex++;
            argumentIndex++;
            continue;
        }

        if (schema->_subcommands.count > 0)
            @throw [self usageErrorWithMessage:
                [OFString stringWithFormat: @"Unknown command '%@'", token]
                                     schema: schema
                                commandPath: commandPath];

        @throw [self usageErrorWithMessage:
            [OFString stringWithFormat: @"Unexpected argument '%@'", token]
                                 schema: schema
                            commandPath: commandPath];
    }

    [self finalizeCommand: command schema: schema commandPath: commandPath];
    return argumentIndex;
}

@end

@implementation CLIOption

@synthesize kind = _kind;
@synthesize valueClass = _valueClass;
@synthesize required = _required;
@synthesize longName = _longName;
@synthesize shortName = _shortName;
@synthesize help = _help;
@synthesize valueName = _valueName;

+ (instancetype)_optionWithKind: (CLIOptionKind)kind
                      valueClass: (Class)valueClass
                        required: (bool)required
{
    auto option = [[self alloc] init];

    option->_kind = kind;
    option->_valueClass = valueClass;
    option->_required = required;
    option->_shortName = '\0';

    if (kind == CLIOptionKindFlag) {
        option->_valueClass = OFNumber.class;
        option->_defaultValue = [OFNumber numberWithBool: false];
        option->_hasDefaultValue = true;
    }

    return option;
}

+ (instancetype)required: (Class)valueClass
{
    return [self _optionWithKind: CLIOptionKindNamed
                      valueClass: valueClass
                        required: true];
}

+ (instancetype)optional: (Class)valueClass
{
    return [self _optionWithKind: CLIOptionKindNamed
                      valueClass: valueClass
                        required: false];
}

+ (instancetype)positional: (Class)valueClass
{
    return [self _optionWithKind: CLIOptionKindPositional
                      valueClass: valueClass
                        required: true];
}

+ (instancetype)optionalPositional: (Class)valueClass
{
    return [self _optionWithKind: CLIOptionKindPositional
                      valueClass: valueClass
                        required: false];
}

+ (instancetype)flag
{
    return [self _optionWithKind: CLIOptionKindFlag
                      valueClass: OFNumber.class
                        required: false];
}

- (instancetype)withLongName: (OFString *)longName
{
    _longName = [longName copy];
    return self;
}

- (instancetype)withShortName: (char)shortName
{
    _shortName = shortName;
    return self;
}

- (instancetype)withHelp: (OFString *)help
{
    _help = [help copy];
    return self;
}

- (instancetype)withValueName: (OFString *)valueName
{
    _valueName = [valueName copy];
    return self;
}

- (instancetype)withDefaultValue: (id)value
{
    _defaultValue = value;
    _hasDefaultValue = true;
    return self;
}

- (bool)hasValue
{
    return _hasParsedValue or _hasDefaultValue;
}

- (id)value
{
    if (_hasParsedValue)
        return $assert_nonnil(_parsedValue);

    if (_hasDefaultValue)
        return $assert_nonnil(_defaultValue);

    @throw [OFOutOfRangeException exception];
}

- (bool)boolValue
{
    if (not self.hasValue)
        return false;

    if ([self.value isKindOfClass: OFNumber.class])
        return ((OFNumber *)self.value).boolValue;

    return true;
}

- (id)valueOr: (id)fallbackValue
{
    if (_hasParsedValue)
        return $assert_nonnil(_parsedValue);

    if (_hasDefaultValue)
        return $assert_nonnil(_defaultValue);

    return fallbackValue;
}

- (void)cli_reset
{
    _parsedValue = nilptr;
    _hasParsedValue = false;
}

- (void)cli_setParsedValue: (id)value
{
    _parsedValue = value;
    _hasParsedValue = true;
}

@end

@implementation CLICommand

+ (OFString *)cliCommandName
{
    return [CLINameTransform kebabCaseForString: [CLINameTransform className: self]];
}

+ (OFString *nillable)cliCommandDescription
{
    return nilptr;
}

@end

@implementation ArgumentParserException

@synthesize message = _message;
@synthesize usage = _usage;

- (instancetype)initWithMessage: (OFString *)message
                          usage: (OFString *nillable)usage
{
    self = [super init];
    _message = [message copy];
    _usage = [usage copy];
    return self;
}

- (OFString *)description
{
    if (_usage == nilptr)
        return _message;

    return [OFString stringWithFormat: @"%@\n\n%@", _message, _usage];
}

@end

@implementation ArgumentParserHelpException

- (OFString *)description
{
    return self.usage ?: self.message;
}

@end

@implementation ArgumentParser

@synthesize command = _command;

- (instancetype)initWithCommand: (CLICommand *)command
{
    if (not [command.class isSubclassOfClass: CLICommand.class])
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _command = command;
    return self;
}

- (id)parseArguments: (OFArray<OFString *> *)arguments
{
    CLICommandSchema *schema = [CLICommandIntrospection schemaForCommand: _command];

    [schema resetValues];
    [CLICommandParserEngine parseCommand: _command
                                  schema: schema
                               arguments: arguments
                              startIndex: 0
                             commandPath: schema->_commandName];

    return _command;
}

- (id)parseCommandLineArguments
{ return [self parseArguments: OFApplication.arguments ?: @[]]; }

- (OFString *)helpText
{
    CLICommandSchema *schema = [CLICommandIntrospection schemaForCommand: _command];
    return [schema helpTextForCommandPath: schema->_commandName];
}

@end

#pragma clang assume_nonnull end
