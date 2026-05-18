#include <stdlib.h>
#include <string.h>

#import <TestSupport/TestSupport.h>
#import <AsyncRT/Networking/HTTP/AsyncHTTPClient.h>
#import "Booru.h"
#import "Gelbooru.h"
#import "Realbooru.h"
#import <AsyncRT/Application/UI/AsyncUI.h>
#import <AsyncRT/Application/UI/AsyncUIAdvanced.h>
#import <AsyncRT/Application/UI/AsyncUIClaySupport.h>
#import <AsyncRT/Application/UI/Backend/Window/AsyncUIHeadlessWindow.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIApplication+Private.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncUITestApplication : AsyncUIApplication

@property(readonly, nonatomic) bool didStart;
@property(readonly, nonatomic) AsyncTaskGroup *nillable startedTaskGroup;

@end

@implementation AsyncUITestApplication {
    bool _didStart;
    AsyncTaskGroup *nillable _startedTaskGroup;
}

- (id<AsyncUIContent>)rootContent
{
    return [AsyncUIBox withLayout: AsyncUIStackLayout.vertical
                     styledBy: AsyncUIBoxStyle.filled
                  interaction: nilptr
                     children: [OFArray arrayWithObject:
        [AsyncUIText withString: @"Hello, AsyncRT UI!" styledBy: AsyncUITextStyle.body]
    ]];
}

- (AsyncUIWindowConfiguration *nillable)windowConfiguration
{
    auto configuration = AsyncUIWindowConfiguration.defaults;
    configuration.title = @"AsyncRT Scientific Calculator";
    configuration.initialWidth = 1360;
    configuration.initialHeight = 860;
    configuration.isResizable = true;
    configuration.automaticallyResizesToContent = false;
    configuration.scalesWithWindowSize = true;
    configuration.contentScale = 1.0;
    return configuration;
}

- (void)applicationDidStartWithTaskGroup: (AsyncTaskGroup *)taskGroup
{
    _didStart = true;
    _startedTaskGroup = taskGroup;
}

@end

typedef struct AsyncUITestRenderHarness {
    AsyncUITestApplication *application;
    AsyncUIHeadlessWindow *window;
    Clay_Context *nillable context;
    void *nillable memory;
    size_t memorySize;
} AsyncUITestRenderHarness;

static Clay_Dimensions AsyncUITestMeasureText(Clay_StringSlice text,
                                          Clay_TextElementConfig *config,
                                          void *userData)
{
    (void)config;
    (void)userData;
    return (Clay_Dimensions){
        .width = (float)text.length * 8.0f,
        .height = 16.0f
    };
}

static AsyncUITestRenderHarness AsyncUITestRenderHarnessMake(void)
{
    AsyncUITestRenderHarness harness = {0};
    auto configuration = AsyncUIWindowConfiguration.defaults;
    configuration.title = @"App Test";
    configuration.initialSize = [AsyncUI sizeWithWidth: 480 height: 320];
    configuration.isResizable = false;
    configuration.automaticallyResizesToContent = false;
    configuration.scalesWithWindowSize = false;
    configuration.contentScale = 1;

    harness.application = [[AsyncUITestApplication alloc] init];
    harness.window = [[AsyncUIHeadlessWindow alloc] initWithApplication: harness.application configuration: configuration];
    [harness.window openWindow];
    [harness.application _setWindowForTesting: harness.window];

    harness.memorySize = AsyncUIClay.minimumMemorySize;
    harness.memory = malloc(harness.memorySize);
    harness.context = [AsyncUIClay initializeWithMemory: $assert_nonnil(harness.memory)
                                               size: harness.memorySize
                                         dimensions: harness.window.viewportSize];
    AsyncUIClay.currentContext = harness.context;
    Clay_SetMeasureTextFunction(AsyncUITestMeasureText, nilptr);
    return harness;
}

static void AsyncUITestRenderHarnessDestroy(AsyncUITestRenderHarness *harness)
{
    [harness->application _setRootContentForTesting: nilptr];
    [harness->application _setWindowForTesting: nilptr];
    [harness->window closeWindow];
    AsyncUIClay.currentContext = nullptr;
    free(harness->memory);
    harness->memory = nullptr;
    harness->context = nullptr;
}

static Clay_RenderCommandArray AsyncUITestRenderContent(AsyncUITestRenderHarness *harness, id<AsyncUIContent> content)
{
    Clay_RenderCommandArray commands = {0};

    [harness->application _setRootContentForTesting: content];
    for (size_t iteration = 0; iteration < 4; iteration++) {
        (void)[harness->application _consumePendingRenderRequest];
        AsyncUIClay.currentContext = harness->context;
        AsyncUIClay.layoutDimensions = harness->window.viewportSize;
        commands = [harness->application _buildRenderCommandsWithViewportSize: harness->window.viewportSize
                                                                    deltaTime: (1.0f / 60.0f)];

        if (not [harness->application _hasPendingRenderRequest])
            break;
    }

    return commands;
}

static OFString *AsyncUITestStringFromSlice(Clay_StringSlice slice)
{
    char *buffer = calloc((size_t)slice.length + 1, sizeof(char));
    OFString *string;

    memcpy(buffer, slice.chars, (size_t)slice.length);
    string = [[OFString alloc] initWithUTF8String: buffer];
    free(buffer);
    return string;
}

static bool AsyncUITestCommandsContainText(Clay_RenderCommandArray commands, OFString *expectedText)
{
    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

        if (command == nullptr or command->commandType != CLAY_RENDER_COMMAND_TYPE_TEXT)
            continue;
        if ([AsyncUITestStringFromSlice(command->renderData.text.stringContents) containsString: expectedText])
            return true;
    }

    return false;
}

[[subclassing_restricted]]
@interface AsyncRuntimeAppTests : AsyncRuntimeTestCase @end

@interface AsyncRuntimeAppTests ()

- (OFString *nillable)_environmentValueForKey: (OFString *)key [[direct]];
- (bool)_environmentFlagIsEnabled: (OFString *)key [[direct]];

@end

@implementation AsyncRuntimeAppTests

- (OFString *nillable)_environmentValueForKey: (OFString *)key
{
    OFDictionary<OFString *, OFString *> *nillable environment = OFApplication.environment;

    if (environment == nilptr)
        return nilptr;

    return [environment objectForKey: key];
}

- (bool)_environmentFlagIsEnabled: (OFString *)key
{
    OFString *nillable value = [self _environmentValueForKey: key];

    if (value == nilptr)
        return false;

    return ([value isEqual: @"1"] or
            [value caseInsensitiveCompare: @"true"] == OFOrderedSame or
            [value caseInsensitiveCompare: @"yes"] == OFOrderedSame or
            [value caseInsensitiveCompare: @"on"] == OFOrderedSame);
}

- (void)test_booru_post_stores_core_fields
{
    auto post = [[BooruPost alloc] initWithID: @"42"
                                   previewIRI: [OFIRI IRIWithString: @"https://img.example/preview.jpg"]
                                      fileIRI: [OFIRI IRIWithString: @"https://img.example/file.png"]
                                         tags: [OFArray arrayWithObjects: @"alpha", @"beta", nil]];

    OTAssert(([post.id isEqual: @"42"]), @"BooruPost should expose the post ID");
    OTAssert(([post.previewIRI.string isEqual: @"https://img.example/preview.jpg"]), @"BooruPost should expose the preview IRI");
    OTAssert((post.sampleIRI == nilptr), @"BooruPost should allow posts without a sample IRI");
    OTAssert(([post.fileIRI.string isEqual: @"https://img.example/file.png"]), @"BooruPost should expose the file IRI");
    OTAssert((post.tags.count == 2), @"BooruPost should preserve tags");
}

- (void)test_booru_post_stores_sample_iri_when_available
{
    auto post = [[BooruPost alloc] initWithID: @"43"
                                   previewIRI: [OFIRI IRIWithString: @"https://img.example/preview.jpg"]
                                    sampleIRI: [OFIRI IRIWithString: @"https://img.example/sample.jpg"]
                                      fileIRI: [OFIRI IRIWithString: @"https://img.example/file.png"]
                                         tags: [OFArray array]];

    OTAssert(([post.sampleIRI.string isEqual: @"https://img.example/sample.jpg"]),
             @"BooruPost should expose the lower-resolution sample IRI when present");
}

- (void)test_booru_page_stores_posts_and_next_state
{
    auto booru = [[Gelbooru alloc] initWithAPIUserID: @"user" andKey: @"key"];
    auto post = [[BooruPost alloc] initWithID: @"42"
                                   previewIRI: [OFIRI IRIWithString: @"https://img.example/preview.jpg"]
                                      fileIRI: [OFIRI IRIWithString: @"https://img.example/file.png"]
                                         tags: [OFArray arrayWithObject: @"alpha"]];
    auto page = [[BooruPage alloc] initWithBooru: booru
                                           posts: [OFArray arrayWithObject: post]
                                      pageNumber: 3
                                            next: [Optional none]];

    OTAssert((page.booru == booru), @"BooruPage should keep its source booru");
    OTAssert((page.posts.count == 1), @"BooruPage should preserve posts");
    OTAssert((page.pageNumber == 3), @"BooruPage should preserve page number");
    OTAssertFalse(page.next.hasValue, @"BooruPage should expose an empty next state");
}

- (void)test_gelbooru_default_configuration
{
    auto gelbooru = [[Gelbooru alloc] initWithAPIUserID: @"user" andKey: @"key"];

    OTAssert(([gelbooru.name isEqual: @"Gelbooru"]), @"Gelbooru should expose its service name");
    OTAssert(([gelbooru.baseIRI.string isEqual: @"https://gelbooru.com/"]), @"Gelbooru should default to gelbooru.com");
    OTAssert((gelbooru.postsPerPage == 100), @"Gelbooru should default to the DAPI post page size");
}

- (void)test_realbooru_default_configuration
{
    auto realbooru = [[Realbooru alloc] initWithAPIUserID: @"ignored" andKey: @"ignored"];
    auto exception = [[RealbooruAPIException alloc] initWithReason: @"failure"
                                               underlyingException: nilptr];

    OTAssert(([realbooru.name isEqual: @"Realbooru"]), @"Realbooru should expose its service name");
    OTAssert(([realbooru.baseIRI.string isEqual: @"https://realbooru.com/"]), @"Realbooru should default to realbooru.com");
    OTAssert((realbooru.postsPerPage == 42), @"Realbooru should default to the listing page size");
    OTAssert(([exception.reason isEqual: @"failure"]), @"Realbooru API exceptions should expose their reason publicly");
}

- (void)test_http_client_bridge_public_surface
{
    auto client = [AsyncHTTPClient client];
    auto request = [[OFHTTPRequest alloc] initWithIRI: [OFIRI IRIWithString: @"https://example.invalid/"]];
    auto clientException = [[AsyncHTTPClientException alloc] initWithReason: @"failure"];
    auto cancellationException = [[AsyncHTTPRequestCancelledException alloc] initWithRequest: request];

    OTAssert(([client respondsToSelector: @selector(performRequest:onScheduler:)]),
             @"AsyncHTTPClient should expose the async request API");
    OTAssert(([clientException.reason isEqual: @"failure"]),
             @"AsyncHTTPClientException should expose its reason publicly");
    OTAssert((cancellationException.request == request),
             @"AsyncHTTPRequestCancelledException should expose its request publicly");
}

- (void)test_gelbooru_live_smoke_fetches_first_page_when_enabled
{
    OFString *nillable userID;
    OFString *nillable apiKey;

    if (not [self _environmentFlagIsEnabled: @"ASYNC_RT_LIVE_GELBOORU"])
        OTSkip(@"Set ASYNC_RT_LIVE_GELBOORU=1 to run the live Gelbooru smoke test");

    userID = [self _environmentValueForKey: @"GELBOORU_USER_ID"];
    apiKey = [self _environmentValueForKey: @"GELBOORU_API_KEY"];

    if (userID == nilptr or userID.length == 0 or apiKey == nilptr or apiKey.length == 0)
        OTSkip(@"Set GELBOORU_USER_ID and GELBOORU_API_KEY to run the live Gelbooru smoke test");

    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto gelbooru = [[Gelbooru alloc] initWithAPIUserID: $assert_nonnil(userID)
                                                     andKey: $assert_nonnil(apiKey)];
        Optional<BooruPage *> *page = [rootTaskGroup performWithTimeout: 20 block: ^id(AsyncTaskGroup *) {
            return [[gelbooru fetchPage: 0 forSearchWithTags: [OFArray arrayWithObject: @"rating:general"]] await];
        }];

        OTAssert(page.hasValue, @"Live Gelbooru smoke test should return at least one result page");

        BooruPage *pageValue = page.value;
        OTAssert((pageValue.posts.count > 0), @"Live Gelbooru smoke test should return at least one post");

        BooruPost *firstPost = $assert_nonnil([pageValue.posts firstObject]);

        OTAssert((firstPost.id.length > 0), @"Live Gelbooru smoke test should return post IDs");
        OTAssert((firstPost.previewIRI.string.length > 0), @"Live Gelbooru smoke test should return preview IRIs");
        OTAssert((firstPost.fileIRI.string.length > 0), @"Live Gelbooru smoke test should return file IRIs");
    }];
}

- (void)test_realbooru_live_smoke_fetches_first_page_when_enabled
{
    if (not [self _environmentFlagIsEnabled: @"ASYNC_RT_LIVE_REALBOORU"])
        OTSkip(@"Set ASYNC_RT_LIVE_REALBOORU=1 to run the live Realbooru smoke test");

    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto realbooru = [[Realbooru alloc] initWithBaseIRI: [OFIRI IRIWithString: @"https://realbooru.com/"]
                                               postsPerPage: 2];
        Optional<BooruPage *> *page = [rootTaskGroup performWithTimeout: 20 block: ^id(AsyncTaskGroup *) {
            return [[realbooru fetchPage: 0 forSearchWithTags: [OFArray arrayWithObject: @"all"]] await];
        }];

        OTAssert(page.hasValue, @"Live Realbooru smoke test should return at least one result page");

        BooruPage *pageValue = page.value;
        OTAssert((pageValue.posts.count > 0), @"Live Realbooru smoke test should return at least one post");
        OTAssert((pageValue.posts.count <= 2), @"Live Realbooru smoke test should respect postsPerPage");

        BooruPost *firstPost = $assert_nonnil([pageValue.posts firstObject]);

        OTAssert((firstPost.id.length > 0), @"Live Realbooru smoke test should return post IDs");
        OTAssert((firstPost.previewIRI.string.length > 0), @"Live Realbooru smoke test should return preview IRIs");
        OTAssert((firstPost.fileIRI.string.length > 0), @"Live Realbooru smoke test should return file IRIs");
    }];
}

- (void)test_application_root_content_renders
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        (void)rootTaskGroup;
        AsyncUITestRenderHarness harness = AsyncUITestRenderHarnessMake();

        @try {
            Clay_RenderCommandArray commands = AsyncUITestRenderContent(&harness, harness.application.rootContent);
            OTAssert((AsyncUITestCommandsContainText(commands, @"Hello, AsyncRT UI!")), @"The sample app should render its root content");
        } @finally {
            AsyncUITestRenderHarnessDestroy(&harness);
        }
    }];
}

- (void)test_application_window_configuration_is_current_sample_configuration
{
    auto application = [[AsyncUITestApplication alloc] init];
    auto configuration = $assert_nonnil(application.windowConfiguration);

    OTAssert(([configuration.title isEqual: @"AsyncRT Scientific Calculator"]), @"The app should set its window title");
    OTAssert((configuration.initialWidth == 1360 and configuration.initialHeight == 860), @"The app should set its initial window size");
    OTAssert(configuration.isResizable, @"The app window should be resizable");
    OTAssertFalse(configuration.automaticallyResizesToContent, @"The app should use a stable initial window size");
    OTAssert(configuration.scalesWithWindowSize, @"The app should scale content with the window");
    OTAssert((configuration.contentScale == 1.0), @"The app should use a 1x logical content scale");
}

- (void)test_application_start_hook_receives_task_group
{
    [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) {
        auto application = [[AsyncUITestApplication alloc] init];

        [application applicationDidStartWithTaskGroup: rootTaskGroup];

        OTAssert(application.didStart, @"The app start hook should be callable on the application");
        OTAssert((application.startedTaskGroup == rootTaskGroup), @"The app start hook should receive the launch task group");
    }];
}

@end

#pragma clang assume_nonnull end
