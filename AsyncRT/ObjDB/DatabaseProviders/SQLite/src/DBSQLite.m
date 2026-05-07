#import "DBSQLite.h"

#include <sqlite3.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface DBSQLiteTransaction : OFObject<DBTransaction>

@property(readonly, nonatomic) DBSQLiteConnection *connection;
@property(readonly, nonatomic) bool isActive;

- (instancetype)initWithConnection: (DBSQLiteConnection *)connection [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface DBSQLiteConnection ()

@property(nonatomic) sqlite3 *nillable databaseHandle;

- (void)_openDatabase;
- (void)_closeDatabase;
- (DBWriteResult *)_executeSQLSynchronously: (OFString *)SQL values: (OFArray<id> *)values;
- (OFArray<OFDictionary<OFString *, id> *> *)_fetchRowsSynchronouslyWithSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (sqlite3_stmt *)_preparedStatementWithSQL: (OFString *)SQL;
- (void)_bindValue: (id)value toParameter: (int)parameterIndex inStatement: (sqlite3_stmt *)statement;
- (id)_valueForColumn: (int)columnIndex inStatement: (sqlite3_stmt *)statement;
+ (DBSQLiteConnectionOptions *)_SQLiteOptionsFromOptions: (DBConnectionOptions *)options;
+ (OFString *)_pathFromIRI: (OFIRI *)IRI;

@end

@implementation DBSQLiteConnectionOptions

+ (instancetype)readOnlyOptions
{ return [self optionsWithReadOnly: true createsIfNeeded: false]; }

+ (instancetype)optionsWithReadOnly: (bool)isReadOnly createsIfNeeded: (bool)createsIfNeeded
{ return [[self alloc] initWithReadOnly: isReadOnly createsIfNeeded: createsIfNeeded]; }

- (instancetype)init
{ return [self initWithReadOnly: false createsIfNeeded: true]; }

- (instancetype)initWithReadOnly: (bool)isReadOnly
                 createsIfNeeded: (bool)createsIfNeeded
{
    self = [super init];
    _isReadOnly = isReadOnly;
    _createsIfNeeded = createsIfNeeded;
    return self;
}

@end

@implementation DBSQLiteException

- (instancetype)initWithResultCode: (int)resultCode  message: (OFString *)message connection: (DBSQLiteConnection *)connection
{
    self = [super init];
    _resultCode = resultCode;
    _message = [message copy];
    _connection = connection;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"SQLite error %d for '%@': %@", _resultCode, _connection.path, _message];
}

@end

@implementation DBSQLiteConnection

+ (OFString *)dbProviderName
{ return @"sqlite"; }

+ (OFArray<OFString *> *)dbProviderSchemes
{ return @[ @"sqlite", @"sqlite3" ]; }

+ (DBSQLiteConnection *)dbConnectionWithIRI: (OFIRI *)IRI options: (DBConnectionOptions *)options
{ return [[self alloc] initWithIRI: IRI options: [self _SQLiteOptionsFromOptions: options]]; }

- (instancetype)initWithIRI: (OFIRI *)IRI options: (DBSQLiteConnectionOptions *)options
{
    self = [super init];
    _IRI = IRI;
    _path = [self.class _pathFromIRI: IRI];
    _options = options;
    _databaseHandle = nullptr;
    return self;
}

- (bool)isOpen
{
    return _databaseHandle != nullptr;
}

- (OFString *)name
{
    return _path;
}

+ (DBSQLiteConnectionOptions *)_SQLiteOptionsFromOptions: (DBConnectionOptions *)options
{
    if ([options isKindOfClass: DBSQLiteConnectionOptions.class])
        return (DBSQLiteConnectionOptions *)options;

    if ([options isMemberOfClass: DBConnectionOptions.class])
        return [DBSQLiteConnectionOptions options];

    @throw [OFInvalidArgumentException exception];
}

+ (OFString *)_pathFromIRI: (OFIRI *)IRI
{
    if (![IRI.scheme isEqual: @"sqlite"] and ![IRI.scheme isEqual: @"sqlite3"])
        @throw [OFInvalidArgumentException exception];

    OFString *path = IRI.path;

    if ([path isEqual: @"/:memory:"])
        return @":memory:";
    if (path.length == 0)
        @throw [OFInvalidArgumentException exception];

    return path;
}

- (int)_openFlags
{
    if (_options.isReadOnly)
        return SQLITE_OPEN_READONLY;

    if (!_options.createsIfNeeded)
        return SQLITE_OPEN_READWRITE;

    return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;
}

- (OFString *)_lastSQLiteMessageForResultCode: (int)resultCode
{
    const char *message = (_databaseHandle != nullptr
        ? sqlite3_errmsg(_databaseHandle)
        : sqlite3_errstr(resultCode));

    if (message == nullptr)
        return @"unknown SQLite error";

    return [OFString stringWithUTF8String: message];
}

- (DBSQLiteException *)_exceptionWithResultCode: (int)resultCode
{ return [[DBSQLiteException alloc] initWithResultCode: resultCode message: [self _lastSQLiteMessageForResultCode: resultCode] connection: self]; }

- (void)_openDatabase
{
    if (_databaseHandle != nullptr)
        return;

    sqlite3 *databaseHandle = nullptr;
    int resultCode = sqlite3_open_v2(_path.UTF8String, &databaseHandle, self._openFlags, nullptr);

    _databaseHandle = databaseHandle;

    if (resultCode == SQLITE_OK)
        return;

    DBSQLiteException *exception = [self _exceptionWithResultCode: resultCode];

    if (_databaseHandle != nullptr) {
        sqlite3_close(_databaseHandle);
        _databaseHandle = nullptr;
    }

    @throw exception;
}

- (void)_closeDatabase
{
    if (_databaseHandle == nullptr)
        return;

    int resultCode = sqlite3_close(_databaseHandle);
    if (resultCode == SQLITE_OK) {
        _databaseHandle = nullptr;
        return;
    }

    @throw [self _exceptionWithResultCode: resultCode];
}

- (sqlite3_stmt *)_preparedStatementWithSQL: (OFString *)SQL
{
    [self _openDatabase];

    sqlite3_stmt *statement = nullptr;
    int resultCode = sqlite3_prepare_v2(_databaseHandle,
                                        SQL.UTF8String,
                                        -1,
                                        &statement,
                                        nullptr);

    if (resultCode != SQLITE_OK) {
        if (statement != nullptr)
            sqlite3_finalize(statement);

        @throw [self _exceptionWithResultCode: resultCode];
    }

    if (statement == nullptr)
        @throw [OFInvalidArgumentException exception];

    return statement;
}

- (void)_bindValue: (id)value
       toParameter: (int)parameterIndex
       inStatement: (sqlite3_stmt *)statement
{
    int resultCode;

    if ([value isKindOfClass: OFString.class]) {
        auto string = (OFString *)value;
        resultCode = sqlite3_bind_text(statement,
                                       parameterIndex,
                                       string.UTF8String,
                                       -1,
                                       SQLITE_TRANSIENT);
    } else if ([value isKindOfClass: OFNumber.class]) {
        auto number = (OFNumber *)value;
        resultCode = sqlite3_bind_int64(statement,
                                        parameterIndex,
                                        number.longLongValue);
    } else if (value == OFNull.null) {
        resultCode = sqlite3_bind_null(statement, parameterIndex);
    } else {
        @throw [OFInvalidArgumentException exception];
    }

    if (resultCode != SQLITE_OK)
        @throw [self _exceptionWithResultCode: resultCode];
}

- (void)_bindValues: (OFArray<id> *)values
        inStatement: (sqlite3_stmt *)statement
{
    for (size_t index = 0; index < values.count; index++)
        [self _bindValue: values[index]
             toParameter: (int)index + 1
             inStatement: statement];
}

- (id)_valueForColumn: (int)columnIndex
          inStatement: (sqlite3_stmt *)statement
{
    switch (sqlite3_column_type(statement, columnIndex)) {
        case SQLITE_INTEGER:
            return [OFNumber numberWithLongLong: sqlite3_column_int64(statement, columnIndex)];
        case SQLITE_FLOAT:
            return [OFNumber numberWithDouble: sqlite3_column_double(statement, columnIndex)];
        case SQLITE_TEXT: {
            const unsigned char *text = sqlite3_column_text(statement, columnIndex);

            if (text == nullptr)
                return OFNull.null;

            return [OFString stringWithUTF8String: (const char *)text];
        }
        case SQLITE_NULL:
            return OFNull.null;
        case SQLITE_BLOB:
        default:
            @throw [self _exceptionWithResultCode: SQLITE_MISMATCH];
    }
}

- (DBWriteResult *)_executeSQLSynchronously: (OFString *)SQL
                                     values: (OFArray<id> *)values
{
    sqlite3_stmt *statement = [self _preparedStatementWithSQL: SQL];

    @try {
        [self _bindValues: values
              inStatement: statement];

        int resultCode = sqlite3_step(statement);
        if (resultCode != SQLITE_DONE)
            @throw [self _exceptionWithResultCode: resultCode];

        return [DBWriteResult resultWithAffectedRowCount: (uint64_t)sqlite3_changes(_databaseHandle)];
    } @finally {
        sqlite3_finalize(statement);
    }
}

- (OFArray<OFDictionary<OFString *, id> *> *)_fetchRowsSynchronouslyWithSQL: (OFString *)SQL
                                                                     values: (OFArray<id> *)values
{
    sqlite3_stmt *statement = [self _preparedStatementWithSQL: SQL];

    @try {
        [self _bindValues: values
              inStatement: statement];

        auto rows = [OFMutableArray<OFDictionary<OFString *, id> *> array];

        while (true) {
            int resultCode = sqlite3_step(statement);

            if (resultCode == SQLITE_DONE)
                return [rows copy];

            if (resultCode != SQLITE_ROW)
                @throw [self _exceptionWithResultCode: resultCode];

            int columnCount = sqlite3_column_count(statement);
            auto row = [OFMutableDictionary<OFString *, id> dictionaryWithCapacity: (size_t)columnCount];

            for (int columnIndex = 0; columnIndex < columnCount; columnIndex++) {
                const char *columnName = sqlite3_column_name(statement, columnIndex);

                if (columnName == nullptr)
                    @throw [self _exceptionWithResultCode: SQLITE_MISMATCH];

                row[[OFString stringWithUTF8String: columnName]] = [self _valueForColumn: columnIndex
                                                                             inStatement: statement];
            }

            [rows addObject: [row copy]];
        }
    } @finally {
        sqlite3_finalize(statement);
    }
}

- (Task<AsyncUnit *> *)open
{
    @try {
        [self _openDatabase];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    return [Task resolved: AsyncUnit.unit];
}

- (Task<AsyncUnit *> *)close
{
    @try {
        [self _closeDatabase];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    return [Task resolved: AsyncUnit.unit];
}

- (Task<id<DBTransaction>> *)beginTransaction
{
    @try {
        [self _executeSQLSynchronously: @"BEGIN IMMEDIATE TRANSACTION"
                                values: @[]];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    return [Task resolved: [[DBSQLiteTransaction alloc] initWithConnection: self]];
}

- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL
{
    return [self executeSQL: SQL
                     values: @[]];
}

- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL
                               values: (OFArray<id> *)values
{
    DBWriteResult *result;

    @try {
        result = [self _executeSQLSynchronously: SQL
                                         values: values];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    return [Task resolved: result];
}

- (Task<OFArray<OFDictionary<OFString *, id> *> *> *)fetchRowsWithSQL: (OFString *)SQL
                                                               values: (OFArray<id> *)values
{
    OFArray<OFDictionary<OFString *, id> *> *rows;

    @try {
        rows = [self _fetchRowsSynchronouslyWithSQL: SQL
                                             values: values];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    return [Task resolved: rows];
}

- (Task<OFNumber *> *)lastInsertRowID
{
    @try {
        [self _openDatabase];
        return [Task resolved: [OFNumber numberWithLongLong: sqlite3_last_insert_rowid(_databaseHandle)]];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }
}

- (void)dealloc
{
    if (_databaseHandle != nullptr)
        sqlite3_close(_databaseHandle);
}

@end

@implementation DBSQLiteTransaction

- (instancetype)initWithConnection: (DBSQLiteConnection *)connection
{
    self = [super init];
    _connection = connection;
    _isActive = true;
    return self;
}

- (Task<AsyncUnit *> *)_finishWithSQL: (OFString *)SQL
{
    if (not _isActive)
        return [Task rejected: [OFInvalidArgumentException exception]];

    @try {
        [_connection _executeSQLSynchronously: SQL
                                       values: @[]];
    } @catch (OFException *exception) {
        return [Task rejected: exception];
    }

    _isActive = false;
    return [Task resolved: AsyncUnit.unit];
}

- (Task<AsyncUnit *> *)commit
{
    return [self _finishWithSQL: @"COMMIT"];
}

- (Task<AsyncUnit *> *)rollback
{
    return [self _finishWithSQL: @"ROLLBACK"];
}

@end

#pragma clang assume_nonnull end
