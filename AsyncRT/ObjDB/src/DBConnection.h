#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

@protocol DBTransaction;

@interface DBConnectionOptions : OFObject

+ (instancetype)options;

@end

[[subclassing_restricted, direct_members]]
@interface DBWriteResult : OFObject

@property(readonly, nonatomic) uint64_t affectedRowCount;
@property(readonly, nonatomic) bool affectedRows;

+ (instancetype)resultWithAffectedRowCount: (uint64_t)affectedRowCount;
- (instancetype)initWithAffectedRowCount: (uint64_t)affectedRowCount [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@protocol DBConnection<OFObject>

@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) OFString *name;

- (Task<AsyncUnit *> *)open;
- (Task<AsyncUnit *> *)close;
- (Task<id<DBTransaction>> *)beginTransaction;

@end

@protocol DBSQLConnection<DBConnection>

- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL;
- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (Task<OFArray<OFDictionary<OFString *, id> *> *> *)fetchRowsWithSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (Task<OFNumber *> *)lastInsertRowID;

@end

@protocol DBTransaction<OFObject>

@property(readonly, nonatomic) id<DBConnection> connection;
@property(readonly, nonatomic) bool isActive;

- (Task<AsyncUnit *> *)commit;
- (Task<AsyncUnit *> *)rollback;

@end

#pragma clang assume_nonnull end
