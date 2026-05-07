#import "TestSupport.h"
#import "ArgumentParser.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ParserServeCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *root;
@property(readonly, nonatomic) CLIOption<OFNumber *> *port;
@property(readonly, nonatomic) CLIOption<OFString *> *host;

@end

@implementation ParserServeCommand

- (instancetype)init
{
    self = [super init];
    _root = [[CLIOption positional: OFString.class]
        withHelp: @"Directory to serve"];
    _port = [[[[CLIOption optional: OFNumber.class]
        withShortName: 'p']
        withHelp: @"Port to listen on"]
        withDefaultValue: [OFNumber numberWithUnsignedShort: 8080]];
    _host = [[[CLIOption optional: OFString.class]
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
@interface ParserRootCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFNumber *> *verbose;
@property(readonly, nonatomic) CLIOption<OFIRI *> *config;
@property(readonly, nonatomic) ParserServeCommand *serve;

@end

@implementation ParserRootCommand

- (instancetype)init
{
    self = [super init];
    _verbose = [[CLIOption.flag withShortName: 'v'] withHelp: @"Enable verbose logging"];
    _config = [[[CLIOption optional: OFIRI.class] withShortName: 'c'] withHelp: @"Config IRI"];
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
@interface ParserPositionalCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *input;

@end

@implementation ParserPositionalCommand

- (instancetype)init
{
    self = [super init];
    _input = [[CLIOption positional: OFString.class] withHelp: @"Input path"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"copy";
}

@end

[[subclassing_restricted]]
@interface ParserInitializationCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *name;

@end

@implementation ParserInitializationCommand

+ (OFString *)cliCommandName
{
    return @"broken";
}

@end

[[subclassing_restricted]]
@interface ParserNumericCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFNumber *> *whole;
@property(readonly, nonatomic) CLIOption<OFNumber *> *negative;
@property(readonly, nonatomic) CLIOption<OFNumber *> *decimal;

@end

@implementation ParserNumericCommand

- (instancetype)init
{
    self = [super init];
    _whole = [[CLIOption optional: OFNumber.class] withLongName: @"whole"];
    _negative = [[CLIOption optional: OFNumber.class] withLongName: @"negative"];
    _decimal = [[CLIOption optional: OFNumber.class] withLongName: @"decimal"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"numbers";
}

@end

[[subclassing_restricted]]
@interface ParserParsableValue : OFObject<CLIValueParsable>

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
@interface ParserParsableCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<ParserParsableValue *> *parsed;

@end

@implementation ParserParsableCommand

- (instancetype)init
{
    self = [super init];
    _parsed = [[CLIOption optional: ParserParsableValue.class] withLongName: @"parsed"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"parsable";
}

@end

[[subclassing_restricted]]
@interface ParserLiteralCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *first;
@property(readonly, nonatomic) CLIOption<OFString *> *second;

@end

@implementation ParserLiteralCommand

- (instancetype)init
{
    self = [super init];
    _first = [[CLIOption positional: OFString.class] withHelp: @"First positional value"];
    _second = [[CLIOption optionalPositional: OFString.class] withHelp: @"Second positional value"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"literal";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateLongCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *first;
@property(readonly, nonatomic) CLIOption<OFString *> *second;

@end

@implementation ParserDuplicateLongCommand

- (instancetype)init
{
    self = [super init];
    _first = [[CLIOption optional: OFString.class] withLongName: @"shared"];
    _second = [[CLIOption optional: OFString.class] withLongName: @"shared"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"duplicate-long";
}

@end

[[subclassing_restricted]]
@interface ParserDuplicateSubcommandCommand : OFObject<CLICommand>

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
@interface ParserRequiredOptionCommand : OFObject<CLICommand>

@property(readonly, nonatomic) CLIOption<OFString *> *token;

@end

@implementation ParserRequiredOptionCommand

- (instancetype)init
{
    self = [super init];
    _token = [[[CLIOption required: OFString.class] withLongName: @"token"] withValueName: @"NAME"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"required-option";
}

@end

[[subclassing_restricted]]
@interface ParserIvarMetadataCommand : OFObject<CLICommand>
{
@private
    CLIOption<OFString *> *_payload;
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
    auto parser = [[ArgumentParser<ParserRootCommand *> alloc] initWithCommand: root];

    ParserRootCommand *parsed = [parser parseArguments: @[
        @"-v",
        @"--config", @"https://example.com/config.json",
        @"serve",
        @"./public",
        @"-H", @"127.0.0.1"
    ]];

    OTAssert((parsed == root), @"ArgumentParser should return the same root instance it parsed into");
    OTAssert((parsed.verbose.boolValue), @"CLIOption flag properties should bind automatically");
    OTAssert((parsed.config.hasValue), @"CLIOption object options should report a value when bound");
    OTAssert(([parsed.config.value.string isEqual: @"https://example.com/config.json"]), @"Object options should parse via initWithString when appropriate");
    OTAssert((parsed.serve == expectedServeInstance), @"The parser should reuse an existing readonly subcommand instance");
    OTAssert(([parsed.serve.root.value isEqual: @"./public"]), @"Positional CLIOption properties should bind into the nested command instance");
    OTAssert((parsed.serve.port.value.unsignedShortValue == 8080), @"Existing default values on CLIOption instances should be preserved when the user does not override them");
    OTAssert((parsed.serve.host.hasValue), @"Optional CLIOption values should report when they were supplied");
    OTAssert(([parsed.serve.host.value isEqual: @"127.0.0.1"]), @"Short options should bind into CLIOption object values");
}

- (void)test_argument_parser_renders_help_text
{
    auto parser = [[ArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    OFString *helpText = parser.helpText;

    OTAssert(([helpText containsString: @"Usage: demo [options] [command]"]), @"helpText should include a usage line for the root command");
    OTAssert(([helpText containsString: @"-c, --config <CONFIG>"]), @"helpText should include named options and their value placeholders");
    OTAssert(([helpText containsString: @"Commands:"]), @"helpText should render a commands section when subcommands exist");
    OTAssert(([helpText containsString: @"serve"]), @"helpText should list the nested subcommand name based on the property name");
}

- (void)test_argument_parser_reports_missing_required_positional
{
    auto parser = [[ArgumentParser<ParserPositionalCommand *> alloc]
        initWithCommand: [[ParserPositionalCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)[parser parseArguments: @[]];
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Missing required argument <INPUT>"]), @"The parser should report missing required positional CLIOption values using the generated usage label");
    }

    OTAssert((caughtException), @"Parsing should fail when a required positional argument is omitted");
}

- (void)test_argument_parser_requires_initialized_cli_nodes
{
    auto parser = [[ArgumentParser<ParserInitializationCommand *> alloc]
        initWithCommand: [[ParserInitializationCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"must be initialized in -init"]), @"The parser should require readonly CLIOption properties to be initialized so their runtime metadata is available");
    }

    OTAssert((caughtException), @"Schema building should fail for uninitialized CLIOption properties");
}

- (void)test_argument_parser_supports_equals_style_long_values_and_short_clusters
{
    auto parser = [[ArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    ParserRootCommand *parsed = [parser parseArguments: @[
        @"-vchttps://example.com/config.json",
        @"serve",
        @"./public",
        @"-H127.0.0.1"
    ]];

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
    auto parser = [[ArgumentParser<ParserLiteralCommand *> alloc] initWithCommand: [[ParserLiteralCommand alloc] init]];
    ParserLiteralCommand *parsed = [parser parseArguments: @[
        @"alpha",
        @"--",
        @"--help"
    ]];

    OTAssert(([parsed.first.value isEqual: @"alpha"]), @"The first required positional should bind before the end-of-options marker");
    OTAssert((parsed.second.hasValue), @"Optional positional options should accept values after --");
    OTAssert(([parsed.second.value isEqual: @"--help"]), @"The end-of-options marker should preserve subsequent tokens as literal positional values");
}

- (void)test_argument_parser_reports_help_and_option_errors
{
    auto parser = [[ArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    bool caughtHelp = false;
    bool caughtFlagValueError = false;
    bool caughtMissingValueError = false;
    bool caughtUnknownShortOption = false;

    @try {
        (void)[parser parseArguments: @[@"--help"]];
    } @catch (ArgumentParserHelpException *exception) {
        caughtHelp = true;
        OTAssert(([exception.description containsString: @"Usage: demo [options] [command]"]), @"Help requests should surface the generated help text");
    }

    @try {
        (void)[parser parseArguments: @[@"--verbose=1"]];
    } @catch (ArgumentParserException *exception) {
        caughtFlagValueError = true;
        OTAssert(([exception.description containsString: @"Flag '--verbose' does not take a value"]), @"Flags should reject inline values");
    }

    @try {
        (void)[parser parseArguments: @[@"--config"]];
    } @catch (ArgumentParserException *exception) {
        caughtMissingValueError = true;
        OTAssert(([exception.description containsString: @"Option '--config' requires a value"]), @"Long options should report when their value is missing");
    }

    @try {
        (void)[parser parseArguments: @[@"-z"]];
    } @catch (ArgumentParserException *exception) {
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
    auto option = [CLIOption optional: OFString.class];
    auto fallback = @"fallback";

    OTAssert((not option.hasValue), @"A fresh optional CLIOption should start without a value");
    OTAssert(([option valueOr: fallback] == fallback), @"CLIOption.valueOr should return the fallback when no parsed or default value is present");
}

- (void)test_argument_parser_parses_numeric_variants_and_reports_invalid_numbers
{
    auto parser = [[ArgumentParser<ParserNumericCommand *> alloc] initWithCommand: [[ParserNumericCommand alloc] init]];
    ParserNumericCommand *parsed = [parser parseArguments: @[
        @"--whole=42",
        @"--negative=-2",
        @"--decimal=1.5"
    ]];
    bool caughtInvalidNumber = false;

    OTAssert((parsed.whole.hasValue), @"Unsigned numeric tokens should parse into OFNumber values");
    OTAssert((parsed.whole.value.unsignedLongLongValue == 42), @"Unsigned numeric tokens should round-trip exactly");
    OTAssert((parsed.negative.hasValue), @"Negative numeric tokens should parse into OFNumber values");
    OTAssert((parsed.negative.value.longLongValue == -2), @"Negative numeric tokens should round-trip exactly");
    OTAssert((parsed.decimal.hasValue), @"Floating-point numeric tokens should parse into OFNumber values");
    OTAssert((parsed.decimal.value.doubleValue == 1.5), @"Floating-point numeric tokens should round-trip exactly");

    @try {
        (void)[parser parseArguments: @[@"--whole=42x"]];
    } @catch (ArgumentParserException *exception) {
        caughtInvalidNumber = true;
        OTAssert(([exception.description containsString: @"Invalid OFNumber value '42x'"]), @"Invalid numbers should be reported with their token");
    }

    OTAssert((caughtInvalidNumber), @"Invalid numeric tokens should fail parsing");
}

- (void)test_argument_parser_uses_custom_cli_value_parsing
{
    auto parser = [[ArgumentParser<ParserParsableCommand *> alloc] initWithCommand: [[ParserParsableCommand alloc] init]];
    ParserParsableCommand *parsed = [parser parseArguments: @[@"--parsed", @"token-value"]];

    OTAssert((parsed.parsed.hasValue), @"Types that implement CLIValueParsable should parse successfully");
    OTAssert(([parsed.parsed.value.token isEqual: @"token-value"]), @"Custom CLIValueParsable types should receive the raw token");
}

- (void)test_argument_parser_rejects_duplicate_option_names
{
    auto parser = [[ArgumentParser<ParserDuplicateLongCommand *> alloc] initWithCommand: [[ParserDuplicateLongCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Duplicate option name '--shared'"]), @"Duplicate long option names should be rejected");
    }

    OTAssert((caughtException), @"Schema building should fail when two options share the same long name");
}

- (void)test_argument_parser_rejects_duplicate_subcommand_names
{
    auto parser = [[ArgumentParser<ParserDuplicateSubcommandCommand *> alloc] initWithCommand: [[ParserDuplicateSubcommandCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Duplicate subcommand name 'serve-command'"]), @"Duplicate subcommand names should be rejected");
    }

    OTAssert((caughtException), @"Schema building should fail when two subcommands derive the same command name");
}

- (void)test_argument_parser_reports_missing_required_named_option_and_custom_value_name
{
    auto parser = [[ArgumentParser<ParserRequiredOptionCommand *> alloc] initWithCommand: [[ParserRequiredOptionCommand alloc] init]];
    OFString *helpText = parser.helpText;
    bool caughtException = false;

    OTAssert(([helpText containsString: @"--token <NAME>"]), @"Explicit value names should appear in help text");

    @try {
        (void)[parser parseArguments: @[]];
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"Missing required option '--token'"]), @"Required named options should report missing values");
    }

    OTAssert((caughtException), @"Parsing should fail when a required named option is omitted");
}

- (void)test_argument_parser_infers_metadata_from_ivar_types
{
    auto parser = [[ArgumentParser<ParserIvarMetadataCommand *> alloc] initWithCommand: [[ParserIvarMetadataCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        OTAssert(([exception.description containsString: @"must be initialized in -init"]), @"The parser should infer option metadata from ivars when the property type is unannotated");
    }

    OTAssert((caughtException), @"Schema discovery should use ivar metadata for unannotated properties");
}

@end
#pragma clang assume_nonnull end
