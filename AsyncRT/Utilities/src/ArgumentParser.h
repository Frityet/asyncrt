#pragma once

#import "common.h"
#pragma clang assume_nonnull begin

typedef enum : uint8_t {
    CLIOptionKindNamed,
    CLIOptionKindPositional,
    CLIOptionKindFlag,
} CLIOptionKind;

@protocol CLIValueParsing

+ (id)cliParseValue: (OFString *)value;

@end

[[subclassing_restricted, direct_members]]
@interface CLIOption<T> : OFObject

@property (readonly, nonatomic) CLIOptionKind kind;
@property (readonly, nonatomic) Class valueClass;
@property (readonly, nonatomic) bool isRequired;
@property (readonly, copy, nonatomic) OFString *nillable longName;
@property (readonly, nonatomic) char shortName;
@property (readonly, copy, nonatomic) OFString *nillable help;
@property (readonly, copy, nonatomic) OFString *nillable valueName;
@property (readonly, nonatomic) bool hasValue;
@property (readonly, nonatomic) T value;
@property (readonly, nonatomic) bool boolValue;

+ (instancetype)required: (Class)valueClass;
+ (instancetype)optional: (Class)valueClass;
+ (instancetype)positional: (Class)valueClass;
+ (instancetype)optionalPositional: (Class)valueClass;
+ (instancetype)flag;

- (instancetype)withLongName: (OFString *)longName;
- (instancetype)withShortName: (char)shortName;
- (instancetype)withHelp: (OFString *)help;
- (instancetype)withValueName: (OFString *)valueName;
- (instancetype)withDefaultValue: (T)value;
- (T)valueOr: (T)fallbackValue;

@end

@interface CLICommand : OFObject

+ (OFString *)cliCommandName;
+ (OFString *nillable)cliCommandDescription;

@end

@interface ArgumentParserException : OFException

@property (readonly, copy, nonatomic) OFString *message;
@property (readonly, copy, nonatomic) OFString *nillable usage;

- (instancetype)initWithMessage: (OFString *)message
                          usage: (OFString *nillable)usage [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface ArgumentParserHelpException : ArgumentParserException @end

[[subclassing_restricted, direct_members]]
@interface ArgumentParser<T> : OFObject

@property (readonly, nonatomic) T command;

- (instancetype)initWithCommand: (T)command;
- (T)parseArguments: (OFArray<OFString *> *)arguments;
- (T)parseCommandLineArguments;
- (OFString *)helpText;

@end

#pragma clang assume_nonnull end
