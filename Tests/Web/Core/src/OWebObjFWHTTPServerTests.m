#import <IO.h>
#import <OWebObjFWHTTPServer.h>
#import <ObjFWTest/ObjFWTest.h>

#include <errno.h>

@interface OWebObjFWHTTPServerTests : OTTestCase

- (OFString *nillable)responseStatusLineFromSocket: (OFTCPSocket *)socket
                                            timeout: (OFTimeInterval)timeout
    [[direct]];

@end

@implementation OWebObjFWHTTPServerTests

- (OFString *nillable)responseStatusLineFromSocket: (OFTCPSocket *)socket
                                            timeout: (OFTimeInterval)timeout
{
    auto deadline = [OFDate dateWithTimeIntervalSinceNow: timeout];
    socket.canBlock = false;

    while (deadline.timeIntervalSinceNow > 0) {
        @try {
            auto line = [socket tryReadLine];
            if (line != nilptr)
                return line;
        } @catch (OFReadFailedException *exception) {
            if (exception.errNo != EAGAIN && exception.errNo != EWOULDBLOCK)
                @throw exception;
        }

        [[OFRunLoop currentRunLoop]
            runMode: OFDefaultRunLoopMode
            beforeDate: [OFDate dateWithTimeIntervalSinceNow: 0.01]];
    }

    return nilptr;
}

- (OFHTTPResponse *)performRequestWithMethod: (OFHTTPRequestMethod)method
                                      path: (OFString *)path
                                      body: (OFData *)body
                                    server: (OWebObjFWHTTPServer *)server
                                    client: (OFHTTPClient *)client
    [[direct]]
{
    auto IRI = [OFIRI IRIWithString: [OFString stringWithFormat:
        @"http://127.0.0.1:%u%@", server.actualPort, path]];
    auto request = [OFHTTPRequest requestWithIRI: IRI];
    request.method = method;
    @try {
        return [[client taskToPerformRequest: request body: body]
            runUntilCompletion];
    } @catch (OFHTTPRequestFailedException *exception) {
        return exception.response;
    }
}

- (void)testRealLoopbackDispatchAndSanitizedFailure
{
    auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 5];
    [router post: @"/echo/:value"
          handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
              return [[OWebHTTPResponse alloc]
                  initWithStatusCode: 201
                              headers: @{
                                  @"Content-Type": @"application/octet-stream",
                                  @"X-Route-Value":
                                      $assert_nonnil(
                                          request.routeParameters[@"value"])
                              }
                                 body: request.body];
          }];
    [router post: @"/boom"
          handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
              (void)request;
              @throw [OWebRouteException exceptionWithReason:
                  @"private handler detail"];
          }];
    [router get: @"/bad-header"
         handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
             (void)request;
             return [[OWebHTTPResponse alloc]
                 initWithStatusCode: 200
                             headers: @{ @"X-Bad": @"one\r\nX-Injected: yes" }
                                body: [OFData data]];
         }];
    [router addRouteWithMethod: OFHTTPRequestMethodHead
                       pattern: @"/head"
                       handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
                           (void)request;
                           const char bytes[] = "hello";
                           return [[OWebHTTPResponse alloc]
                               initWithStatusCode: 200
                                           headers: @{
                                               @"Content-Length": @"999",
                                               @"Connection": @"keep-alive"
                                           }
                                              body: [OFData dataWithItems:
                                                  bytes count: 5]];
                       }];

    auto server = [[OWebObjFWHTTPServer alloc] initWithRouter: router];
    __block size_t reportedExceptions = 0;
    server.exceptionHandler = ^(id exception) {
        (void)exception;
        reportedExceptions++;
    };
    auto client = [[OFHTTPClient alloc] init];

    @try {
        [server start];
        OTAssert(server.isRunning);
        OTAssert(server.actualPort != 0);
        OTAssert(server.configuredPort == 0);
        OTAssertEqualObjects(server.host, @"127.0.0.1");
        OTAssertThrowsSpecific([server start], OFAlreadyOpenException);

        const char fiveBytes[] = "hello";
        auto echo = [self performRequestWithMethod: OFHTTPRequestMethodPost
                                              path: @"/echo/a%20b?unused=1"
                                              body: [OFData dataWithItems:
                                                  fiveBytes count: 5]
                                            server: server
                                            client: client];
        OTAssert(echo.statusCode == 201);
        OTAssertEqualObjects(echo.headers[@"X-Route-Value"], @"a b");
        OTAssertEqualObjects([[echo taskToReadBody] runUntilCompletion],
            [OFData dataWithItems: fiveBytes count: 5]);

        auto head = [self performRequestWithMethod: OFHTTPRequestMethodHead
                                               path: @"/head"
                                               body: [OFData data]
                                             server: server
                                             client: client];
        OTAssert(head.statusCode == 200);
        OTAssertEqualObjects(head.headers[@"Content-Length"], @"5");
        OTAssertEqualObjects(head.headers[@"Connection"], @"close");
        [head close];

        auto badHeader = [self
            performRequestWithMethod: OFHTTPRequestMethodGet
                                 path: @"/bad-header"
                                 body: [OFData data]
                               server: server
                               client: client];
        OTAssert(badHeader.statusCode == 500);
        OTAssert(badHeader.headers[@"X-Injected"] == nilptr);
        OTAssertEqualObjects([[badHeader taskToReadString]
            runUntilCompletion], @"Internal Server Error");

        auto failure = [self
            performRequestWithMethod: OFHTTPRequestMethodPost
                                 path: @"/boom"
                                 body: [OFData data]
                               server: server
                               client: client];
        OTAssert(failure.statusCode == 500);
        auto failureText = [[failure taskToReadString] runUntilCompletion];
        OTAssertEqualObjects(failureText, @"Internal Server Error");
        OTAssert([failureText rangeOfString: @"private"].location == OFNotFound);
        OTAssert(reportedExceptions == 2);
    } @finally {
        [client close];
        [server stop];
    }

    OTAssert(!server.isRunning);
    OTAssert(server.actualPort == 0);
    [server stop];
}

- (void)testCanonicalOversizedContentLengthIsRejectedBeforeBodyRead
{
    auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 5];
    __block size_t dispatchedRequests = 0;
    [router post: @"/echo"
          handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
              (void)request;
              @synchronized (router) {
                  dispatchedRequests++;
              }
              return [OWebHTTPResponse textResponse: @"unexpected"
                                               statusCode: 200];
          }];

    auto server = [[OWebObjFWHTTPServer alloc] initWithRouter: router];
    auto socket = [[OFTCPSocket alloc] init];

    @try {
        [server start];
        [socket connectToHost: @"127.0.0.1" port: server.actualPort];
        [socket writeFormat:
            @"POST /echo HTTP/1.1\r\n"
             @"Host: 127.0.0.1:%u\r\n"
             @"Content-Length: 6\r\n"
             @"Connection: close\r\n\r\n",
            server.actualPort];

        auto statusLine = [self responseStatusLineFromSocket: socket
                                                     timeout: 2];
        OTAssertNotNil(statusLine);
        OTAssert([$assert_nonnil(statusLine) hasPrefix: @"HTTP/1.1 413 "]);
        @synchronized (router) {
            OTAssert(dispatchedRequests == 0);
        }
    } @finally {
        [socket close];
        [server stop];
    }
}

@end
