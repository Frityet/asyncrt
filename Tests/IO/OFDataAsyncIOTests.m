#import <AsyncRT/IO/IO.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

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

@end

#pragma clang assume_nonnull end
