#import "TestSupport.h"
#import "App/ArgumentParser.h"

#pragma clang assume_nonnull begin

@interface ParserServeCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *root;
@property(readonly, nonatomic) CLIOption<OFNumber *> *port;
@property(readonly, nonatomic) CLIOption<OFString *> *host;

@end

@implementation ParserServeCommand

@synthesize root = _root;
@synthesize port = _port;
@synthesize host = _host;

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

@interface ParserRootCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFNumber *> *verbose;
@property(readonly, nonatomic) CLIOption<OFIRI *> *config;
@property(readonly, nonatomic) ParserServeCommand *serve;

@end

@implementation ParserRootCommand

@synthesize verbose = _verbose;
@synthesize config = _config;
@synthesize serve = _serve;

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

@interface ParserPositionalCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *input;

@end

@implementation ParserPositionalCommand

@synthesize input = _input;

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

@interface ParserInitializationCommand : CLICommand

@property(readonly, nonatomic) CLIOption<OFString *> *name;

@end

@implementation ParserInitializationCommand

+ (OFString *)cliCommandName
{
    return @"broken";
}

@end

static void argument_parser_binds_nested_command_instances(void)
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

    [AsyncRuntimeTestSupport assertCondition: (parsed == root)
                                     message: (@"ArgumentParser should return the same root instance it parsed into")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.verbose.boolValue)
                                     message: (@"CLIOption flag properties should bind automatically")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.config.hasValue)
                                     message: (@"CLIOption object options should report a value when bound")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.config.value.string isEqual: @"https://example.com/config.json"])
                                     message: (@"Object options should parse via initWithString when appropriate")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.serve == expectedServeInstance)
                                     message: (@"The parser should reuse an existing readonly subcommand instance")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.serve.root.value isEqual: @"./public"])
                                     message: (@"Positional CLIOption properties should bind into the nested command instance")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.serve.port.value.unsignedShortValue == 8080)
                                     message: (@"Existing default values on CLIOption instances should be preserved when the user does not override them")];
    [AsyncRuntimeTestSupport assertCondition: (parsed.serve.host.hasValue)
                                     message: (@"Optional CLIOption values should report when they were supplied")];
    [AsyncRuntimeTestSupport assertCondition: ([parsed.serve.host.value isEqual: @"127.0.0.1"])
                                     message: (@"Short options should bind into CLIOption object values")];
}

static void argument_parser_renders_help_text(void)
{
    auto parser = [[ArgumentParser<ParserRootCommand *> alloc] initWithCommand: [[ParserRootCommand alloc] init]];
    OFString *helpText = parser.helpText;

    [AsyncRuntimeTestSupport assertCondition: ([helpText containsString: @"Usage: demo [options] [command]"])
                                     message: (@"helpText should include a usage line for the root command")];
    [AsyncRuntimeTestSupport assertCondition: ([helpText containsString: @"-c, --config <CONFIG>"])
                                     message: (@"helpText should include named options and their value placeholders")];
    [AsyncRuntimeTestSupport assertCondition: ([helpText containsString: @"Commands:"])
                                     message: (@"helpText should render a commands section when subcommands exist")];
    [AsyncRuntimeTestSupport assertCondition: ([helpText containsString: @"serve"])
                                     message: (@"helpText should list the nested subcommand name based on the property name")];
}

static void argument_parser_reports_missing_required_positional(void)
{
    auto parser = [[ArgumentParser<ParserPositionalCommand *> alloc]
        initWithCommand: [[ParserPositionalCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)[parser parseArguments: @[]];
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        [AsyncRuntimeTestSupport assertCondition: ([exception.description containsString: @"Missing required argument <INPUT>"])
                                         message: (@"The parser should report missing required positional CLIOption values using the generated usage label")];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException)
                                     message: (@"Parsing should fail when a required positional argument is omitted")];
}

static void argument_parser_requires_initialized_cli_nodes(void)
{
    auto parser = [[ArgumentParser<ParserInitializationCommand *> alloc]
        initWithCommand: [[ParserInitializationCommand alloc] init]];
    bool caughtException = false;

    @try {
        (void)parser.helpText;
    } @catch (ArgumentParserException *exception) {
        caughtException = true;
        [AsyncRuntimeTestSupport assertCondition: ([exception.description containsString: @"must be initialized in -init"])
                                         message: (@"The parser should require readonly CLIOption properties to be initialized so their runtime metadata is available")];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException)
                                     message: (@"Schema building should fail for uninitialized CLIOption properties")];
}

ASYNC_RUNTIME_SYNC_TEST(argument_parser_binds_nested_command_instances)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_renders_help_text)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_reports_missing_required_positional)
ASYNC_RUNTIME_SYNC_TEST(argument_parser_requires_initialized_cli_nodes)

#pragma clang assume_nonnull end
