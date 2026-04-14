#import "TestSupport.h"
#import "App/ArgumentParser.h"

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

@synthesize rawValue = _rawValue;

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

@synthesize rawValue = _rawValue;

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

@synthesize mysteryOption = _mysteryOption;

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

@synthesize leafValue = _leafValue;

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

@synthesize count = _count;
@synthesize force = _force;
@synthesize mode = _mode;
@synthesize source = _source;
@synthesize literal = _literal;
@synthesize serve = _serve;

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

@synthesize serve = _serve;

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

@synthesize verbose = _verbose;

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

@synthesize first = _first;
@synthesize second = _second;

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

@synthesize first = _first;
@synthesize second = _second;

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

@synthesize dupValue = _dupValue;
@synthesize dup_value = _dup_value;

- (instancetype)init
{
    self = [super init];
    _dupValue = [[ParserLeafCoverageCommand alloc] init];
    _dup_value = [[ParserLeafCoverageCommand alloc] init];
    return self;
}

@end

static void coroutine_guard_and_common_coverage(void)
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

    [AsyncRuntimeTestSupport assertCondition: ([[Coroutine describeStatus: CoroutineStatus_READY] isEqual: @"READY"])
                                     message: (@"Coroutine should describe READY status explicitly")];
    [AsyncRuntimeTestSupport assertCondition: ([[Coroutine describeStatus: CoroutineStatus_RUNNING] isEqual: @"RUNNING"])
                                     message: (@"Coroutine should describe RUNNING status explicitly")];
    [AsyncRuntimeTestSupport assertCondition: ([[Coroutine describeStatus: CoroutineStatus_SUSPENDED] isEqual: @"SUSPENDED"])
                                     message: (@"Coroutine should describe SUSPENDED status explicitly")];
    [AsyncRuntimeTestSupport assertCondition: ([[Coroutine describeStatus: CoroutineStatus_DEAD] isEqual: @"DEAD"])
                                     message: (@"Coroutine should describe DEAD status explicitly")];
    [AsyncRuntimeTestSupport assertCondition: ([rootCoroutine.description isEqual: rootCoroutine.describe])
                                     message: (@"Coroutine.description should delegate to -describe")];
    [AsyncRuntimeTestSupport assertCondition: ([rootCoroutine.describe containsString: @"RUNNING"])
                                     message: (@"Root coroutine descriptions should include the running state")];

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

    [AsyncRuntimeTestSupport assertCondition: (caughtMissingYieldCaller)
                                     message: (@"Root coroutine yield should report a missing caller")];
    [AsyncRuntimeTestSupport assertCondition: (caughtMissingReturnCaller)
                                     message: (@"Root coroutine return should report a missing caller")];
    [AsyncRuntimeTestSupport assertCondition: (caughtReadyYield)
                                     message: (@"Yielding from a ready coroutine should fail the READY->SUSPENDED transition")];
    [AsyncRuntimeTestSupport assertCondition: (caughtReadyReturn)
                                     message: (@"Returning from a ready coroutine should fail the READY->DEAD transition")];
    [AsyncRuntimeTestSupport assertCondition: (caughtRunningResume)
                                     message: (@"Resuming the running root coroutine should fail the RUNNING->RUNNING transition")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDeadResume)
                                     message: (@"Resuming a dead coroutine should fail the DEAD->RUNNING transition")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilEnumeration)
                                     message: (@"Fast enumeration should reject nil yields")];
    [AsyncRuntimeTestSupport assertCondition: (caughtNilBlock)
                                     message: (@"Coroutines should reject nil blocks defensively")];
    [AsyncRuntimeTestSupport assertCondition: (caughtZeroStack)
                                     message: (@"Coroutines should reject a zero stack size")];

    [AsyncRuntimeTestSupport assertCondition: ([exception.description containsString: @"CoroutineException"])
                                     message: (@"CoroutineException should describe the wrapped coroutine")];
    [AsyncRuntimeTestSupport assertCondition: ([stateException.description containsString: @"RUNNING"])
                                     message: (@"CoroutineStateTransitionFailedException should describe both states")];
    [AsyncRuntimeTestSupport assertCondition: ([missingCallerException.description containsString: @"cannot yield"])
                                     message: (@"CoroutineMissingCallerException should describe the rejected operation")];
    [AsyncRuntimeTestSupport assertCondition: ([stackExceptionNegative.description containsString: @"mco_resume"])
                                     message: (@"Negative stack setup errors should still produce a description")];
    [AsyncRuntimeTestSupport assertCondition: ([stackExceptionPositive.description containsString: @"mco_create"])
                                     message: (@"Errno-based stack setup errors should still produce a description")];

    [AsyncRuntimeTestSupport assertCondition: (NamespaceClass.self == NamespaceClass.class)
                                     message: (@"NamespaceClass should return its class from +self")];
    [AsyncRuntimeTestSupport assertCondition: ([NamespaceClass class] == NamespaceClass.class)
                                     message: (@"NamespaceClass +class should mirror Objective-C class lookup")];

}

static void argument_parser_internal_helpers(void)
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

    [AsyncRuntimeTestSupport assertCondition: ([[CLINameTransform kebabCaseForString: @"foo_barBaz2Qux"] isEqual: @"foo-bar-baz2-qux"])
                                     message: (@"CLINameTransform should convert underscores and camel-case into kebab-case")];
    [AsyncRuntimeTestSupport assertCondition: ([[CLINameTransform upperValueNameForPropertyName: @"cachePath"] isEqual: @"CACHE-PATH"])
                                     message: (@"CLINameTransform should derive upper-cased value labels from property names")];
    [AsyncRuntimeTestSupport assertCondition: ([[CLINameTransform className: Nil] isEqual: @"<unknown>"])
                                     message: (@"CLINameTransform should report unknown when the value class is missing")];
    [AsyncRuntimeTestSupport assertCondition: ([[CLINameTransform shortNameString: 'z'] isEqual: @"z"])
                                     message: (@"CLINameTransform should render single-character short options as strings")];

    [AsyncRuntimeTestSupport assertCondition: (optionalPositional.isPositional and not optionalPositional.isRequired)
                                     message: (@"Resolved optional positionals should report their positional and required state")];
    [AsyncRuntimeTestSupport assertCondition: ([optionalPositional.usageLabel isEqual: @"[<INPUT-VALUE>]"])
                                     message: (@"Optional positional usage labels should render with brackets")];
    [AsyncRuntimeTestSupport assertCondition: ([optionalPositional.helpSyntax isEqual: @"[<INPUT-VALUE>]"])
                                     message: (@"Optional positional help syntax should mirror the usage label")];
    [AsyncRuntimeTestSupport assertCondition: (longOnlyFlag.isFlag)
                                     message: (@"Resolved flags should report flag kind")];
    [AsyncRuntimeTestSupport assertCondition: ([longOnlyFlag.helpSyntax isEqual: @"--dry-run"])
                                     message: (@"Long-only flags should omit the short-option prefix in help text")];
    [AsyncRuntimeTestSupport assertCondition: ([longOnlyOption.helpSyntax isEqual: @"--output <DEST>"])
                                     message: (@"Long-only named options should include their value label in help text")];
    [AsyncRuntimeTestSupport assertCondition: ([fallbackParser.helpText containsString: @"--mystery <THING>"])
                                     message: (@"Schema building should infer CLIOption classes from backing ivars when the property type is plain id")];

    [AsyncRuntimeTestSupport assertCondition: ([[(CLIOption<OFString *> *)fallbackCommand.mysteryOption value] isEqual: @"shadow"])
                                     message: (@"Parser fallback properties should still bind parsed values")];
    [AsyncRuntimeTestSupport assertCondition: ([(CLIOption<OFString *> *)fallbackCommand.mysteryOption hasValue])
                                     message: (@"Fallback CLIOption properties should report values after parsing")];

    [AsyncRuntimeTestSupport assertCondition: ([(OFString *)[CLIValueCodec parseToken: @"hello" forValueClass: OFString.class] isEqual: @"hello"])
                                     message: (@"CLIValueCodec should parse OFString values by copying the token")];
    [AsyncRuntimeTestSupport assertCondition: ([[(OFNumber *)[CLIValueCodec parseToken: @"42" forValueClass: OFNumber.class] stringValue] isEqual: @"42"])
                                     message: (@"CLIValueCodec should parse unsigned numbers")];
    [AsyncRuntimeTestSupport assertCondition: (((OFNumber *)[CLIValueCodec parseToken: @"-7" forValueClass: OFNumber.class]).longLongValue == -7)
                                     message: (@"CLIValueCodec should parse signed numbers")];
    [AsyncRuntimeTestSupport assertCondition: (((OFNumber *)[CLIValueCodec parseToken: @"6.25e1" forValueClass: OFNumber.class]).doubleValue == 62.5)
                                     message: (@"CLIValueCodec should parse floating-point numbers with exponents")];
    [AsyncRuntimeTestSupport assertCondition: ([customParsed isKindOfClass: ParserCustomParsedValue.class]
        and [((ParserCustomParsedValue *)customParsed).rawValue isEqual: @"DEMO"])
                                     message: (@"CLIValueCodec should use +cliParseValue: when available")];
    [AsyncRuntimeTestSupport assertCondition: ([stringConstructed isKindOfClass: ParserStringConstructedValue.class]
        and [((ParserStringConstructedValue *)stringConstructed).rawValue isEqual: @"hello"])
                                     message: (@"CLIValueCodec should fall back to -initWithString: when available")];

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
    [AsyncRuntimeTestSupport assertCondition: (stringOption.boolValue)
                                     message: (@"CLIOption.boolValue should treat non-number parsed values as truthy")];
    [AsyncRuntimeTestSupport assertCondition: ([[stringOption valueOr: @"fallback"] isEqual: @"value"])
                                     message: (@"CLIOption.valueOr: should return the parsed value when present")];
    [stringOption cli_reset];
    [AsyncRuntimeTestSupport assertCondition: ([[stringOption valueOr: @"fallback"] isEqual: @"fallback"])
                                     message: (@"CLIOption.valueOr: should use the fallback when unset")];

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

    [AsyncRuntimeTestSupport assertCondition: (caughtUnknownValueClass)
                                     message: (@"CLIValueCodec should reject unknown parsing targets")];
    [AsyncRuntimeTestSupport assertCondition: (caughtMissingValueClass)
                                     message: (@"CLIValueCodec should reject missing value classes")];
    [AsyncRuntimeTestSupport assertCondition: (caughtInvalidNumber)
                                     message: (@"CLIValueCodec should reject malformed numeric tokens")];
    [AsyncRuntimeTestSupport assertCondition: (caughtMissingOptionValue)
                                     message: (@"CLIOption.value should reject unset options without defaults")];
    [AsyncRuntimeTestSupport assertCondition: (caughtParserInit)
                                     message: (@"ArgumentParser should reject non-CLICommand roots")];
}

static void argument_parser_error_branches(void)
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
    [AsyncRuntimeTestSupport assertCondition: (parsed.count.value.longLongValue == 42)
                                     message: (@"Short option clusters should allow attached values for the first non-flag option")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.force.boolValue)
                                     message: (@"Short flag clusters should set the flag before consuming the value option")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.source.value isEqual: @"source.txt"])
                                     message: (@"Required positionals should still bind after clustered short options")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.literal.value isEqual: @"-literal"])
                                     message: (@"The '--' token should disable subsequent option parsing")];

    parsed = [parser parseArguments: @[@"--count=9", @"serve", @"tail"]];
    [AsyncRuntimeTestSupport assertCondition: (parsed.count.value.longLongValue == 9)
                                     message: (@"Long options should accept an explicit '=value' form")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.source.value isEqual: @"serve"])
                                     message: (@"Subcommand names should remain positionals while required positionals are still missing")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.literal.value isEqual: @"tail"])
                                     message: (@"Optional positionals should bind once required positionals are satisfied")];
    [AsyncRuntimeTestSupport assertCondition: ([parser.helpText containsString: @"Commands:"])
                                     message: (@"Help text should still render command sections when entries have no help text")];

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

    [AsyncRuntimeTestSupport assertCondition: (caughtHelp)
                                     message: (@"-h should throw a help exception with rendered usage text")];
    [AsyncRuntimeTestSupport assertCondition: (caughtUnknownOption)
                                     message: (@"Unknown long options should report a usage error")];
    [AsyncRuntimeTestSupport assertCondition: (caughtFlagValue)
                                     message: (@"Flags should reject explicit long-form values")];
    [AsyncRuntimeTestSupport assertCondition: (caughtLongValueRequired)
                                     message: (@"Named long options should require a following value when one is missing")];
    [AsyncRuntimeTestSupport assertCondition: (caughtShortUnknown)
                                     message: (@"Unknown short options should report a usage error")];
    [AsyncRuntimeTestSupport assertCondition: (caughtShortValueRequired)
                                     message: (@"Short named options should require a following value when the cluster ends")];
    [AsyncRuntimeTestSupport assertCondition: (caughtMissingRequiredOption)
                                     message: (@"Parsing should fail when a required named option is omitted")];
    [AsyncRuntimeTestSupport assertCondition: (caughtUnknownCommand)
                                     message: (@"Unexpected subcommand tokens should report an unknown command")];
    [AsyncRuntimeTestSupport assertCondition: (caughtUnexpectedArgument)
                                     message: (@"Commands without subcommands should report stray arguments as unexpected")];
    [AsyncRuntimeTestSupport assertCondition: (caughtInvalidParsedValue)
                                     message: (@"Value codec failures should be wrapped as usage errors with help text")];
}

static void argument_parser_schema_validation(void)
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

    [AsyncRuntimeTestSupport assertCondition: ([plainException.description isEqual: @"plain"])
                                     message: (@"ArgumentParserException should return its bare message when no usage is attached")];
    [AsyncRuntimeTestSupport assertCondition: ([helpException.description isEqual: @"Usage: demo"])
                                     message: (@"ArgumentParserHelpException should prefer usage text in its description")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDuplicateLong)
                                     message: (@"Schema introspection should reject duplicate long option names")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDuplicateShort)
                                     message: (@"Schema introspection should reject duplicate short option names")];
    [AsyncRuntimeTestSupport assertCondition: (caughtDuplicateSubcommand)
                                     message: (@"Schema introspection should reject duplicate subcommand names")];
}

ASYNC_RUNTIME_SYNC_TEST(coroutine_guard_and_common_coverage)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_internal_helpers)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_error_branches)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_schema_validation)

#pragma clang assume_nonnull end
