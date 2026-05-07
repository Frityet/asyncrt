#import "DBEntity.h"

#pragma clang assume_nonnull begin

@implementation DBEntitySchema

+ (instancetype)schemaWithEntityClass: (Class<DBEntity>)entityClass primaryKeyClass: (Class)primaryKeyClass
{
    if (not [(Class)entityClass conformsToProtocol: @protocol(DBEntity)])
        @throw [OFInvalidArgumentException exception];

    return [[DBEntitySchema alloc] initWithEntityClass: entityClass
                                            entityName: [entityClass dbEntityName]
                                       primaryKeyClass: primaryKeyClass];
}

+ (instancetype)schemaWithEntityClass: (Class<DBEntity>)entityClass
                           entityName: (OFString *)entityName
                      primaryKeyClass: (Class)primaryKeyClass
{
    return [[DBEntitySchema alloc] initWithEntityClass: entityClass
                                            entityName: entityName
                                       primaryKeyClass: primaryKeyClass];
}

- (instancetype)initWithEntityClass: (Class<DBEntity>)entityClass
                         entityName: (OFString *)entityName
                    primaryKeyClass: (Class)primaryKeyClass
{
    Class nillable nullablePrimaryKeyClass = primaryKeyClass;

    if (entityName.length == 0
        or nullablePrimaryKeyClass == nullptr
        or ![(Class)entityClass conformsToProtocol: @protocol(DBEntity)])
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _entityClass = entityClass;
    _entityName = [entityName copy];
    _primaryKeyClass = primaryKeyClass;
    return self;
}

@end

#pragma clang assume_nonnull end
