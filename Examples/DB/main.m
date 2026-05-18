#import <AsyncRT/Application/Core.h>
#import <AsyncRT/Database/Providers/SQLite.h>

#pragma clang assume_nonnull begin

@interface AsyncDBExampleApplication : AsyncApplication
@end

@implementation AsyncDBExampleApplication

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;
    (void)taskGroup;

    auto connection = [AsyncDBSQLiteConnection dbConnectionWithIRI: [OFIRI IRIWithString: @"sqlite:///:memory:"]
                                                           options: [AsyncDBSQLiteConnectionOptions options]];

    [[connection open] await];

    id<AsyncDBPreparedStatement> createStatement =
        [[connection prepareStatementWithSQL: @"CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, body TEXT NOT NULL)"] await];
    [[createStatement execute] await];

    id<AsyncDBPreparedStatement> insertStatement =
        [[connection prepareStatementWithSQL: @"INSERT INTO notes (body) VALUES (?)"] await];
    [[insertStatement executeWithValues: [OFArray arrayWithObject: @"hello from AsyncDB"]] await];

    id<AsyncDBPreparedStatement> selectStatement =
        [[connection prepareStatementWithSQL: @"SELECT id, body FROM notes ORDER BY id"] await];
    auto rows = [[selectStatement fetchRows] await];

    for (OFDictionary<OFString *, id> *row in rows)
        [OFStdOut writeLine: [OFString stringWithFormat: @"%@ %@", row[@"id"], row[@"body"]]];

    [[connection close] await];
    return AsyncUnit.unit;
}

@end

OF_APPLICATION_DELEGATE(AsyncDBExampleApplication)

#pragma clang assume_nonnull end
