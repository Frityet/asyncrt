#import <ObjFWTest/ObjFWTest.h>

@interface OWebObjFWLiteralCompatibilityTests: OTTestCase
@end

@implementation OWebObjFWLiteralCompatibilityTests

- (void)testEmptyCollectionsUseObjFWFactories
{
	OFDictionary *dictionary = @{};
	OFArray *array = @[];

	OTAssertTrue([dictionary isKindOfClass: [OFDictionary class]]);
	OTAssertTrue([array isKindOfClass: [OFArray class]]);
	OTAssertEqualObjects(dictionary.JSONRepresentation, @"{}");
	OTAssertEqualObjects(array.JSONRepresentation, @"[]");
}

- (void)testScalarLiteralUsesObjFWFactory
{
	bool value = true;
	OFNumber *number = @(value);

	OTAssertTrue([number isKindOfClass: [OFNumber class]]);
	OTAssertEqualObjects(number.JSONRepresentation, @"true");
}

@end
