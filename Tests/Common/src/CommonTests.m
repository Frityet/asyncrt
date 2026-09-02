#import <Common.h>
#import <ObjFWTest/ObjFWTest.h>

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

@end

#pragma clang assume_nonnull end
