#pragma once

#import <AsyncRT/Core.h>

#pragma clang assume_nonnull begin

@protocol AsyncDBTransaction;
@protocol AsyncDBPreparedStatement;

@interface AsyncDBConnectionOptions : OFObject

+ (instancetype)options;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncDBWriteResult : OFObject

@property(readonly, nonatomic) uint64_t affectedRowCount;
@property(readonly, nonatomic) bool affectedRows;

+ (instancetype)resultWithAffectedRowCount: (uint64_t)affectedRowCount;
- (instancetype)initWithAffectedRowCount: (uint64_t)affectedRowCount [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@protocol AsyncDBConnection<OFObject>

@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) OFString *name;

- (AsyncTask<AsyncUnit *> *)open;
- (AsyncTask<AsyncUnit *> *)close;
- (AsyncTask<id<AsyncDBTransaction>> *)beginTransaction;
- (AsyncTask<id<AsyncDBPreparedStatement>> *)prepareStatementWithSQL: (OFString *)SQL;
- (AsyncTask<OFNumber *> *)lastInsertRowID;

@end

@protocol AsyncDBPreparedStatement<OFObject>

@property(readonly, nonatomic) id<AsyncDBConnection> connection;
@property(readonly, copy, nonatomic) OFString *SQL;

- (AsyncTask<AsyncDBWriteResult *> *)execute;
- (AsyncTask<AsyncDBWriteResult *> *)executeWithValues: (OFArray<id> *)values;
- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)fetchRows;
- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)fetchRowsWithValues: (OFArray<id> *)values;

@end

@protocol AsyncDBTransaction<OFObject>

@property(readonly, nonatomic) id<AsyncDBConnection> connection;
@property(readonly, nonatomic) bool isActive;

- (AsyncTask<AsyncUnit *> *)commit;
- (AsyncTask<AsyncUnit *> *)rollback;

@end

@interface OFObject (AsyncDBConnectionConvenience)

- (AsyncTask<AsyncDBWriteResult *> *)asyncdb_executeSQL: (OFString *)SQL;
- (AsyncTask<AsyncDBWriteResult *> *)asyncdb_executeSQL: (OFString *)SQL
                                                 values: (OFArray<id> *)values;
- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)asyncdb_fetchRowsWithSQL: (OFString *)SQL;
- (AsyncTask<OFArray<OFDictionary<OFString *, id> *> *> *)asyncdb_fetchRowsWithSQL: (OFString *)SQL
                                                                             values: (OFArray<id> *)values;

@end

#pragma clang assume_nonnull end
