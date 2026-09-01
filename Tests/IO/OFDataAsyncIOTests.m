#import <AsyncRT/IO/IO.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncIOHTTPServerDelegate : OFObject <OFHTTPServerDelegate>
@end

@implementation AsyncIOHTTPServerDelegate

- (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)request
        requestBody: (OFStream *nillable)requestBody
           response: (OFHTTPResponse *)response
{
    if ([request.IRI.path isEqual: @"/empty"] && requestBody == nilptr) {
        response.statusCode = 204;
        response.headers = @{ @"Content-Length": @"0" };
        [response close];
        return;
    }

    if (requestBody == nilptr) {
        response.statusCode = 400;
        response.headers = @{ @"Content-Length": @"0" };
        [response close];
        return;
    }

    @try {
        auto body = [requestBody readDataUntilEndOfStream];
        response.statusCode = 200;
        response.headers = @{
            @"Content-Type": @"application/octet-stream",
            @"Content-Length": [OFString stringWithFormat: @"%zu",
                body.count * body.itemSize]
        };
        [response writeData: $assert_nonnil(body)];
        [response close];
    } @catch (OFException *exception) {
        (void)exception;
        @try {
            response.statusCode = 500;
            response.headers = @{ @"Content-Length": @"0" };
            [response close];
        } @catch (OFException *closeException) {
            (void)closeException;
        }
    }
}

@end

@interface OFDataAsyncIOTests : OTTestCase
@end

@implementation OFDataAsyncIOTests

- (void)testTaskToReadDataWithContentsOfFile
{
    auto fileName = [OFString stringWithFormat: @"AsyncRT-OFDataAsyncIO-%@.bin", OFUUID.UUID.UUIDString];
    auto path = [OFFileManager.defaultManager.currentDirectoryPath stringByAppendingPathComponent: fileName];
    const char bytes[] = "async-data";
    auto expected = [OFData dataWithItems: bytes count: sizeof(bytes) - 1];

    @try {
        [expected writeToFile: path];
        auto actual = [[OFData taskToReadDataWithContentsOfFile: path] runUntilCompletion];
        OTAssertEqualObjects(actual, expected, @"async file data read must return exactly the file contents");
    } @finally {
        if ([OFFileManager.defaultManager fileExistsAtPath: path])
            [OFFileManager.defaultManager removeItemAtPath: path];
    }
}

- (void)testTaskToPerformRequestWithBody
{
    auto server = [OFHTTPServer server];
    auto serverDelegate = [[AsyncIOHTTPServerDelegate alloc] init];
    server.host = @"127.0.0.1";
    server.port = 0;
    server.numberOfThreads = 1;
    server.delegate = serverDelegate;
    [server start];

    auto client = [[OFHTTPClient alloc] init];
    auto request = [OFHTTPRequest requestWithIRI: [OFIRI IRIWithString:
        [OFString stringWithFormat: @"http://127.0.0.1:%u/echo", server.port]]];
    request.method = OFHTTPRequestMethodPost;
    request.headers = @{ @"Content-Type": @"application/octet-stream" };

    const char bytes[] = "async-http-body";
    auto expected = [OFData dataWithItems: bytes count: sizeof(bytes) - 1];

    @try {
        auto response = [[client taskToPerformRequest: request body: expected]
            runUntilCompletion];
        OTAssert(response.statusCode == 200,
            @"async HTTP body request must receive a successful response");

        auto actual = [[response taskToReadBody] runUntilCompletion];
        OTAssertEqualObjects(actual, expected,
            @"async HTTP body request must send and receive the complete body");
    } @finally {
        [client close];
        [server stop];
    }
}

- (void)testTaskToPerformRequestWithEmptyBody
{
    auto server = [OFHTTPServer server];
    auto serverDelegate = [[AsyncIOHTTPServerDelegate alloc] init];
    server.host = @"127.0.0.1";
    server.port = 0;
    server.numberOfThreads = 1;
    server.delegate = serverDelegate;
    [server start];

    auto client = [[OFHTTPClient alloc] init];
    auto request = [OFHTTPRequest requestWithIRI: [OFIRI IRIWithString:
        [OFString stringWithFormat: @"http://127.0.0.1:%u/empty", server.port]]];
    request.method = OFHTTPRequestMethodPost;

    @try {
        auto response = [[client taskToPerformRequest: request
                                                  body: [OFData data]]
            runUntilCompletion];
        OTAssert(response.statusCode == 204,
            @"an empty async HTTP body must be treated as no request body");
        auto actual = [[response taskToReadBody] runUntilCompletion];
        OTAssert(actual.count == 0,
            @"the empty-body response must be readable without a reset");
    } @finally {
        [client close];
        [server stop];
    }
}

- (void)testTaskToReadString
{
    auto server = [OFHTTPServer server];
    auto serverDelegate = [[AsyncIOHTTPServerDelegate alloc] init];
    server.host = @"127.0.0.1";
    server.port = 0;
    server.numberOfThreads = 1;
    server.delegate = serverDelegate;
    [server start];

    auto client = [[OFHTTPClient alloc] init];
    auto request = [OFHTTPRequest requestWithIRI: [OFIRI IRIWithString:
        [OFString stringWithFormat: @"http://127.0.0.1:%u/echo", server.port]]];
    request.method = OFHTTPRequestMethodPost;
    request.headers = @{ @"Content-Type": @"text/plain" };

    auto expected = [OFString stringWithUTF8String: "async-http-string"];

    @try {
        auto response = [[client taskToPerformRequest: request
                                                  body: [expected dataWithEncoding: OFStringEncodingUTF8]]
            runUntilCompletion];
        auto actual = [[response taskToReadString] runUntilCompletion];
        OTAssertEqualObjects(actual, expected,
            @"async HTTP response string read must decode the complete body");
    } @finally {
        [client close];
        [server stop];
    }
}

@end

#pragma clang assume_nonnull end
