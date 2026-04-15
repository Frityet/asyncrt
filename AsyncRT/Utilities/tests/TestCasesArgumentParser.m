#import "TestSupport.h"
#import "ArgumentParser.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ParserServeCommand : CLICommand

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

+ (OFString *nillable)cliCommandDescription
{
    return @"Serve a directory";
}

@end

[[subclassing_restricted]]
@interface ParserRootCommand : CLICommand

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

+ (OFString *nillable)cliCommandDescription
{
    return @"Demo command tree";
}

@end

[[subclassing_restricted]]
@interface ParserPositionalCommand : CLICommand

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
@interface ParserInitializationCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *name;

@end

@implementation ParserInitializationCommand

+ (OFString *)cliCommandName
{
    return @"broken";
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

@end
#pragma clang assume_nonnull end
