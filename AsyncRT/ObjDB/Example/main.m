#import "AsyncApplication.h"
#import "DBConnection.h"
#import "DBEntity.h"
#import "DBProvider.h"
#import "DBQuery.h"
#import "DBRepository.h"
#import "ObjDBModule.h"
#import "DBSQLite.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ObjDBExampleNote : OFObject<DBRecordCoding, DBPrimaryKeyedEntity>

@property(readonly, nonatomic) OFNumber *noteID;
@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, copy, nonatomic) OFString *body;
@property(readonly, nonatomic) OFNumber *priority;
@property(readonly, nonatomic) bool isArchived;

+ (instancetype)noteWithID: (OFNumber *)noteID title: (OFString *)title body: (OFString *)body priority: (OFNumber *)priority isArchived: (bool)isArchived;
- (instancetype)initWithID: (OFNumber *)noteID title: (OFString *)title body: (OFString *)body priority: (OFNumber *)priority isArchived: (bool)isArchived [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation ObjDBExampleNote

+ (instancetype)noteWithID: (OFNumber *)noteID
                     title: (OFString *)title
                      body: (OFString *)body
                  priority: (OFNumber *)priority
                isArchived: (bool)isArchived
{
    return [[self alloc] initWithID: noteID title: title body: body priority: priority isArchived: isArchived];
}

- (instancetype)initWithID: (OFNumber *)noteID
                     title: (OFString *)title
                      body: (OFString *)body
                  priority: (OFNumber *)priority
                isArchived: (bool)isArchived
{
    self = [super init];
    _noteID = noteID;
    _title = [title copy];
    _body = [body copy];
    _priority = priority;
    _isArchived = isArchived;
    return self;
}

+ (OFString *)dbEntityName
{
    return @"notes";
}

+ (instancetype)dbEntityFromFields: (OFDictionary<OFString *, id> *)fields
{
    OFNumber *noteID = (OFNumber *)$assert_nonnil(fields[@"id"]);
    OFString *title = (OFString *)$assert_nonnil(fields[@"title"]);
    OFString *body = (OFString *)$assert_nonnil(fields[@"body"]);
    OFNumber *priority = (OFNumber *)$assert_nonnil(fields[@"priority"]);
    OFNumber *archived = (OFNumber *)$assert_nonnil(fields[@"archived"]);

    return [self noteWithID: noteID
                      title: title
                       body: body
                   priority: priority
                 isArchived: archived.boolValue];
}

- (OFDictionary<OFString *, id> *)dbFields
{
    return @{
        @"id": _noteID,
        @"title": _title,
        @"body": _body,
        @"priority": _priority,
        @"archived": @(_isArchived)
    };
}

- (id)dbPrimaryKey
{
    return _noteID;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"#%@ %@ (priority %@, archived: %@)", _noteID, _title, _priority, (_isArchived ? @"yes" : @"no")];
}

@end

[[subclassing_restricted]]
@interface ObjDBExampleNoteRepository : DBRepository<ObjDBExampleNote *, OFNumber *>

- (Task<DBWriteResult *> *)createStorage;
- (Task<DBWriteResult *> *)dropStorage;

@end

@interface ObjDBExampleNoteRepository ()

@property(readonly, nonatomic) DBSQLiteConnection *sqliteConnection;
@property(readonly, nonatomic) id<DBSQLConnection> sqlConnection;

- (Task<DBWriteResult *> *)_executeStatementWithSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (ObjDBExampleNote *)_noteFromRow: (OFDictionary<OFString *, id> *)row;
- (OFArray<ObjDBExampleNote *> *)_notesFromRows: (OFArray<OFDictionary<OFString *, id> *> *)rows;
- (OFString *)_validatedColumnNameForFieldName: (OFString *)fieldName;
- (OFString *)_whereClauseForQuery: (DBQuery<ObjDBExampleNote *> *)query values: (OFMutableArray<id> *)values;
- (OFString *)_orderClauseForQuery: (DBQuery<ObjDBExampleNote *> *)query;
- (OFString *)_selectSQLForQuery: (DBQuery<ObjDBExampleNote *> *)query values: (OFMutableArray<id> *)values;
- (Task<OFArray<OFDictionary<OFString *, id> *> *> *)_rowsForQuery: (DBQuery<ObjDBExampleNote *> *)query;

@end

@implementation ObjDBExampleNoteRepository

- (DBSQLiteConnection *)sqliteConnection
{
    if (not [self.connection isKindOfClass: DBSQLiteConnection.class])
        @throw [OFInvalidArgumentException exception];

    return (DBSQLiteConnection *)self.connection;
}

- (id<DBSQLConnection>)sqlConnection
{
    if (not [self.connection conformsToProtocol: @protocol(DBSQLConnection)])
        @throw [OFInvalidArgumentException exception];

    return (id<DBSQLConnection>)self.connection;
}

- (Task<DBWriteResult *> *)_executeStatementWithSQL: (OFString *)SQL
                                             values: (OFArray<id> *)values
{
    return [self.sqlConnection executeSQL: SQL
                                   values: values];
}

- (ObjDBExampleNote *)_noteFromRow: (OFDictionary<OFString *, id> *)row
{
    return [ObjDBExampleNote noteWithID: (OFNumber *)$assert_nonnil(row[@"id"])
                                  title: (OFString *)$assert_nonnil(row[@"title"])
                                   body: (OFString *)$assert_nonnil(row[@"body"])
                               priority: (OFNumber *)$assert_nonnil(row[@"priority"])
                             isArchived: ((OFNumber *)$assert_nonnil(row[@"archived"])).boolValue];
}

- (OFArray<ObjDBExampleNote *> *)_notesFromRows: (OFArray<OFDictionary<OFString *, id> *> *)rows
{
    auto notes = [OFMutableArray<ObjDBExampleNote *> arrayWithCapacity: rows.count];

    for (OFDictionary<OFString *, id> *row in rows)
        [notes addObject: [self _noteFromRow: row]];

    return [notes copy];
}

- (OFString *)_validatedColumnNameForFieldName: (OFString *)fieldName
{
    if ([fieldName isEqual: @"id"] or [fieldName isEqual: @"title"] or [fieldName isEqual: @"body"] or [fieldName isEqual: @"priority"] or [fieldName isEqual: @"archived"])
        return fieldName;

    @throw [OFInvalidArgumentException exception];
}

- (OFString *)_whereClauseForQuery: (DBQuery<ObjDBExampleNote *> *)query
                            values: (OFMutableArray<id> *)values
{
    if (query.predicates.count == 0)
        return @"";

    auto clauses = [OFMutableArray<OFString *> arrayWithCapacity: query.predicates.count];

    for (DBPredicate<ObjDBExampleNote *, id, id> *predicate in query.predicates) {
        OFString *columnName = [self _validatedColumnNameForFieldName: predicate.field.fieldName];

        switch (predicate.comparisonOperator) {
            case DBComparisonOperator_EQUAL:
                [clauses addObject: [OFString stringWithFormat: @"%@ = ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_NOT_EQUAL:
                [clauses addObject: [OFString stringWithFormat: @"%@ <> ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_LESS_THAN:
                [clauses addObject: [OFString stringWithFormat: @"%@ < ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_LESS_THAN_OR_EQUAL:
                [clauses addObject: [OFString stringWithFormat: @"%@ <= ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_GREATER_THAN:
                [clauses addObject: [OFString stringWithFormat: @"%@ > ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_GREATER_THAN_OR_EQUAL:
                [clauses addObject: [OFString stringWithFormat: @"%@ >= ?", columnName]];
                [values addObject: predicate.value];
                break;
            case DBComparisonOperator_CONTAINS:
                [clauses addObject: [OFString stringWithFormat: @"%@ LIKE ?", columnName]];
                [values addObject: [OFString stringWithFormat: @"%%%@%%", predicate.value]];
                break;
            case DBComparisonOperator_CONTAINED_IN: {
                auto containedValues = (OFArray<id> *)predicate.value;

                if (containedValues.count == 0) {
                    [clauses addObject: @"0 = 1"];
                    break;
                }

                auto placeholders = [OFMutableArray<OFString *> arrayWithCapacity: containedValues.count];
                for (id containedValue in containedValues) {
                    [placeholders addObject: @"?"];
                    [values addObject: containedValue];
                }

                [clauses addObject: [OFString stringWithFormat: @"%@ IN (%@)",
                                                               columnName,
                                                               [placeholders componentsJoinedByString: @", "]]];
                break;
            }
        }
    }

    return [OFString stringWithFormat: @" WHERE %@",
                                      [clauses componentsJoinedByString: @" AND "]];
}

- (OFString *)_orderClauseForQuery: (DBQuery<ObjDBExampleNote *> *)query
{
    if (query.sortDescriptors.count == 0)
        return @"";

    auto clauses = [OFMutableArray<OFString *> arrayWithCapacity: query.sortDescriptors.count];

    for (DBSortDescriptor<ObjDBExampleNote *> *sortDescriptor in query.sortDescriptors) {
        OFString *columnName = [self _validatedColumnNameForFieldName: sortDescriptor.fieldName];
        [clauses addObject: [OFString stringWithFormat: @"%@ %@",
                                                       columnName,
                                                       (sortDescriptor.isAscending ? @"ASC" : @"DESC")]];
    }

    return [OFString stringWithFormat: @" ORDER BY %@",
                                      [clauses componentsJoinedByString: @", "]];
}

- (OFString *)_selectSQLForQuery: (DBQuery<ObjDBExampleNote *> *)query
                          values: (OFMutableArray<id> *)values
{
    auto SQL = [OFMutableString stringWithString: @"SELECT id, title, body, priority, archived FROM notes"];

    [SQL appendString: [self _whereClauseForQuery: query values: values]];
    [SQL appendString: [self _orderClauseForQuery: query]];

    if (query.hasLimit)
        [SQL appendFormat: @" LIMIT %zu", query.limit];
    else if (query.offset > 0)
        [SQL appendString: @" LIMIT -1"];

    if (query.offset > 0)
        [SQL appendFormat: @" OFFSET %zu", query.offset];

    return SQL;
}

- (Task<OFArray<OFDictionary<OFString *, id> *> *> *)_rowsForQuery: (DBQuery<ObjDBExampleNote *> *)query
{
    auto values = [OFMutableArray array];
    OFString *SQL = [self _selectSQLForQuery: query values: values];
    return [self.sqlConnection fetchRowsWithSQL: SQL values: values];
}

- (Task<DBWriteResult *> *)createStorage
{
    return [self.sqlConnection executeSQL:
        @"CREATE TABLE IF NOT EXISTS notes ("
         "id INTEGER PRIMARY KEY AUTOINCREMENT, "
         "title TEXT NOT NULL, "
         "body TEXT NOT NULL, "
         "priority INTEGER NOT NULL, "
         "archived INTEGER NOT NULL DEFAULT 0"
         ")"];
}

- (Task<DBWriteResult *> *)dropStorage
{
    return [self.sqlConnection executeSQL: @"DROP TABLE IF EXISTS notes"];
}

- (Task<Optional<ObjDBExampleNote *> *> *)findByPrimaryKey: (OFNumber *)primaryKey
{
    auto idField = [DBField<ObjDBExampleNote *, OFNumber *> fieldWithName: @"id"
                                                               valueClass: OFNumber.class];
    auto rowsTask = [self _rowsForQuery: [self.query where: [idField isEqualTo: primaryKey]]];

    return (Task<Optional<ObjDBExampleNote *> *> *)[rowsTask mapOnScheduler: AsyncScheduler.defaultScheduler
                                                                   transform: ^id(OFArray<OFDictionary<OFString *, id> *> *rows) {
        OFArray<ObjDBExampleNote *> *notes = [self _notesFromRows: rows];
        return (notes.count == 0 ? [Optional none] : [Optional some: notes[0]]);
    }];
}

- (Task<OFArray<ObjDBExampleNote *> *> *)fetch: (DBQuery<ObjDBExampleNote *> *)query
{
    return (Task<OFArray<ObjDBExampleNote *> *> *)[[self _rowsForQuery: query] mapOnScheduler: AsyncScheduler.defaultScheduler
                                                                                    transform: ^id(OFArray<OFDictionary<OFString *, id> *> *rows) {
        return [self _notesFromRows: rows];
    }];
}

- (Task<OFNumber *> *)count: (DBQuery<ObjDBExampleNote *> *)query
{
    auto values = [OFMutableArray<id> array];
    auto SQL = [OFMutableString stringWithString: @"SELECT COUNT(*) AS count FROM notes"];
    [SQL appendString: [self _whereClauseForQuery: query values: values]];

    auto rowsTask = [self.sqlConnection fetchRowsWithSQL: SQL
                                                  values: values];

    return (Task<OFNumber *> *)[rowsTask mapOnScheduler: AsyncScheduler.defaultScheduler
                                              transform: ^id(OFArray<OFDictionary<OFString *, id> *> *rows) {
        if (rows.count != 1)
            @throw [OFInvalidArgumentException exception];

        return (OFNumber *)$assert_nonnil(rows[0][@"count"]);
    }];
}

- (Task<ObjDBExampleNote *> *)insert: (ObjDBExampleNote *)entity
{
    auto insertTask = [self.sqlConnection executeSQL: @"INSERT INTO notes (title, body, priority, archived) VALUES (?, ?, ?, ?)"
                                             values: @[
                                                 entity.title,
                                                 entity.body,
                                                 entity.priority,
                                                 [OFNumber numberWithBool: entity.isArchived]
                                             ]];

    return (Task<ObjDBExampleNote *> *)[insertTask flatMapOnScheduler: AsyncScheduler.defaultScheduler
                                                            transform: ^Task *(DBWriteResult *result) {
        (void)result;
        return [[self.sqlConnection lastInsertRowID] mapOnScheduler: AsyncScheduler.defaultScheduler
                                                          transform: ^id(OFNumber *noteID) {
            return [ObjDBExampleNote noteWithID: noteID
                                          title: entity.title
                                           body: entity.body
                                       priority: entity.priority
                                     isArchived: entity.isArchived];
        }];
    }];
}

- (Task<ObjDBExampleNote *> *)update: (ObjDBExampleNote *)entity
{
    return (Task<ObjDBExampleNote *> *)[[self _executeStatementWithSQL:
        @"UPDATE notes SET title = ?, body = ?, priority = ?, archived = ? WHERE id = ?"
                                                       values: @[
                                                           entity.title,
                                                           entity.body,
                                                           entity.priority,
                                                           [OFNumber numberWithBool: entity.isArchived],
                                                           (OFNumber *)entity.dbPrimaryKey
                                                       ]] mapOnScheduler: AsyncScheduler.defaultScheduler
                                                                transform: ^id(DBWriteResult *result) {
        (void)result;
        return entity;
    }];
}

- (Task<ObjDBExampleNote *> *)upsert: (ObjDBExampleNote *)entity
{
    return (Task<ObjDBExampleNote *> *)[[self _executeStatementWithSQL:
        @"INSERT INTO notes (id, title, body, priority, archived) VALUES (?, ?, ?, ?, ?) "
         "ON CONFLICT(id) DO UPDATE SET "
         "title = excluded.title, "
         "body = excluded.body, "
         "priority = excluded.priority, "
         "archived = excluded.archived"
                                                       values: @[
                                                           (OFNumber *)entity.dbPrimaryKey,
                                                           entity.title,
                                                           entity.body,
                                                           entity.priority,
                                                           [OFNumber numberWithBool: entity.isArchived]
                                                       ]] mapOnScheduler: AsyncScheduler.defaultScheduler
                                                                transform: ^id(DBWriteResult *result) {
        (void)result;
        return entity;
    }];
}

- (Task<DBWriteResult *> *)deleteByPrimaryKey: (OFNumber *)primaryKey
{
    return [self _executeStatementWithSQL: @"DELETE FROM notes WHERE id = ?"
                                   values: @[primaryKey]];
}

- (Task<DBWriteResult *> *)deleteWhere: (DBQuery<ObjDBExampleNote *> *)query
{
    auto values = [OFMutableArray<id> array];
    auto SQL = [OFMutableString stringWithString: @"DELETE FROM notes"];
    [SQL appendString: [self _whereClauseForQuery: query values: values]];

    return [self _executeStatementWithSQL: SQL
                                   values: values];
}

@end

[[subclassing_restricted]]
@interface ObjDBExampleApplication : AsyncApplication
@end

@implementation ObjDBExampleApplication

- (void)_printNotes: (OFArray<ObjDBExampleNote *> *)notes heading: (OFString *)heading
{
    [OFStdOut writeLine: heading];
    for (ObjDBExampleNote *note in notes)
        [OFStdOut writeFormat: @"  %@\n", note];
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;
    (void)taskGroup;

    auto registry = DBProviderRegistry.defaultRegistry;
    bool hasNamedProvider = [registry hasProviderNamed: @"sqlite"];
    bool hasSchemeProvider = [registry hasProviderForScheme: @"sqlite3"];
    auto options = [DBSQLiteConnectionOptions optionsWithReadOnly: false
                                                  createsIfNeeded: true];
    auto connection = [registry connectionWithProviderName: @"sqlite"
                                                       IRI: [OFIRI IRIWithString: @"sqlite3:///:memory:"]
                                                   options: options];

    if (not [connection isKindOfClass: DBSQLiteConnection.class])
        @throw [OFInvalidArgumentException exception];

    auto sqliteConnection = (DBSQLiteConnection *)connection;
    auto schema = [DBEntitySchema<ObjDBExampleNote *, OFNumber *> schemaWithEntityClass: ObjDBExampleNote.class
                                                                             entityName: @"notes"
                                                                        primaryKeyClass: OFNumber.class];
    auto repository = [[ObjDBExampleNoteRepository alloc] initWithConnection: sqliteConnection
                                                                      schema: schema];
    auto titleField = [DBField<ObjDBExampleNote *, OFString *> fieldWithName: @"title"
                                                                  valueClass: OFString.class];
    auto bodyField = [DBField<ObjDBExampleNote *, OFString *> fieldWithName: @"body"
                                                                 valueClass: OFString.class];
    auto priorityField = [DBField<ObjDBExampleNote *, OFNumber *> fieldWithName: @"priority"
                                                                     valueClass: OFNumber.class];
    auto archivedField = [DBField<ObjDBExampleNote *, OFNumber *> fieldWithName: @"archived"
                                                                     valueClass: OFNumber.class];

    [OFStdOut writeFormat: @"%@/%@ via providers %@ (name %@, scheme %@)\n",
                              ObjDBModule.moduleName,
                              ObjDBModule.toolName,
                              [registry.providerNames componentsJoinedByString: @", "],
                              (hasNamedProvider ? @"yes" : @"no"),
                              (hasSchemeProvider ? @"yes" : @"no")];

    [OFStdOut writeFormat: @"schema %@ primary key %@ on %@\n",
                              schema.entityName,
                              schema.primaryKeyClass,
                              sqliteConnection.name];

    auto openResult = [[sqliteConnection open] await];
    (void)openResult;
    auto dropResult = [[repository dropStorage] await];
    (void)dropResult;
    DBWriteResult *createResult = [[repository createStorage] await];
    [OFStdOut writeFormat: @"created storage, affected rows: %@\n",
                              (createResult.affectedRows ? @"yes" : @"no")];

    @try {
        id<DBTransaction> rolledBackTransaction = [[sqliteConnection beginTransaction] await];
        (void)[[repository insert: [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 0]
                                                          title: @"rolled back"
                                                           body: @"this row should disappear"
                                                       priority: [OFNumber numberWithInt: 1]
                                                     isArchived: false]] await];
        auto rollbackResult = [[rolledBackTransaction rollback] await];
        (void)rollbackResult;

        id<DBTransaction> committedTransaction = [[sqliteConnection beginTransaction] await];

        auto asyncNote = [[repository insert: [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 0]
                                                                       title: @"Async application sample"
                                                                        body: @"Uses providers, entities, repositories, queries, and SQLite"
                                                                    priority: [OFNumber numberWithInt: 5]
                                                                  isArchived: false]] await];
        auto queryNote = [[repository insert: [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 0]
                                                                       title: @"Typed query builder"
                                                                        body: @"Shows predicates, sorting, limits, and offsets"
                                                                    priority: [OFNumber numberWithInt: 3]
                                                                  isArchived: false]] await];
        auto archiveNote = [[repository insert: [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 0]
                                                                         title: @"Archived repository draft"
                                                                          body: @"Will be updated, upserted, fetched, and deleted"
                                                                      priority: [OFNumber numberWithInt: 2]
                                                                    isArchived: true]] await];

        auto updatedArchiveNote = [ObjDBExampleNote noteWithID: archiveNote.noteID
                                                         title: @"Archived repository draft"
                                                          body: @"Updated through DBRepository.update:"
                                                      priority: [OFNumber numberWithInt: 4]
                                                    isArchived: true];
        auto updateResult = [[repository update: updatedArchiveNote] await];
        (void)updateResult;

        auto upsertedNote = [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 99]
                                                  title: @"Manual primary key upsert"
                                                   body: @"Inserted through DBRepository.upsert:"
                                               priority: [OFNumber numberWithInt: 2]
                                             isArchived: false];
        auto upsertResult = [[repository upsert: upsertedNote] await];
        (void)upsertResult;
        auto staleNote = [[repository insert: [ObjDBExampleNote noteWithID: [OFNumber numberWithLongLong: 0]
                                                                    title: @"Low priority cleanup"
                                                                     body: @"Deleted by a typed less-than query"
                                                                 priority: [OFNumber numberWithInt: 1]
                                                               isArchived: false]] await];
        (void)staleNote;
        auto commitResult = [[committedTransaction commit] await];
        (void)commitResult;

        auto roundTrippedNote = [ObjDBExampleNote dbEntityFromFields: asyncNote.dbFields];
        [OFStdOut writeFormat: @"record coding round-trip: %@\n", roundTrippedNote];

        Optional<ObjDBExampleNote *> *foundNote = [[repository findByPrimaryKey: queryNote.noteID] await];
        [OFStdOut writeFormat: @"find by primary key %@: %@\n",
                                  queryNote.noteID,
                                  (foundNote.hasValue ? foundNote.value.title : @"missing")];

        auto visibleQuery = [[[[[[repository.query where: [titleField isNotEqualTo: @"rolled back"]]
                                                  where: [bodyField contains: @"DBRepository"]]
                                                  where: [priorityField isGreaterThanOrEqualTo: [OFNumber numberWithInt: 2]]]
                                                  where: [priorityField isLessThanOrEqualTo: [OFNumber numberWithInt: 5]]]
                                                  where: [priorityField isContainedIn: @[
                                                      [OFNumber numberWithInt: 3],
                                                      [OFNumber numberWithInt: 4],
                                                      [OFNumber numberWithInt: 5]
                                                  ]]]
                                                  sortedBy: priorityField.descending];
        visibleQuery = [[visibleQuery sortedBy: titleField.ascending] limitedTo: 10];
        visibleQuery = [visibleQuery offsetBy: 0];

        [self _printNotes: [[repository fetch: visibleQuery] await]
                  heading: @"filtered notes:"];

        auto activeQuery = [repository.query where: [archivedField isEqualTo: [OFNumber numberWithBool: false]]];
        auto highPriorityQuery = [repository.query where: [priorityField isGreaterThan: [OFNumber numberWithInt: 3]]];
        auto staleQuery = [repository.query where: [priorityField isLessThan: [OFNumber numberWithInt: 2]]];
        OFNumber *activeCount = [[repository count: activeQuery] await];
        OFNumber *highPriorityCount = [[repository count: highPriorityQuery] await];
        DBWriteResult *deletedStaleRows = [[repository deleteWhere: staleQuery] await];
        DBWriteResult *deletedUpsertedRow = [[repository deleteByPrimaryKey: upsertedNote.noteID] await];

        [OFStdOut writeFormat: @"active %@, high priority %@, deleted stale %llu, deleted key %@: %llu\n",
                                  activeCount,
                                  highPriorityCount,
                                  deletedStaleRows.affectedRowCount,
                                  upsertedNote.noteID,
                                  deletedUpsertedRow.affectedRowCount];

        Task<DBWriteResult *> *invalidSQLTask = [sqliteConnection executeSQL:
            @"INSERT INTO missing_table DEFAULT VALUES"];
        OFException *failure = invalidSQLTask.failureException;

        if (invalidSQLTask.status == AsyncTaskStatus_REJECTED and
            [failure isKindOfClass: DBSQLiteException.class]) {
            auto SQLiteException = (DBSQLiteException *)failure;
            [OFStdOut writeFormat: @"captured SQLite exception %d from %@\n",
                                      SQLiteException.resultCode,
                                      SQLiteException.connection.name];
        }
    } @finally {
        auto closeResult = [[sqliteConnection close] await];
        (void)closeResult;
    }

    return @0;
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(ObjDBExampleApplication)
