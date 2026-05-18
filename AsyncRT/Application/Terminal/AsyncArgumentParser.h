#pragma once

#import <AsyncRT/Common/common.h>
#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] : uint8_t {
    AsyncCLIOptionKindNamed,
    AsyncCLIOptionKindPositional,
    AsyncCLIOptionKindFlag,
} AsyncCLIOptionKind;

@protocol AsyncCLIValueParsable

+ (instancetype)cliParseValue: (OFString *)value;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncCLIOption<T> : OFObject

@property (readonly, nonatomic) AsyncCLIOptionKind kind;
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

@protocol AsyncCLICommand<OFObject>

+ (OFString *)cliCommandName;
@optional
+ (OFString *)cliCommandDescription;

@end

@interface AsyncArgumentParserException : OFException

@property (readonly, copy, nonatomic) OFString *message;
@property (readonly, copy, nonatomic) OFString *nillable usage;

- (instancetype)initWithMessage: (OFString *)message
                          usage: (OFString *nillable)usage [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncArgumentParserHelpException : AsyncArgumentParserException @end

[[subclassing_restricted, direct_members]]
@interface AsyncArgumentParser<covariant T : id<AsyncCLICommand>> : OFObject

@property (readonly, nonatomic) T command;

- (instancetype)initWithCommand: (T nillable)command;
- (T)parseArguments: (OFArray<OFString *> *)arguments;
- (T)parseCommandLineArguments;
- (OFString *)helpText;

@end

#pragma clang assume_nonnull end
