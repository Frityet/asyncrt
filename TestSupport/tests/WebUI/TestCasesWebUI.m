#import <TestSupport/TestSupport.h>
#import <AsyncRT/Application/WebUI/AsyncWebUIApplication.h>
#import <AsyncRT/Application/WebUI/AsyncWebUIView.h>
#import <AsyncRT/Application/WebUI/AsyncWebUIRequest.h>

@interface AsyncRuntimeWebUITests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeWebUITests

- (void)testWebUIWindowConfiguration {
    AsyncWebUIWindowConfiguration *config = [AsyncWebUIWindowConfiguration configuration];
    OTAssertEqualObjects(config.title, @"AsyncRT WebUI");
    config.title = @"Test";
    OTAssertEqualObjects(config.title, @"Test");
}

@end
