#import "DBRepository.h"

#pragma clang assume_nonnull begin

@implementation DBRepository

- (instancetype)initWithConnection: (id<DBConnection>)connection
                             schema: (DBEntitySchema *)schema
{
    self = [super init];
    _connection = connection;
    _schema = schema;
    return self;
}

- (DBQuery *)query
{
    return [DBQuery queryForEntityClass: _schema.entityClass];
}

- (Task *)findByPrimaryKey: (id)primaryKey
{
    (void)primaryKey;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)fetch: (DBQuery *)query
{
    (void)query;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)count: (DBQuery *)query
{
    (void)query;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)insert: (id)entity
{
    (void)entity;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)update: (id)entity
{
    (void)entity;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)upsert: (id)entity
{
    (void)entity;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)deleteByPrimaryKey: (id)primaryKey
{
    (void)primaryKey;
    OF_UNRECOGNIZED_SELECTOR
}

- (Task *)deleteWhere: (DBQuery *)query
{
    (void)query;
    OF_UNRECOGNIZED_SELECTOR
}

@end

#pragma clang assume_nonnull end
