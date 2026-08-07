#import "AsyncRT/Common/Common.h"
#import "AsyncRT/Core/AsyncExecutor.h"
#import "AsyncRT/Core/AsyncTask.h"
#import "AsyncRT/IO/OFStream+AsyncIO.h"
#import "Schema.h"

#pragma clang assume_nonnull begin

constexpr auto SCHEMA_FILENAME = @"clang.schema.json";
constexpr auto GENERATED_HEADER_FILENAME = @"JSONSchema.h";
constexpr auto PROJECT_DIRECTORY_ENVIRONMENT_KEY = @"ASYNC_RUNTIME_PROJECT_DIR";

@interface OCGen : OFObject<OFApplicationDelegate>

- (OFIRI *)_schemaIRI;

@end

@implementation OCGen

- (AsyncTask *)asyncMain
{
    return [AsyncTask spawn: ^{
        auto schemaStream = [OFFile fileWithPath: self._schemaIRI.path mode: @"r"];
        OFString *schemaString;
        @try {
            schemaString = [[schemaStream taskToReadString] await];
        } @finally {
            [schemaStream close];
        }

        auto schema = [Schema fromJSONObject: schemaString.objectByParsingJSON];
        auto directory = OFApplication.arguments.count > 0 ? [OFIRI fileIRIWithPath: $assert_nonnil(OFApplication.arguments[0]) isDirectory: true] : OFFileManager.defaultManager.currentDirectoryIRI;
        [[schema taskToGenerateInterfacesToDirectory: directory] await];
        $log(@"Generated {} and per-interface sources in {}", GENERATED_HEADER_FILENAME, directory.string);
        [OFApplication terminateWithStatus: 0];

        return nilptr;
    }];
}

- (OFIRI *)_schemaIRI
{
    auto environment = OFApplication.environment;
    if (environment != nilptr) {
        auto projectDirectory = environment[PROJECT_DIRECTORY_ENVIRONMENT_KEY];
        if (projectDirectory != nilptr)
            return [[OFIRI fileIRIWithPath: $as_nonnil(projectDirectory) isDirectory: true]
                IRIByAppendingPathComponent: SCHEMA_FILENAME isDirectory: false];
    }

    return [OFIRI fileIRIWithPath: SCHEMA_FILENAME isDirectory: false];
}

- (void)applicationDidFinishLaunching: _
{
    [AsyncExecutor.current enqueue: ^{
        (void)[self asyncMain];
    }];
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(OCGen);
