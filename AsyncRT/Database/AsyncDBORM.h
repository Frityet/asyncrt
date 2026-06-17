#pragma once

#import <AsyncRT/Database/AsyncDBConnection.h>

#pragma clang assume_nonnull begin

@class AsyncDBColumnSchema;
@class AsyncDBEntitySchema;
@class AsyncDBTable;
@class AsyncDBColumnReference;
@class AsyncDBPredicate;
@class AsyncDBDeleteAction;
@class AsyncDBForeignKeyConstraint;
@class AsyncDBSelectQuery<__covariant T>;

@protocol AsyncDBExpression
@end

@protocol AsyncDBBooleanPredicate <AsyncDBExpression>

- (id<AsyncDBBooleanPredicate>)AND: (id<AsyncDBBooleanPredicate>)other;
- (id<AsyncDBBooleanPredicate>)OR: (id<AsyncDBBooleanPredicate>)other;
- (id<AsyncDBBooleanPredicate>)NOT;

@end

@protocol AsyncDBComparableExpression <AsyncDBExpression>

- (id<AsyncDBBooleanPredicate>)IS: (id)other;
- (id<AsyncDBBooleanPredicate>)IS_NOT: (id)other;
- (id<AsyncDBBooleanPredicate>)IN: (OFArray<id> *)values;
- (id<AsyncDBBooleanPredicate>)NOT_IN: (OFArray<id> *)values;

@end

@protocol AsyncDBOrderedExpression <AsyncDBComparableExpression>

- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN: (id)other;
- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN_OR_EQUAL: (id)other;
- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN: (id)other;
- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN_OR_EQUAL: (id)other;

@end

@protocol AsyncDBStringExpression <AsyncDBOrderedExpression>

- (id<AsyncDBBooleanPredicate>)LIKE: (OFString *)pattern;
- (id<AsyncDBBooleanPredicate>)NOT_LIKE: (OFString *)pattern;

@end

@protocol AsyncDBColumn <AsyncDBOrderedExpression>
@end

@protocol AsyncDBPrimaryKey <AsyncDBColumn>
@end

@protocol AsyncDBForeignKey <AsyncDBColumn>

- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column;
- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column
                                  onDelete: (AsyncDBDeleteAction *nillable)deleteAction;

@end

@protocol AsyncDBNullable <AsyncDBColumn>
@end

@protocol AsyncDBUnique <AsyncDBColumn>
@end

@interface OFNumber (AsyncDBExpression) <AsyncDBColumn, AsyncDBPrimaryKey, AsyncDBNullable, AsyncDBUnique>
@end

@interface OFString (AsyncDBExpression) <AsyncDBColumn, AsyncDBPrimaryKey, AsyncDBNullable, AsyncDBUnique, AsyncDBStringExpression>
@end

@interface OFDate (AsyncDBExpression) <AsyncDBColumn, AsyncDBNullable, AsyncDBUnique>
@end

[[subclassing_restricted, direct_members]]
@interface AsyncDBDeleteAction : OFObject

@property(readonly, copy, nonatomic) OFString *SQL;

+ (instancetype)cascade;
+ (instancetype)restrict;
+ (instancetype)setNull;
+ (instancetype)noAction;
+ (instancetype)actionWithSQL: (OFString *)SQL;
- (instancetype)initWithSQL: (OFString *)SQL [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncDBColumnSchema : OFObject

@property(readonly, copy, nonatomic) OFString *propertyName;
@property(readonly, copy, nonatomic) OFString *SQLName;
@property(readonly, copy, nonatomic) OFString *valueClassName;
@property(readonly, nonatomic) Class nillable valueClass;
@property(readonly, nonatomic) bool isPrimaryKey;
@property(readonly, nonatomic) bool isForeignKey;
@property(readonly, nonatomic) bool isNullable;
@property(readonly, nonatomic) bool isUnique;
@property(readonly, nonatomic) Class nillable referencedTableClass;

- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncDBEntitySchema : OFObject

@property(readonly, nonatomic) Class entityClass;
@property(readonly, copy, nonatomic) OFString *tableName;
@property(readonly, copy, nonatomic) OFArray<AsyncDBColumnSchema *> *columns;
@property(readonly, nonatomic) AsyncDBColumnSchema *primaryKeyColumn;

- (AsyncDBColumnSchema *)columnNamed: (OFString *)propertyName;
- (AsyncDBColumnSchema *)columnWithSQLName: (OFString *)SQLName;
- (bool)hasColumnNamed: (OFString *)propertyName;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncDBColumnReference : OFObject<AsyncDBForeignKey, AsyncDBStringExpression>

@property(readonly, nonatomic) AsyncDBTable *table;
@property(readonly, nonatomic) AsyncDBColumnSchema *schema;
@property(readonly, copy, nonatomic) OFString *propertyName;
@property(readonly, copy, nonatomic) OFString *SQLName;

- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncDBForeignKeyConstraint : OFObject

@property(readonly, nonatomic) AsyncDBColumnReference *sourceColumn;
@property(readonly, nonatomic) AsyncDBColumnReference *referencedColumn;
@property(readonly, nonatomic) AsyncDBDeleteAction *nillable deleteAction;

- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBTable : OFObject

@property(readonly, nonatomic) bool isTableReference;
@property(readonly, nonatomic) AsyncDBEntitySchema *schema;

+ (instancetype)table;
+ (AsyncDBEntitySchema *)schema;
+ (OFString *)tableName;
+ (OFDictionary<OFString *, OFString *> *)sqlNameOverrides;
+ (OFArray<OFArray<AsyncDBColumnReference *> *> *)unique;
+ (OFArray<AsyncDBForeignKeyConstraint *> *)relationships;
+ (AsyncTask<AsyncDBWriteResult *> *)createTableInConnection: (id<AsyncDBConnection>)connection;
+ (AsyncTask<__kindof AsyncDBTable *> *)fetchFromConnection: (id<AsyncDBConnection>)connection
                                                 primaryKey: (id)primaryKey;
- (AsyncDBColumnReference *)columnNamed: (OFString *)propertyName;
- (AsyncTask<AsyncDBWriteResult *> *)insertIntoConnection: (id<AsyncDBConnection>)connection;
- (AsyncTask<AsyncDBWriteResult *> *)updateInConnection: (id<AsyncDBConnection>)connection;
- (AsyncTask<AsyncDBWriteResult *> *)deleteFromConnection: (id<AsyncDBConnection>)connection;

@end

@interface AsyncDBTable (AsyncDBForeignKeyExpression) <AsyncDBForeignKey>
@end

@interface AsyncDBQueryBuilder<__covariant T> : OFObject

+ (instancetype)FROM: (AsyncDBTable *)table;

- (instancetype)DISTINCT;
- (instancetype)JOIN: (AsyncDBTable *)table;
- (instancetype)JOIN: (AsyncDBTable *)table ON: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)LEFT_JOIN: (AsyncDBTable *)table;
- (instancetype)LEFT_JOIN: (AsyncDBTable *)table ON: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)CROSS_JOIN: (AsyncDBTable *)table;
- (instancetype)JOIN_ALL: (OFArray<AsyncDBTable *> *)tables;
- (instancetype)WHERE: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)AND_WHERE: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)OR_WHERE: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)GROUP_BY: (OFArray<AsyncDBColumnReference *> *)columns;
- (instancetype)HAVING: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)AND_HAVING: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)OR_HAVING: (id<AsyncDBBooleanPredicate>)predicate;
- (instancetype)ORDER_BY: (id<AsyncDBExpression>)column;
- (instancetype)ORDER_BY: (id<AsyncDBExpression>)column ASC: (bool)ascending;
- (instancetype)LIMIT: (size_t)limit;
- (instancetype)OFFSET: (size_t)offset;
- (instancetype)LIMIT: (size_t)limit OFFSET: (size_t)offset;
- (AsyncDBSelectQuery<T> *)SELECT: (OFDictionary<OFString *, id<AsyncDBExpression>> *)expressions
                             INTO: (Class)resultClass;
- (AsyncDBSelectQuery<T> *)SELECT_ALL_INTO: (Class)resultClass;

@end

[[subclassing_restricted]]
@interface AsyncDBSelectQuery<__covariant T> : OFObject

@property(readonly, copy, nonatomic) OFString *SQL;
@property(readonly, copy, nonatomic) OFArray<id> *boundValues;
@property(readonly, nonatomic) Class resultClass;

- (AsyncTask<OFArray<T> *> *)allInConnection: (id<AsyncDBConnection>)connection;
- (AsyncTask<T> *)firstInConnection: (id<AsyncDBConnection>)connection;
- (AsyncTask<Optional<T> *> *)firstOptionalInConnection: (id<AsyncDBConnection>)connection;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
