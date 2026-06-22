#import <AsyncRT/Database/AsyncDBORM.h>

#include <ctype.h>
#if defined(__APPLE__)
#   include <objc/runtime.h>
#else
#   include <ObjFWRT/ObjFWRT.h>
#endif

#include <stdlib.h> 
#include <string.h>

#pragma clang assume_nonnull begin

@interface AsyncDBColumnSchema ()

- (instancetype)initWithPropertyName: (OFString *)propertyName
                              SQLName: (OFString *)SQLName
                       valueClassName: (OFString *)valueClassName
                            valueClass: (Class nillable)valueClass
                          isPrimaryKey: (bool)isPrimaryKey
                          isForeignKey: (bool)isForeignKey
                            isNullable: (bool)isNullable
                              isUnique: (bool)isUnique
                  referencedTableClass: (Class nillable)referencedTableClass [[designated_initailiser]];

@end

@interface AsyncDBEntitySchema ()

- (instancetype)initWithEntityClass: (Class)entityClass
                          tableName: (OFString *)tableName
                            columns: (OFArray<AsyncDBColumnSchema *> *)columns [[designated_initailiser]];

@end

@interface AsyncDBColumnReference ()

- (instancetype)initWithTable: (AsyncDBTable *)table
                       schema: (AsyncDBColumnSchema *)schema [[designated_initailiser]];

@end

@interface AsyncDBForeignKeyConstraint ()

- (instancetype)initWithSourceColumn: (AsyncDBColumnReference *)sourceColumn
                     referencedColumn: (AsyncDBColumnReference *)referencedColumn
                         deleteAction: (AsyncDBDeleteAction *nillable)deleteAction [[designated_initailiser]];

@end

@interface AsyncDBTable () {
    bool _asyncdb_isTableReference;
    OFMutableDictionary<OFString *, id> *_asyncdb_columnValues;
    OFMutableDictionary<OFString *, AsyncDBColumnReference *> *_asyncdb_columnReferences;
}

- (instancetype)initAsTableReference;
+ (OFString *)_asyncdb_createTableSQLForSchema: (AsyncDBEntitySchema *)schema;
- (id nillable)_asyncdb_valueForColumnProperty: (OFString *)propertyName;
- (void)_asyncdb_setValue: (id nillable)value forColumnProperty: (OFString *)propertyName;
- (bool)_asyncdb_hasValueForColumnProperty: (OFString *)propertyName;

@end

enum AsyncDBPredicateKind {
    AsyncDBPredicateKind_COMPARISON,
    AsyncDBPredicateKind_AND,
    AsyncDBPredicateKind_OR,
    AsyncDBPredicateKind_NOT
};

@interface AsyncDBPredicate : OFObject<AsyncDBBooleanPredicate>

@property(readonly, nonatomic) enum AsyncDBPredicateKind kind;
@property(readonly, copy, nonatomic) OFString *nillable operation;
@property(readonly, nonatomic) id left;
@property(readonly, nonatomic) id nillable right;

+ (instancetype)predicateWithLeft: (id)left operation: (OFString *)operation right: (id)right;
+ (instancetype)compoundPredicateWithKind: (enum AsyncDBPredicateKind)kind
                                      left: (id)left
                                     right: (id nillable)right;
- (instancetype)initWithKind: (enum AsyncDBPredicateKind)kind
                   operation: (OFString *nillable)operation
                        left: (id)left
                       right: (id nillable)right [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBValueExpression : OFObject<AsyncDBExpression>

@property(readonly, nonatomic) id value;

+ (instancetype)expressionWithValue: (id)value;
- (instancetype)initWithValue: (id)value [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBJoinClause : OFObject

@property(readonly, copy, nonatomic) OFString *kind;
@property(readonly, nonatomic) AsyncDBTable *table;
@property(readonly, nonatomic) id<AsyncDBBooleanPredicate> nillable predicate;

+ (instancetype)joinWithKind: (OFString *)kind
                       table: (AsyncDBTable *)table
                   predicate: (id<AsyncDBBooleanPredicate> nillable)predicate;
- (instancetype)initWithKind: (OFString *)kind
                       table: (AsyncDBTable *)table
                   predicate: (id<AsyncDBBooleanPredicate> nillable)predicate [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBOrderClause : OFObject

@property(readonly, nonatomic) id<AsyncDBExpression> column;
@property(readonly, nonatomic) bool ascending;

+ (instancetype)orderWithColumn: (id<AsyncDBExpression>)column ascending: (bool)ascending;
- (instancetype)initWithColumn: (id<AsyncDBExpression>)column ascending: (bool)ascending [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBQueryBuilder () {
    AsyncDBTable *_fromTable;
    bool _distinct;
    OFMutableArray<AsyncDBJoinClause *> *_joins;
    id<AsyncDBBooleanPredicate> nillable _wherePredicate;
    OFMutableArray<AsyncDBColumnReference *> *_groupByColumns;
    id<AsyncDBBooleanPredicate> nillable _havingPredicate;
    OFMutableArray<AsyncDBOrderClause *> *_orderClauses;
    Optional<OFNumber *> *_limitValue;
    Optional<OFNumber *> *_offsetValue;
}

- (instancetype)initWithTable: (AsyncDBTable *)table [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBSelectQuery () {
    OFDictionary<OFString *, id<AsyncDBExpression>> *_selection;
}

- (instancetype)initWithSQL: (OFString *)SQL
                boundValues: (OFArray<id> *)boundValues
                resultClass: (Class)resultClass
                  selection: (OFDictionary<OFString *, id<AsyncDBExpression>> *)selection [[designated_initailiser]];

@end

@namespace(AsyncDBORM)

+ (OFString *)stringFromClass: (Class)cls;
+ (OFString *)quotedIdentifier: (OFString *)identifier;
+ (OFString *)defaultSQLNameForProperty: (OFString *)propertyName isForeignKey: (bool)isForeignKey;
+ (SEL)setterSelectorForPropertyName: (OFString *)propertyName;
+ (OFString *)propertyNameFromSetterSelector: (SEL)selector;
+ (bool)classIsTableClass: (Class nillable)cls;
+ (OFString *nillable)objectClassNameFromProperty: (objc_property_t)property;
+ (bool)property: (objc_property_t)property hasProtocol: (OFString *)protocolName;
+ (OFString *)SQLTypeForColumn: (AsyncDBColumnSchema *)column;
+ (id)SQLiteValueForModelValue: (id nillable)value column: (AsyncDBColumnSchema *)column;
+ (id nillable)modelValueForSQLiteValue: (id)value valueClass: (Class nillable)valueClass;
+ (bool)isConcreteExpressionObject: (id)value;
+ (OFString *nillable)classNameForProperty: (Class)cls propertyName: (OFString *)propertyName;
+ (void)setObject: (id)object property: (OFString *)propertyName value: (id nillable)value;
@end

@interface AsyncDBORM (SchemaReflection)
+ (void)installAccessorsForSchema: (AsyncDBEntitySchema *)schema class: (Class)cls;
+ (void)appendPropertyColumnsForClass: (Class)cls
                              columns: (OFMutableArray<AsyncDBColumnSchema *> *)columns
                            overrides: (OFDictionary<OFString *, OFString *> *)overrides;
@end

@interface AsyncDBORM (SQLGeneration)
+ (OFString *)SQLForExpression: (id)expression boundValues: (OFMutableArray<id> *)boundValues;
+ (id<AsyncDBBooleanPredicate> nillable)inferredJoinPredicateForTable: (AsyncDBTable *)joinTable
                                                         joinedTables: (OFArray<AsyncDBTable *> *)joinedTables;
@end

static OFMutableDictionary<OFString *, AsyncDBEntitySchema *> *nillable AsyncDBSchemaCache;
static OFMutableSet<OFString *> *nillable AsyncDBAccessorInstallCache;

@namespace_implementation(AsyncDBORM)

+ (OFString *)stringFromClass: (Class)cls
{
    return [OFString stringWithUTF8String: $assert_nonnil(class_getName(cls))];
}

+ (OFString *)quotedIdentifier: (OFString *)identifier
{
    return [OFString stringWithFormat: @"\"%@\"",
                                      [identifier stringByReplacingOccurrencesOfString: @"\""
                                                                            withString: @"\"\""]];
}

+ (OFString *)defaultSQLNameForProperty: (OFString *)propertyName isForeignKey: (bool)isForeignKey
{
    if (isForeignKey)
        return [OFString stringWithFormat: @"%@_id", propertyName];

    return propertyName;
}

+ (SEL)setterSelectorForPropertyName: (OFString *)propertyName
{
    const char *propertyNameUTF8 = propertyName.UTF8String;
    size_t length = strlen(propertyNameUTF8);
    char *setter = malloc(length + 6);

    if (setter == nullptr)
        @throw [OFOutOfMemoryException exception];

    strcpy(setter, "set");
    if (length > 0) {
        setter[3] = (char)toupper((unsigned char)propertyNameUTF8[0]);
        memcpy(setter + 4, propertyNameUTF8 + 1, length - 1);
    }
    setter[length + 3] = ':';
    setter[length + 4] = '\0';

    SEL selector = sel_registerName(setter);
    free(setter);
    return selector;
}

+ (OFString *)propertyNameFromSetterSelector: (SEL)selector
{
    const char *selectorName = sel_getName(selector);
    size_t length = strlen(selectorName);

    if (length < 5 or strncmp(selectorName, "set", 3) != 0 or selectorName[length - 1] != ':')
        @throw [OFInvalidArgumentException exception];

    char *propertyName = malloc(length - 3);
    if (propertyName == nullptr)
        @throw [OFOutOfMemoryException exception];

    propertyName[0] = (char)tolower((unsigned char)selectorName[3]);
    memcpy(propertyName + 1, selectorName + 4, length - 5);
    propertyName[length - 4] = '\0';

    OFString *result = [OFString stringWithUTF8String: propertyName];
    free(propertyName);
    return result;
}

static id nillable
AsyncDBDynamicColumnGetter(AsyncDBTable *self, SEL selector)
{
    return [self _asyncdb_valueForColumnProperty: [OFString stringWithUTF8String: sel_getName(selector)]];
}

static void
AsyncDBDynamicColumnSetter(AsyncDBTable *self, SEL selector, id nillable value)
{
    [self _asyncdb_setValue: value
          forColumnProperty: [AsyncDBORM propertyNameFromSetterSelector: selector]];
}

+ (bool)classIsTableClass: (Class nillable)cls
{
    for (Class currentClass = cls; currentClass != Nil; currentClass = class_getSuperclass(currentClass))
        if (currentClass == AsyncDBTable.class)
            return true;

    return false;
}

+ (OFString *nillable)objectClassNameFromProperty: (objc_property_t)property
{
    char *type = property_copyAttributeValue(property, "T");
    if (type == nullptr)
        return nilptr;

    OFString *typeString = [OFString stringWithUTF8String: type];
    free(type);

    if (![typeString hasPrefix: @"@\""])
        return nilptr;

    OFRange endRange = [typeString rangeOfString: @"\""
                                         options: (OFStringSearchOptions)0
                                           range: OFMakeRange(2, typeString.length - 2)];
    if (endRange.location == OFNotFound)
        return nilptr;

    OFString *objectType = [typeString substringWithRange: OFMakeRange(2, endRange.location - 2)];
    OFRange protocolStart = [objectType rangeOfString: @"<"];
    if (protocolStart.location == OFNotFound)
        return objectType;

    return [objectType substringToIndex: protocolStart.location];
}

+ (bool)property: (objc_property_t)property hasProtocol: (OFString *)protocolName
{
    char *type = property_copyAttributeValue(property, "T");
    if (type == nullptr)
        return false;

    OFString *typeString = [OFString stringWithUTF8String: type];
    free(type);

    return [typeString containsString: [OFString stringWithFormat: @"<%@>", protocolName]];
}

+ (OFString *)SQLTypeForColumn: (AsyncDBColumnSchema *)column
{
    if ([column.valueClassName isEqual: @"OFNumber"])
        return @"INTEGER";
    if ([column.valueClassName isEqual: @"OFString"])
        return @"TEXT";
    if ([column.valueClassName isEqual: @"OFDate"])
        return @"REAL";
    if (column.isForeignKey)
        return @"INTEGER";

    @throw [OFInvalidArgumentException exception];
}

+ (id)SQLiteValueForModelValue: (id nillable)value column: (AsyncDBColumnSchema *)column
{
    if (value == nilptr)
        return OFNull.null;

    if (column.isForeignKey and [value isKindOfClass: AsyncDBTable.class]) {
        AsyncDBTable *tableValue = (AsyncDBTable *)value;
        return [tableValue _asyncdb_valueForColumnProperty: tableValue.schema.primaryKeyColumn.propertyName] ?: OFNull.null;
    }

    if ([value isKindOfClass: OFDate.class])
        return [OFNumber numberWithDouble: ((OFDate *)value).timeIntervalSince1970];

    return $assert_nonnil(value);
}

+ (id nillable)modelValueForSQLiteValue: (id)value valueClass: (Class nillable)valueClass
{
    if (value == OFNull.null)
        return nilptr;

    if (valueClass == OFDate.class and [value isKindOfClass: OFNumber.class])
        return [OFDate dateWithTimeIntervalSince1970: ((OFNumber *)value).doubleValue];

    return value;
}

+ (bool)isConcreteExpressionObject: (id)value
{
    return [value isKindOfClass: AsyncDBColumnReference.class] or
        [value isKindOfClass: AsyncDBPredicate.class] or
        [value isKindOfClass: AsyncDBValueExpression.class];
}

+ (OFString *nillable)classNameForProperty: (Class)cls propertyName: (OFString *)propertyName
{
    for (Class currentClass = cls;
         currentClass != Nil and currentClass != AsyncDBTable.class;
         currentClass = class_getSuperclass(currentClass)) {
        #if defined(__APPLE__)
        objc_property_t property = class_getProperty(currentClass, propertyName.UTF8String);
        #else
        unsigned int pcount;
        objc_property_t *properties = class_copyPropertyList(currentClass, &pcount);
        objc_property_t property = nullptr;
        for (unsigned int i = 0; i < pcount; i++) {
            property = properties[i];
            if (strcmp(property_getName(property), propertyName.UTF8String) == 0) {
                free(properties);
                break;
            }
        }

        #endif
        if (property != nullptr)
            return [AsyncDBORM objectClassNameFromProperty: property];
    }
        
    return nilptr;
}

+ (void)setObject: (id)object property: (OFString *)propertyName value: (id nillable)value
{
    SEL setter = [AsyncDBORM setterSelectorForPropertyName: propertyName];
    if (not [object respondsToSelector: setter])
        @throw [OFInvalidArgumentException exception];

    auto setterImp = (void (*)(id, SEL, id nillable))(void *)[object methodForSelector: setter];
    setterImp(object, setter, value);
}

@end

@implementation AsyncDBDeleteAction

+ (instancetype)cascade
{ return [self actionWithSQL: @"CASCADE"]; }

+ (instancetype)restrict
{ return [self actionWithSQL: @"RESTRICT"]; }

+ (instancetype)setNull
{ return [self actionWithSQL: @"SET NULL"]; }

+ (instancetype)noAction
{ return [self actionWithSQL: @"NO ACTION"]; }

+ (instancetype)actionWithSQL: (OFString *)SQL
{ return [[self alloc] initWithSQL: SQL]; }

- (instancetype)initWithSQL: (OFString *)SQL
{
    self = [super init];
    _SQL = [SQL copy];
    return self;
}

@end

@implementation AsyncDBColumnSchema

- (instancetype)initWithPropertyName: (OFString *)propertyName
                              SQLName: (OFString *)SQLName
                       valueClassName: (OFString *)valueClassName
                            valueClass: (Class nillable)valueClass
                          isPrimaryKey: (bool)isPrimaryKey
                          isForeignKey: (bool)isForeignKey
                            isNullable: (bool)isNullable
                              isUnique: (bool)isUnique
                  referencedTableClass: (Class nillable)referencedTableClass
{
    self = [super init];
    _propertyName = [propertyName copy];
    _SQLName = [SQLName copy];
    _valueClassName = [valueClassName copy];
    _valueClass = valueClass;
    _isPrimaryKey = isPrimaryKey;
    _isForeignKey = isForeignKey;
    _isNullable = isNullable;
    _isUnique = isUnique;
    _referencedTableClass = referencedTableClass;
    return self;
}

@end

@implementation AsyncDBEntitySchema

- (instancetype)initWithEntityClass: (Class)entityClass
                          tableName: (OFString *)tableName
                            columns: (OFArray<AsyncDBColumnSchema *> *)columns
{
    self = [super init];
    _entityClass = entityClass;
    _tableName = [tableName copy];
    _columns = [columns copy];

    AsyncDBColumnSchema *nillable primaryKeyColumn = nilptr;
    for (AsyncDBColumnSchema *column in _columns) {
        if (not column.isPrimaryKey)
            continue;
        if (primaryKeyColumn != nilptr)
            @throw [OFInvalidArgumentException exception];
        primaryKeyColumn = column;
    }
    if (primaryKeyColumn == nilptr)
        @throw [OFInvalidArgumentException exception];

    _primaryKeyColumn = $assert_nonnil(primaryKeyColumn);
    return self;
}

- (AsyncDBColumnSchema *)columnNamed: (OFString *)propertyName
{
    for (AsyncDBColumnSchema *column in _columns)
        if ([column.propertyName isEqual: propertyName])
            return column;

    @throw [OFInvalidArgumentException exception];
}

- (AsyncDBColumnSchema *)columnWithSQLName: (OFString *)SQLName
{
    for (AsyncDBColumnSchema *column in _columns)
        if ([column.SQLName isEqual: SQLName])
            return column;

    @throw [OFInvalidArgumentException exception];
}

- (bool)hasColumnNamed: (OFString *)propertyName
{
    @try {
        (void)[self columnNamed: propertyName];
        return true;
    } @catch (OFInvalidArgumentException *) {
        return false;
    }
}

@end

@implementation AsyncDBValueExpression

+ (instancetype)expressionWithValue: (id)value
{ return [[self alloc] initWithValue: value]; }

- (instancetype)initWithValue: (id)value
{
    self = [super init];
    _value = value;
    return self;
}

@end

#define ASYNC_DB_LITERAL_ORDERED_EXPRESSION_IMPLEMENTATION \
- (id<AsyncDBBooleanPredicate>)_asyncdb_predicateWithOperation: (OFString *)operation other: (id)other \
{ \
    id right = [AsyncDBORM isConcreteExpressionObject: other] \
        ? other \
        : [AsyncDBValueExpression expressionWithValue: other]; \
    return [AsyncDBPredicate predicateWithLeft: [AsyncDBValueExpression expressionWithValue: self] \
                                    operation: operation \
                                        right: right]; \
} \
- (id<AsyncDBBooleanPredicate>)IS: (id)other \
{ return [self _asyncdb_predicateWithOperation: @"=" other: other]; } \
- (id<AsyncDBBooleanPredicate>)IS_NOT: (id)other \
{ return [self _asyncdb_predicateWithOperation: @"<>" other: other]; } \
- (id<AsyncDBBooleanPredicate>)IN: (OFArray<id> *)values \
{ return [self _asyncdb_predicateWithOperation: @"IN" other: values]; } \
- (id<AsyncDBBooleanPredicate>)NOT_IN: (OFArray<id> *)values \
{ return [self _asyncdb_predicateWithOperation: @"NOT IN" other: values]; } \
- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN: (id)other \
{ return [self _asyncdb_predicateWithOperation: @"<" other: other]; } \
- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN_OR_EQUAL: (id)other \
{ return [self _asyncdb_predicateWithOperation: @"<=" other: other]; } \
- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN: (id)other \
{ return [self _asyncdb_predicateWithOperation: @">" other: other]; } \
- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN_OR_EQUAL: (id)other \
{ return [self _asyncdb_predicateWithOperation: @">=" other: other]; }

@implementation OFNumber (AsyncDBExpression)
ASYNC_DB_LITERAL_ORDERED_EXPRESSION_IMPLEMENTATION
@end

@implementation OFDate (AsyncDBExpression)
ASYNC_DB_LITERAL_ORDERED_EXPRESSION_IMPLEMENTATION
@end

@implementation OFString (AsyncDBExpression)
ASYNC_DB_LITERAL_ORDERED_EXPRESSION_IMPLEMENTATION
- (id<AsyncDBBooleanPredicate>)LIKE: (OFString *)pattern
{ return [self _asyncdb_predicateWithOperation: @"LIKE" other: pattern]; }
- (id<AsyncDBBooleanPredicate>)NOT_LIKE: (OFString *)pattern
{ return [self _asyncdb_predicateWithOperation: @"NOT LIKE" other: pattern]; }
@end

#undef ASYNC_DB_LITERAL_ORDERED_EXPRESSION_IMPLEMENTATION

@implementation AsyncDBPredicate

+ (instancetype)predicateWithLeft: (id)left operation: (OFString *)operation right: (id)right
{
    return [[self alloc] initWithKind: AsyncDBPredicateKind_COMPARISON
                            operation: operation
                                 left: left
                                right: right];
}

+ (instancetype)compoundPredicateWithKind: (enum AsyncDBPredicateKind)kind
                                      left: (id)left
                                     right: (id nillable)right
{
    return [[self alloc] initWithKind: kind
                            operation: nilptr
                                 left: left
                                right: right];
}

- (instancetype)initWithKind: (enum AsyncDBPredicateKind)kind
                   operation: (OFString *nillable)operation
                        left: (id)left
                       right: (id nillable)right
{
    self = [super init];
    _kind = kind;
    _operation = [operation copy];
    _left = left;
    _right = right;
    return self;
}

- (id<AsyncDBBooleanPredicate>)AND: (id<AsyncDBBooleanPredicate>)other
{
    return [AsyncDBPredicate compoundPredicateWithKind: AsyncDBPredicateKind_AND
                                                 left: self
                                                right: other];
}

- (id<AsyncDBBooleanPredicate>)OR: (id<AsyncDBBooleanPredicate>)other
{
    return [AsyncDBPredicate compoundPredicateWithKind: AsyncDBPredicateKind_OR
                                                 left: self
                                                right: other];
}

- (id<AsyncDBBooleanPredicate>)NOT
{
    return [AsyncDBPredicate compoundPredicateWithKind: AsyncDBPredicateKind_NOT
                                                 left: self
                                                right: nilptr];
}

@end

@implementation AsyncDBColumnReference

- (instancetype)initWithTable: (AsyncDBTable *)table
                       schema: (AsyncDBColumnSchema *)schema
{
    self = [super init];
    _table = table;
    _schema = schema;
    _propertyName = [schema.propertyName copy];
    _SQLName = [schema.SQLName copy];
    return self;
}

- (id<AsyncDBBooleanPredicate>)_predicateWithOperation: (OFString *)operation
                                                 other: (id)other
{
    id right = [AsyncDBORM isConcreteExpressionObject: other]
        ? other
        : [AsyncDBValueExpression expressionWithValue: other];
    return [AsyncDBPredicate predicateWithLeft: self
                                     operation: operation
                                         right: right];
}

- (id<AsyncDBBooleanPredicate>)IS: (id)other
{ return [self _predicateWithOperation: @"=" other: other]; }

- (id<AsyncDBBooleanPredicate>)IS_NOT: (id)other
{ return [self _predicateWithOperation: @"<>" other: other]; }

- (id<AsyncDBBooleanPredicate>)IN: (OFArray<id> *)values
{ return [self _predicateWithOperation: @"IN" other: values]; }

- (id<AsyncDBBooleanPredicate>)NOT_IN: (OFArray<id> *)values
{ return [self _predicateWithOperation: @"NOT IN" other: values]; }

- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN: (id)other
{ return [self _predicateWithOperation: @"<" other: other]; }

- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN_OR_EQUAL: (id)other
{ return [self _predicateWithOperation: @"<=" other: other]; }

- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN: (id)other
{ return [self _predicateWithOperation: @">" other: other]; }

- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN_OR_EQUAL: (id)other
{ return [self _predicateWithOperation: @">=" other: other]; }

- (id<AsyncDBBooleanPredicate>)LIKE: (OFString *)pattern
{ return [self _predicateWithOperation: @"LIKE" other: pattern]; }

- (id<AsyncDBBooleanPredicate>)NOT_LIKE: (OFString *)pattern
{ return [self _predicateWithOperation: @"NOT LIKE" other: pattern]; }

- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column
{
    return [self references: column
                   onDelete: nilptr];
}

- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column
                                  onDelete: (AsyncDBDeleteAction *nillable)deleteAction
{
    return [[AsyncDBForeignKeyConstraint alloc] initWithSourceColumn: self
                                                    referencedColumn: column
                                                        deleteAction: deleteAction];
}

@end

@implementation AsyncDBForeignKeyConstraint

- (instancetype)initWithSourceColumn: (AsyncDBColumnReference *)sourceColumn
                     referencedColumn: (AsyncDBColumnReference *)referencedColumn
                         deleteAction: (AsyncDBDeleteAction *nillable)deleteAction
{
    self = [super init];
    _sourceColumn = sourceColumn;
    _referencedColumn = referencedColumn;
    _deleteAction = deleteAction;
    return self;
}

@end

@implementation AsyncDBORM (SchemaReflection)

+ (void)installAccessorsForSchema: (AsyncDBEntitySchema *)schema class: (Class)cls
{
    if (AsyncDBAccessorInstallCache == nilptr)
        AsyncDBAccessorInstallCache = [OFMutableSet set];

    OFString *className = [AsyncDBORM stringFromClass: cls];
    if ([AsyncDBAccessorInstallCache containsObject: className])
        return;

    for (AsyncDBColumnSchema *column in schema.columns) {
        SEL getter = sel_registerName(column.propertyName.UTF8String);
        SEL setter = [AsyncDBORM setterSelectorForPropertyName: column.propertyName];

        class_replaceMethod(cls, getter, (IMP)(void *)AsyncDBDynamicColumnGetter, "@@:");
        class_replaceMethod(cls, setter, (IMP)(void *)AsyncDBDynamicColumnSetter, "v@:@");
    }

    [AsyncDBAccessorInstallCache addObject: className];
}

+ (void)appendPropertyColumnsForClass: (Class)cls
                              columns: (OFMutableArray<AsyncDBColumnSchema *> *)columns
                            overrides: (OFDictionary<OFString *, OFString *> *)overrides
{
    Class superclass = class_getSuperclass(cls);
    if (superclass != Nil and superclass != AsyncDBTable.class and [AsyncDBORM classIsTableClass: superclass])
        [AsyncDBORM appendPropertyColumnsForClass: superclass
                                          columns: columns
                                        overrides: overrides];

    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties == nullptr)
        return;

    @try {
        for (unsigned int index = 0; index < propertyCount; index++) {
            objc_property_t property = properties[index];
            OFString *propertyName = [OFString stringWithUTF8String: property_getName(property)];
            OFString *nillable valueClassName = [AsyncDBORM objectClassNameFromProperty: property];

            bool isColumn = [AsyncDBORM property: property hasProtocol: @"AsyncDBColumn"];
            bool isPrimaryKey = [AsyncDBORM property: property hasProtocol: @"AsyncDBPrimaryKey"];
            bool isForeignKey = [AsyncDBORM property: property hasProtocol: @"AsyncDBForeignKey"];
            bool isNullable = [AsyncDBORM property: property hasProtocol: @"AsyncDBNullable"];
            bool isUnique = [AsyncDBORM property: property hasProtocol: @"AsyncDBUnique"];

            if (not isColumn and not isPrimaryKey and not isForeignKey)
                continue;
            if (valueClassName == nilptr)
                @throw [OFInvalidArgumentException exception];

            Class valueClass = objc_getClass(valueClassName.UTF8String);
            Class referencedTableClass = nilptr;
            if (isForeignKey) {
                if (valueClass == Nil or ![AsyncDBORM classIsTableClass: valueClass])
                    @throw [OFInvalidArgumentException exception];
                referencedTableClass = valueClass;
            }

            OFString *SQLName = overrides[propertyName];
            if (SQLName == nilptr)
                SQLName = [AsyncDBORM defaultSQLNameForProperty: propertyName isForeignKey: isForeignKey];

            [columns addObject: [[AsyncDBColumnSchema alloc] initWithPropertyName: propertyName
                                                                          SQLName: SQLName
                                                                   valueClassName: $assert_nonnil(valueClassName)
                                                                        valueClass: valueClass
                                                                      isPrimaryKey: isPrimaryKey
                                                                      isForeignKey: isForeignKey
                                                                        isNullable: isNullable
                                                                          isUnique: isUnique
                                                              referencedTableClass: referencedTableClass]];
        }
    } @finally {
        free(properties);
    }
}

@end

@implementation AsyncDBTable

+ (instancetype)table
{
    return [[self alloc] initAsTableReference];
}

+ (OFString *)tableName
{
    return [AsyncDBORM stringFromClass: self].lowercaseString;
}

+ (OFDictionary<OFString *, OFString *> *)sqlNameOverrides
{
    return [OFDictionary dictionary];
}

+ (OFArray<OFArray<AsyncDBColumnReference *> *> *)unique
{
    return [OFArray array];
}

+ (OFArray<AsyncDBForeignKeyConstraint *> *)relationships
{
    return [OFArray array];
}

+ (AsyncDBEntitySchema *)schema
{
    if (self == AsyncDBTable.class)
        @throw [OFInvalidArgumentException exception];
    if (AsyncDBSchemaCache == nilptr)
        AsyncDBSchemaCache = [OFMutableDictionary dictionary];

    OFString *className = [AsyncDBORM stringFromClass: self];
    AsyncDBEntitySchema *schema = AsyncDBSchemaCache[className];
    if (schema != nilptr)
        return schema;

    auto columns = [OFMutableArray<AsyncDBColumnSchema *> array];
    [AsyncDBORM appendPropertyColumnsForClass: self
                                      columns: columns
                                    overrides: [self sqlNameOverrides]];
    schema = [[AsyncDBEntitySchema alloc] initWithEntityClass: self
                                                   tableName: [self tableName]
                                                     columns: columns];
    AsyncDBSchemaCache[className] = schema;
    [AsyncDBORM installAccessorsForSchema: schema
                                    class: self];
    return schema;
}

- (instancetype)init
{
    self = [super init];
    _asyncdb_isTableReference = false;
    _asyncdb_columnValues = [[OFMutableDictionary alloc] init];
    _asyncdb_columnReferences = nilptr;
    (void)[self.class schema];
    return self;
}

- (instancetype)initAsTableReference
{
    self = [super init];
    _asyncdb_isTableReference = true;
    _asyncdb_columnValues = [[OFMutableDictionary alloc] init];
    _asyncdb_columnReferences = [[OFMutableDictionary alloc] init];
    (void)[self.class schema];
    return self;
}

- (bool)isTableReference
{
    return _asyncdb_isTableReference;
}

- (AsyncDBEntitySchema *)schema
{
    return [self.class schema];
}

- (AsyncDBColumnReference *)columnNamed: (OFString *)propertyName
{
    AsyncDBColumnReference *column = _asyncdb_columnReferences[propertyName];
    if (column != nilptr)
        return column;

    column = [[AsyncDBColumnReference alloc] initWithTable: self
                                                    schema: [self.schema columnNamed: propertyName]];
    _asyncdb_columnReferences[propertyName] = column;
    return column;
}

- (id nillable)_asyncdb_valueForColumnProperty: (OFString *)propertyName
{
    if (_asyncdb_isTableReference)
        return [self columnNamed: propertyName];

    id value = _asyncdb_columnValues[propertyName];
    return value == OFNull.null ? nilptr : value;
}

- (void)_asyncdb_setValue: (id nillable)value forColumnProperty: (OFString *)propertyName
{
    (void)[self.schema columnNamed: propertyName];

    if (_asyncdb_isTableReference)
        @throw [OFInvalidArgumentException exception];

    if (value == nilptr)
        _asyncdb_columnValues[propertyName] = OFNull.null;
    else
        _asyncdb_columnValues[propertyName] = value;
}

- (bool)_asyncdb_hasValueForColumnProperty: (OFString *)propertyName
{
    return _asyncdb_columnValues[propertyName] != nilptr;
}

+ (OFString *)_asyncdb_createTableSQLForSchema: (AsyncDBEntitySchema *)schema
{
    auto parts = [OFMutableArray<OFString *> array];
    AsyncDBTable *table = [schema.entityClass table];

    for (AsyncDBColumnSchema *column in schema.columns) {
        auto columnSQL = [OFMutableString stringWithFormat: @"%@ %@",
                                                        [AsyncDBORM quotedIdentifier: column.SQLName],
                                                        [AsyncDBORM SQLTypeForColumn: column]];

        if (column.isPrimaryKey)
            [columnSQL appendString: @" PRIMARY KEY"];
        if (column.isPrimaryKey and [column.valueClassName isEqual: @"OFNumber"])
            [columnSQL appendString: @" AUTOINCREMENT"];
        if (not column.isNullable and not column.isPrimaryKey)
            [columnSQL appendString: @" NOT NULL"];
        if (column.isUnique)
            [columnSQL appendString: @" UNIQUE"];

        [parts addObject: columnSQL];
    }

    for (OFArray<AsyncDBColumnReference *> *uniqueColumns in [schema.entityClass unique]) {
        auto uniqueNames = [OFMutableArray<OFString *> arrayWithCapacity: uniqueColumns.count];
        for (AsyncDBColumnReference *column in uniqueColumns)
            [uniqueNames addObject: [AsyncDBORM quotedIdentifier: column.SQLName]];

        [parts addObject: [OFString stringWithFormat: @"UNIQUE (%@)",
                                                     [uniqueNames componentsJoinedByString: @", "]]];
    }

    auto relationships = [OFMutableArray<AsyncDBForeignKeyConstraint *> array];
    [relationships addObjectsFromArray: [schema.entityClass relationships]];

    for (AsyncDBColumnSchema *column in schema.columns) {
        if (not column.isForeignKey or column.referencedTableClass == Nil)
            continue;

        AsyncDBColumnReference *sourceColumn = [table columnNamed: column.propertyName];
        AsyncDBColumnReference *referencedColumn = [(AsyncDBTable *)[column.referencedTableClass table] columnNamed:
            [column.referencedTableClass schema].primaryKeyColumn.propertyName];
        [relationships addObject: [sourceColumn references: referencedColumn]];
    }

    for (AsyncDBForeignKeyConstraint *relationship in relationships) {
        auto relationshipSQL = [OFMutableString stringWithFormat: @"FOREIGN KEY (%@) REFERENCES %@ (%@)",
                                                              [AsyncDBORM quotedIdentifier: relationship.sourceColumn.SQLName],
                                                              [AsyncDBORM quotedIdentifier: relationship.referencedColumn.table.schema.tableName],
                                                              [AsyncDBORM quotedIdentifier: relationship.referencedColumn.SQLName]];
        if (relationship.deleteAction != nilptr)
            [relationshipSQL appendFormat: @" ON DELETE %@", relationship.deleteAction.SQL];
        [parts addObject: relationshipSQL];
    }

    return [OFString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (%@)",
                                      [AsyncDBORM quotedIdentifier: schema.tableName],
                                      [parts componentsJoinedByString: @", "]];
}

+ (AsyncTask<AsyncDBWriteResult *> *)createTableInConnection: (id<AsyncDBConnection>)connection
{
    return [(id)connection asyncdb_executeSQL: [self _asyncdb_createTableSQLForSchema: [self schema]]];
}

- (AsyncTask<AsyncDBWriteResult *> *)insertIntoConnection: (id<AsyncDBConnection>)connection
{
    auto columnNames = [OFMutableArray<OFString *> array];
    auto placeholders = [OFMutableArray<OFString *> array];
    auto values = [OFMutableArray<id> array];

    for (AsyncDBColumnSchema *column in self.schema.columns) {
        if (column.isPrimaryKey and ![self _asyncdb_hasValueForColumnProperty: column.propertyName])
            continue;
        if (![self _asyncdb_hasValueForColumnProperty: column.propertyName]) {
            if (not column.isNullable)
                @throw [OFInvalidArgumentException exception];
            continue;
        }

        [columnNames addObject: [AsyncDBORM quotedIdentifier: column.SQLName]];
        [placeholders addObject: @"?"];
        [values addObject: [AsyncDBORM SQLiteValueForModelValue: [self _asyncdb_valueForColumnProperty: column.propertyName]
                                                         column: column]];
    }

    OFString *SQL = [OFString stringWithFormat: @"INSERT INTO %@ (%@) VALUES (%@)",
                                               [AsyncDBORM quotedIdentifier: self.schema.tableName],
                                               [columnNames componentsJoinedByString: @", "],
                                               [placeholders componentsJoinedByString: @", "]];
    AsyncDBColumnSchema *primaryKey = self.schema.primaryKeyColumn;
    bool shouldLoadPrimaryKey = ![self _asyncdb_hasValueForColumnProperty: primaryKey.propertyName];

    AsyncTask<AsyncDBWriteResult *> *insertTask = [(id)connection asyncdb_executeSQL: SQL
                                                                              values: values];
    if (not shouldLoadPrimaryKey)
        return insertTask;

    return (AsyncTask<AsyncDBWriteResult *> *)[insertTask flatMap: ^AsyncTask *(AsyncDBWriteResult *result) {
        return [[connection lastInsertRowID] map: ^id(OFNumber *rowID) {
            [self _asyncdb_setValue: rowID
                  forColumnProperty: primaryKey.propertyName];
            return result;
        }];
    }];
}

- (AsyncTask<AsyncDBWriteResult *> *)updateInConnection: (id<AsyncDBConnection>)connection
{
    AsyncDBColumnSchema *primaryKey = self.schema.primaryKeyColumn;
    if (![self _asyncdb_hasValueForColumnProperty: primaryKey.propertyName])
        @throw [OFInvalidArgumentException exception];

    auto assignments = [OFMutableArray<OFString *> array];
    auto values = [OFMutableArray<id> array];

    for (AsyncDBColumnSchema *column in self.schema.columns) {
        if (column.isPrimaryKey)
            continue;
        if (![self _asyncdb_hasValueForColumnProperty: column.propertyName])
            continue;

        [assignments addObject: [OFString stringWithFormat: @"%@ = ?",
                                                           [AsyncDBORM quotedIdentifier: column.SQLName]]];
        [values addObject: [AsyncDBORM SQLiteValueForModelValue: [self _asyncdb_valueForColumnProperty: column.propertyName]
                                                         column: column]];
    }

    if (assignments.count == 0)
        @throw [OFInvalidArgumentException exception];

    [values addObject: [AsyncDBORM SQLiteValueForModelValue: [self _asyncdb_valueForColumnProperty: primaryKey.propertyName]
                                                     column: primaryKey]];

    OFString *SQL = [OFString stringWithFormat: @"UPDATE %@ SET %@ WHERE %@ = ?",
                                               [AsyncDBORM quotedIdentifier: self.schema.tableName],
                                               [assignments componentsJoinedByString: @", "],
                                               [AsyncDBORM quotedIdentifier: primaryKey.SQLName]];
    return [(id)connection asyncdb_executeSQL: SQL
                                       values: values];
}

- (AsyncTask<AsyncDBWriteResult *> *)deleteFromConnection: (id<AsyncDBConnection>)connection
{
    AsyncDBColumnSchema *primaryKey = self.schema.primaryKeyColumn;
    if (![self _asyncdb_hasValueForColumnProperty: primaryKey.propertyName])
        @throw [OFInvalidArgumentException exception];

    OFString *SQL = [OFString stringWithFormat: @"DELETE FROM %@ WHERE %@ = ?",
                                               [AsyncDBORM quotedIdentifier: self.schema.tableName],
                                               [AsyncDBORM quotedIdentifier: primaryKey.SQLName]];
    return [(id)connection asyncdb_executeSQL: SQL
                                       values: [OFArray arrayWithObject:
                                           [AsyncDBORM SQLiteValueForModelValue: [self _asyncdb_valueForColumnProperty: primaryKey.propertyName]
                                                                        column: primaryKey]]];
}

+ (AsyncTask<__kindof AsyncDBTable *> *)fetchFromConnection: (id<AsyncDBConnection>)connection
                                                 primaryKey: (id)primaryKey
{
    AsyncDBEntitySchema *schema = [self schema];
    auto selectedColumns = [OFMutableArray<OFString *> arrayWithCapacity: schema.columns.count];
    for (AsyncDBColumnSchema *column in schema.columns)
        [selectedColumns addObject: [AsyncDBORM quotedIdentifier: column.SQLName]];

    OFString *SQL = [OFString stringWithFormat: @"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1",
                                               [selectedColumns componentsJoinedByString: @", "],
                                               [AsyncDBORM quotedIdentifier: schema.tableName],
                                               [AsyncDBORM quotedIdentifier: schema.primaryKeyColumn.SQLName]];

    return (AsyncTask<__kindof AsyncDBTable *> *)[[(id)connection asyncdb_fetchRowsWithSQL: SQL
                                                                                    values: [OFArray arrayWithObject: primaryKey]]
        map: ^id(OFArray<OFDictionary<OFString *, id> *> *rows) {
            if (rows.count == 0)
                @throw [OFInvalidArgumentException exception];

            AsyncDBTable *record = [[self alloc] init];
            OFDictionary<OFString *, id> *row = rows[0];
            for (AsyncDBColumnSchema *column in schema.columns)
                [record _asyncdb_setValue: [AsyncDBORM modelValueForSQLiteValue: row[column.SQLName] ?: OFNull.null
                                                                          valueClass: column.valueClass]
                        forColumnProperty: column.propertyName];
            return record;
        }];
}

@end

@implementation AsyncDBTable (AsyncDBForeignKeyExpression)

- (AsyncDBColumnReference *)_asyncdb_primaryKeyColumnReference
{
    return [self columnNamed: self.schema.primaryKeyColumn.propertyName];
}

- (id<AsyncDBBooleanPredicate>)IS: (id)other
{ return [(id<AsyncDBComparableExpression>)self._asyncdb_primaryKeyColumnReference IS: other]; }

- (id<AsyncDBBooleanPredicate>)IS_NOT: (id)other
{ return [(id<AsyncDBComparableExpression>)self._asyncdb_primaryKeyColumnReference IS_NOT: other]; }

- (id<AsyncDBBooleanPredicate>)IN: (OFArray<id> *)values
{ return [(id<AsyncDBComparableExpression>)self._asyncdb_primaryKeyColumnReference IN: values]; }

- (id<AsyncDBBooleanPredicate>)NOT_IN: (OFArray<id> *)values
{ return [(id<AsyncDBComparableExpression>)self._asyncdb_primaryKeyColumnReference NOT_IN: values]; }

- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN: (id)other
{ return [(id<AsyncDBOrderedExpression>)self._asyncdb_primaryKeyColumnReference IS_LESS_THAN: other]; }

- (id<AsyncDBBooleanPredicate>)IS_LESS_THAN_OR_EQUAL: (id)other
{ return [(id<AsyncDBOrderedExpression>)self._asyncdb_primaryKeyColumnReference IS_LESS_THAN_OR_EQUAL: other]; }

- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN: (id)other
{ return [(id<AsyncDBOrderedExpression>)self._asyncdb_primaryKeyColumnReference IS_GREATER_THAN: other]; }

- (id<AsyncDBBooleanPredicate>)IS_GREATER_THAN_OR_EQUAL: (id)other
{ return [(id<AsyncDBOrderedExpression>)self._asyncdb_primaryKeyColumnReference IS_GREATER_THAN_OR_EQUAL: other]; }

- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column
{ return [self._asyncdb_primaryKeyColumnReference references: column]; }

- (AsyncDBForeignKeyConstraint *)references: (AsyncDBColumnReference *)column
                                  onDelete: (AsyncDBDeleteAction *nillable)deleteAction
{
    return [self._asyncdb_primaryKeyColumnReference references: column
                                                     onDelete: deleteAction];
}

@end

@implementation AsyncDBJoinClause

+ (instancetype)joinWithKind: (OFString *)kind
                       table: (AsyncDBTable *)table
                   predicate: (id<AsyncDBBooleanPredicate> nillable)predicate
{
    return [[self alloc] initWithKind: kind
                                table: table
                            predicate: predicate];
}

- (instancetype)initWithKind: (OFString *)kind
                       table: (AsyncDBTable *)table
                   predicate: (id<AsyncDBBooleanPredicate> nillable)predicate
{
    self = [super init];
    _kind = [kind copy];
    _table = table;
    _predicate = predicate;
    return self;
}

@end

@implementation AsyncDBOrderClause

+ (instancetype)orderWithColumn: (id<AsyncDBExpression>)column ascending: (bool)ascending
{
    return [[self alloc] initWithColumn: column
                              ascending: ascending];
}

- (instancetype)initWithColumn: (id<AsyncDBExpression>)column ascending: (bool)ascending
{
    self = [super init];
    _column = column;
    _ascending = ascending;
    return self;
}

@end

@implementation AsyncDBORM (QuerySQL)

+ (OFString *)SQLForExpression: (id)expression boundValues: (OFMutableArray<id> *)boundValues
{
    if ([expression isKindOfClass: AsyncDBColumnReference.class]) {
        AsyncDBColumnReference *column = expression;
        return [OFString stringWithFormat: @"%@.%@",
                                          [AsyncDBORM quotedIdentifier: column.table.schema.tableName],
                                          [AsyncDBORM quotedIdentifier: column.SQLName]];
    }

    if ([expression isKindOfClass: AsyncDBValueExpression.class]) {
        AsyncDBValueExpression *valueExpression = expression;
        [boundValues addObject: valueExpression.value];
        return @"?";
    }

    if ([expression isKindOfClass: AsyncDBPredicate.class]) {
        AsyncDBPredicate *predicate = expression;
        switch (predicate.kind) {
            case AsyncDBPredicateKind_COMPARISON:
                if ([predicate.operation isEqual: @"IN"] or [predicate.operation isEqual: @"NOT IN"]) {
                    id right = $assert_nonnil(predicate.right);
                    if (![right isKindOfClass: AsyncDBValueExpression.class])
                        @throw [OFInvalidArgumentException exception];

                    OFArray<id> *values = ((AsyncDBValueExpression *)right).value;
                    if (![values isKindOfClass: OFArray.class] or values.count == 0)
                        @throw [OFInvalidArgumentException exception];

                    auto placeholders = [OFMutableArray<OFString *> arrayWithCapacity: values.count];
                    for (id value in values) {
                        [boundValues addObject: value];
                        [placeholders addObject: @"?"];
                    }

                    return [OFString stringWithFormat: @"%@ %@ (%@)",
                                                      [AsyncDBORM SQLForExpression: predicate.left boundValues: boundValues],
                                                      predicate.operation,
                                                      [placeholders componentsJoinedByString: @", "]];
                }
                return [OFString stringWithFormat: @"%@ %@ %@",
                                                  [AsyncDBORM SQLForExpression: predicate.left boundValues: boundValues],
                                                  predicate.operation,
                                                  [AsyncDBORM SQLForExpression: $assert_nonnil(predicate.right) boundValues: boundValues]];
            case AsyncDBPredicateKind_AND:
                return [OFString stringWithFormat: @"(%@ AND %@)",
                                                  [AsyncDBORM SQLForExpression: predicate.left boundValues: boundValues],
                                                  [AsyncDBORM SQLForExpression: $assert_nonnil(predicate.right) boundValues: boundValues]];
            case AsyncDBPredicateKind_OR:
                return [OFString stringWithFormat: @"(%@ OR %@)",
                                                  [AsyncDBORM SQLForExpression: predicate.left boundValues: boundValues],
                                                  [AsyncDBORM SQLForExpression: $assert_nonnil(predicate.right) boundValues: boundValues]];
            case AsyncDBPredicateKind_NOT:
                return [OFString stringWithFormat: @"(NOT %@)",
                                                  [AsyncDBORM SQLForExpression: predicate.left boundValues: boundValues]];
        }
    }

    @throw [OFInvalidArgumentException exception];
}

+ (id<AsyncDBBooleanPredicate> nillable)inferredJoinPredicateForTable: (AsyncDBTable *)joinTable
                                                         joinedTables: (OFArray<AsyncDBTable *> *)joinedTables
{
    for (AsyncDBTable *joinedTable in joinedTables) {
        for (AsyncDBColumnSchema *column in joinedTable.schema.columns) {
            if (column.referencedTableClass == joinTable.class) {
                AsyncDBColumnReference *sourceColumn = [joinedTable columnNamed: column.propertyName];
                AsyncDBColumnReference *targetColumn = [joinTable columnNamed: joinTable.schema.primaryKeyColumn.propertyName];
                return [(id<AsyncDBComparableExpression>)sourceColumn IS: targetColumn];
            }
        }

        for (AsyncDBColumnSchema *column in joinTable.schema.columns) {
            if (column.referencedTableClass == joinedTable.class) {
                AsyncDBColumnReference *sourceColumn = [joinTable columnNamed: column.propertyName];
                AsyncDBColumnReference *targetColumn = [joinedTable columnNamed: joinedTable.schema.primaryKeyColumn.propertyName];
                return [(id<AsyncDBComparableExpression>)sourceColumn IS: targetColumn];
            }
        }
    }

    return nilptr;
}

@end

@implementation AsyncDBQueryBuilder

+ (instancetype)FROM: (AsyncDBTable *)table
{
    return [[self alloc] initWithTable: table];
}

- (instancetype)initWithTable: (AsyncDBTable *)table
{
    self = [super init];
    _fromTable = table;
    _joins = [[OFMutableArray alloc] init];
    _groupByColumns = [[OFMutableArray alloc] init];
    _orderClauses = [[OFMutableArray alloc] init];
    _limitValue = [Optional none];
    _offsetValue = [Optional none];
    return self;
}

- (instancetype)DISTINCT
{
    _distinct = true;
    return self;
}

- (instancetype)_join: (OFString *)kind
                table: (AsyncDBTable *)table
            predicate: (id<AsyncDBBooleanPredicate> nillable)predicate
{
    [_joins addObject: [AsyncDBJoinClause joinWithKind: kind
                                                 table: table
                                             predicate: predicate]];
    return self;
}

- (instancetype)JOIN: (AsyncDBTable *)table
{
    id<AsyncDBBooleanPredicate> predicate = [AsyncDBORM inferredJoinPredicateForTable: table
                                                                         joinedTables: [self _joinedTables]];
    if (predicate == nilptr)
        @throw [OFInvalidArgumentException exception];
    return [self JOIN: table
                   ON: predicate];
}

- (instancetype)JOIN: (AsyncDBTable *)table ON: (id<AsyncDBBooleanPredicate>)predicate
{ return [self _join: @"JOIN" table: table predicate: predicate]; }

- (instancetype)LEFT_JOIN: (AsyncDBTable *)table
{
    id<AsyncDBBooleanPredicate> predicate = [AsyncDBORM inferredJoinPredicateForTable: table
                                                                         joinedTables: [self _joinedTables]];
    if (predicate == nilptr)
        @throw [OFInvalidArgumentException exception];
    return [self LEFT_JOIN: table
                        ON: predicate];
}

- (instancetype)LEFT_JOIN: (AsyncDBTable *)table ON: (id<AsyncDBBooleanPredicate>)predicate
{ return [self _join: @"LEFT JOIN" table: table predicate: predicate]; }

- (instancetype)CROSS_JOIN: (AsyncDBTable *)table
{ return [self _join: @"CROSS JOIN" table: table predicate: nilptr]; }

- (OFArray<AsyncDBTable *> *)_joinedTables
{
    auto tables = [OFMutableArray<AsyncDBTable *> arrayWithObject: _fromTable];
    for (AsyncDBJoinClause *join in _joins)
        [tables addObject: join.table];
    return tables;
}

- (instancetype)JOIN_ALL: (OFArray<AsyncDBTable *> *)tables
{
    auto pendingTables = [OFMutableArray<AsyncDBTable *> arrayWithArray: tables];

    while (pendingTables.count > 0) {
        bool joinedAny = false;

        for (size_t index = 0; index < pendingTables.count; index++) {
            AsyncDBTable *table = pendingTables[index];
            id<AsyncDBBooleanPredicate> predicate = [AsyncDBORM inferredJoinPredicateForTable: table
                                                                                 joinedTables: [self _joinedTables]];
            if (predicate == nilptr)
                continue;

            [self JOIN: table
                    ON: predicate];
            [pendingTables removeObjectAtIndex: index];
            joinedAny = true;
            break;
        }

        if (not joinedAny)
            @throw [OFInvalidArgumentException exception];
    }

    return self;
}

- (instancetype)WHERE: (id<AsyncDBBooleanPredicate>)predicate
{
    _wherePredicate = predicate;
    return self;
}

- (instancetype)AND_WHERE: (id<AsyncDBBooleanPredicate>)predicate
{
    _wherePredicate = _wherePredicate == nilptr ? predicate : [_wherePredicate AND: predicate];
    return self;
}

- (instancetype)OR_WHERE: (id<AsyncDBBooleanPredicate>)predicate
{
    _wherePredicate = _wherePredicate == nilptr ? predicate : [_wherePredicate OR: predicate];
    return self;
}

- (instancetype)GROUP_BY: (OFArray<AsyncDBColumnReference *> *)columns
{
    [_groupByColumns addObjectsFromArray: columns];
    return self;
}

- (instancetype)HAVING: (id<AsyncDBBooleanPredicate>)predicate
{
    _havingPredicate = predicate;
    return self;
}

- (instancetype)AND_HAVING: (id<AsyncDBBooleanPredicate>)predicate
{
    _havingPredicate = _havingPredicate == nilptr ? predicate : [_havingPredicate AND: predicate];
    return self;
}

- (instancetype)OR_HAVING: (id<AsyncDBBooleanPredicate>)predicate
{
    _havingPredicate = _havingPredicate == nilptr ? predicate : [_havingPredicate OR: predicate];
    return self;
}

- (instancetype)ORDER_BY: (id<AsyncDBExpression>)column
{
    return [self ORDER_BY: column
                     ASC: true];
}

- (instancetype)ORDER_BY: (id<AsyncDBExpression>)column ASC: (bool)ascending
{
    [_orderClauses addObject: [AsyncDBOrderClause orderWithColumn: column
                                                        ascending: ascending]];
    return self;
}

- (instancetype)LIMIT: (size_t)limit
{
    _limitValue = [Optional some: @(limit)];
    return self;
}

- (instancetype)OFFSET: (size_t)offset
{
    _offsetValue = [Optional some: @(offset)];
    return self;
}

- (instancetype)LIMIT: (size_t)limit OFFSET: (size_t)offset
{
    return [[self LIMIT: limit] OFFSET: offset];
}

- (AsyncDBSelectQuery *)SELECT_ALL_INTO: (Class)resultClass
{
    auto selection = [OFMutableDictionary<OFString *, id<AsyncDBExpression>> dictionary];
    for (AsyncDBColumnSchema *column in _fromTable.schema.columns)
        selection[column.propertyName] = [_fromTable columnNamed: column.propertyName];
    return [self SELECT: selection
                   INTO: resultClass];
}

- (AsyncDBSelectQuery *)SELECT: (OFDictionary<OFString *, id<AsyncDBExpression>> *)expressions
                          INTO: (Class)resultClass
{
    auto boundValues = [OFMutableArray<id> array];
    auto selectParts = [OFMutableArray<OFString *> arrayWithCapacity: expressions.count];

    for (OFString *alias in expressions.allKeys) {
        [selectParts addObject: [OFString stringWithFormat: @"%@ AS %@",
                                                           [AsyncDBORM SQLForExpression: $assert_nonnil(expressions[alias])
                                                                            boundValues: boundValues],
                                                           [AsyncDBORM quotedIdentifier: alias]]];
    }

    auto SQL = [OFMutableString stringWithFormat: @"SELECT %@%@ FROM %@",
                                              _distinct ? @"DISTINCT " : @"",
                                              [selectParts componentsJoinedByString: @", "],
                                              [AsyncDBORM quotedIdentifier: _fromTable.schema.tableName]];

    for (AsyncDBJoinClause *join in _joins) {
        [SQL appendFormat: @" %@ %@", join.kind, [AsyncDBORM quotedIdentifier: join.table.schema.tableName]];
        if (join.predicate != nilptr)
            [SQL appendFormat: @" ON %@", [AsyncDBORM SQLForExpression: $assert_nonnil(join.predicate)
                                                            boundValues: boundValues]];
    }

    if (_wherePredicate != nilptr)
        [SQL appendFormat: @" WHERE %@", [AsyncDBORM SQLForExpression: $assert_nonnil(_wherePredicate)
                                                           boundValues: boundValues]];

    if (_groupByColumns.count > 0) {
        auto groups = [OFMutableArray<OFString *> arrayWithCapacity: _groupByColumns.count];
        for (AsyncDBColumnReference *column in _groupByColumns)
            [groups addObject: [AsyncDBORM SQLForExpression: column boundValues: boundValues]];
        [SQL appendFormat: @" GROUP BY %@", [groups componentsJoinedByString: @", "]];
    }

    if (_havingPredicate != nilptr)
        [SQL appendFormat: @" HAVING %@", [AsyncDBORM SQLForExpression: $assert_nonnil(_havingPredicate)
                                                            boundValues: boundValues]];

    if (_orderClauses.count > 0) {
        auto orders = [OFMutableArray<OFString *> arrayWithCapacity: _orderClauses.count];
        for (AsyncDBOrderClause *order in _orderClauses)
            [orders addObject: [OFString stringWithFormat: @"%@ %@",
                                                          [AsyncDBORM SQLForExpression: order.column boundValues: boundValues],
                                                          order.ascending ? @"ASC" : @"DESC"]];
        [SQL appendFormat: @" ORDER BY %@", [orders componentsJoinedByString: @", "]];
    }

    if (_limitValue.hasValue) {
        [SQL appendString: @" LIMIT ?"];
        [boundValues addObject: _limitValue.value];
    }

    if (_offsetValue.hasValue) {
        [SQL appendString: @" OFFSET ?"];
        [boundValues addObject: _offsetValue.value];
    }

    return [[AsyncDBSelectQuery alloc] initWithSQL: SQL
                                       boundValues: boundValues
                                       resultClass: resultClass
                                         selection: expressions];
}

@end

@implementation AsyncDBSelectQuery

- (instancetype)initWithSQL: (OFString *)SQL
                boundValues: (OFArray<id> *)boundValues
                resultClass: (Class)resultClass
                  selection: (OFDictionary<OFString *, id<AsyncDBExpression>> *)selection
{
    self = [super init];
    _SQL = [SQL copy];
    _boundValues = [boundValues copy];
    _resultClass = resultClass;
    _selection = [selection copy];
    return self;
}

- (id)_mappedObjectForRow: (OFDictionary<OFString *, id> *)row
{
    id object = [[_resultClass alloc] init];

    for (OFString *alias in _selection.allKeys) {
        OFString *nillable valueClassName = [AsyncDBORM classNameForProperty: _resultClass
                                                                 propertyName: alias];
        Class valueClass = valueClassName != nilptr ? objc_getClass(valueClassName.UTF8String) : Nil;
        [AsyncDBORM setObject: object
                      property: alias
                         value: [AsyncDBORM modelValueForSQLiteValue: row[alias] ?: OFNull.null
                                                           valueClass: valueClass]];
    }

    return object;
}

- (AsyncTask<OFArray<id> *> *)allInConnection: (id<AsyncDBConnection>)connection
{
    return (AsyncTask<OFArray<id> *> *)[[(id)connection asyncdb_fetchRowsWithSQL: _SQL
                                                                          values: _boundValues]
        map: ^id(OFArray<OFDictionary<OFString *, id> *> *rows) {
            auto objects = [OFMutableArray arrayWithCapacity: rows.count];
            for (OFDictionary<OFString *, id> *row in rows)
                [objects addObject: [self _mappedObjectForRow: row]];
            return [objects copy];
        }];
}

- (AsyncTask<id> *)firstInConnection: (id<AsyncDBConnection>)connection
{
    return [[self allInConnection: connection] map: ^id(OFArray *rows) {
        if (rows.count == 0)
            @throw [OFInvalidArgumentException exception];
        return rows[0];
    }];
}

- (AsyncTask<Optional<id> *> *)firstOptionalInConnection: (id<AsyncDBConnection>)connection
{
    return (AsyncTask<Optional<id> *> *)[[self allInConnection: connection] map: ^id(OFArray *rows) {
        if (rows.count == 0)
            return [Optional none];
        return [Optional some: rows[0]];
    }];
}

@end

#pragma clang assume_nonnull end
