#pragma once

#import <AsyncRT/Database.h>

#pragma clang assume_nonnull begin

@class AsyncDBSQLiteConnection;

[[subclassing_restricted]]
@interface AsyncDBSQLiteConnectionOptions : AsyncDBConnectionOptions

@property(readonly, nonatomic) bool isReadOnly;
@property(readonly, nonatomic) bool createsIfNeeded;

+ (instancetype)readOnlyOptions;
+ (instancetype)optionsWithReadOnly: (bool)isReadOnly createsIfNeeded: (bool)createsIfNeeded;
- (instancetype)initWithReadOnly: (bool)isReadOnly createsIfNeeded: (bool)createsIfNeeded [[designated_initailiser]];

@end

[[subclassing_restricted, direct_members]]
@interface AsyncDBSQLiteException : OFException

@property(readonly, nonatomic) int resultCode;
@property(readonly, copy, nonatomic) OFString *message;
@property(readonly, nonatomic) AsyncDBSQLiteConnection *connection;

- (instancetype)initWithResultCode: (int)resultCode message: (OFString *)message connection: (AsyncDBSQLiteConnection *)connection [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncDBSQLiteConnection : OFObject<AsyncDBProvider, AsyncDBConnection>

@property(readonly, nonatomic) OFIRI *IRI;
@property(readonly, nonatomic) OFString *path;
@property(readonly, nonatomic) AsyncDBSQLiteConnectionOptions *options;
@property(readonly, nonatomic) bool isOpen;
@property(readonly, nonatomic) OFString *name;

+ (AsyncDBSQLiteConnection *)dbConnectionWithIRI: (OFIRI *)IRI options: (AsyncDBConnectionOptions *)options;
- (instancetype)initWithIRI: (OFIRI *)IRI options: (AsyncDBSQLiteConnectionOptions *)options [[designated_initailiser]];
- (AsyncTask<id<AsyncDBPreparedStatement>> *)prepareStatementWithSQL: (OFString *)SQL;
- (AsyncTask<OFNumber *> *)lastInsertRowID;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
