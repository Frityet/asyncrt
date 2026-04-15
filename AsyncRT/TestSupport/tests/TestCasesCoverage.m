#import "TestSupport.h"
#import "ArgumentParser.h"

#pragma clang assume_nonnull begin

@interface CLIOption (CoverageTesting)
- (void)cli_reset;
- (void)cli_setParsedValue: (id)value;
@end

[[subclassing_restricted]]
@interface CLIResolvedOption : OFObject
+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (CLIOption *)option;
- (bool)isPositional;
- (bool)isFlag;
- (bool)isRequired;
- (OFString *)usageLabel;
- (OFString *)helpSyntax;
@end

[[subclassing_restricted]]
@interface CLICommandSchema : OFObject
- (void)resetValues;
- (OFString *)helpTextForCommandPath: (OFString *)commandPath;
@end

[[subclassing_restricted]]
@interface CLINameTransform : OFObject
+ (OFString *)kebabCaseForString: (OFString *)string;
+ (OFString *)upperValueNameForPropertyName: (OFString *)propertyName;
+ (OFString *)className: (Class nillable)class_;
+ (OFString *)shortNameString: (char)shortName;
@end

[[subclassing_restricted]]
@interface CLIValueCodec : OFObject
+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass;
@end

[[subclassing_restricted]]
@interface CLICommandIntrospection : OFObject
+ (CLICommandSchema *)schemaForCommand: (CLICommand *)command;
@end

[[subclassing_restricted]]
@interface ParserCustomParsedValue : OFObject<CLIValueParsing>

@property(readonly, copy, nonatomic) OFString *rawValue;

- (instancetype)initWithRawValue: (OFString *)rawValue [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation ParserCustomParsedValue

- (instancetype)initWithRawValue: (OFString *)rawValue
{
    self = [super init];
    _rawValue = [rawValue copy];
    return self;
}

+ (id)cliParseValue: (OFString *)value
{
    return [[self alloc] initWithRawValue: [value uppercaseString]];
}

@end

[[subclassing_restricted]]
@interface ParserStringConstructedValue : OFObject

@property(readonly, copy, nonatomic) OFString *rawValue;

- (instancetype)initWithString: (OFString *)string [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation ParserStringConstructedValue

- (instancetype)initWithString: (OFString *)string
{
    self = [super init];
    _rawValue = [string copy];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserOpaqueValue : OFObject @end
@implementation ParserOpaqueValue @end

[[subclassing_restricted]]
@interface ParserIvarFallbackCommand : CLICommand {
    CLIOption<OFString *> *_mysteryOption;
}

@property(readonly, nonatomic) id mysteryOption;

@end

@implementation ParserIvarFallbackCommand

- (instancetype)init
{
    self = [super init];
    _mysteryOption = [[[[CLIOption optional: OFString.class]
        withLongName: @"mystery"]
        withValueName: @"THING"]
        withDefaultValue: @"fallback"];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserLeafCoverageCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *leafValue;

@end

@implementation ParserLeafCoverageCommand

- (instancetype)init
{
    self = [super init];
    _leafValue = [CLIOption optionalPositional: OFString.class];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserErrorCoverageCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFNumber *> *count;
@property(readonly, nonatomic) CLIOption<OFNumber *> *force;
@property(readonly, nonatomic) CLIOption<OFString *> *mode;
@property(readonly, nonatomic) CLIOption<OFString *> *source;
@property(readonly, nonatomic) CLIOption<OFString *> *literal;
@property(readonly, nonatomic) ParserLeafCoverageCommand *serve;

@end

@implementation ParserErrorCoverageCommand

- (instancetype)init
{
    self = [super init];
    _count = [[[[CLIOption required: OFNumber.class]
        withShortName: 'c']
        withValueName: @"COUNT"]
        withLongName: @"count"];
    _force = [[CLIOption flag] withShortName: 'f'];
    _mode = [[[CLIOption optional: OFString.class]
        withLongName: @"mode"]
        withValueName: @"MODE"];
    _source = [CLIOption positional: OFString.class];
    _literal = [CLIOption optionalPositional: OFString.class];
    _serve = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserSubcommandOnlyCommand : CLICommand

@property(readonly, nonatomic) ParserLeafCoverageCommand *serve;

@end

@implementation ParserSubcommandOnlyCommand

- (instancetype)init
{
    self = [super init];
    _serve = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserUnexpectedArgumentCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFNumber *> *verbose;

@end

@implementation ParserUnexpectedArgumentCommand

- (instancetype)init
{
    self = [super init];
    _verbose = [CLIOption flag];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateLongCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *first;
@property(readonly, nonatomic) CLIOption<OFString *> *second;

@end

@implementation ParserDuplicateLongCommand

- (instancetype)init
{
    self = [super init];
    _first = [[CLIOption optional: OFString.class] withLongName: @"duplicate"];
    _second = [[CLIOption optional: OFString.class] withLongName: @"duplicate"];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateShortCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *first;
@property(readonly, nonatomic) CLIOption<OFString *> *second;

@end

@implementation ParserDuplicateShortCommand

- (instancetype)init
{
    self = [super init];
    _first = [[CLIOption optional: OFString.class] withShortName: 'd'];
    _second = [[CLIOption optional: OFString.class] withShortName: 'd'];
    return self;
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateSubcommandCommand : CLICommand

@property(readonly, nonatomic) ParserLeafCoverageCommand *dupValue;
@property(readonly, nonatomic) ParserLeafCoverageCommand *dup_value;

@end

@implementation ParserDuplicateSubcommandCommand

- (instancetype)init
{
    self = [super init];
    _dupValue = [[ParserLeafCoverageCommand alloc] init];
    _dup_value = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeCoverageTests : OTTestCase @end

@implementation AsyncRuntimeCoverageTests

- (void)test_coroutine_guard_and_common_coverage
{
    auto rootCoroutine = [[Coroutine alloc] _initAsRootCoroutine];
    auto emptyCoroutine = [Coroutine withBlock: ^id(Coroutine *co) {
        [co yield];
        [co return];
        return @"unreachable";
    }];
    auto nilYieldCoroutine = [[Coroutine alloc] initWithBlock: ^id(Coroutine *co) {
        [co yield: nilptr];
        return @"done";
    }];
    bool caughtMissingYieldCaller = false;
    bool caughtMissingReturnCaller = false;
    bool caughtReadyYield = false;
    bool caughtReadyReturn = false;
    bool caughtRunningResume = false;
    bool caughtDeadResume = false;
    bool caughtNilEnumeration = false;
    bool caughtNilBlock = false;
    bool caughtZeroStack = false;
    auto exception = [[CoroutineException alloc] initWithCoroutine: rootCoroutine];
    auto stateException = [[CoroutineStateTransitionFailedException alloc]
        initWithCoroutine: rootCoroutine
                fromState: CoroutineStatus_RUNNING
                  toState: CoroutineStatus_DEAD];
    auto missingCallerException = [[CoroutineMissingCallerException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"yield"];
    auto stackExceptionNegative = [[CoroutineStackSetupFailedException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"mco_resume"
                errorCode: -1];
    auto stackExceptionPositive = [[CoroutineStackSetupFailedException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"mco_create"
                errorCode: ENOMEM];

    OTAssert(([[Coroutine describeStatus: CoroutineStatus_READY] isEqual: @"READY"]), @"Coroutine should describe READY status explicitly");
    OTAssert(([[Coroutine describeStatus: CoroutineStatus_RUNNING] isEqual: @"RUNNING"]), @"Coroutine should describe RUNNING status explicitly");
    OTAssert(([[Coroutine describeStatus: CoroutineStatus_SUSPENDED] isEqual: @"SUSPENDED"]), @"Coroutine should describe SUSPENDED status explicitly");
    OTAssert(([[Coroutine describeStatus: CoroutineStatus_DEAD] isEqual: @"DEAD"]), @"Coroutine should describe DEAD status explicitly");
    OTAssert(([rootCoroutine.description isEqual: rootCoroutine.describe]), @"Coroutine.description should delegate to -describe");
    OTAssert(([rootCoroutine.describe containsString: @"RUNNING"]), @"Root coroutine descriptions should include the running state");

    @try {
        [rootCoroutine yield];
    } @catch (CoroutineMissingCallerException *caught) {
        caughtMissingYieldCaller = [caught.operation isEqual: @"yield"]
            and [caught.description containsString: @"without a caller"];
    }

    @try {
        [rootCoroutine return];
    } @catch (CoroutineMissingCallerException *caught) {
        caughtMissingReturnCaller = [caught.operation isEqual: @"return"]
            and [caught.description containsString: @"without a caller"];
    }

    @try {
        [emptyCoroutine yield];
    } @catch (CoroutineStateTransitionFailedException *caught) {
        caughtReadyYield = (caught.fromState == CoroutineStatus_READY
            and caught.toState == CoroutineStatus_SUSPENDED
            and [caught.description containsString: @"cannot transition"]);
    }

    @try {
        [emptyCoroutine return];
    } @catch (CoroutineStateTransitionFailedException *caught) {
        caughtReadyReturn = (caught.fromState == CoroutineStatus_READY
            and caught.toState == CoroutineStatus_DEAD);
    }

    @try {
        [rootCoroutine resume];
    } @catch (CoroutineStateTransitionFailedException *caught) {
        caughtRunningResume = (caught.fromState == CoroutineStatus_RUNNING
            and caught.toState == CoroutineStatus_RUNNING);
    }

    (void)[emptyCoroutine resume];
    (void)[emptyCoroutine resume];

    @try {
        [emptyCoroutine resume];
    } @catch (CoroutineStateTransitionFailedException *caught) {
        caughtDeadResume = (caught.fromState == CoroutineStatus_DEAD
            and caught.toState == CoroutineStatus_RUNNING);
    }

    @try {
        for (__unused id object in nilYieldCoroutine) {
        }
    } @catch (OFInvalidArgumentException *) {
        caughtNilEnumeration = true;
    }

    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
        (void)[[Coroutine alloc] initWithBlock: (id (^)(Coroutine *))0];
#pragma clang diagnostic pop
    } @catch (OFInvalidArgumentException *) {
        caughtNilBlock = true;
    }

    @try {
        (void)[[Coroutine alloc] initWithBlock: ^id(Coroutine *) {
            return @"ok";
        } stackSize: 0];
    } @catch (OFInvalidArgumentException *) {
        caughtZeroStack = true;
    }

    OTAssert((caughtMissingYieldCaller), @"Root coroutine yield should report a missing caller");
    OTAssert((caughtMissingReturnCaller), @"Root coroutine return should report a missing caller");
    OTAssert((caughtReadyYield), @"Yielding from a ready coroutine should fail the READY->SUSPENDED transition");
    OTAssert((caughtReadyReturn), @"Returning from a ready coroutine should fail the READY->DEAD transition");
    OTAssert((caughtRunningResume), @"Resuming the running root coroutine should fail the RUNNING->RUNNING transition");
    OTAssert((caughtDeadResume), @"Resuming a dead coroutine should fail the DEAD->RUNNING transition");
    OTAssert((caughtNilEnumeration), @"Fast enumeration should reject nil yields");
    OTAssert((caughtNilBlock), @"Coroutines should reject nil blocks defensively");
    OTAssert((caughtZeroStack), @"Coroutines should reject a zero stack size");

    OTAssert(([exception.description containsString: @"CoroutineException"]), @"CoroutineException should describe the wrapped coroutine");
    OTAssert(([stateException.description containsString: @"RUNNING"]), @"CoroutineStateTransitionFailedException should describe both states");
    OTAssert(([missingCallerException.description containsString: @"cannot yield"]), @"CoroutineMissingCallerException should describe the rejected operation");
    OTAssert(([stackExceptionNegative.description containsString: @"mco_resume"]), @"Negative stack setup errors should still produce a description");
    OTAssert(([stackExceptionPositive.description containsString: @"mco_create"]), @"Errno-based stack setup errors should still produce a description");

    OTAssert((NamespaceClass.self == NamespaceClass.class), @"NamespaceClass should return its class from +self");
    OTAssert(([NamespaceClass class] == NamespaceClass.class), @"NamespaceClass +class should mirror Objective-C class lookup");
}

- (void)test_argument_parser_internal_helpers
{
    auto fallbackCommand = [[ParserIvarFallbackCommand alloc] init];
    auto fallbackParser = [[ArgumentParser<ParserIvarFallbackCommand *> alloc] initWithCommand: fallbackCommand];
    auto optionalPositional = [CLIResolvedOption optionWithPropertyName: @"input_value"
                                                                 option: [CLIOption optionalPositional: OFString.class]];
    auto longOnlyFlag = [CLIResolvedOption optionWithPropertyName: @"dryRun"
                                                           option: [[CLIOption flag] withLongName: @"dry-run"]];
    auto longOnlyOption = [CLIResolvedOption optionWithPropertyName: @"outputPath"
                                                             option: [[[[CLIOption optional: OFString.class]
                                                                 withLongName: @"output"]
                                                                 withValueName: @"DEST"]
                                                                 withHelp: @"Destination"]];
    auto stringOption = [[CLIOption optional: OFString.class] withLongName: @"name"];
    bool caughtMissingOptionValue = false;
    bool caughtParserInit = false;
    bool caughtUnknownValueClass = false;
    bool caughtMissingValueClass = false;
    bool caughtInvalidNumber = false;
    auto customParsed = [CLIValueCodec parseToken: @"demo" forValueClass: ParserCustomParsedValue.class];
    auto stringConstructed = [CLIValueCodec parseToken: @"hello" forValueClass: ParserStringConstructedValue.class];

    (void)[fallbackParser parseArguments: @[@"--mystery", @"shadow"]];

    OTAssert(([[CLINameTransform kebabCaseForString: @"foo_barBaz2Qux"] isEqual: @"foo-bar-baz2-qux"]), @"CLINameTransform should convert underscores and camel-case into kebab-case");
    OTAssert(([[CLINameTransform upperValueNameForPropertyName: @"cachePath"] isEqual: @"CACHE-PATH"]), @"CLINameTransform should derive upper-cased value labels from property names");
    OTAssert(([[CLINameTransform className: Nil] isEqual: @"<unknown>"]), @"CLINameTransform should report unknown when the value class is missing");
    OTAssert(([[CLINameTransform shortNameString: 'z'] isEqual: @"z"]), @"CLINameTransform should render single-character short options as strings");

    OTAssert((optionalPositional.isPositional and not optionalPositional.isRequired), @"Resolved optional positionals should report their positional and required state");
    OTAssert(([optionalPositional.usageLabel isEqual: @"[<INPUT-VALUE>]"]), @"Optional positional usage labels should render with brackets");
    OTAssert(([optionalPositional.helpSyntax isEqual: @"[<INPUT-VALUE>]"]), @"Optional positional help syntax should mirror the usage label");
    OTAssert((longOnlyFlag.isFlag), @"Resolved flags should report flag kind");
    OTAssert(([longOnlyFlag.helpSyntax isEqual: @"--dry-run"]), @"Long-only flags should omit the short-option prefix in help text");
    OTAssert(([longOnlyOption.helpSyntax isEqual: @"--output <DEST>"]), @"Long-only named options should include their value label in help text");
    OTAssert(([fallbackParser.helpText containsString: @"--mystery <THING>"]), @"Schema building should infer CLIOption classes from backing ivars when the property type is plain id");

    OTAssert(([[(CLIOption<OFString *> *)fallbackCommand.mysteryOption value] isEqual: @"shadow"]), @"Parser fallback properties should still bind parsed values");
    OTAssert(([(CLIOption<OFString *> *)fallbackCommand.mysteryOption hasValue]), @"Fallback CLIOption properties should report values after parsing");

    OTAssert(([(OFString *)[CLIValueCodec parseToken: @"hello" forValueClass: OFString.class] isEqual: @"hello"]), @"CLIValueCodec should parse OFString values by copying the token");
    OTAssert(([[(OFNumber *)[CLIValueCodec parseToken: @"42" forValueClass: OFNumber.class] stringValue] isEqual: @"42"]), @"CLIValueCodec should parse unsigned numbers");
    OTAssert((((OFNumber *)[CLIValueCodec parseToken: @"-7" forValueClass: OFNumber.class]).longLongValue == -7), @"CLIValueCodec should parse signed numbers");
    OTAssert((((OFNumber *)[CLIValueCodec parseToken: @"6.25e1" forValueClass: OFNumber.class]).doubleValue == 62.5), @"CLIValueCodec should parse floating-point numbers with exponents");
    OTAssert(([customParsed isKindOfClass: ParserCustomParsedValue.class]
        and [((ParserCustomParsedValue *)customParsed).rawValue isEqual: @"DEMO"]), @"CLIValueCodec should use +cliParseValue: when available");
    OTAssert(([stringConstructed isKindOfClass: ParserStringConstructedValue.class]
        and [((ParserStringConstructedValue *)stringConstructed).rawValue isEqual: @"hello"]), @"CLIValueCodec should fall back to -initWithString: when available");

    @try {
        (void)[CLIValueCodec parseToken: @"opaque" forValueClass: ParserOpaqueValue.class];
    } @catch (ArgumentParserException *exception) {
        caughtUnknownValueClass = [exception.message containsString: @"Don't know how to parse"];
    }

    @try {
        (void)[CLIValueCodec parseToken: @"missing" forValueClass: Nil];
    } @catch (ArgumentParserException *exception) {
        caughtMissingValueClass = [exception.message containsString: @"Missing value class"];
    }

    @try {
        (void)[CLIValueCodec parseToken: @"12oops" forValueClass: OFNumber.class];
    } @catch (ArgumentParserException *exception) {
        caughtInvalidNumber = [exception.message containsString: @"Invalid OFNumber value '12oops'"];
    }

    [stringOption cli_setParsedValue: @"value"];
    OTAssert((stringOption.boolValue), @"CLIOption.boolValue should treat non-number parsed values as truthy");
    OTAssert(([[stringOption valueOr: @"fallback"] isEqual: @"value"]), @"CLIOption.valueOr: should return the parsed value when present");
    [stringOption cli_reset];
    OTAssert(([[stringOption valueOr: @"fallback"] isEqual: @"fallback"]), @"CLIOption.valueOr: should use the fallback when unset");

    @try {
        (void)stringOption.value;
    } @catch (OFOutOfRangeException *) {
        caughtMissingOptionValue = true;
    }

    @try {
        (void)[[ArgumentParser alloc] initWithCommand: (id)[[OFObject alloc] init]];
    } @catch (OFInvalidArgumentException *) {
        caughtParserInit = true;
    }

    OTAssert((caughtUnknownValueClass), @"CLIValueCodec should reject unknown parsing targets");
    OTAssert((caughtMissingValueClass), @"CLIValueCodec should reject missing value classes");
    OTAssert((caughtInvalidNumber), @"CLIValueCodec should reject malformed numeric tokens");
    OTAssert((caughtMissingOptionValue), @"CLIOption.value should reject unset options without defaults");
    OTAssert((caughtParserInit), @"ArgumentParser should reject non-CLICommand roots");
}

- (void)test_argument_parser_error_branches
{
    auto parser = [[ArgumentParser<ParserErrorCoverageCommand *> alloc]
        initWithCommand: [[ParserErrorCoverageCommand alloc] init]];
    auto subcommandParser = [[ArgumentParser<ParserSubcommandOnlyCommand *> alloc]
        initWithCommand: [[ParserSubcommandOnlyCommand alloc] init]];
    auto unexpectedParser = [[ArgumentParser<ParserUnexpectedArgumentCommand *> alloc]
        initWithCommand: [[ParserUnexpectedArgumentCommand alloc] init]];
    bool caughtHelp = false;
    bool caughtUnknownOption = false;
    bool caughtFlagValue = false;
    bool caughtLongValueRequired = false;
    bool caughtShortUnknown = false;
    bool caughtShortValueRequired = false;
    bool caughtMissingRequiredOption = false;
    bool caughtUnknownCommand = false;
    bool caughtUnexpectedArgument = false;
    bool caughtInvalidParsedValue = false;
    ParserErrorCoverageCommand *parsed;

    parsed = [parser parseArguments: @[@"-fc42", @"source.txt", @"--", @"-literal"]];
    OTAssert((parsed.count.value.longLongValue == 42), @"Short option clusters should allow attached values for the first non-flag option");
    OTAssert((parsed.force.boolValue), @"Short flag clusters should set the flag before consuming the value option");
    OTAssert(([parsed.source.value isEqual: @"source.txt"]), @"Required positionals should still bind after clustered short options");
    OTAssert(([parsed.literal.value isEqual: @"-literal"]), @"The '--' token should disable subsequent option parsing");

    parsed = [parser parseArguments: @[@"--count=9", @"serve", @"tail"]];
    OTAssert((parsed.count.value.longLongValue == 9), @"Long options should accept an explicit '=value' form");
    OTAssert(([parsed.source.value isEqual: @"serve"]), @"Subcommand names should remain positionals while required positionals are still missing");
    OTAssert(([parsed.literal.value isEqual: @"tail"]), @"Optional positionals should bind once required positionals are satisfied");
    OTAssert(([parser.helpText containsString: @"Commands:"]), @"Help text should still render command sections when entries have no help text");

    @try {
        (void)[parser parseArguments: @[@"-h"]];
    } @catch (ArgumentParserHelpException *exception) {
        caughtHelp = [exception.description containsString: @"Usage:"];
    }

    @try {
        (void)[parser parseArguments: @[@"--unknown", @"value"]];
    } @catch (ArgumentParserException *exception) {
        caughtUnknownOption = [exception.description containsString: @"Unknown option '--unknown'"];
    }

    @try {
        (void)[parser parseArguments: @[@"--force=yes", @"--count", @"1", @"source.txt"]];
    } @catch (ArgumentParserException *exception) {
        caughtFlagValue = [exception.description containsString: @"Flag '--force' does not take a value"];
    }

    @try {
        (void)[parser parseArguments: @[@"--count"]];
    } @catch (ArgumentParserException *exception) {
        caughtLongValueRequired = [exception.description containsString: @"Option '--count' requires a value"];
    }

    @try {
        (void)[parser parseArguments: @[@"-z"]];
    } @catch (ArgumentParserException *exception) {
        caughtShortUnknown = [exception.description containsString: @"Unknown option '-z'"];
    }

    @try {
        (void)[parser parseArguments: @[@"-c"]];
    } @catch (ArgumentParserException *exception) {
        caughtShortValueRequired = [exception.description containsString: @"Option '-c' requires a value"];
    }

    @try {
        (void)[parser parseArguments: @[@"source.txt"]];
    } @catch (ArgumentParserException *exception) {
        caughtMissingRequiredOption = [exception.description containsString: @"Missing required option '--count'"];
    }

    @try {
        (void)[subcommandParser parseArguments: @[@"unknown-command"]];
    } @catch (ArgumentParserException *exception) {
        caughtUnknownCommand = [exception.description containsString: @"Unknown command 'unknown-command'"];
    }

    @try {
        (void)[unexpectedParser parseArguments: @[@"stray"]];
    } @catch (ArgumentParserException *exception) {
        caughtUnexpectedArgument = [exception.description containsString: @"Unexpected argument 'stray'"];
    }

    @try {
        (void)[parser parseArguments: @[@"--count", @"not-a-number", @"source.txt"]];
    } @catch (ArgumentParserException *exception) {
        caughtInvalidParsedValue = [exception.description containsString: @"Invalid OFNumber value 'not-a-number'"]
            and [exception.description containsString: @"Usage:"];
    }

    OTAssert((caughtHelp), @"-h should throw a help exception with rendered usage text");
    OTAssert((caughtUnknownOption), @"Unknown long options should report a usage error");
    OTAssert((caughtFlagValue), @"Flags should reject explicit long-form values");
    OTAssert((caughtLongValueRequired), @"Named long options should require a following value when one is missing");
    OTAssert((caughtShortUnknown), @"Unknown short options should report a usage error");
    OTAssert((caughtShortValueRequired), @"Short named options should require a following value when the cluster ends");
    OTAssert((caughtMissingRequiredOption), @"Parsing should fail when a required named option is omitted");
    OTAssert((caughtUnknownCommand), @"Unexpected subcommand tokens should report an unknown command");
    OTAssert((caughtUnexpectedArgument), @"Commands without subcommands should report stray arguments as unexpected");
    OTAssert((caughtInvalidParsedValue), @"Value codec failures should be wrapped as usage errors with help text");
}

- (void)test_argument_parser_schema_validation
{
    bool caughtDuplicateLong = false;
    bool caughtDuplicateShort = false;
    bool caughtDuplicateSubcommand = false;
    auto plainException = [[ArgumentParserException alloc] initWithMessage: @"plain" usage: nilptr];
    auto helpException = [[ArgumentParserHelpException alloc] initWithMessage: @"help" usage: @"Usage: demo"];

    @try {
        (void)[CLICommandIntrospection schemaForCommand: [[ParserDuplicateLongCommand alloc] init]];
    } @catch (ArgumentParserException *exception) {
        caughtDuplicateLong = [exception.description containsString: @"Duplicate option name '--duplicate'"];
    }

    @try {
        (void)[CLICommandIntrospection schemaForCommand: [[ParserDuplicateShortCommand alloc] init]];
    } @catch (ArgumentParserException *exception) {
        caughtDuplicateShort = [exception.description containsString: @"Duplicate short option '-d'"];
    }

    @try {
        (void)[CLICommandIntrospection schemaForCommand: [[ParserDuplicateSubcommandCommand alloc] init]];
    } @catch (ArgumentParserException *exception) {
        caughtDuplicateSubcommand = [exception.description containsString: @"Duplicate subcommand name 'dup-value'"];
    }

    OTAssert(([plainException.description isEqual: @"plain"]), @"ArgumentParserException should return its bare message when no usage is attached");
    OTAssert(([helpException.description isEqual: @"Usage: demo"]), @"ArgumentParserHelpException should prefer usage text in its description");
    OTAssert((caughtDuplicateLong), @"Schema introspection should reject duplicate long option names");
    OTAssert((caughtDuplicateShort), @"Schema introspection should reject duplicate short option names");
    OTAssert((caughtDuplicateSubcommand), @"Schema introspection should reject duplicate subcommand names");
}

@end
#pragma clang assume_nonnull end
