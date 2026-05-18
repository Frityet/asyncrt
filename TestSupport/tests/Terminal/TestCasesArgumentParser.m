#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/Terminal/AsyncArgumentParser.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ParserServeCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *root;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *port;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *host;

@end

@implementation ParserServeCommand

- (instancetype)init
{
    self = [super init];
    _root = [[AsyncCLIOption positional: OFString.class]
        withHelp: @"Directory to serve"];
    _port = [[[[AsyncCLIOption optional: OFNumber.class]
        withShortName: 'p']
        withHelp: @"Port to listen on"]
        withDefaultValue: [OFNumber numberWithUnsignedShort: 8080]];
    _host = [[[AsyncCLIOption optional: OFString.class]
        withShortName: 'H']
        withHelp: @"Host to bind to"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parser-serve-command";
}

+ (OFString *)cliCommandDescription
{
    return @"Serve a directory";
}

@end

[[subclassing_restricted]]
@interface ParserRootCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *verbose;
@property(readonly, nonatomic) AsyncCLIOption<OFIRI *> *config;
@property(readonly, nonatomic) ParserServeCommand *serve;

@end

@implementation ParserRootCommand

- (instancetype)init
{
    self = [super init];
    _verbose = [[AsyncCLIOption.flag withShortName: 'v'] withHelp: @"Enable verbose logging"];
    _config = [[[AsyncCLIOption optional: OFIRI.class] withShortName: 'c'] withHelp: @"Config IRI"];
    _serve = [[ParserServeCommand alloc] init];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"demo";
}

+ (OFString *)cliCommandDescription
{
    return @"Demo command tree";
}

@end

[[subclassing_restricted]]
@interface ParserPositionalCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *input;

@end

@implementation ParserPositionalCommand

- (instancetype)init
{
    self = [super init];
    _input = [[AsyncCLIOption positional: OFString.class] withHelp: @"Input path"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"copy";
}

@end

[[subclassing_restricted]]
@interface ParserInitializationCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *name;

@end

@implementation ParserInitializationCommand

+ (OFString *)cliCommandName
{
    return @"broken";
}

@end

[[subclassing_restricted]]
@interface ParserNumericCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *whole;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *negative;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *decimal;

@end

@implementation ParserNumericCommand

- (instancetype)init
{
    self = [super init];
    _whole = [[AsyncCLIOption optional: OFNumber.class] withLongName: @"whole"];
    _negative = [[AsyncCLIOption optional: OFNumber.class] withLongName: @"negative"];
    _decimal = [[AsyncCLIOption optional: OFNumber.class] withLongName: @"decimal"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"numbers";
}

@end

[[subclassing_restricted]]
@interface ParserParsableValue : OFObject<AsyncCLIValueParsable>

@property(readonly, nonatomic) OFString *token;

@end

@implementation ParserParsableValue

- (instancetype)initWithToken: (OFString *)token
{
    self = [super init];
    _token = [token copy];
    return self;
}

+ (instancetype)cliParseValue: (OFString *)value
{
    return [[self alloc] initWithToken: value];
}

@end

[[subclassing_restricted]]
@interface ParserParsableCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<ParserParsableValue *> *parsed;

@end

@implementation ParserParsableCommand

- (instancetype)init
{
    self = [super init];
    _parsed = [[AsyncCLIOption optional: ParserParsableValue.class] withLongName: @"parsed"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parsable";
}

@end

[[subclassing_restricted]]
@interface ParserLiteralCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *first;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *second;

@end

@implementation ParserLiteralCommand

- (instancetype)init
{
    self = [super init];
    _first = [[AsyncCLIOption positional: OFString.class] withHelp: @"First positional value"];
    _second = [[AsyncCLIOption optionalPositional: OFString.class] withHelp: @"Second positional value"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"literal";
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
    _first = [[AsyncCLIOption optional: OFString.class] withLongName: @"shared"];
    _second = [[AsyncCLIOption optional: OFString.class] withLongName: @"shared"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"duplicate-long";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateSubcommandCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) ParserServeCommand *serveCommand;
@property(readonly, nonatomic) ParserServeCommand *serve_command;

@end

@implementation ParserDuplicateSubcommandCommand

- (instancetype)init
{
    self = [super init];
    _serveCommand = [[ParserServeCommand alloc] init];
    _serve_command = [[ParserServeCommand alloc] init];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"duplicate-subcommand";
}

@end

[[subclassing_restricted]]
@interface ParserRequiredOptionCommand : OFObject<AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *token;

@end

@implementation ParserRequiredOptionCommand

- (instancetype)init
{
    self = [super init];
    _token = [[[AsyncCLIOption required: OFString.class] withLongName: @"token"] withValueName: @"NAME"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"required-option";
}

@end

[[subclassing_restricted]]
@interface ParserIvarMetadataCommand : OFObject<AsyncCLICommand>
{
@private
    AsyncCLIOption<OFString *> *_payload;
}

@property(readonly, nonatomic) id payload;

@end

@implementation ParserIvarMetadataCommand

+ (OFString *)cliCommandName
{
    return @"ivar-metadata";
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeArgumentParserTests : OTTestCase @end

@implementation AsyncRuntimeArgumentParserTests

- (void)test_argument_parser_binds_nested_command_instances
{
    auto root = [[ParserRootCommand alloc] init];
    ParserServeCommand *expectedServeInstance = root.serve;
    auto parser = [[AsyncArgumentParser<ParserRootCommand *> alloc] initWithCommand: root];

    ParserRootCommand *parsed = [parser parseArguments: [OFArray arrayWithObjects:
        @"-v",
        @"--config", @"https://example.com/config.json",
        @"serve",
        @"./public",
        @"-H", @"127.0.0.1",
        nil]];

    OTAssert((parsed == root), @"AsyncArgumentParser should return the same root instance it parsed into");
    OTAssert((parsed.verbose.boolValue), @"AsyncCLIOption flag properties should bind automatically");
    OTAssert((parsed.config.hasValue), @"AsyncCLIOption object options should report a value when bound");
    OTAssert(([parsed.config.value.string isEqual: @"https://example.com/config.json"]), @"Object options should parse via initWithString when appropriate");
    OTAssert((parsed.serve == expectedServeInstance), @"The parser should reuse an existing readonly subcommand instance");
    OTAssert(([parsed.serve.root.value isEqual: @"./public"]), @"Positional AsyncCLIOption properties should bind into the nested command instance");
    OTAssert((parsed.serve.port.value.unsignedShortValue == 8080), @"Existing default values on AsyncCLIOption instances should be preserved when the user does not override them");
    OTAssert((parsed.serve.host.hasValue), @"Optional AsyncCLIOption values should report when they were supplied");
    OTAssert(([parsed.serve.host.value isEqual: @"127.0.0.1"]), @"Short options should bind into AsyncCLIOption object values");
}

- (void)test_argument_parser_renders_help_text
{
    auto parser = [[AsyncArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    OFString *helpText = parser.helpText;

    OTAssert(([helpText containsString: @"Usage: demo [options] [command]"]), @"helpText should include a usage line for the root command");
    OTAssert(([helpText containsString: @"-c, --config <CONFIG>"]), @"helpText should include named options and their value placeholders");
    OTAssert(([helpText containsString: @"Commands:"]), @"helpText should render a commands section when subcommands exist");
    OTAssert(([helpText containsString: @"serve"]), @"helpText should list the nested subcommand name based on the property name");
}

- (void)test_argument_parser_reports_missing_required_positional
{
    auto parser = [[AsyncArgumentParser<ParserPositionalCommand *> alloc]
        initWithCommand: [[ParserPositionalCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)[parser parseArguments: [OFArray array]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Missing required argument <INPUT>"]), @"The parser should report missing required positional AsyncCLIOption values using the generated usage label");
    }

    OTAssert((caughtException), @"Parsing should fail when a required positional argument is omitted");
}

- (void)test_argument_parser_requires_initialized_cli_nodes
{
    auto parser = [[AsyncArgumentParser<ParserInitializationCommand *> alloc]
        initWithCommand: [[ParserInitializationCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"must be initialized in -init"]), @"The parser should require readonly AsyncCLIOption properties to be initialized so their runtime metadata is available");
    }

    OTAssert((caughtException), @"Schema building should fail for uninitialized AsyncCLIOption properties");
}

- (void)test_argument_parser_supports_equals_style_long_values_and_short_clusters
{
    auto parser = [[AsyncArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    ParserRootCommand *parsed = [parser parseArguments: [OFArray arrayWithObjects:
        @"-vchttps://example.com/config.json",
        @"serve",
        @"./public",
        @"-H127.0.0.1",
        nil]];

    OTAssert((parsed.verbose.boolValue), @"Short option clusters should still set flag options");
    OTAssert((parsed.config.hasValue), @"Long options should accept inline values using =");
    OTAssert(([parsed.config.value.string isEqual: @"https://example.com/config.json"]), @"Inline long-option values should parse through the configured value class");
    OTAssert((parsed.serve.root.hasValue), @"Nested subcommands should still bind their required positional values");
    OTAssert(([parsed.serve.root.value isEqual: @"./public"]), @"Nested subcommands should preserve positional values");
    OTAssert((parsed.serve.host.hasValue), @"Nested short-option clusters should bind values on the subcommand");
    OTAssert(([parsed.serve.host.value isEqual: @"127.0.0.1"]), @"Attached short-option values should be consumed from the same token");
}

- (void)test_argument_parser_respects_end_of_options_and_optional_positionals
{
    auto parser = [[AsyncArgumentParser<ParserLiteralCommand *> alloc] initWithCommand: [[ParserLiteralCommand alloc] init]];
    ParserLiteralCommand *parsed = [parser parseArguments: [OFArray arrayWithObjects:
        @"alpha",
        @"--",
        @"--help",
        nil]];

    OTAssert(([parsed.first.value isEqual: @"alpha"]), @"The first required positional should bind before the end-of-options marker");
    OTAssert((parsed.second.hasValue), @"Optional positional options should accept values after --");
    OTAssert(([parsed.second.value isEqual: @"--help"]), @"The end-of-options marker should preserve subsequent tokens as literal positional values");
}

- (void)test_argument_parser_reports_help_and_option_errors
{
    auto parser = [[AsyncArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    bool caughtHelp = false;
    bool caughtFlagValueError = false;
    bool caughtMissingValueError = false;
    bool caughtUnknownShortOption = false;

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"--help"]];
    } @catch (AsyncArgumentParserHelpException *exception) {
        caughtHelp = true;
        OTAssert(([exception.description containsString: @"Usage: demo [options] [command]"]), @"Help requests should surface the generated help text");
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"--verbose=1"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtFlagValueError = true;
        OTAssert(([exception.description containsString: @"Flag '--verbose' does not take a value"]), @"Flags should reject inline values");
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"--config"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtMissingValueError = true;
        OTAssert(([exception.description containsString: @"Option '--config' requires a value"]), @"Long options should report when their value is missing");
    }

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"-z"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtUnknownShortOption = true;
        OTAssert(([exception.description containsString: @"Unknown option '-z'"]), @"Unknown short options should be rejected");
    }

    OTAssert((caughtHelp), @"The parser should surface help requests");
    OTAssert((caughtFlagValueError), @"The parser should reject flag values");
    OTAssert((caughtMissingValueError), @"The parser should reject missing long-option values");
    OTAssert((caughtUnknownShortOption), @"The parser should reject unknown short options");
}

- (void)test_cli_option_value_or_returns_fallback_when_unset
{
    auto option = [AsyncCLIOption optional: OFString.class];
    auto fallback = @"fallback";

    OTAssert((not option.hasValue), @"A fresh optional AsyncCLIOption should start without a value");
    OTAssert(([option valueOr: fallback] == fallback), @"AsyncCLIOption.valueOr should return the fallback when no parsed or default value is present");
}

- (void)test_argument_parser_parses_numeric_variants_and_reports_invalid_numbers
{
    auto parser = [[AsyncArgumentParser<ParserNumericCommand *> alloc] initWithCommand: [[ParserNumericCommand alloc] init]];
    ParserNumericCommand *parsed = [parser parseArguments: [OFArray arrayWithObjects:
        @"--whole=42",
        @"--negative=-2",
        @"--decimal=1.5",
        nil]];
    bool caughtInvalidNumber = false;

    OTAssert((parsed.whole.hasValue), @"Unsigned numeric tokens should parse into OFNumber values");
    OTAssert((parsed.whole.value.unsignedLongLongValue == 42), @"Unsigned numeric tokens should round-trip exactly");
    OTAssert((parsed.negative.hasValue), @"Negative numeric tokens should parse into OFNumber values");
    OTAssert((parsed.negative.value.longLongValue == -2), @"Negative numeric tokens should round-trip exactly");
    OTAssert((parsed.decimal.hasValue), @"Floating-point numeric tokens should parse into OFNumber values");
    OTAssert((parsed.decimal.value.doubleValue == 1.5), @"Floating-point numeric tokens should round-trip exactly");

    @try {
        (void)[parser parseArguments: [OFArray arrayWithObject: @"--whole=42x"]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtInvalidNumber = true;
        OTAssert(([exception.description containsString: @"Invalid OFNumber value '42x'"]), @"Invalid numbers should be reported with their token");
    }

    OTAssert((caughtInvalidNumber), @"Invalid numeric tokens should fail parsing");
}

- (void)test_argument_parser_uses_custom_cli_value_parsing
{
    auto parser = [[AsyncArgumentParser<ParserParsableCommand *> alloc] initWithCommand: [[ParserParsableCommand alloc] init]];
    ParserParsableCommand *parsed = [parser parseArguments: [OFArray arrayWithObjects: @"--parsed", @"token-value", nil]];

    OTAssert((parsed.parsed.hasValue), @"Types that implement AsyncCLIValueParsable should parse successfully");
    OTAssert(([parsed.parsed.value.token isEqual: @"token-value"]), @"Custom AsyncCLIValueParsable types should receive the raw token");
}

- (void)test_argument_parser_rejects_duplicate_option_names
{
    auto parser = [[AsyncArgumentParser<ParserDuplicateLongCommand *> alloc] initWithCommand: [[ParserDuplicateLongCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Duplicate option name '--shared'"]), @"Duplicate long option names should be rejected");
    }

    OTAssert((caughtException), @"Schema building should fail when two options share the same long name");
}

- (void)test_argument_parser_rejects_duplicate_subcommand_names
{
    auto parser = [[AsyncArgumentParser<ParserDuplicateSubcommandCommand *> alloc] initWithCommand: [[ParserDuplicateSubcommandCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Duplicate subcommand name 'serve-command'"]), @"Duplicate subcommand names should be rejected");
    }

    OTAssert((caughtException), @"Schema building should fail when two subcommands derive the same command name");
}

- (void)test_argument_parser_reports_missing_required_named_option_and_custom_value_name
{
    auto parser = [[AsyncArgumentParser<ParserRequiredOptionCommand *> alloc] initWithCommand: [[ParserRequiredOptionCommand alloc] init]];
    OFString *helpText = parser.helpText;
    bool caughtException = false;

    OTAssert(([helpText containsString: @"--token <NAME>"]), @"Explicit value names should appear in help text");

    @try {
        (void)[parser parseArguments: [OFArray array]];
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Missing required option '--token'"]), @"Required named options should report missing values");
    }

    OTAssert((caughtException), @"Parsing should fail when a required named option is omitted");
}

- (void)test_argument_parser_infers_metadata_from_ivar_types
{
    auto parser = [[AsyncArgumentParser<ParserIvarMetadataCommand *> alloc] initWithCommand: [[ParserIvarMetadataCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (AsyncArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"must be initialized in -init"]), @"The parser should infer option metadata from ivars when the property type is unannotated");
    }

    OTAssert((caughtException), @"Schema discovery should use ivar metadata for unannotated properties");
}

@end
#pragma clang assume_nonnull end
