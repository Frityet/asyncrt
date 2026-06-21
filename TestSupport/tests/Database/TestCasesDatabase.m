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

@interface AsyncDBTestMovie : AsyncDBTable
@property(retain, nonatomic) OFNumber<AsyncDBColumn, AsyncDBPrimaryKey> *id;
@property(retain, nonatomic) OFString<AsyncDBColumn> *name;
@property(retain, nonatomic) OFDate<AsyncDBColumn> *releaseDate;
@property(retain, nonatomic) OFNumber<AsyncDBColumn> *runtime;
@end

@implementation AsyncDBTestMovie
+ (OFString *)tableName { return @"movies"; }
+ (OFDictionary<OFString *, OFString *> *)sqlNameOverrides
{ return @{ @"releaseDate": @"release_date" }; }
@end

@interface AsyncDBTestCinema : AsyncDBTable
@property(retain, nonatomic) OFNumber<AsyncDBColumn, AsyncDBPrimaryKey> *id;
@property(retain, nonatomic) OFString<AsyncDBColumn, AsyncDBUnique> *name;
@property(retain, nonatomic) OFString<AsyncDBColumn> *city;
@property(retain, nonatomic) OFString<AsyncDBColumn> *country;
@end

@implementation AsyncDBTestCinema
+ (OFString *)tableName { return @"cinemas"; }
@end

@interface AsyncDBTestShowing : AsyncDBTable
@property(retain, nonatomic) OFNumber<AsyncDBColumn, AsyncDBPrimaryKey> *id;
@property(retain, nonatomic) AsyncDBTestMovie<AsyncDBForeignKey> *movie;
@property(retain, nonatomic) AsyncDBTestCinema<AsyncDBForeignKey> *cinema;
@property(retain, nonatomic) OFString<AsyncDBColumn> *auditorium;
@property(retain, nonatomic) OFDate<AsyncDBColumn> *startsAt;
@property(retain, nonatomic) OFDate<AsyncDBColumn> *endsAt;
@end

@implementation AsyncDBTestShowing
+ (OFString *)tableName { return @"showings"; }
+ (OFDictionary<OFString *, OFString *> *)sqlNameOverrides
{ return @{ @"startsAt": @"starts_at", @"endsAt": @"ends_at" }; }
@end

@interface AsyncDBTestTicket : AsyncDBTable
@property(retain, nonatomic) OFNumber<AsyncDBColumn, AsyncDBPrimaryKey> *id;
@property(retain, nonatomic) AsyncDBTestShowing<AsyncDBForeignKey> *showing;
@property(retain, nonatomic) OFString<AsyncDBColumn> *seat;
@property(retain, nonatomic) OFNumber<AsyncDBColumn> *price;
@property(retain, nonatomic) OFString<AsyncDBColumn> *status;
@end

@implementation AsyncDBTestTicket
+ (OFString *)tableName { return @"tickets"; }
@end

@interface AsyncDBTestTicketReservation : AsyncDBTable
@property(retain, nonatomic) OFNumber<AsyncDBColumn, AsyncDBPrimaryKey> *id;
@property(retain, nonatomic) AsyncDBTestTicket<AsyncDBForeignKey> *ticket;
@property(retain, nonatomic) OFNumber<AsyncDBColumn> *customerID;
@property(retain, nonatomic) OFDate<AsyncDBColumn> *reservedAt;
@property(retain, nonatomic) OFDate<AsyncDBColumn> *expiresAt;
@end

@implementation AsyncDBTestTicketReservation
+ (OFString *)tableName { return @"ticket_reservations"; }
+ (OFDictionary<OFString *, OFString *> *)sqlNameOverrides
{ return @{ @"customerID": @"customer_id", @"reservedAt": @"reserved_at", @"expiresAt": @"expires_at" }; }
@end

@interface AsyncDBTestTicketReservationQueryRow : OFObject
@property(retain, nonatomic) OFString *movieName;
@property(retain, nonatomic) OFString *cinemaName;
@property(retain, nonatomic) OFString *city;
@property(retain, nonatomic) OFString *country;
@property(retain, nonatomic) OFString *auditorium;
@property(retain, nonatomic) OFDate *startsAt;
@property(retain, nonatomic) OFString *seat;
@property(retain, nonatomic) OFNumber *price;
@property(retain, nonatomic) OFString *status;
@property(retain, nonatomic) OFNumber *customerID;
@end

@implementation AsyncDBTestTicketReservationQueryRow
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

- (void)test_asyncdb_orm_reflects_property_protocol_schema
{
    AsyncDBEntitySchema *movieSchema = AsyncDBTestMovie.schema;
    AsyncDBEntitySchema *showingSchema = AsyncDBTestShowing.schema;
    AsyncDBEntitySchema *cinemaSchema = AsyncDBTestCinema.schema;

    OTAssert(([movieSchema.tableName isEqual: @"movies"]), @"ORM schemas should use table name overrides");
    OTAssert(([movieSchema.primaryKeyColumn.propertyName isEqual: @"id"]), @"ORM schemas should detect primary keys");
    OTAssert(([[movieSchema columnNamed: @"releaseDate"].SQLName isEqual: @"release_date"]),
             @"ORM schemas should use SQL name overrides");
    OTAssert(([cinemaSchema columnNamed: @"name"].isUnique), @"ORM schemas should detect unique columns");
    OTAssert(([showingSchema columnNamed: @"movie"].isForeignKey), @"ORM schemas should detect foreign keys");
    OTAssert(([showingSchema columnNamed: @"movie"].referencedTableClass == AsyncDBTestMovie.class),
             @"ORM schemas should keep referenced table classes");

    auto Movies = AsyncDBTestMovie.table;
    OTAssert(([Movies.name isKindOfClass: AsyncDBColumnReference.class]),
             @"Table references should return column references from reflected properties");
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

        [self runAsyncBlock: ^{
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

- (void)test_asyncdb_orm_crud_transactions_and_joined_selects
{
    [self runAsyncBlock: ^{
        auto connection = [AsyncDBSQLiteConnection dbConnectionWithIRI: [OFIRI IRIWithString: @"sqlite:///:memory:"]
                                                               options: [AsyncDBSQLiteConnectionOptions options]];
        [[connection open] await];

        [[AsyncDBTestMovie createTableInConnection: connection] await];
        [[AsyncDBTestCinema createTableInConnection: connection] await];
        [[AsyncDBTestShowing createTableInConnection: connection] await];
        [[AsyncDBTestTicket createTableInConnection: connection] await];
        [[AsyncDBTestTicketReservation createTableInConnection: connection] await];

        auto movie = [[AsyncDBTestMovie alloc] init];
        movie.name = @"Arrival";
        movie.releaseDate = [OFDate dateWithTimeIntervalSince1970: 1476403200];
        movie.runtime = [OFNumber numberWithInt: 116];
        OTAssert(([[movie insertIntoConnection: connection] await].affectedRows),
                 @"ORM insert should write model rows");
        OTAssert((movie.id.longLongValue == 1), @"ORM insert should load generated primary keys");

        auto cinema = [[AsyncDBTestCinema alloc] init];
        cinema.name = @"Rio";
        cinema.city = @"London";
        cinema.country = @"UK";
        [[cinema insertIntoConnection: connection] await];

        auto showing = [[AsyncDBTestShowing alloc] init];
        showing.movie = movie;
        showing.cinema = cinema;
        showing.auditorium = @"Screen 1";
        showing.startsAt = [OFDate dateWithTimeIntervalSince1970: 1800000000];
        showing.endsAt = [OFDate dateWithTimeIntervalSince1970: 1800007200];
        [[showing insertIntoConnection: connection] await];

        auto ticket = [[AsyncDBTestTicket alloc] init];
        ticket.showing = showing;
        ticket.seat = @"A1";
        ticket.price = [OFNumber numberWithInt: 1200];
        ticket.status = @"reserved";
        [[ticket insertIntoConnection: connection] await];

        auto reservation = [[AsyncDBTestTicketReservation alloc] init];
        reservation.ticket = ticket;
        reservation.customerID = [OFNumber numberWithInt: 42];
        reservation.reservedAt = [OFDate dateWithTimeIntervalSince1970: 1799990000];
        reservation.expiresAt = [OFDate dateWithTimeIntervalSince1970: 1799993600];
        [[reservation insertIntoConnection: connection] await];

        auto fetchedMovie = (AsyncDBTestMovie *)[[AsyncDBTestMovie fetchFromConnection: connection
                                                                            primaryKey: movie.id] await];
        OTAssert(([fetchedMovie.name isEqual: @"Arrival"]), @"ORM fetch should map records by primary key");

        fetchedMovie.runtime = [OFNumber numberWithInt: 117];
        OTAssert(([[fetchedMovie updateInConnection: connection] await].affectedRows),
                 @"ORM update should update rows by primary key");

        auto updatedMovie = (AsyncDBTestMovie *)[[AsyncDBTestMovie fetchFromConnection: connection
                                                                            primaryKey: movie.id] await];
        OTAssert((updatedMovie.runtime.intValue == 117), @"ORM update should persist changed values");

        id<AsyncDBTransaction> transaction = [[connection beginTransaction] await];
        auto rolledBackTicket = [[AsyncDBTestTicket alloc] init];
        rolledBackTicket.showing = showing;
        rolledBackTicket.seat = @"B2";
        rolledBackTicket.price = [OFNumber numberWithInt: 900];
        rolledBackTicket.status = @"reserved";
        [[rolledBackTicket insertIntoConnection: connection] await];
        [[transaction rollback] await];

        auto Tickets = AsyncDBTestTicket.table;
        auto Showings = AsyncDBTestShowing.table;
        auto Movies = AsyncDBTestMovie.table;
        auto Cinemas = AsyncDBTestCinema.table;
        auto Reservations = AsyncDBTestTicketReservation.table;

        id<AsyncDBBooleanPredicate> statusPredicate =
            [(id<AsyncDBComparableExpression>)Tickets.status IN: @[ @"reserved", @"held" ]];
        id<AsyncDBBooleanPredicate> expiryPredicate =
            [(id<AsyncDBOrderedExpression>)Reservations.expiresAt IS_GREATER_THAN: Reservations.reservedAt];
        id<AsyncDBBooleanPredicate> seatPredicate =
            [(id<AsyncDBComparableExpression>)Tickets.seat NOT_IN: @[ @"Z9" ]];

        auto query = [[[[[[[[AsyncDBQueryBuilder<AsyncDBTestTicketReservationQueryRow *> FROM: Tickets]
            JOIN_ALL: @[ Movies, Cinemas, Showings ]]
            LEFT_JOIN: Reservations]
            WHERE: [[statusPredicate AND: expiryPredicate] AND: seatPredicate]]
            ORDER_BY: Showings.startsAt ASC: true]
            ORDER_BY: Cinemas.name ASC: true]
            LIMIT: 50]
            SELECT: @{
                @"movieName": Movies.name,
                @"cinemaName": Cinemas.name,
                @"city": Cinemas.city,
                @"country": Cinemas.country,
                @"auditorium": Showings.auditorium,
                @"startsAt": Showings.startsAt,
                @"seat": Tickets.seat,
                @"price": Tickets.price,
                @"status": Tickets.status,
                @"customerID": Reservations.customerID,
            }
            INTO: AsyncDBTestTicketReservationQueryRow.class];

        auto rows = [[query allInConnection: connection] await];
        OTAssert((rows.count == 1), @"Joined ORM queries should return committed matching rows only");

        auto row = rows[0];
        OTAssert(([row.movieName isEqual: @"Arrival"]), @"Joined ORM queries should map selected movie fields");
        OTAssert(([row.cinemaName isEqual: @"Rio"]), @"Joined ORM queries should map selected cinema fields");
        OTAssert(([row.seat isEqual: @"A1"]), @"Joined ORM queries should map selected ticket fields");
        OTAssert((row.customerID.intValue == 42), @"Joined ORM queries should map selected reservation fields");

        OTAssert(([[reservation deleteFromConnection: connection] await].affectedRows),
                 @"ORM delete should delete rows by primary key");

        auto rowsAfterDelete = [[query allInConnection: connection] await];
        OTAssert((rowsAfterDelete.count == 0), @"Deleted ORM rows should disappear from joined queries");

        [[connection close] await];
    }];
}

@end

#pragma clang assume_nonnull end
