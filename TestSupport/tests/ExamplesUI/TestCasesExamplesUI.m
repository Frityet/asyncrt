#import <TestSupport/TestSupport.h>

#import "Booru.h"
#import "Gelbooru.h"
#import "Realbooru.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeAppTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeAppTests

- (void)test_booru_post_and_page_models
{
    auto booru = [[Gelbooru alloc] initWithAPIUserID: @"user"
                                              andKey: @"key"];
    auto post = [[BooruPost alloc] initWithID: @"42"
                                   previewIRI: [OFIRI IRIWithString: @"https://example.test/preview.jpg"]
                                    sampleIRI: [OFIRI IRIWithString: @"https://example.test/sample.jpg"]
                                      fileIRI: [OFIRI IRIWithString: @"https://example.test/file.png"]
                                         tags: [OFArray arrayWithObjects: @"alpha", @"beta", nil]];
    auto page = [[BooruPage alloc] initWithBooru: booru
                                           posts: [OFArray arrayWithObject: post]
                                      pageNumber: 7
                                            next: [Optional none]];

    OTAssert(([post.id isEqual: @"42"]), @"BooruPost should preserve IDs");
    OTAssert(([post.sampleIRI.string isEqual: @"https://example.test/sample.jpg"]), @"BooruPost should preserve sample IRIs");
    OTAssert((post.tags.count == 2), @"BooruPost should preserve tag arrays");
    OTAssert((page.booru == booru), @"BooruPage should keep its source");
    OTAssert((page.posts.count == 1), @"BooruPage should keep posts");
    OTAssert((page.pageNumber == 7), @"BooruPage should keep page numbers");
    OTAssertFalse(page.next.hasValue, @"BooruPage should expose empty next pages");
}

- (void)test_booru_configuration_and_exception_details
{
    auto gelbooru = [[Gelbooru alloc] initWithAPIUserID: @"user"
                                                 andKey: @"key"];
    auto realbooru = [[Realbooru alloc] initWithAPIUserID: @"ignored"
                                                   andKey: @"ignored"];
    auto gelbooruException = [[GelbooruAPIException alloc] initWithReason: @"gelbooru failed"
                                                       underlyingException: nilptr];
    auto realbooruException = [[RealbooruAPIException alloc] initWithReason: @"realbooru failed"
                                                        underlyingException: nilptr];

    OTAssert(([gelbooru.name isEqual: @"Gelbooru"]), @"Gelbooru should expose its service name");
    OTAssert(([gelbooru.baseIRI.string isEqual: @"https://gelbooru.com/"]), @"Gelbooru should use its default base IRI");
    OTAssert((gelbooru.postsPerPage == 100), @"Gelbooru should use its API page size default");
    OTAssert(([realbooru.name isEqual: @"Realbooru"]), @"Realbooru should expose its service name");
    OTAssert(([realbooru.baseIRI.string isEqual: @"https://realbooru.com/"]), @"Realbooru should use its default base IRI");
    OTAssert((realbooru.postsPerPage == 42), @"Realbooru should use its listing page size default");
    OTAssert(([gelbooruException.reason isEqual: @"gelbooru failed"]), @"Gelbooru exceptions should expose reasons");
    OTAssert(([realbooruException.reason isEqual: @"realbooru failed"]), @"Realbooru exceptions should expose reasons");
}

- (void)test_invalid_page_arguments_throw_synchronously
{
    auto gelbooru = [[Gelbooru alloc] initWithAPIUserID: @"user"
                                                 andKey: @"key"];
    auto realbooru = [[Realbooru alloc] initWithAPIUserID: @"ignored"
                                                   andKey: @"ignored"];
    bool gelbooruRejected = false;
    bool realbooruRejected = false;

    @try {
        (void)[gelbooru fetchPage: -1
                forSearchWithTags: [OFArray array]];
    } @catch (OFInvalidArgumentException *) {
        gelbooruRejected = true;
    }

    @try {
        (void)[realbooru fetchPage: -1
                 forSearchWithTags: [OFArray array]];
    } @catch (OFInvalidArgumentException *) {
        realbooruRejected = true;
    }

    OTAssert(gelbooruRejected, @"Gelbooru should reject invalid page numbers");
    OTAssert(realbooruRejected, @"Realbooru should reject invalid page numbers");
}

- (void)test_realbooru_unavailable_tag_listing_returns_async_failure
{
    [self runAsyncBlock: ^{
        auto realbooru = [[Realbooru alloc] initWithAPIUserID: @"ignored"
                                                       andKey: @"ignored"];
        bool caught = false;

        @try {
            (void)[[realbooru fetchAllTags] await];
        } @catch (RealbooruAPIException *exception) {
            caught = [exception.reason containsString: @"tag listing is unavailable"];
        }

        OTAssert(caught, @"Realbooru tag listing should fail with a useful async exception");
    }];
}

- (void)test_http_client_example_support_uses_current_selector
{
    auto client = [AsyncHTTPClient client];
    auto request = [[OFHTTPRequest alloc] initWithIRI: [OFIRI IRIWithString: @"https://example.invalid/"]];
    auto cancellationException = [[AsyncHTTPRequestCancelledException alloc] initWithRequest: request];

    OTAssert(([client respondsToSelector: @selector(performRequest:)]), @"Example support should use the current HTTP client selector");
    OTAssert(([client respondsToSelector: @selector(performRequest:redirects:)]), @"Redirect overload should remain available");
    OTAssert((cancellationException.request == request), @"Cancellation exceptions should expose the original request");
}

@end

#pragma clang assume_nonnull end
