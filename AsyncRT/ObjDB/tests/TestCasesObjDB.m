#import "TestSupport.h"
#import "DBConnection.h"
#import "DBEntity.h"
#import "DBProvider.h"
#import "DBQuery.h"
#import "DBRepository.h"
#import "ObjDBModule.h"
#import "DBSQLite.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ObjDBSampleUser : OFObject<DBEntity>
@end

@implementation ObjDBSampleUser

+ (OFString *)dbEntityName
{
    return @"users";
}

@end

[[subclassing_restricted]]
@interface ObjDBTestConnection : OFObject<DBConnection>
@end

@implementation ObjDBTestConnection

- (bool)isOpen
{
    return true;
}

- (OFString *)name
{
    return @"test";
}

- (Task<AsyncUnit *> *)open
{
    return [Task resolved: AsyncUnit.unit];
}

- (Task<AsyncUnit *> *)close
{
    return [Task resolved: AsyncUnit.unit];
}

- (Task<id<DBTransaction>> *)beginTransaction
{
    return [Task rejected: [OFNotImplementedException exceptionWithSelector: _cmd
                                                                      object: self]];
}

@end

[[subclassing_restricted]]
@interface ObjDBTestProviderConnection : OFObject<DBProvider>
@end

@implementation ObjDBTestProviderConnection

+ (OFString *)dbProviderName
{
    return @"test-memory";
}

+ (OFArray<OFString *> *)dbProviderSchemes
{
    return @[@"test-memory"];
}

+ (id<DBConnection>)dbConnectionWithIRI: (OFIRI *)IRI
                                options: (DBConnectionOptions *)options
{
    (void)IRI;
    (void)options;
    return [[self alloc] init];
}

- (bool)isOpen
{
    return false;
}

- (OFString *)name
{
    return @"provider-test";
}

- (Task<AsyncUnit *> *)open
{
    return [Task resolved: AsyncUnit.unit];
}

- (Task<AsyncUnit *> *)close
{
    return [Task resolved: AsyncUnit.unit];
}

- (Task<id<DBTransaction>> *)beginTransaction
{
    return [Task rejected: [OFNotImplementedException exceptionWithSelector: _cmd
                                                                      object: self]];
}

@end

[[subclassing_restricted]]
@interface AsyncRuntimeObjDBTests : AsyncRuntimeTestCase @end

@implementation AsyncRuntimeObjDBTests

- (void)test_objdb_target_metadata
{
    OTAssert(([ObjDBModule.targetName isEqual: @"ObjDB"]), @"ObjDB should expose its xmake library target name");
    OTAssert(([ObjDBModule.moduleName isEqual: @"ObjDB"]), @"ObjDB should expose its module name");
    OTAssert(([ObjDBModule.toolName isEqual: @"odb"]), @"ObjDB should expose its tool target name");
}

- (void)test_objdb_entity_schema_reads_entity_metadata
{
    auto schema = [DBEntitySchema<ObjDBSampleUser *, OFString *> schemaWithEntityClass: ObjDBSampleUser.class
                                                                      primaryKeyClass: OFString.class];

    OTAssert((schema.entityClass == ObjDBSampleUser.class), @"Schema should retain the entity class");
    OTAssert(([schema.entityName isEqual: @"users"]), @"Schema should infer the DB entity name");
    OTAssert((schema.primaryKeyClass == OFString.class), @"Schema should retain the key class");
}

- (void)test_objdb_typed_fields_build_typed_queries
{
    auto name = [DBField<ObjDBSampleUser *, OFString *> fieldWithName: @"name"
                                                           valueClass: OFString.class];
    auto age = [DBField<ObjDBSampleUser *, OFNumber *> fieldWithName: @"age"
                                                          valueClass: OFNumber.class];
    DBPredicate<ObjDBSampleUser *, OFString *, OFString *> *namePredicate = [name isEqualTo: @"Ada"];
    DBPredicate<ObjDBSampleUser *, OFNumber *, OFNumber *> *agePredicate = [age isGreaterThan: [OFNumber numberWithInt: 20]];
    auto sortedByName = [name ascending];

    auto emptyQuery = [DBQuery<ObjDBSampleUser *> queryForEntityClass: ObjDBSampleUser.class];
    auto filteredQuery = [[[emptyQuery where: namePredicate]
                                      where: agePredicate]
                                      sortedBy: sortedByName];
    auto pagedQuery = [[filteredQuery limitedTo: 25] offsetBy: 50];

    OTAssert((emptyQuery.predicates.count == 0), @"Queries should be immutable when adding predicates");
    OTAssert((filteredQuery.predicates.count == 2), @"Typed predicates should be collected");
    OTAssert((filteredQuery.sortDescriptors.count == 1), @"Typed sort descriptors should be collected");
    OTAssert((namePredicate.field == name), @"Predicates should retain their typed field");
    OTAssert((namePredicate.comparisonOperator == DBComparisonOperator_EQUAL), @"Field equality should map to the equality operator");
    OTAssert(([namePredicate.value isEqual: @"Ada"]), @"Predicates should retain their comparison value");
    OTAssert((agePredicate.comparisonOperator == DBComparisonOperator_GREATER_THAN), @"Numeric comparisons should keep their operator");
    OTAssert((sortedByName.isAscending), @"Ascending field descriptors should report their direction");
    OTAssert((pagedQuery.hasLimit and pagedQuery.limit == 25 and pagedQuery.offset == 50), @"Queries should retain pagination metadata");
}

- (void)test_objdb_repository_base_exposes_typed_query_and_abstract_crud_surface
{
    auto connection = [[ObjDBTestConnection alloc] init];
    auto schema = [DBEntitySchema<ObjDBSampleUser *, OFString *> schemaWithEntityClass: ObjDBSampleUser.class
                                                                      primaryKeyClass: OFString.class];
    auto repository = [[DBRepository<ObjDBSampleUser *, OFString *> alloc] initWithConnection: connection
                                                                                       schema: schema];
    bool caughtAbstractFetch = false;

    OTAssert((repository.connection == connection), @"Repositories should retain their backing connection");
    OTAssert((repository.schema == schema), @"Repositories should retain their schema");
    OTAssert((repository.query.entityClass == ObjDBSampleUser.class), @"Repositories should create typed root queries");

    @try {
        [repository fetch: repository.query];
    } @catch (OFNotImplementedException *exception) {
        (void)exception;
        caughtAbstractFetch = true;
    }

    OTAssert((caughtAbstractFetch), @"The base repository should require concrete storage adapters for CRUD");
}

- (void)test_objdb_write_result_reports_affected_rows
{
    auto emptyResult = [DBWriteResult resultWithAffectedRowCount: 0];
    auto changedResult = [DBWriteResult resultWithAffectedRowCount: 3];

    OTAssert((emptyResult.affectedRowCount == 0 and not emptyResult.affectedRows), @"Empty write results should report no affected rows");
    OTAssert((changedResult.affectedRowCount == 3 and changedResult.affectedRows), @"Changed write results should expose affected row metadata");
}

- (void)test_objdb_provider_registry_discovers_database_providers_from_plugins
{
    auto registry = [DBProviderRegistry registryWithPlugins: @[[Plugin currentProcessPlugin]]];
    bool hasNamedProvider = [registry hasProviderNamed: @"test-memory"];
    bool hasSchemeProvider = [registry hasProviderForScheme: @"test-memory"];
    OFArray<Class> *connectionClasses = [[Plugin currentProcessPlugin] classesThatImplementProtocol: @protocol(DBConnection)];
    auto connection = [registry connectionWithIRI: [OFIRI IRIWithString: @"test-memory://localhost"]
                                          options: [DBConnectionOptions options]];
    bool foundProviderAsConnectionClass = false;
    bool missingProviderThrows = false;

    for (Class connectionClass in connectionClasses) {
        if (connectionClass == ObjDBTestProviderConnection.class)
            foundProviderAsConnectionClass = true;
    }

    @try {
        [registry connectionWithProviderName: @"missing-provider"
                                         IRI: [OFIRI IRIWithString: @"test-memory://localhost"]
                                     options: [DBConnectionOptions options]];
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
        missingProviderThrows = true;
    }

    OTAssert((hasNamedProvider), @"ObjDB should discover DB providers by provider name");
    OTAssert((hasSchemeProvider), @"ObjDB should discover DB providers by IRI scheme");
    OTAssert((missingProviderThrows), @"ObjDB should throw when provider lookup fails");
    OTAssert((foundProviderAsConnectionClass), @"Plugin should support discovering DB connection classes directly by protocol");
    OTAssert(([registry.providerNames containsObject: @"test-memory"]), @"ObjDB should expose discovered provider names");
    OTAssert(([connection isKindOfClass: ObjDBTestProviderConnection.class]), @"ObjDB should create connections through discovered providers");
}

- (void)test_objdb_sqlite_provider_opens_database_and_executes_sql
{
    OFIRI *temporaryDirectoryIRI = $assert_nonnil(OFSystemInfo.temporaryDirectoryIRI);
    OFString *temporaryDirectoryPath = $assert_nonnil(temporaryDirectoryIRI.fileSystemRepresentation);
    OFString *databasePath = [OFString stringWithFormat: @"%@/asyncrt-objdb-sqlite-%ld.db",
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

            auto registry = [DBProviderRegistry registryWithPlugins: @[[Plugin currentProcessPlugin]]];
            bool hasSQLiteProvider = [registry hasProviderForScheme: @"sqlite"];
            auto options = [DBSQLiteConnectionOptions optionsWithReadOnly: false
                                                          createsIfNeeded: true];
            auto connection = [registry connectionWithIRI: databaseIRI
                                                  options: options];

            OTAssert((hasSQLiteProvider), @"The SQLite provider should register for sqlite IRIs");
            OTAssert(([connection isKindOfClass: DBSQLiteConnection.class]), @"The SQLite provider should create SQLite connections");

            auto sqliteConnection = (DBSQLiteConnection *)connection;
            id<DBSQLConnection> sqlConnection = sqliteConnection;
            OTAssert((not sqliteConnection.isOpen), @"SQLite connections should start closed");
            OTAssert(([sqliteConnection.path isEqual: databasePath]), @"SQLite connections should retain the database path");
            OTAssert((sqliteConnection.options == options), @"SQLite connections should retain typed connection options");

            OTAssert(([[sqliteConnection open] await] == AsyncUnit.unit), @"SQLite connections should open successfully");
            OTAssert((sqliteConnection.isOpen), @"SQLite connections should report open state");

            DBWriteResult *createResult = [[sqlConnection executeSQL:
                @"CREATE TABLE entries (id INTEGER PRIMARY KEY, name TEXT NOT NULL)"] await];
            DBWriteResult *insertResult = [[sqlConnection executeSQL:
                @"INSERT INTO entries (name) VALUES (?)"
                                                       values: @[@"alpha"]] await];
            id<DBTransaction> transaction = [[sqliteConnection beginTransaction] await];

            (void)[[sqlConnection executeSQL: @"INSERT INTO entries (name) VALUES (?)"
                                      values: @[@"rolled-back"]] await];
            OTAssert((not createResult.affectedRows), @"CREATE TABLE should not report changed rows");
            OTAssert((insertResult.affectedRowCount == 1 and insertResult.affectedRows), @"INSERT should report one affected row");
            OTAssert((transaction.isActive), @"SQLite transactions should start active");
            OTAssert(([[transaction rollback] await] == AsyncUnit.unit), @"SQLite transactions should rollback");
            OTAssert((not transaction.isActive), @"SQLite transactions should report inactive after rollback");

            auto rows = [[sqlConnection fetchRowsWithSQL: @"SELECT id, name FROM entries ORDER BY id"
                                                   values: @[]] await];
            OTAssert((rows.count == 1 and [rows[0][@"name"] isEqual: @"alpha"]), @"SQLite row fetches should go through the core SQL connection abstraction");

            bool caughtInvalidSQL = false;
            @try {
                (void)[[sqlConnection executeSQL: @"INSERT INTO missing_table DEFAULT VALUES"] await];
            } @catch (DBSQLiteException *exception) {
                caughtInvalidSQL = (exception.connection == sqliteConnection);
            }

            OTAssert((caughtInvalidSQL), @"SQLite execution errors should reject with DBSQLiteException");

            OTAssert(([[sqliteConnection close] await] == AsyncUnit.unit), @"SQLite connections should close successfully");
            OTAssert((not sqliteConnection.isOpen), @"SQLite connections should report closed state");
        }];
    } @finally {
        if ([fileManager fileExistsAtPath: databasePath])
            [fileManager removeItemAtPath: databasePath];
    }
}

@end

#pragma clang assume_nonnull end
