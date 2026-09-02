#import <Common.h>
#import <ObjFWTest/ObjFWTest.h>

#if defined(__APPLE__)
# include <dlfcn.h>
# import <objc/runtime.h>
#endif

#pragma clang assume_nonnull begin

typedef struct {
    int value;
} FormatTestPoint;

[[clang::overloadable]]
static inline OFString *describe(FormatTestPoint point)
{ return $fmt(@"point({})", point.value); }

@interface CommonTests : OTTestCase
@end

@implementation CommonTests

- (void)testFmtAppendsTypedFragments
{
    char ch = 'x';
    FormatTestPoint point = { .value = 7 };
    OFString *formatted = $fmt(
        @"value={}, flag={}, cstr={}, obj={}, nil={}, char={}, {}",
        3, true, "ok", @42, nilptr, ch, point);

    OTAssertEqualObjects(formatted,
        @"value=3, flag=true, cstr=ok, obj=42, nil=<nil>, char=x, point(7)",
        @"$fmt must replace placeholders using typed describe overloads");
}

- (void)testFmtEscapesLiteralBraces
{
    OTAssertEqualObjects($fmt(@"{{{}}}", @"value"), @"{value}",
        @"$fmt must allow escaped literal braces around placeholders");
}

- (void)testFmtRejectsPlaceholderCountMismatch
{
    OTAssertThrowsSpecific($fmt(@"missing {}"), OFInvalidFormatException,
        @"$fmt must reject missing arguments");
    OTAssertThrowsSpecific($fmt(@"extra", 1), OFInvalidFormatException,
        @"$fmt must reject extra arguments");
}

- (void)testConcurrentFirstUseOfConstantStringsIsSafe
{
#if defined(__APPLE__)
    /*
     * Keep these literals unique to this test so constructing the collection
     * does not initialize them before the worker barrier. Every round makes
     * all workers first-touch the same literal concurrently.
     */
    OFArray<OFString *> *literals = @[
        @"async-rt-constant-race-00", @"async-rt-constant-race-01",
        @"async-rt-constant-race-02", @"async-rt-constant-race-03",
        @"async-rt-constant-race-04", @"async-rt-constant-race-05",
        @"async-rt-constant-race-06", @"async-rt-constant-race-07",
        @"async-rt-constant-race-08", @"async-rt-constant-race-09",
        @"async-rt-constant-race-10", @"async-rt-constant-race-11",
        @"async-rt-constant-race-12", @"async-rt-constant-race-13",
        @"async-rt-constant-race-14", @"async-rt-constant-race-15",
        @"async-rt-constant-race-16", @"async-rt-constant-race-17",
        @"async-rt-constant-race-18", @"async-rt-constant-race-19",
        @"async-rt-constant-race-20", @"async-rt-constant-race-21",
        @"async-rt-constant-race-22", @"async-rt-constant-race-23",
        @"async-rt-constant-race-24", @"async-rt-constant-race-25",
        @"async-rt-constant-race-26", @"async-rt-constant-race-27",
        @"async-rt-constant-race-28", @"async-rt-constant-race-29",
        @"async-rt-constant-race-30", @"async-rt-constant-race-31",
        @"async-rt-constant-race-32", @"async-rt-constant-race-33",
        @"async-rt-constant-race-34", @"async-rt-constant-race-35",
        @"async-rt-constant-race-36", @"async-rt-constant-race-37",
        @"async-rt-constant-race-38", @"async-rt-constant-race-39",
        @"async-rt-constant-race-40", @"async-rt-constant-race-41",
        @"async-rt-constant-race-42", @"async-rt-constant-race-43",
        @"async-rt-constant-race-44", @"async-rt-constant-race-45",
        @"async-rt-constant-race-46", @"async-rt-constant-race-47",
        @"async-rt-constant-race-48", @"async-rt-constant-race-49",
        @"async-rt-constant-race-50", @"async-rt-constant-race-51",
        @"async-rt-constant-race-52", @"async-rt-constant-race-53",
        @"async-rt-constant-race-54", @"async-rt-constant-race-55",
        @"async-rt-constant-race-56", @"async-rt-constant-race-57",
        @"async-rt-constant-race-58", @"async-rt-constant-race-59",
        @"async-rt-constant-race-60", @"async-rt-constant-race-61",
        @"async-rt-constant-race-62", @"async-rt-constant-race-63"
    ];
    constexpr size_t threadCount = 32;
    auto condition = [OFCondition condition];
    auto threads = [OFMutableArray<OFThread *> arrayWithCapacity: threadCount];
    block_reference size_t releasedRound = 0;
    block_reference size_t readyCount = 0;
    block_reference size_t completedCount = 0;
    block_reference OFException *nillable failure = nilptr;
    block_reference size_t emptyRound = OFNotFound;

    for (size_t threadIndex = 0; threadIndex < threadCount; threadIndex++) {
        auto thread = [OFThread threadWithBlock: ^id nillable {
            (void)threadIndex;
            for (size_t round = 0; round < literals.count; round++) {
                [condition lock];
                @try {
                    readyCount++;
                    [condition broadcast];
                    while (releasedRound == round)
                        [condition wait];
                } @finally {
                    [condition unlock];
                }

                @try {
                    if (literals[round].length == 0) {
                        [condition lock];
                        @try {
                            if (emptyRound == OFNotFound)
                                emptyRound = round;
                        } @finally {
                            [condition unlock];
                        }
                    }
                } @catch (OFException *exception) {
                    [condition lock];
                    @try {
                        if (failure == nilptr)
                            failure = exception;
                    } @finally {
                        [condition unlock];
                    }
                }

                [condition lock];
                @try {
                    completedCount++;
                    [condition broadcast];
                } @finally {
                    [condition unlock];
                }
            }
            return nilptr;
        }];
        [threads addObject: thread];
        [thread start];
    }

    for (size_t round = 0; round < literals.count; round++) {
        [condition lock];
        @try {
            while (readyCount < threadCount)
                [condition wait];
            readyCount = 0;
            releasedRound = round + 1;
            [condition broadcast];
            while (completedCount < threadCount)
                [condition wait];
            completedCount = 0;
        } @finally {
            [condition unlock];
        }
    }

    for (OFThread *thread in threads)
        [thread join];

    OTAssertNil(failure,
        @"concurrent first use of an ObjFW constant string must be safe: %@",
        failure);
    OTAssertEqual(emptyRound, OFNotFound,
        @"constant string round %zu transiently reported an empty value",
        emptyRound);
#endif
}

- (void)testDynamicallyLoadedImageConstantStringsArePreinitialized
{
#if defined(__APPLE__)
    typedef size_t (*LiteralCountFunction)(void);
    typedef id (*LiteralAtIndexFunction)(size_t);

    void *image = dlopen(ASYNC_RT_CONSTANT_STRING_IMAGE_PATH,
        RTLD_NOW | RTLD_LOCAL);
    if (image == nullptr) {
        const char *error = dlerror();
        OTAssertTrue(false, @"could not load constant-string fixture: %s",
            (error != nullptr ? error : "unknown dynamic-loader error"));
        return;
    }

    auto literalCount = (LiteralCountFunction)dlsym(image,
        "AsyncRTConstantStringImageLiteralCount");
    auto literalAtIndex = (LiteralAtIndexFunction)dlsym(image,
        "AsyncRTConstantStringImageLiteralAtIndex");
    OTAssertTrue(literalCount != nullptr);
    OTAssertTrue(literalAtIndex != nullptr);

    auto initializedClass = objc_lookUpClass("OFConstantUTF8String");
    OTAssertTrue(initializedClass != nullptr);
    for (size_t index = 0; index < literalCount(); index++) {
        id literal = literalAtIndex(index);
        OTAssertNotNil(literal);
        OTAssertTrue(object_getClass(literal) == initializedClass,
            @"dyld must preinitialize literal %zu before dlopen returns",
            index);
        OTAssertTrue([(OFString *)literal hasPrefix:
            @"async-rt-plugin-constant-"]);
    }
#endif
}

@end

#pragma clang assume_nonnull end
