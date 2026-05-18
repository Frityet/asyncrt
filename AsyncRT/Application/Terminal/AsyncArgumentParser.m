#include <AsyncRT/Application/Terminal/AsyncArgumentParser.h>

#if !defined(__APPLE__)
#include <ObjFWRT/ObjFWRT.h>
#else
#include <objc/objc.h>
#endif
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#pragma clang assume_nonnull begin

@interface AsyncCLIOption (AsyncArgumentParserInternal)
- (void)cli_reset;
- (void)cli_setParsedValue: (id)value;
@end

[[subclassing_restricted, direct_members]]
@interface AsyncCLIResolvedOption : OFObject {
@public
    OFString *_propertyName;
    AsyncCLIOption *_option;
    OFString *_longName;
    char _shortName;
    OFString *nillable _help;
    OFString *_valueName;
}
+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (AsyncCLIOption *)option;
- (bool)isPositional;
- (bool)isFlag;
- (bool)isRequired;
- (OFString *)usageLabel;
- (OFString *)helpSyntax;
@end

[[subclassing_restricted, direct_members]]
@interface AsyncCLIResolvedSubcommand : OFObject {
@public
    OFString *_propertyName;
    id<AsyncCLICommand> _command;
    OFString *_commandName;
    OFString *nillable _help;
}
+ (instancetype)subcommandWithPropertyName: (OFString *)propertyName
                                   command: (id<AsyncCLICommand>)command;
@end

[[subclassing_restricted, direct_members]]
@interface AsyncCLICommandSchema : OFObject {
@public
    id<AsyncCLICommand> _command;
    OFString *_commandName;
    OFString *nillable _commandDescription;
    OFArray<AsyncCLIResolvedOption *> *_namedOptions;
    OFArray<AsyncCLIResolvedOption *> *_positionals;
    OFArray<AsyncCLIResolvedOption *> *_flags;
    OFArray<AsyncCLIResolvedSubcommand *> *_subcommands;
    OFDictionary<OFString *, AsyncCLIResolvedOption *> *_optionsByLongName;
    OFDictionary<OFString *, AsyncCLIResolvedOption *> *_optionsByShortName;
    OFDictionary<OFString *, AsyncCLIResolvedSubcommand *> *_subcommandsByName;
}
+ (instancetype)schemaForCommand: (id<AsyncCLICommand>)command;
- (size_t)parseArguments: (OFArray<OFString *> *)arguments
              startIndex: (size_t)startIndex
             commandPath: (OFString *)commandPath;
- (void)resetValues;
- (OFString *)helpTextForCommandPath: (OFString *)commandPath;
@end

@interface OFString (AsyncArgumentParserAdditions)

- (OFString *)kebabCaseString;

@end

@namespace(AsyncCLITypeInspector)

+ (Class nillable)propertyClassForProperty: (objc_property_t)property
                                    onClass: (Class)class_
                               propertyName: (OFString *)propertyName;
@end

@namespace(AsyncCLIValueCodec)

+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass;
@end

@namespace(AsyncCLICommandMetadata)

+ (OFString *nillable)descriptionForCommand: (id<AsyncCLICommand>)command;
@end

@implementation OFString (AsyncArgumentParserAdditions)

- (OFString *)kebabCaseString
{
    const char *utf8 = self.UTF8String;
    size_t length = self.UTF8StringLength;
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

@end

@namespace_implementation(AsyncCLICommandMetadata)

+ (OFString *nillable)descriptionForCommand: (id<AsyncCLICommand>)command
{
    Class commandClass = command.class;

    if (![commandClass respondsToSelector: @selector(cliCommandDescription)])
        return nilptr;

    return [commandClass cliCommandDescription];
}

@end

[[direct_members]]
@implementation AsyncCLIResolvedOption

+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (AsyncCLIOption *)option
{
    auto resolvedOption = [[self alloc] init];

    resolvedOption->_propertyName = [propertyName copy];
    resolvedOption->_option = option;
    resolvedOption->_longName = [(option.longName ?: [propertyName kebabCaseString]) copy];
    resolvedOption->_shortName = option.shortName;
    resolvedOption->_help = [option.help copy];
    resolvedOption->_valueName = [(option.valueName ?: [[propertyName kebabCaseString] uppercaseString]) copy];

    return resolvedOption;
}

- (bool)isPositional
{
    return _option.kind == AsyncCLIOptionKindPositional;
}

- (bool)isFlag
{
    return _option.kind == AsyncCLIOptionKindFlag;
}

- (bool)isRequired
{
    return _option.isRequired;
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

[[direct_members]]
@implementation AsyncCLIResolvedSubcommand

+ (instancetype)subcommandWithPropertyName: (OFString *)propertyName
                                   command: (id<AsyncCLICommand>)command
{
    auto resolvedSubcommand = [[self alloc] init];

    resolvedSubcommand->_propertyName = [propertyName copy];
    resolvedSubcommand->_command = command;
    resolvedSubcommand->_commandName = [[propertyName kebabCaseString] copy];
    resolvedSubcommand->_help = [[AsyncCLICommandMetadata descriptionForCommand: command] copy];

    return resolvedSubcommand;
}

@end

@namespace_implementation(AsyncCLITypeInspector)

+ (Class nillable)_classFromQuotedObjectEncoding: (const char *nillable)encoding
{
    if (encoding == nullptr
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

+ (Class nillable)_classFromIvarsOnClass: (Class)class_
                            propertyName: (OFString *)propertyName
{
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(class_, &ivarCount);
    Class inferredClass = nullptr;
    auto underscoredPropertyName = [OFString stringWithFormat: @"_%@", propertyName];

    @try {
        for (unsigned int index = 0; index < ivarCount; index++) {
            auto ivarName = [OFString stringWithUTF8String: $assert_nonnil(ivar_getName(ivars[index]))];

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
        propertyClass = [self _classFromQuotedObjectEncoding: typeEncoding];
    } @finally {
        free(typeEncoding);
    }

    if (propertyClass != nullptr)
        return propertyClass;

    return [self _classFromIvarsOnClass: class_ propertyName: propertyName];
}

@end

@namespace_implementation(AsyncCLIValueCodec)

+ (id)_invalidValueExceptionForToken: (OFString *)token
                           valueClass: (Class)valueClass
{
    return [[AsyncArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Invalid %@ value '%@'",
                                                                                          [valueClass className],
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

        return [OFNumber numberWithDouble: value];
    }

    if (token.UTF8StringLength > 0 and string[0] == '-') {
        errno = 0;
        long long value = strtoll(string, &end, 0);
        if (errno != 0 or end == string or *end != '\0')
            @throw [self _invalidValueExceptionForToken: token valueClass: OFNumber.class];

        return [OFNumber numberWithLongLong: value];
    }

    errno = 0;
    unsigned long long value = strtoull(string, &end, 0);
    if (errno != 0 or end == string or *end != '\0')
        @throw [self _invalidValueExceptionForToken: token valueClass: OFNumber.class];

    return [OFNumber numberWithUnsignedLongLong: value];
}

+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass
{
    if (valueClass == nullptr)
        @throw [[AsyncArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Missing value class for '%@'",
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

    @throw [[AsyncArgumentParserException alloc] initWithMessage: [OFString stringWithFormat: @"Don't know how to parse '%@' as %@",
                                                                                          token, [valueClass className]]
                                                      usage: nilptr];
}

@end

[[direct_members]]
@implementation AsyncCLICommandSchema

+ (AsyncArgumentParserException *)_schemaExceptionWithMessage: (OFString *)message
{
    return [[AsyncArgumentParserException alloc] initWithMessage: message usage: nilptr];
}

+ (instancetype)schemaForCommand: (id<AsyncCLICommand>)command
{
    auto schema = [[self alloc] init];
    auto namedOptions = [OFMutableArray<AsyncCLIResolvedOption *> array],
         positionals = [OFMutableArray<AsyncCLIResolvedOption *> array],
         flags = [OFMutableArray<AsyncCLIResolvedOption *> array];

    auto subcommands = [OFMutableArray<AsyncCLIResolvedSubcommand *> array];
    auto optionsByLongName = [OFMutableDictionary<OFString *, AsyncCLIResolvedOption *> dictionary];
    auto optionsByShortName = [OFMutableDictionary<OFString *, AsyncCLIResolvedOption *> dictionary];
    auto subcommandsByName = [OFMutableDictionary<OFString *, AsyncCLIResolvedSubcommand *> dictionary];
    auto seenPropertyNames = [OFMutableSet<OFString *> set];

    schema->_command = command;
    schema->_commandName = [[command.class cliCommandName] copy];
    schema->_commandDescription = [[AsyncCLICommandMetadata descriptionForCommand: command] copy];

    for (Class currentClass = command.class;
         currentClass != nullptr and [currentClass conformsToProtocol: @protocol(AsyncCLICommand)];
         currentClass = currentClass.superclass) {
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);

        @try {
            for (unsigned int propertyIndex = 0; propertyIndex < propertyCount; propertyIndex++) {
                objc_property_t property = properties[propertyIndex];
                auto propertyName = [OFString stringWithUTF8String: property_getName(property)];

                if ([seenPropertyNames containsObject: propertyName])
                    continue;
                [seenPropertyNames addObject: propertyName];

                id currentValue = [(OFObject *)command valueForKey: propertyName];
                Class propertyClass = [AsyncCLITypeInspector propertyClassForProperty: property
                                                                         onClass: currentClass
                                                                    propertyName: propertyName];

                if (currentValue == nilptr) {
                    if ((propertyClass != nullptr and [propertyClass isSubclassOfClass: AsyncCLIOption.class])
                        or (propertyClass != nullptr and [propertyClass conformsToProtocol: @protocol(AsyncCLICommand)]))
                        @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Property '%@' on %@ must be initialized in -init",
                                                                                                propertyName,
                                                                                                [command.class className]]];
                    continue;
                }

                if ([currentValue isKindOfClass: AsyncCLIOption.class]) {
                    AsyncCLIOption *option = currentValue;
                    auto resolvedOption = [AsyncCLIResolvedOption optionWithPropertyName: propertyName option: option];

                    if (option.kind == AsyncCLIOptionKindPositional) {
                        [positionals addObject: resolvedOption];
                        continue;
                    }

                    if (optionsByLongName[resolvedOption->_longName] != nilptr)
                        @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate option name '--%@' on %@",
                                                                                                resolvedOption->_longName,
                                                                                                [command.class className]]];

                    optionsByLongName[resolvedOption->_longName] = resolvedOption;
                    if (resolvedOption->_shortName != '\0') {
                        OFString *shortKey = [OFString stringWithFormat: @"%c", resolvedOption->_shortName];
                        if (optionsByShortName[shortKey] != nilptr)
                            @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate short option '-%c' on %@",
                                                                                                    resolvedOption->_shortName,
                                                                                                    [command.class className]]];
                        optionsByShortName[shortKey] = resolvedOption;
                    }

                    if (option.kind == AsyncCLIOptionKindFlag)
                        [flags addObject: resolvedOption];
                    else
                        [namedOptions addObject: resolvedOption];

                    continue;
                }

                if ([currentValue conformsToProtocol: @protocol(AsyncCLICommand)]) {
                    auto resolvedSubcommand = [AsyncCLIResolvedSubcommand subcommandWithPropertyName: propertyName command: currentValue];

                    if (subcommandsByName[resolvedSubcommand->_commandName] != nilptr)
                        @throw [self _schemaExceptionWithMessage: [OFString stringWithFormat: @"Duplicate subcommand name '%@' on %@",
                                                                                                resolvedSubcommand->_commandName,
                                                                                                [command.class className]]];

                    subcommandsByName[resolvedSubcommand->_commandName] = resolvedSubcommand;
                    [subcommands addObject: resolvedSubcommand];
                }
            }
        } @finally {
            free(properties);
        }

        // if (currentClass == AsyncCLICommand.class)
        //     break;
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

- (AsyncArgumentParserException *)usageErrorWithMessage: (OFString *)message
                                      commandPath: (OFString *)commandPath
{
    return [[AsyncArgumentParserException alloc] initWithMessage: message
                                                      usage: [self helpTextForCommandPath: commandPath]];
}

- (AsyncArgumentParserHelpException *)helpExceptionForCommandPath: (OFString *)commandPath
{
    return [[AsyncArgumentParserHelpException alloc] initWithMessage: @"Help requested"
                                                          usage: [self helpTextForCommandPath: commandPath]];
}

- (void)assignToken: (OFString *)token
           toOption: (AsyncCLIResolvedOption *)resolvedOption
        commandPath: (OFString *)commandPath
{
    @try {
        [resolvedOption->_option cli_setParsedValue: [AsyncCLIValueCodec parseToken: token
                                                                  forValueClass: resolvedOption->_option.valueClass]];
    } @catch (AsyncArgumentParserException *exception) {
        @throw [self usageErrorWithMessage: exception.message commandPath: commandPath];
    }
}

- (bool)hasRemainingRequiredPositionalsFromIndex: (size_t)positionIndex
{
    for (size_t index = positionIndex; index < _positionals.count; index++) {
        if (_positionals[index].isRequired and not _positionals[index]->_option.hasValue)
            return true;
    }

    return false;
}

- (void)finalizeCommandPath: (OFString *)commandPath
{
    for (AsyncCLIResolvedOption *resolvedPositional in _positionals) {
        if (resolvedPositional.isRequired and not resolvedPositional->_option.hasValue)
            @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Missing required argument %@",
                                                                            resolvedPositional.usageLabel]
                                    commandPath: commandPath];
    }

    for (AsyncCLIResolvedOption *resolvedOption in _namedOptions) {
        if (resolvedOption.isRequired and not resolvedOption->_option.hasValue)
            @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Missing required option '--%@'",
                                                                            resolvedOption->_longName]
                                    commandPath: commandPath];
    }
}

- (void)resetValues
{
    for (AsyncCLIResolvedOption *resolvedOption in _namedOptions)
        [resolvedOption->_option cli_reset];

    for (AsyncCLIResolvedOption *resolvedFlag in _flags)
        [resolvedFlag->_option cli_reset];

    for (AsyncCLIResolvedOption *resolvedPositional in _positionals)
        [resolvedPositional->_option cli_reset];

    for (AsyncCLIResolvedSubcommand *resolvedSubcommand in _subcommands)
        [[AsyncCLICommandSchema schemaForCommand: resolvedSubcommand->_command] resetValues];
}

- (OFString *)_usageLineForCommandPath: (OFString *)commandPath
{
    auto builder = [[OFMutableString alloc] init];

    [builder appendFormat: @"Usage: %@", commandPath];

    if (_namedOptions.count > 0 or _flags.count > 0)
        [builder appendString: @" [options]"];

    for (AsyncCLIResolvedOption *resolvedPositional in _positionals)
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

    for (AsyncCLIResolvedOption *resolvedPositional in _positionals) {
        if (resolvedPositional->_help != nilptr)
            [argumentLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                   resolvedPositional.helpSyntax,
                                                                   resolvedPositional->_help]];
        else
            [argumentLines addObject: [OFString stringWithFormat: @"  %@",
                                                                    resolvedPositional.helpSyntax]];
    }

    [optionLines addObject: @"  -h, --help\n    Show this help text"];

    for (AsyncCLIResolvedOption *resolvedFlag in _flags) {
        if (resolvedFlag->_help != nilptr)
            [optionLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                 resolvedFlag.helpSyntax,
                                                                 resolvedFlag->_help]];
        else
            [optionLines addObject: [OFString stringWithFormat: @"  %@", resolvedFlag.helpSyntax]];
    }

    for (AsyncCLIResolvedOption *resolvedOption in _namedOptions) {
        if (resolvedOption->_help != nilptr)
            [optionLines addObject: [OFString stringWithFormat: @"  %@\n    %@",
                                                                 resolvedOption.helpSyntax,
                                                                 resolvedOption->_help]];
        else
            [optionLines addObject: [OFString stringWithFormat: @"  %@", resolvedOption.helpSyntax]];
    }

    for (AsyncCLIResolvedSubcommand *resolvedSubcommand in _subcommands) {
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
- (size_t)parseArguments: (OFArray<OFString *> *)arguments
              startIndex: (size_t)startIndex
             commandPath: (OFString *)commandPath
{
    size_t argumentIndex = startIndex;
    size_t positionalIndex = 0;
    bool optionsEnabled = true;

    while (argumentIndex < arguments.count) {
        OFString *token = arguments[argumentIndex];

        if (optionsEnabled and [token isEqual: @"--"]) {
            optionsEnabled = false;
            argumentIndex++;
            continue;
        }

        if (optionsEnabled and ([token isEqual: @"--help"] or [token isEqual: @"-h"]))
            @throw [self helpExceptionForCommandPath: commandPath];

        if (optionsEnabled and [token hasPrefix: @"--"] and token.UTF8StringLength > 2) {
            OFString *body = [token substringFromIndex: 2];
            OFRange equalsRange = [body rangeOfString: @"="];
            OFString *optionName = body;
            OFString *nillable explicitValue = nilptr;

            if (equalsRange.location != OFNotFound) {
                optionName = [body substringToIndex: equalsRange.location];
                explicitValue = [body substringFromIndex: equalsRange.location + equalsRange.length];
            }

            AsyncCLIResolvedOption *resolvedOption = _optionsByLongName[optionName];
            if (resolvedOption == nilptr)
                @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Unknown option '--%@'", optionName]
                                       commandPath: commandPath];

            if (resolvedOption.isFlag) {
                if (explicitValue != nilptr)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Flag '--%@' does not take a value", optionName]
                                           commandPath: commandPath];

                [resolvedOption->_option cli_setParsedValue: [OFNumber numberWithBool: true]];
                argumentIndex++;
                continue;
            }

            if (explicitValue == nilptr) {
                argumentIndex++;
                if (argumentIndex >= arguments.count)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Option '--%@' requires a value", optionName]
                                           commandPath: commandPath];
                explicitValue = arguments[argumentIndex];
            }

            [self assignToken: $assert_nonnil(explicitValue)
                     toOption: resolvedOption
                  commandPath: commandPath];
            argumentIndex++;
            continue;
        }

        if (optionsEnabled and [token hasPrefix: @"-"] and token.UTF8StringLength > 1) {
            const char *cluster = token.UTF8String + 1;
            size_t clusterLength = token.UTF8StringLength - 1;

            for (size_t clusterIndex = 0; clusterIndex < clusterLength; clusterIndex++) {
                OFString *shortKey = [OFString stringWithFormat: @"%c", cluster[clusterIndex]];
                AsyncCLIResolvedOption *resolvedOption = _optionsByShortName[shortKey];

                if (resolvedOption == nilptr)
                    @throw [self usageErrorWithMessage: [OFString stringWithFormat: @"Unknown option '-%c'", cluster[clusterIndex]]
                                           commandPath: commandPath];

                if (resolvedOption.isFlag) {
                    [resolvedOption->_option cli_setParsedValue: [OFNumber numberWithBool: true]];
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
                                               commandPath: commandPath];
                    value = arguments[argumentIndex];
                }

                [self assignToken: $assert_nonnil(value)
                         toOption: resolvedOption
                      commandPath: commandPath];
                break;
            }

            argumentIndex++;
            continue;
        }

        AsyncCLIResolvedSubcommand *resolvedSubcommand = _subcommandsByName[token];
        if (optionsEnabled
            and resolvedSubcommand != nilptr
            and not [self hasRemainingRequiredPositionalsFromIndex: positionalIndex]) {
            [self finalizeCommandPath: commandPath];

            AsyncCLICommandSchema *subcommandSchema = [AsyncCLICommandSchema schemaForCommand: resolvedSubcommand->_command];
            auto subcommandPath = [OFString stringWithFormat: @"%@ %@", commandPath, token];
            return [subcommandSchema parseArguments: arguments
                                         startIndex: argumentIndex + 1
                                        commandPath: subcommandPath];
        }

        if (positionalIndex < _positionals.count) {
            AsyncCLIResolvedOption *resolvedPositional = _positionals[positionalIndex];
            [self assignToken: token
                     toOption: resolvedPositional
                  commandPath: commandPath];
            positionalIndex++;
            argumentIndex++;
            continue;
        }

        if (_subcommands.count > 0)
            @throw [self usageErrorWithMessage:
                [OFString stringWithFormat: @"Unknown command '%@'", token]
                                commandPath: commandPath];

        @throw [self usageErrorWithMessage:
            [OFString stringWithFormat: @"Unexpected argument '%@'", token]
                            commandPath: commandPath];
    }

    [self finalizeCommandPath: commandPath];
    return argumentIndex;
}

@end

@implementation AsyncCLIOption {
    AsyncCLIOptionKind _kind;
    Class _valueClass;
    bool _isRequired;
    OFString *nillable _longName;
    char _shortName;
    OFString *nillable _help;
    OFString *nillable _valueName;
    id nillable _defaultValue;
    bool _hasDefaultValue;
    id nillable _parsedValue;
    bool _hasParsedValue;
}

+ (instancetype)_optionWithKind: (AsyncCLIOptionKind)kind
                      valueClass: (Class)valueClass
                        required: (bool)required
{
    auto option = [[self alloc] init];

    option->_kind = kind;
    option->_valueClass = valueClass;
    option->_isRequired = required;
    option->_shortName = '\0';

    if (kind == AsyncCLIOptionKindFlag) {
        option->_valueClass = OFNumber.class;
        option->_defaultValue = [OFNumber numberWithBool: false];
        option->_hasDefaultValue = true;
    }

    return option;
}

+ (instancetype)required: (Class)valueClass
{
    return [self _optionWithKind: AsyncCLIOptionKindNamed
                      valueClass: valueClass
                        required: true];
}

+ (instancetype)optional: (Class)valueClass
{
    return [self _optionWithKind: AsyncCLIOptionKindNamed
                      valueClass: valueClass
                        required: false];
}

+ (instancetype)positional: (Class)valueClass
{
    return [self _optionWithKind: AsyncCLIOptionKindPositional
                      valueClass: valueClass
                        required: true];
}

+ (instancetype)optionalPositional: (Class)valueClass
{
    return [self _optionWithKind: AsyncCLIOptionKindPositional
                      valueClass: valueClass
                        required: false];
}

+ (instancetype)flag
{
    return [self _optionWithKind: AsyncCLIOptionKindFlag
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

@implementation AsyncArgumentParserException


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

@implementation AsyncArgumentParserHelpException

- (OFString *)description
{
    return self.usage ?: self.message;
}

@end

@implementation AsyncArgumentParser

- (instancetype)initWithCommand: (id<AsyncCLICommand> nillable)command
{
    if (command == nilptr or ![command.class conformsToProtocol: @protocol(AsyncCLICommand)])
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _command = $assert_nonnil(command);
    return self;
}

- (id)parseArguments: (OFArray<OFString *> *)arguments
{
    AsyncCLICommandSchema *schema = [AsyncCLICommandSchema schemaForCommand: _command];

    [schema resetValues];
    [schema parseArguments: arguments
                startIndex: 0
               commandPath: schema->_commandName];

    return _command;
}

- (id)parseCommandLineArguments
{ return [self parseArguments: OFApplication.arguments ?: [OFArray array]]; }

- (OFString *)helpText
{
    AsyncCLICommandSchema *schema = [AsyncCLICommandSchema schemaForCommand: _command];
    return [schema helpTextForCommandPath: schema->_commandName];
}

@end

#pragma clang assume_nonnull end
