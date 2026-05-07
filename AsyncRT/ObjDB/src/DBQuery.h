#pragma once

#import "DBEntity.h"

#pragma clang assume_nonnull begin

@class DBPredicate<covariant EntityType : id<DBEntity>, covariant FieldValueType, covariant PredicateValueType>;
@class DBSortDescriptor<covariant EntityType : id<DBEntity>>;

enum [[clang::enum_extensibility(closed)]] DBComparisonOperator {
    DBComparisonOperator_EQUAL,
    DBComparisonOperator_NOT_EQUAL,
    DBComparisonOperator_LESS_THAN,
    DBComparisonOperator_LESS_THAN_OR_EQUAL,
    DBComparisonOperator_GREATER_THAN,
    DBComparisonOperator_GREATER_THAN_OR_EQUAL,
    DBComparisonOperator_CONTAINS,
    DBComparisonOperator_CONTAINED_IN
};

enum [[clang::enum_extensibility(closed)]] DBSortDirection {
    DBSortDirection_ASCENDING,
    DBSortDirection_DESCENDING
};

[[subclassing_restricted, direct_members]]
@interface DBField<covariant EntityType : id<DBEntity>, covariant ValueType> : OFObject

@property(readonly, copy, nonatomic) OFString *fieldName;
@property(readonly, nonatomic) Class valueClass;

+ (instancetype)fieldWithName: (OFString *)fieldName
                    valueClass: (Class)valueClass;
- (instancetype)initWithName: (OFString *)fieldName
                  valueClass: (Class)valueClass [[designated_initailiser]];
- (DBPredicate<EntityType, ValueType, ValueType> *)isEqualTo: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)isNotEqualTo: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)isLessThan: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)isLessThanOrEqualTo: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)isGreaterThan: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)isGreaterThanOrEqualTo: (ValueType)value;
- (DBPredicate<EntityType, ValueType, ValueType> *)contains: (ValueType)value;
- (DBPredicate<EntityType, ValueType, OFArray<ValueType> *> *)isContainedIn: (OFArray<ValueType> *)values;
- (DBSortDescriptor<EntityType> *)ascending;
- (DBSortDescriptor<EntityType> *)descending;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface DBPredicate<covariant EntityType : id<DBEntity>, covariant FieldValueType, covariant PredicateValueType> : OFObject

@property(readonly, nonatomic) DBField<EntityType, FieldValueType> *field;
@property(readonly, nonatomic) enum DBComparisonOperator comparisonOperator;
@property(readonly, nonatomic) PredicateValueType value;

+ (instancetype)predicateWithField: (DBField<EntityType, FieldValueType> *)field
                comparisonOperator: (enum DBComparisonOperator)comparisonOperator
                              value: (PredicateValueType)value;
- (instancetype)initWithField: (DBField<EntityType, FieldValueType> *)field
           comparisonOperator: (enum DBComparisonOperator)comparisonOperator
                         value: (PredicateValueType)value [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface DBSortDescriptor<covariant EntityType : id<DBEntity>> : OFObject

@property(readonly, copy, nonatomic) OFString *fieldName;
@property(readonly, nonatomic) enum DBSortDirection direction;
@property(readonly, nonatomic) bool isAscending;

+ (instancetype)sortDescriptorWithFieldName: (OFString *)fieldName
                                  direction: (enum DBSortDirection)direction;
- (instancetype)initWithFieldName: (OFString *)fieldName
                        direction: (enum DBSortDirection)direction [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface DBQuery<covariant EntityType : id<DBEntity>> : OFObject

@property(readonly, nonatomic) Class<DBEntity> entityClass;
@property(readonly, nonatomic) OFArray<DBPredicate<EntityType, id, id> *> *predicates;
@property(readonly, nonatomic) OFArray<DBSortDescriptor<EntityType> *> *sortDescriptors;
@property(readonly, nonatomic) bool hasLimit;
@property(readonly, nonatomic) size_t limit;
@property(readonly, nonatomic) size_t offset;

+ (instancetype)queryForEntityClass: (Class<DBEntity>)entityClass;
- (instancetype)where: (DBPredicate<EntityType, id, id> *)predicate;
- (instancetype)sortedBy: (DBSortDescriptor<EntityType> *)sortDescriptor;
- (instancetype)limitedTo: (size_t)limit;
- (instancetype)offsetBy: (size_t)offset;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
