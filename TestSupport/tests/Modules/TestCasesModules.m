@import AsyncRT.Core;
@import AsyncRT.Database.Provider.SQLite;

#import <TestSupport/TestSupport.h>

@interface AsyncRuntimeModuleImportTests : AsyncRuntimeTestCase
@end

@implementation AsyncRuntimeModuleImportTests

- (void)test_core_and_database_modules_import
{
    OTAssertNotNil(AsyncUnit.unit, @"AsyncRT.Core should import AsyncUnit");
    OTAssertEqualObjects([AsyncDBSQLiteConnection dbProviderName],
                         @"sqlite",
                         @"AsyncRT.Database.Provider.SQLite should import the SQLite provider");
}

@end
