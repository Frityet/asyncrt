#import "DBQuery.h"

#pragma clang assume_nonnull begin

@interface DBField ()

- (void)_validateValue: (id)value;
- (void)_validateContainedValues: (OFArray *)values;

@end

@interface DBPredicate ()

+ (bool)_comparisonOperatorIsValid: (enum DBComparisonOperator)comparisonOperator;

@end

@interface DBQuery ()

- (instancetype)initWithEntityClass: (Class<DBEntity>)entityClass
                         predicates: (OFArray *)predicates
                    sortDescriptors: (OFArray *)sortDescriptors
                           hasLimit: (bool)hasLimit
                              limit: (size_t)limit
                             offset: (size_t)offset [[designated_initailiser]];

@end

@implementation DBField

+ (instancetype)fieldWithName: (OFString *)fieldName valueClass: (Class)valueClass
{
    return [[self alloc] initWithName: fieldName valueClass: valueClass];
}

- (instancetype)initWithName: (OFString *)fieldName valueClass: (Class)valueClass
{
    Class nillable nullableValueClass = valueClass;

    if (fieldName.length == 0 or nullableValueClass == nullptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _fieldName = [fieldName copy];
    _valueClass = valueClass;
    return self;
}

- (void)_validateValue: (id)value
{
    id nillable nullableValue = value;

    if (nullableValue == nilptr or not [value isKindOfClass: _valueClass])
        @throw [OFInvalidArgumentException exception];
}

- (void)_validateContainedValues: (OFArray *)values
{
    OFArray *nillable nullableValues = values;

    if (nullableValues == nilptr)
        @throw [OFInvalidArgumentException exception];

    for (id value in values)
        [self _validateValue: value];
}

- (DBPredicate *)_predicateWithOperator: (enum DBComparisonOperator)comparisonOperator value: (id)value
{
    return [DBPredicate predicateWithField: self comparisonOperator: comparisonOperator value: value];
}

- (DBPredicate *)isEqualTo: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_EQUAL value: value];
}

- (DBPredicate *)isNotEqualTo: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_NOT_EQUAL value: value];
}

- (DBPredicate *)isLessThan: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_LESS_THAN value: value];
}

- (DBPredicate *)isLessThanOrEqualTo: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_LESS_THAN_OR_EQUAL value: value];
}

- (DBPredicate *)isGreaterThan: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_GREATER_THAN value: value];
}

- (DBPredicate *)isGreaterThanOrEqualTo: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_GREATER_THAN_OR_EQUAL value: value];
}

- (DBPredicate *)contains: (id)value
{
    return [self _predicateWithOperator: DBComparisonOperator_CONTAINS value: value];
}

- (DBPredicate *)isContainedIn: (OFArray *)values
{
    return [self _predicateWithOperator: DBComparisonOperator_CONTAINED_IN value: values];
}

- (DBSortDescriptor *)ascending
{
    return [DBSortDescriptor sortDescriptorWithFieldName: _fieldName direction: DBSortDirection_ASCENDING];
}

- (DBSortDescriptor *)descending
{
    return [DBSortDescriptor sortDescriptorWithFieldName: _fieldName direction: DBSortDirection_DESCENDING];
}

@end

@implementation DBPredicate

+ (instancetype)predicateWithField: (DBField *)field comparisonOperator: (enum DBComparisonOperator)comparisonOperator value: (id)value
{
    return [[self alloc] initWithField: field comparisonOperator: comparisonOperator value: value];
}

- (instancetype)initWithField: (DBField *)field comparisonOperator: (enum DBComparisonOperator)comparisonOperator value: (id)value
{
    DBField *nillable nullableField = field;

    if (nullableField == nilptr or not [self.class _comparisonOperatorIsValid: comparisonOperator])
        @throw [OFInvalidArgumentException exception];

    if (comparisonOperator == DBComparisonOperator_CONTAINED_IN) {
        if (![value isKindOfClass: OFArray.class])
            @throw [OFInvalidArgumentException exception];

        [field _validateContainedValues: (OFArray *)value];
    } else {
        [field _validateValue: value];
    }

    self = [super init];
    _field = field;
    _comparisonOperator = comparisonOperator;
    _value = value;
    return self;
}

+ (bool)_comparisonOperatorIsValid: (enum DBComparisonOperator)comparisonOperator
{
    switch (comparisonOperator) {
        case DBComparisonOperator_EQUAL:
        case DBComparisonOperator_NOT_EQUAL:
        case DBComparisonOperator_LESS_THAN:
        case DBComparisonOperator_LESS_THAN_OR_EQUAL:
        case DBComparisonOperator_GREATER_THAN:
        case DBComparisonOperator_GREATER_THAN_OR_EQUAL:
        case DBComparisonOperator_CONTAINS:
        case DBComparisonOperator_CONTAINED_IN:
            return true;
    }

    return false;
}

@end

@implementation DBSortDescriptor

+ (instancetype)sortDescriptorWithFieldName: (OFString *)fieldName direction: (enum DBSortDirection)direction
{
    return [[self alloc] initWithFieldName: fieldName direction: direction];
}

- (instancetype)initWithFieldName: (OFString *)fieldName direction: (enum DBSortDirection)direction
{
    if (fieldName.length == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _fieldName = [fieldName copy];
    _direction = direction;
    return self;
}

- (bool)isAscending
{ return _direction == DBSortDirection_ASCENDING; }

@end

@implementation DBQuery

+ (instancetype)queryForEntityClass: (Class<DBEntity>)entityClass
{
    if (not [(Class)entityClass conformsToProtocol: @protocol(DBEntity)])
        @throw [OFInvalidArgumentException exception];

    return [[self alloc] initWithEntityClass: entityClass predicates: @[] sortDescriptors: @[] hasLimit: false limit: 0 offset: 0];
}

- (instancetype)initWithEntityClass: (Class<DBEntity>)entityClass
                         predicates: (OFArray *)predicates
                    sortDescriptors: (OFArray *)sortDescriptors
                           hasLimit: (bool)hasLimit
                              limit: (size_t)limit
                             offset: (size_t)offset
{
    if (not [(Class)entityClass conformsToProtocol: @protocol(DBEntity)])
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _entityClass = entityClass;
    _predicates = [predicates copy];
    _sortDescriptors = [sortDescriptors copy];
    _hasLimit = hasLimit;
    _limit = limit;
    _offset = offset;
    return self;
}

- (instancetype)where: (DBPredicate *)predicate
{
    DBPredicate *nillable nullablePredicate = predicate;

    if (nullablePredicate == nilptr)
        @throw [OFInvalidArgumentException exception];

    auto predicates = [OFMutableArray<DBPredicate *> arrayWithCapacity: _predicates.count + 1];
    for (DBPredicate *existingPredicate in _predicates)
        [predicates addObject: existingPredicate];
    [predicates addObject: predicate];

    return [[self.class alloc] initWithEntityClass: _entityClass
                                        predicates: predicates
                                   sortDescriptors: _sortDescriptors
                                          hasLimit: _hasLimit
                                             limit: _limit
                                            offset: _offset];
}

- (instancetype)sortedBy: (DBSortDescriptor *)sortDescriptor
{
    DBSortDescriptor *nillable nullableSortDescriptor = sortDescriptor;

    if (nullableSortDescriptor == nilptr)
        @throw [OFInvalidArgumentException exception];

    auto sortDescriptors = [OFMutableArray<DBSortDescriptor *> arrayWithCapacity: _sortDescriptors.count + 1];
    for (DBSortDescriptor *existingSortDescriptor in _sortDescriptors)
        [sortDescriptors addObject: existingSortDescriptor];
    [sortDescriptors addObject: sortDescriptor];

    return [[self.class alloc] initWithEntityClass: _entityClass
                                        predicates: _predicates
                                   sortDescriptors: sortDescriptors
                                          hasLimit: _hasLimit
                                             limit: _limit
                                            offset: _offset];
}

- (instancetype)limitedTo: (size_t)limit
{
    return [[self.class alloc] initWithEntityClass: _entityClass
                                        predicates: _predicates
                                   sortDescriptors: _sortDescriptors
                                          hasLimit: true
                                             limit: limit
                                            offset: _offset];
}

- (instancetype)offsetBy: (size_t)offset
{
    return [[self.class alloc] initWithEntityClass: _entityClass
                                        predicates: _predicates
                                   sortDescriptors: _sortDescriptors
                                          hasLimit: _hasLimit
                                             limit: _limit
                                            offset: offset];
}

@end

#pragma clang assume_nonnull end
