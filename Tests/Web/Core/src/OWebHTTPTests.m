#import <OWebHTTP.h>
#import <ObjFWTest/ObjFWTest.h>

@interface OWebHTTPTests : OTTestCase
@end

@implementation OWebHTTPTests

- (void)testRouteParametersQueryAndCaseInsensitiveHeaders
{
    auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 64];
    __block bool middlewareRan = false;
    [router useMiddleware: ^OWebHTTPResponse *(OWebHTTPRequest *request,
                                               OWebHTTPNext next) {
        middlewareRan = true;
        return next(request);
    }];
    [router get: @"/memories/:reference"
         handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
             OTAssertEqualObjects(request.routeParameters[@"reference"], @"a b");
             OTAssertEqualObjects([request firstQueryValueForName: @"q"], @"one");
             OTAssertEqualObjects(request.queryParameters[@"q"][1], @"two");
             OTAssertEqualObjects([request headerForName: @"origin"],
                 @"http://127.0.0.1:8080");
             return [OWebHTTPResponse JSONResponse: @{ @"ok": @true }
                                                statusCode: 200];
         }];

    auto request = [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodGet
                  path: @"/memories/a%20b?q=one&q=two"
               headers: @{ @"Origin": @"http://127.0.0.1:8080" }
                  body: [OFData data]];
    auto response = [router dispatchRequest: request];

    OTAssert(middlewareRan);
    OTAssert(response.statusCode == 200);
    OTAssertEqualObjects(response.headers[@"Content-Type"],
        @"application/json; charset=utf-8");
}

- (void)testRejectsAmbiguousPathsAndCapsBodies
{
    auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 2];
    [router post: @"/event/:instance"
          handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
              (void)request;
              return [OWebHTTPResponse responseWithStatusCode: 204];
          }];

    auto oversized = [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodPost
                  path: @"/event/1"
               headers: @{}
                  body: [OFData dataWithItems: "abc" count: 3]];
    OTAssert([router dispatchRequest: oversized].statusCode == 413);

    auto groupedBody = [OFData dataWithItems: "abcd" count: 2 itemSize: 2];
    auto grouped = [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodPost
                  path: @"/event/1"
               headers: @{}
                  body: groupedBody];
    OTAssertEqual(grouped.bodyByteCount, (size_t)4);
    OTAssert([router dispatchRequest: grouped].statusCode == 413);

    auto encodedSlash = [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodPost
                  path: @"/event/a%2Fb"
               headers: @{}
                  body: [OFData data]];
    OTAssert([router dispatchRequest: encodedSlash].statusCode == 404);
}

- (void)testMissingRouteIsDeterministic
{
    auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 32];
    auto request = [[OWebHTTPRequest alloc]
        initWithMethod: OFHTTPRequestMethodGet
                  path: @"/missing"
               headers: @{}
                  body: [OFData data]];
    auto response = [router dispatchRequest: request];
    OTAssert(response.statusCode == 404);
    OTAssertEqualObjects([OFString stringWithData: response.body
                                         encoding: OFStringEncodingUTF8],
        @"Not Found");
}

@end
