#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

@protocol DBEntity<OFObject>

+ (OFString *)dbEntityName;

@end

@protocol DBRecordCoding<DBEntity>

+ (instancetype)dbEntityFromFields: (OFDictionary<OFString *, id> *)fields;
- (OFDictionary<OFString *, id> *)dbFields;

@end

@protocol DBPrimaryKeyedEntity<DBEntity>

- (id)dbPrimaryKey;

@end

[[subclassing_restricted, direct_members]]
@interface DBEntitySchema<covariant EntityType : id<DBEntity>, KeyType> : OFObject

@property(readonly, nonatomic) Class<DBEntity> entityClass;
@property(readonly, copy, nonatomic) OFString *entityName;
@property(readonly, nonatomic) Class primaryKeyClass;

+ (instancetype)schemaWithEntityClass: (Class<DBEntity>)entityClass primaryKeyClass: (Class)primaryKeyClass;
+ (instancetype)schemaWithEntityClass: (Class<DBEntity>)entityClass entityName: (OFString *)entityName primaryKeyClass: (Class)primaryKeyClass;
- (instancetype)initWithEntityClass: (Class<DBEntity>)entityClass entityName: (OFString *)entityName primaryKeyClass: (Class)primaryKeyClass [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
