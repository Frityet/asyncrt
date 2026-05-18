#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/Terminal/AsyncArgumentParser.h>

#pragma clang assume_nonnull begin

@interface AsyncCLIOption (CoverageTesting)
- (void)cli_reset;
- (void)cli_setParsedValue: (id)value;
@end

[[subclassing_restricted]]
@interface AsyncCLIResolvedOption : OFObject
+ (instancetype)optionWithPropertyName: (OFString *)propertyName
                                option: (AsyncCLIOption *)option;
- (bool)isPositional;
- (bool)isFlag;
- (bool)isRequired;
- (OFString *)usageLabel;
- (OFString *)helpSyntax;
@end

[[subclassing_restricted]]
@interface AsyncCLICommandSchema : OFObject
+ (instancetype)schemaForCommand: (id<AsyncCLICommand>)command;
- (void)resetValues;
- (OFString *)helpTextForCommandPath: (OFString *)commandPath;
@end

@namespace(AsyncCLIValueCodec)

+ (id)parseToken: (OFString *)token forValueClass: (Class nillable)valueClass;
@end

[[subclassing_restricted]]
@interface ParserCustomParsedValue : OFObject<AsyncCLIValueParsable>

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
@interface ParserIvarFallbackCommand : OFObject<AsyncCLICommand> {
    AsyncCLIOption<OFString *> *_mysteryOption;
}

@property(readonly, nonatomic) id mysteryOption;

@end

@implementation ParserIvarFallbackCommand

- (instancetype)init
{
    self = [super init];
    _mysteryOption = [[[[AsyncCLIOption optional: OFString.class]
        withLongName: @"mystery"]
        withValueName: @"THING"]
        withDefaultValue: @"fallback"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-ivar-fallback-command";
}

@end

[[subclassing_restricted]]
@interface ParserLeafCoverageCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *leafValue;

@end

@implementation ParserLeafCoverageCommand

- (instancetype)init
{
    self = [super init];
    _leafValue = [AsyncCLIOption optionalPositional: OFString.class];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-leaf-coverage-command";
}

@end

[[subclassing_restricted]]
@interface ParserErrorCoverageCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *count;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *force;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *mode;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *source;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *literal;
@property(readonly, nonatomic) ParserLeafCoverageCommand *serve;

@end

@implementation ParserErrorCoverageCommand

- (instancetype)init
{
    self = [super init];
    _count = [[[[AsyncCLIOption required: OFNumber.class]
        withShortName: 'c']
        withValueName: @"COUNT"]
        withLongName: @"count"];
    _force = [[AsyncCLIOption flag] withShortName: 'f'];
    _mode = [[[AsyncCLIOption optional: OFString.class]
        withLongName: @"mode"]
        withValueName: @"MODE"];
    _source = [AsyncCLIOption positional: OFString.class];
    _literal = [AsyncCLIOption optionalPositional: OFString.class];
    _serve = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-error-coverage-command";
}

@end

[[subclassing_restricted]]
@interface ParserSubcommandOnlyCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) ParserLeafCoverageCommand *serve;

@end

@implementation ParserSubcommandOnlyCommand

- (instancetype)init
{
    self = [super init];
    _serve = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-subcommand-only-command";
}

@end

[[subclassing_restricted]]
@interface ParserUnexpectedArgumentCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *verbose;

@end

@implementation ParserUnexpectedArgumentCommand

- (instancetype)init
{
    self = [super init];
    _verbose = [AsyncCLIOption flag];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-unexpected-argument-command";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateLongCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *first;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *second;

@end

@implementation ParserDuplicateLongCommand

- (instancetype)init
{
    self = [super init];
    _first = [[AsyncCLIOption optional: OFString.class] withLongName: @"duplicate"];
    _second = [[AsyncCLIOption optional: OFString.class] withLongName: @"duplicate"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-duplicate-long-command";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateShortCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *first;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *second;

@end

@implementation ParserDuplicateShortCommand

- (instancetype)init
{
    self = [super init];
    _first = [[AsyncCLIOption optional: OFString.class] withShortName: 'd'];
    _second = [[AsyncCLIOption optional: OFString.class] withShortName: 'd'];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-duplicate-short-command";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateSubcommandCommand : OFObject<AsyncCLICommand>

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

+ (OFString *)cliCommandName
{
    return @"parser-duplicate-subcommand-command";
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeCoverageTests : OTTestCase @end

@implementation AsyncRuntimeCoverageTests

- (void)test_coroutine_guard_and_common_coverage
{
    auto rootCoroutine = [[AsyncCoroutine alloc] _initAsRootCoroutine];
    auto emptyCoroutine = [AsyncCoroutine withBlock: ^id(AsyncCoroutine *co) {
        [co yield];
        [co return];
        return @"unreachable";
    }];
    auto nilYieldCoroutine = [[AsyncCoroutine alloc] initWithBlock: ^id(AsyncCoroutine *co) {
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
    auto exception = [[AsyncCoroutineException alloc] initWithCoroutine: rootCoroutine];
    auto stateException = [[AsyncCoroutineStateTransitionFailedException alloc]
        initWithCoroutine: rootCoroutine
                fromState: AsyncCoroutineStatus_RUNNING
                  toState: AsyncCoroutineStatus_DEAD];
    auto missingCallerException = [[AsyncCoroutineMissingCallerException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"yield"];
    auto stackExceptionNegative = [[AsyncCoroutineStackSetupFailedException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"mco_resume"
                errorCode: -1];
    auto stackExceptionPositive = [[AsyncCoroutineStackSetupFailedException alloc]
        initWithCoroutine: rootCoroutine
                operation: @"mco_create"
                errorCode: ENOMEM];

    OTAssert(([[AsyncCoroutine describeStatus: AsyncCoroutineStatus_READY] isEqual: @"READY"]), @"AsyncCoroutine should describe READY status explicitly");
    OTAssert(([[AsyncCoroutine describeStatus: AsyncCoroutineStatus_RUNNING] isEqual: @"RUNNING"]), @"AsyncCoroutine should describe RUNNING status explicitly");
    OTAssert(([[AsyncCoroutine describeStatus: AsyncCoroutineStatus_SUSPENDED] isEqual: @"SUSPENDED"]), @"AsyncCoroutine should describe SUSPENDED status explicitly");
    OTAssert(([[AsyncCoroutine describeStatus: AsyncCoroutineStatus_DEAD] isEqual: @"DEAD"]), @"AsyncCoroutine should describe DEAD status explicitly");
    OTAssert(([rootCoroutine.description isEqual: rootCoroutine.describe]), @"AsyncCoroutine.description should delegate to -describe");
    OTAssert(([rootCoroutine.describe containsString: @"RUNNING"]), @"Root coroutine descriptions should include the running state");

    @try {
        [rootCoroutine yield];
    } @catch (AsyncCoroutineMissingCallerException *caught) {
        caughtMissingYieldCaller = [caught.operation isEqual: @"yield"]
            and [caught.description containsString: @"without a caller"];
    }

    @try {
        [rootCoroutine return];
    } @catch (AsyncCoroutineMissingCallerException *caught) {
        caughtMissingReturnCaller = [caught.operation isEqual: @"return"]
            and [caught.description containsString: @"without a caller"];
    }

    @try {
        [emptyCoroutine yield];
    } @catch (AsyncCoroutineStateTransitionFailedException *caught) {
        caughtReadyYield = (caught.fromState == AsyncCoroutineStatus_READY
            and caught.toState == AsyncCoroutineStatus_SUSPENDED
            and [caught.description containsString: @"cannot transition"]);
    }

    @try {
        [emptyCoroutine return];
    } @catch (AsyncCoroutineStateTransitionFailedException *caught) {
        caughtReadyReturn = (caught.fromState == AsyncCoroutineStatus_READY
            and caught.toState == AsyncCoroutineStatus_DEAD);
    }

    @try {
        [rootCoroutine resume];
    } @catch (AsyncCoroutineStateTransitionFailedException *caught) {
        caughtRunningResume = (caught.fromState == AsyncCoroutineStatus_RUNNING
            and caught.toState == AsyncCoroutineStatus_RUNNING);
    }

    (void)[emptyCoroutine resume];
    (void)[emptyCoroutine resume];

    @try {
        [emptyCoroutine resume];
    } @catch (AsyncCoroutineStateTransitionFailedException *caught) {
        caughtDeadResume = (caught.fromState == AsyncCoroutineStatus_DEAD
            and caught.toState == AsyncCoroutineStatus_RUNNING);
    }

    @try {
        for (id object in nilYieldCoroutine) {
            (void)object;
        }
    } @catch (OFInvalidArgumentException *) {
        caughtNilEnumeration = true;
    }

    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
        (void)[[AsyncCoroutine alloc] initWithBlock: (id (^)(AsyncCoroutine *))0];
#pragma clang diagnostic pop
    } @catch (OFInvalidArgumentException *) {
        caughtNilBlock = true;
    }

    @try {
        (void)[[AsyncCoroutine alloc] initWithBlock: ^id(AsyncCoroutine *) {
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
    OTAssert((caughtNilBlock), @"AsyncCoroutines should reject nil blocks defensively");
    OTAssert((caughtZeroStack), @"AsyncCoroutines should reject a zero stack size");

    OTAssert(([exception.description containsString: @"AsyncCoroutineException"]), @"AsyncCoroutineException should describe the wrapped coroutine");
    OTAssert(([stateException.description containsString: @"RUNNING"]), @"AsyncCoroutineStateTransitionFailedException should describe both states");
    OTAssert(([missingCallerException.description containsString: @"cannot yield"]), @"AsyncCoroutineMissingCallerException should describe the rejected operation");
    OTAssert(([stackExceptionNegative.description containsString: @"mco_resume"]), @"Negative stack setup errors should still produce a description");
    OTAssert(([stackExceptionPositive.description containsString: @"mco_create"]), @"Errno-based stack setup errors should still produce a description");

    OTAssert((NamespaceClass.self == NamespaceClass.class), @"NamespaceClass should return its class from +self");
    OTAssert(([NamespaceClass class] == NamespaceClass.class), @"NamespaceClass +class should mirror Objective-C class lookup");
}

- (void)test_argument_parser_internal_helpers
{
    auto fallbackCommand = [[ParserIvarFallbackCommand alloc] init];
    auto fallbackParser = [[AsyncArgumentParser<ParserIvarFallbackCommand *> alloc] initWithCommand: fallbackCommand];
    auto optionalPositional = [AsyncCLIResolvedOption optionWithPropertyName: @"input_value"
                                                                 option: [AsyncCLIOption optionalPositional: OFString.class]];
    auto longOnlyFlag = [AsyncCLIResolvedOption optionWithPropertyName: @"dryRun"
                                                           option: [[AsyncCLIOption flag] withLongName: @"dry-run"]];
    auto longOnlyOption = [AsyncCLIResolvedOption optionWithPropertyName: @"outputPath"
                                                             option: [[[[AsyncCLIOption optional: OFString.class]
                                                                 withLongName: @"output"]
                                                                 withValueName: @"DEST"]
                                                                 withHelp: @"Destination"]];
    auto stringOption = [[AsyncCLIOption optional: OFString.class] withLongName: @"name"];
    bool caughtMissingOptionValue = false;
    bool caughtParserInit = false;
    bool caughtUnknownValueClass = false;
    bool caughtMissingValueClass = false;
    bool caughtInvalidNumber = false;
    auto customParsed = [AsyncCLIValueCodec parseToken: @"demo" forValueClass: ParserCustomParsedValue.class];
    auto stringConstructed = [AsyncCLIValueCodec parseToken: @"hello" forValueClass: ParserStringConstructedValue.class];

    (void)[fallbackParser parseArguments: [OFArray arrayWithObjects: @"--mystery", @"shadow", nil]];

    OTAssert(([[ParserIvarFallbackCommand cliCommandName] isEqual: @"parser-ivar-fallback-command"]), @"AsyncCLICommand should derive kebab-case names from the class name");
    OTAssert((optionalPositional.isPositional and not optionalPositional.isRequired), @"Resolved optional positionals should report their positional and required state");
    OTAssert(([optionalPositional.usageLabel isEqual: @"[<INPUT-VALUE>]"]), @"Optional positional usage labels should render with brackets");
    OTAssert(([optionalPositional.helpSyntax isEqual: @"[<INPUT-VALUE>]"]), @"Optional positional help syntax should mirror the usage label");
    OTAssert((longOnlyFlag.isFlag), @"Resolved flags should report flag kind");
    OTAssert(([longOnlyFlag.helpSyntax isEqual: @"--dry-run"]), @"Long-only flags should omit the short-option prefix in help text");
    OTAssert(([longOnlyOption.helpSyntax isEqual: @"--output <DEST>"]), @"Long-only named options should include their value label in help text");
    OTAssert(([fallbackParser.helpText containsString: @"--mystery <THING>"]), @"Schema building should infer AsyncCLIOption classes from backing ivars when the property type is plain id");

    OTAssert(([[(AsyncCLIOption<OFString *> *)fallbackCommand.mysteryOption value] isEqual: @"shadow"]), @"Parser fallback properties should still bind parsed values");
    OTAssert(([(AsyncCLIOption<OFString *> *)fallbackCommand.mysteryOption hasValue]), @"Fallback AsyncCLIOption properties should report values after parsing");

    OTAssert(([(OFString *)[AsyncCLIValueCodec parseToken: @"hello" forValueClass: OFString.class] isEqual: @"hello"]), @"AsyncCLIValueCodec should parse OFString values by copying the token");
    OTAssert(([[(OFNumber *)[AsyncCLIValueCodec parseToken: @"42" forValueClass: OFNumber.class] stringValue] isEqual: @"42"]), @"AsyncCLIValueCodec should parse unsigned numbers");
    OTAssert((((OFNumber *)[AsyncCLIValueCodec parseToken: @"-7" forValueClass: OFNumber.class]).longLongValue == -7), @"AsyncCLIValueCodec should parse signed numbers");
    OTAssert((((OFNumber *)[AsyncCLIValueCodec parseToken: @"6.25e1" forValueClass: OFNumber.class]).doubleValue == 62.5), @"AsyncCLIValueCodec should parse floating-point numbers with exponents");
    OTAssert(([customParsed isKindOfClass: ParserCustomParsedValue.class]
        and [((ParserCustomParsedValue *)customParsed).rawValue isEqual: @"DEMO"]), @"AsyncCLIValueCodec should use +cliParseValue: when available");
    OTAssert(([stringConstructed isKindOfClass: ParserStringConstructedValue.class]
        and [((ParserStringConstructedValue *)stringConstructed).rawValue isEqual: @"hello"]), @"AsyncCLIValueCodec should fall back to -initWithString: when available");

    @try {
        (void)[AsyncCLIValueCodec parseToken: @"opaque" forValueClass: ParserOpaqueValue.class];
    } @catch (AsyncArgumentParserException *exception) {
        caughtUnknownValueClass = [exception.message containsString: @"Don't know how to parse"];
    }

    @try {
        (void)[AsyncCLIValueCodec parseToken: @"missing" forValueClass: Nil];
    } @catch (AsyncArgumentParserException *exception) {
        caughtMissingValueClass = [exception.message containsString: @"Missing value class"];
    }

    @try {
        (void)[AsyncCLIValueCodec parseToken: @"12oops" forValueClass: OFNumber.class];
    } @catch (AsyncArgumentParserException *exception) {
        caughtInvalidNumber = [exception.message containsString: @"Invalid OFNumber value '12oops'"];
    }

    [stringOption cli_setParsedValue: @"value"];
    OTAssert((stringOption.boolValue), @"AsyncCLIOption.boolValue should treat non-number parsed values as truthy");
    OTAssert(([[stringOption valueOr: @"fallback"] isEqual: @"value"]), @"AsyncCLIOption.valueOr: should return the parsed value when present");
    [stringOption cli_reset];
    OTAssert(([[stringOption valueOr: @"fallback"] isEqual: @"fallback"]), @"AsyncCLIOption.valueOr: should use the fallback when unset");

    @try {
        (void)stringOption.value;
    } @catch (OFOutOfRangeException *) {
        caughtMissingOptionValue = true;
    }

    @try {
        (void)[[AsyncArgumentParser alloc] initWithCommand: (id)[[OFObject alloc] init]];
    } @catch (OFInvalidArgumentException *) {
        caughtParserInit = true;
    }

    OTAssert((caughtUnknownValueClass), @"AsyncCLIValueCodec should reject unknown parsing targets");
    OTAssert((caughtMissingValueClass), @"AsyncCLIValueCodec should reject missing value classes");
    OTAssert((caughtInvalidNumber), @"AsyncCLIValueCodec should reject malformed numeric tokens");
    OTAssert((caughtMissingOptionValue), @"AsyncCLIOption.value should reject unset options without defaults");
    OTAssert((caughtParserInit), @"AsyncArgumentParser should reject non-AsyncCLICommand roots");
}

- (void)test_argument_parser_error_branches
{
    auto parser = [[AsyncArgumentParser<ParserErrorCoverageCommand *> alloc]
        initWithCommand: [[ParserErrorCoverageCommand alloc] init]];
    auto subcommandParser = [[AsyncArgumentParser<ParserSubcommandOnlyCommand *> alloc]
        initWithCommand: [[ParserSubcommandOnlyCommand alloc] init]];
    auto unexpectedParser = [[AsyncArgumentParser<ParserUnexpectedArgumentCommand *> alloc]
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

    parsed = [parser parseArguments: [OFArray arrayWithObjects: @"-fc42", @"source.txt", @"--", @"-literal", nil]];
    OTAssert((parsed.count.value.longLongValue == 42), @"Short option clusters should allow attached values for the first non-flag option");
    OTAssert((parsed.force.boolValue), @"Short flag clusters should set the flag before consuming the value option");
    OTAssert(([parsed.source.value isEqual: @"source.txt"]), @"Required positionals should still bind after clustered short options");
    OTAssert(([parsed.literal.value isEqual: @"-literal"]), @"The '--' token should disable subsequent option parsing");

    parsed = [parser parseArguments: [OFArray arrayWithObjects: @"--count=9", @"serve", @"tail", nil]];
    OTAssert((parsed.count.value.longLongValue == 9), @"Long options should accept an explicit '=value' form");
    OTAssert(([parsed.source.value isEqual: @"serve"]), @"Subcommand names should remain positionals while required positionals are still missing");
    OTAssert(([parsed.literal.value isEqual: @"tail"]), @"Optional positionals should bind once required positionals are satisfied");
    OTAssert(([parser.helpText containsString: @"Commands:"]), @"Help text should still render command sections when entries have no help text");

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"-h"]];
    } @catch (AsyncArgumentParserHelpException *exception) {
        caughtHelp = [exception.description containsString: @"Usage:"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObjects: @"--unknown", @"value", nil]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtUnknownOption = [exception.description containsString: @"Unknown option '--unknown'"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObjects: @"--force=yes", @"--count", @"1", @"source.txt", nil]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtFlagValue = [exception.description containsString: @"Flag '--force' does not take a value"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"--count"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtLongValueRequired = [exception.description containsString: @"Option '--count' requires a value"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"-z"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtShortUnknown = [exception.description containsString: @"Unknown option '-z'"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"-c"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtShortValueRequired = [exception.description containsString: @"Option '-c' requires a value"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"source.txt"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtMissingRequiredOption = [exception.description containsString: @"Missing required option '--count'"];
    }

    @try {
        (void)[subcommandParser parseArguments: [OFArray arrayWithObject: @"unknown-command"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtUnknownCommand = [exception.description containsString: @"Unknown command 'unknown-command'"];
    }

    @try {
        (void)[unexpectedParser parseArguments: [OFArray arrayWithObject: @"stray"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtUnexpectedArgument = [exception.description containsString: @"Unexpected argument 'stray'"];
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObjects: @"--count", @"not-a-number", @"source.txt", nil]];
    } @catch (AsyncArgumentParserException *exception) {
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
    auto plainException = [[AsyncArgumentParserException alloc] initWithMessage: @"plain" usage: nilptr];
    auto helpException = [[AsyncArgumentParserHelpException alloc] initWithMessage: @"help" usage: @"Usage: demo"];

    @try {
        (void)[AsyncCLICommandSchema schemaForCommand: [[ParserDuplicateLongCommand alloc] init]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtDuplicateLong = [exception.description containsString: @"Duplicate option name '--duplicate'"];
    }

    @try {
        (void)[AsyncCLICommandSchema schemaForCommand: [[ParserDuplicateShortCommand alloc] init]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtDuplicateShort = [exception.description containsString: @"Duplicate short option '-d'"];
    }

    @try {
        (void)[AsyncCLICommandSchema schemaForCommand: [[ParserDuplicateSubcommandCommand alloc] init]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtDuplicateSubcommand = [exception.description containsString: @"Duplicate subcommand name 'dup-value'"];
    }

    OTAssert(([plainException.description isEqual: @"plain"]), @"AsyncArgumentParserException should return its bare message when no usage is attached");
    OTAssert(([helpException.description isEqual: @"Usage: demo"]), @"AsyncArgumentParserHelpException should prefer usage text in its description");
    OTAssert((caughtDuplicateLong), @"Schema introspection should reject duplicate long option names");
    OTAssert((caughtDuplicateShort), @"Schema introspection should reject duplicate short option names");
    OTAssert((caughtDuplicateSubcommand), @"Schema introspection should reject duplicate subcommand names");
}

@end
#pragma clang assume_nonnull end
