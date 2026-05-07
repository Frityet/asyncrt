#pragma once

#import "DBConnection.h"
#import "DBEntity.h"
#import "DBQuery.h"
#import "Optional.h"

#pragma clang assume_nonnull begin

@interface DBRepository<covariant EntityType : id<DBEntity>, KeyType> : OFObject

@property(readonly, nonatomic) id<DBConnection> connection;
@property(readonly, nonatomic) DBEntitySchema<EntityType, KeyType> *schema;
@property(readonly, nonatomic) DBQuery<EntityType> *query;

- (instancetype)initWithConnection: (id<DBConnection>)connection schema: (DBEntitySchema<EntityType, KeyType> *)schema [[designated_initailiser]];
- (DBQuery<EntityType> *)query;
- (Task<Optional<EntityType> *> *)findByPrimaryKey: (KeyType)primaryKey;
- (Task<OFArray<EntityType> *> *)fetch: (DBQuery<EntityType> *)query;
- (Task<OFNumber *> *)count: (DBQuery<EntityType> *)query;
- (Task<EntityType> *)insert: (EntityType)entity;
- (Task<EntityType> *)update: (EntityType)entity;
- (Task<EntityType> *)upsert: (EntityType)entity;
- (Task<DBWriteResult *> *)deleteByPrimaryKey: (KeyType)primaryKey;
- (Task<DBWriteResult *> *)deleteWhere: (DBQuery<EntityType> *)query;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
