#import <AsyncRT/Common/OFArray+LINQ.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface OFArrayLINQTests: OTTestCase
@end

@implementation OFArrayLINQTests

- (OFArray<OFNumber *> *)numberArrayWithValues: (const int *)values
                                          count: (size_t)count
{
    auto result = [OFMutableArray<OFNumber *> arrayWithCapacity: count];
    for (size_t i = 0; i < count; i++)
        [result addObject: [OFNumber numberWithInt: values[i]]];
    [result makeImmutable];
    return result;
}

- (OFArray<OFString *> *)stringArrayWithValues: (const char *const *)values
                                          count: (size_t)count
{
    auto result = [OFMutableArray<OFString *> arrayWithCapacity: count];
    for (size_t i = 0; i < count; i++)
        [result addObject: [OFString stringWithUTF8String: values[i]]];
    [result makeImmutable];
    return result;
}

- (void)testTypedProjectionPagingAndQuantifiers
{
    int numberValues[] = { 1, 2, 2, 3 };
    auto numbers = [self numberArrayWithValues: numberValues count: 4];

    auto evens = [numbers where: ^bool(OFNumber *number) {
        return number.intValue % 2 == 0;
    }];
    int evenValues[] = { 2, 2 };
    auto expectedEvens = [self numberArrayWithValues: evenValues count: 2];
    OTAssertEqualObjects(evens, expectedEvens,
        @"where must preserve matching objects and their order");

    auto doubled = [numbers select: ^id(OFNumber *number) {
        return [OFNumber numberWithInt: number.intValue * 2];
    }];
    int doubledValues[] = { 2, 4, 4, 6 };
    auto expectedDoubled =
        [self numberArrayWithValues: doubledValues count: 4];
    OTAssertEqualObjects(doubled, expectedDoubled,
        @"select must project each source object");

    OTAssertTrue([numbers any: ^bool(OFNumber *number) {
        return number.intValue == 3;
    }], @"any must find a matching object");
    OTAssertTrue([numbers all: ^bool(OFNumber *number) {
        return number.intValue > 0;
    }], @"all must accept a predicate satisfied by every object");
    OTAssertEqual([numbers sum], 8.0, @"sum must aggregate OFNumber values");
    OTAssertEqual([numbers average], 2.0, @"average must divide by source count");

    auto page = [[numbers skip: 1] take: 2];
    OTAssertEqualObjects(page, expectedEvens,
        @"skip and take must compose");
}

- (void)testOrderingGroupingAndKeyedSets
{
    const char *wordValues[] = { "bbb", "a", "cc", "d" };
    auto words = [self stringArrayWithValues: wordValues count: 4];

    auto ordered = [[words orderBy: ^id(OFString *word) {
        return [OFNumber numberWithInt: (int)word.length];
    }] toArray];
    const char *orderedValues[] = { "a", "d", "cc", "bbb" };
    auto expectedOrdered =
        [self stringArrayWithValues: orderedValues count: 4];
    OTAssertEqualObjects(ordered, expectedOrdered,
        @"orderBy must sort by the selected key");

    auto groups = [words groupBy: ^id(OFString *word) {
        return [OFNumber numberWithInt: (int)word.length];
    }];
    OTAssertEqual(groups.count, 3, @"groupBy must create one group per key");
    const char *firstGroupValues[] = { "bbb" };
    auto expectedFirstGroup =
        [self stringArrayWithValues: firstGroupValues count: 1];
    OTAssertEqualObjects(groups[0].elements, expectedFirstGroup,
        @"groupBy must retain source order within a group");

    auto distinct = [words distinctBy: ^id(OFString *word) {
        return [OFNumber numberWithInt: (int)word.length];
    }];
    const char *distinctValues[] = { "bbb", "a", "cc" };
    auto expectedDistinct =
        [self stringArrayWithValues: distinctValues count: 3];
    OTAssertEqualObjects(distinct, expectedDistinct,
        @"distinctBy must keep the first object for each key");

    const char *moreWordValues[] = { "e", "ffff" };
    auto moreWords = [self stringArrayWithValues: moreWordValues count: 2];
    auto unioned = [words union: moreWords by: ^id(OFString *word) {
        return [OFNumber numberWithInt: (int)word.length];
    }];
    const char *unionValues[] = { "bbb", "a", "cc", "ffff" };
    auto expectedUnion =
        [self stringArrayWithValues: unionValues count: 4];
    OTAssertEqualObjects(unioned, expectedUnion,
        @"union:by: must combine unique keys in source order");
}

- (void)testDictionaryAndZip
{
    int numberValues[] = { 1, 2, 3 };
    auto numbers = [self numberArrayWithValues: numberValues count: 3];
    int otherValues[] = { 10, 20 };
    auto other = [self numberArrayWithValues: otherValues count: 2];

    auto dictionary = [numbers toDictionaryWithKeySelector: ^id(OFNumber *number) {
        return number;
    }];
    auto two = [OFNumber numberWithInt: 2];
    OTAssertEqualObjects([dictionary objectForKey: two], two,
        @"toDictionary must use the selected key and source value");

    auto pairs = [numbers zip: other];
    OTAssertEqual(pairs.count, 2, @"zip must stop at the shorter sequence");
    OTAssertEqualObjects(pairs[1].firstObject, two,
        @"zip must preserve the left value");
    OTAssertEqualObjects(pairs[1].secondObject, [OFNumber numberWithInt: 20],
        @"zip must preserve the right value");
}

@end

#pragma clang assume_nonnull end
