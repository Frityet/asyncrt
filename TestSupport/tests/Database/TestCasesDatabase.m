#import <TestSupport/TestSupport.h>
#import <AsyncRT/Database/Providers/SQLite.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncDBTestProviderConnection : OFObject<AsyncDBProvider>
@end

@implementation AsyncDBTestProviderConnection

+ (OFString *)dbProviderName
{
    return @"test-memory";
}

+ (OFArray<OFString *> *)dbProviderSchemes
{
    return [OFArray arrayWithObject: @"test-memory"];
}

+ (id<AsyncDBConnection>)dbConnectionWithIRI: (OFIRI *)IRI
                                     options: (AsyncDBConnectionOptions *)options
{
    (void)IRI;
    (void)options;
    return [[self alloc] init];
}

- (bool)isOpen { return true; }
- (OFString *)name { return @"provider-test"; }
- (AsyncTask<AsyncUnit *> *)open { return [AsyncTask resolved: AsyncUnit.unit]; }
- (AsyncTask<AsyncUnit *> *)close { return [AsyncTask resolved: AsyncUnit.unit]; }
- (AsyncTask<id<AsyncDBTransaction>> *)beginTransaction
{
    return [AsyncTask rejected: [OFNotImplementedException exceptionWithSelector: _cmd
                                                                          object: self]];
}
- (AsyncTask<id<AsyncDBPreparedStatement>> *)prepareStatementWithSQL: (OFString *)SQL
{
    (void)SQL;
    return [AsyncTask rejected: [OFNotImplementedException exceptionWithSelector: _cmd
                                                                          object: self]];
}
- (AsyncTask<OFNumber *> *)lastInsertRowID
{
    return [AsyncTask rejected: [OFNotImplementedException exceptionWithSelector: _cmd
                                                                          object: self]];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeDatabaseTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeDatabaseTests

- (void)test_asyncdb_write_result_reports_affected_rows
{
    auto emptyResult = [AsyncDBWriteResult resultWithAffectedRowCount: 0];
    auto changedResult = [AsyncDBWriteResult resultWithAffectedRowCount: 3];

    OTAssert((emptyResult.affectedRowCount == 0 and not emptyResult.affectedRows),
             @"Empty write results should report no affected rows");
    OTAssert((changedResult.affectedRowCount == 3 and changedResult.affectedRows),
             @"Changed write results should expose affected row metadata");
}

- (void)test_asyncdb_provider_registry_uses_explicit_provider_classes
{
    auto registry = [AsyncDBProviderRegistry registryWithProviderClass: AsyncDBTestProviderConnection.class];
    auto connection = [registry connectionWithProviderClass: AsyncDBTestProviderConnection.class
                                                        IRI: [OFIRI IRIWithString: @"test-memory://localhost"]
                                                    options: [AsyncDBConnectionOptions options]];
    bool missingProviderThrows = false;

    [registry registerProviderClass: AsyncDBTestProviderConnection.class];

    @try {
        [registry connectionWithProviderName: @"missing-provider"
                                         IRI: [OFIRI IRIWithString: @"test-memory://localhost"]
                                     options: [AsyncDBConnectionOptions options]];
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
        missingProviderThrows = true;
    }

    OTAssert((registry.providerNames.count == 1), @"Duplicate explicit providers should not be registered twice");
    OTAssert(([registry hasProviderNamed: @"test-memory"]), @"AsyncDB should expose explicitly registered providers by name");
    OTAssert(([registry hasProviderForScheme: @"test-memory"]), @"AsyncDB should expose explicitly registered providers by IRI scheme");
    OTAssert((missingProviderThrows), @"AsyncDB should throw when provider lookup fails");
    OTAssert(([connection isKindOfClass: AsyncDBTestProviderConnection.class]), @"Registry should create provider connections");
}

- (void)test_asyncdb_sqlite_prepared_statements
{
    OFIRI *temporaryDirectoryIRI = $assert_nonnil(OFSystemInfo.temporaryDirectoryIRI);
    OFString *temporaryDirectoryPath = $assert_nonnil(temporaryDirectoryIRI.fileSystemRepresentation);
    OFString *databasePath = [OFString stringWithFormat: @"%@/asyncrt-asyncdb-sqlite-%ld.db",
                                                           temporaryDirectoryPath,
                                                           OFApplication.processID];
    OFIRI *databaseIRI = [OFIRI IRIWithString: [OFString stringWithFormat: @"sqlite://%@",
                                                                             databasePath]];
    auto fileManager = [OFFileManager defaultManager];

    @try {
        if ([fileManager fileExistsAtPath: databasePath])
            [fileManager removeItemAtPath: databasePath];

        [self runAsyncBlock: ^(AsyncTaskGroup *rootScope) {
            (void)rootScope;

            auto registry = [AsyncDBProviderRegistry registryWithProviderClass: AsyncDBSQLiteConnection.class];
            auto options = [AsyncDBSQLiteConnectionOptions optionsWithReadOnly: false
                                                               createsIfNeeded: true];
            auto connection = [registry connectionWithProviderClass: AsyncDBSQLiteConnection.class
                                                                IRI: databaseIRI
                                                            options: options];
            auto sqliteConnection = (AsyncDBSQLiteConnection *)connection;

            OTAssert(([connection isKindOfClass: AsyncDBSQLiteConnection.class]),
                     @"SQLite provider should create SQLite connections");
            OTAssert((not sqliteConnection.isOpen), @"SQLite connections should start closed");
            OTAssert(([[sqliteConnection open] await] == AsyncUnit.unit), @"SQLite should open");

            id<AsyncDBPreparedStatement> createStatement =
                [[sqliteConnection prepareStatementWithSQL: @"CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, body TEXT NOT NULL)"] await];
            OTAssert(([[createStatement execute] await].affectedRows == false),
                     @"DDL should execute through prepared statements");

            id<AsyncDBPreparedStatement> insertStatement =
                [[sqliteConnection prepareStatementWithSQL: @"INSERT INTO notes (body) VALUES (?)"] await];
            auto insertResult = [[insertStatement executeWithValues: [OFArray arrayWithObject: @"hello"]] await];
            OTAssert((insertResult.affectedRowCount == 1), @"INSERT should report one affected row");
            OTAssert((sqliteConnection.lastInsertRowID.await.longLongValue == 1), @"SQLite should expose the last row id");

            id<AsyncDBPreparedStatement> selectStatement =
                [[sqliteConnection prepareStatementWithSQL: @"SELECT id, body FROM notes WHERE body = ?"] await];
            auto rows = [[selectStatement fetchRowsWithValues: [OFArray arrayWithObject: @"hello"]] await];

            OTAssert((rows.count == 1), @"Prepared SELECT should return matching rows");
            OTAssert(([rows[0][@"body"] isEqual: @"hello"]), @"Rows should expose text values by column name");

            id<AsyncDBTransaction> transaction = [[sqliteConnection beginTransaction] await];
            [[insertStatement executeWithValues: [OFArray arrayWithObject: @"inside transaction"]] await];
            OTAssert((transaction.isActive), @"Transactions should start active");
            OTAssert(([[transaction rollback] await] == AsyncUnit.unit), @"Rollback should complete");
            OTAssert((not transaction.isActive), @"Transactions should become inactive after rollback");

            bool unsupportedValueRejected = false;
            @try {
                [[insertStatement executeWithValues: [OFArray arrayWithObject: [OFData data]]] await];
            } @catch (OFInvalidArgumentException *exception) {
                (void)exception;
                unsupportedValueRejected = true;
            }
            OTAssert((unsupportedValueRejected), @"SQLite statements should reject unsupported bound values");

            OTAssert(([[sqliteConnection close] await] == AsyncUnit.unit), @"SQLite should close");
        }];
    } @finally {
        if ([fileManager fileExistsAtPath: databasePath])
            [fileManager removeItemAtPath: databasePath];
    }
}

@end

#pragma clang assume_nonnull end
