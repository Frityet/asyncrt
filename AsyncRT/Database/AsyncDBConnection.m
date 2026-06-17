#import <AsyncRT/Database/AsyncDBConnection.h>

#pragma clang assume_nonnull begin

@implementation AsyncDBConnectionOptions

+ (instancetype)options
{
    return [[self alloc] init];
}

@end

@implementation AsyncDBWriteResult

+ (instancetype)resultWithAffectedRowCount: (uint64_t)affectedRowCount
{
    return [[self alloc] initWithAffectedRowCount: affectedRowCount];
}

- (instancetype)initWithAffectedRowCount: (uint64_t)affectedRowCount
{
    self = [super init];
    _affectedRowCount = affectedRowCount;
    return self;
}

- (bool)affectedRows
{
    return _affectedRowCount > 0;
}

@end

@implementation OFObject (AsyncDBConnectionConvenience)

- (AsyncTask<AsyncDBWriteResult *> *)asyncdb_executeSQL: (OFString *)SQL
{
    return [self asyncdb_executeSQL: SQL
                             values: [OFArray array]];
}

- (AsyncTask<AsyncDBWriteResult *> *)asyncdb_executeSQL: (OFString *)SQL
                                                 values: (OFArray<id> *)values
{
    if (![self conformsToProtocol: @protocol(AsyncDBConnection)])
        return [AsyncTask rejected: [OFInvalidArgumentException exception]];

    id<AsyncDBConnection> connection = (id<AsyncDBConnection>)self;
    return (AsyncTask<AsyncDBWriteResult *> *)[[connection prepareStatementWithSQL: SQL]
        flatMap: ^AsyncTask *(id<AsyncDBPreparedStatement> statement) {
            return [statement executeWithValues: values];
        }];
}

- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)asyncdb_fetchRowsWithSQL: (OFString *)SQL
{
    return [self asyncdb_fetchRowsWithSQL: SQL
                                   values: [OFArray array]];
}

- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)asyncdb_fetchRowsWithSQL: (OFString *)SQL
                                                                             values: (OFArray<id> *)values
{
    if (![self conformsToProtocol: @protocol(AsyncDBConnection)])
        return [AsyncTask rejected: [OFInvalidArgumentException exception]];

    id<AsyncDBConnection> connection = (id<AsyncDBConnection>)self;
    return (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)[[connection prepareStatementWithSQL: SQL]
        flatMap: ^AsyncTask *(id<AsyncDBPreparedStatement> statement) {
            return [statement fetchRowsWithValues: values];
        }];
}

@end

#pragma clang assume_nonnull end
