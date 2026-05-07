#pragma once

#import "DBProvider.h"

#pragma clang assume_nonnull begin

@class DBSQLiteConnection;

[[subclassing_restricted]]
@interface DBSQLiteConnectionOptions : DBConnectionOptions

@property(readonly, nonatomic) bool isReadOnly;
@property(readonly, nonatomic) bool createsIfNeeded;

+ (instancetype)readOnlyOptions;
+ (instancetype)optionsWithReadOnly: (bool)isReadOnly createsIfNeeded: (bool)createsIfNeeded;
- (instancetype)initWithReadOnly: (bool)isReadOnly createsIfNeeded: (bool)createsIfNeeded [[designated_initailiser]];

@end

[[subclassing_restricted, direct_members]]
@interface DBSQLiteException : OFException

@property(readonly, nonatomic) int resultCode;
@property(readonly, copy, nonatomic) OFString *message;
@property(readonly, nonatomic) DBSQLiteConnection *connection;

- (instancetype)initWithResultCode: (int)resultCode message: (OFString *)message connection: (DBSQLiteConnection *)connection [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface DBSQLiteConnection : OFObject<DBProvider, DBSQLConnection>

@property(readonly, nonatomic) OFIRI *IRI;
@property(readonly, nonatomic) OFString *path;
@property(readonly, nonatomic) DBSQLiteConnectionOptions *options;
@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) OFString *name;

+ (DBSQLiteConnection *)dbConnectionWithIRI: (OFIRI *)IRI options: (DBConnectionOptions *)options;
- (instancetype)initWithIRI: (OFIRI *)IRI options: (DBSQLiteConnectionOptions *)options [[designated_initailiser]];
- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL;
- (Task<DBWriteResult *> *)executeSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (Task<OFArray<OFDictionary<OFString *, id> *> *> *)fetchRowsWithSQL: (OFString *)SQL values: (OFArray<id> *)values;
- (Task<OFNumber *> *)lastInsertRowID;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
