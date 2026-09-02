#import <Common.h>

#pragma clang assume_nonnull begin

/** A key and the elements assigned to it by a LINQ grouping operation. */
[[subclassing_restricted]]
@interface OFArrayLINQGroup<TKey, TValue>: OFObject
@property (readonly, nonatomic, retain) TKey key;
@property (readonly, nonatomic, copy) OFArray<TValue> *elements;

- (instancetype)initWithKey: (TKey)key elements: (OFArray<TValue> *)elements;
@end

/** A deferred, composable ordering returned by `orderBy:`. */
[[subclassing_restricted]]
@interface OFArrayLINQOrdered<T>: OFObject

- (OFArray<T> *)toArray;
- (OFArrayLINQOrdered<T> *)thenBy: (id nillable (^)(T object))keySelector;
- (OFArrayLINQOrdered<T> *)thenBy: (id nillable (^)(T object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator;
- (OFArrayLINQOrdered<T> *)thenByDescending: (id nillable (^)(T object))keySelector;
- (OFArrayLINQOrdered<T> *)thenByDescending: (id nillable (^)(T object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator;
@end

/** C#-style sequence LINQ operators for OFArray. */
@interface OFArray<T> (LINQ)

/* Sequence construction and projection. */
+ (OFArray<T> *)empty;
+ (OFArray<T> *)repeat: (T)object count: (size_t)count;
+ (OFArray<T> *)repeatObject: (T)object count: (size_t)count;
+ (OFArray<OFNumber *> *)range: (int64_t)start count: (size_t)count;
+ (OFArray<OFNumber *> *)rangeFrom: (int64_t)start count: (size_t)count;

- (OFArray<T> *)toArray;
- (OFArray<T> *)append: (T)object;
- (OFArray<T> *)prepend: (T)object;
- (OFArray<T> *)concat: (OFArray<T> *)other;
- (OFArray<T> *)defaultIfEmpty: (T)defaultValue;
- (OFArray<T> *)reverse;
- (OFArray<T> *)where: (bool (^)(T object))predicate;
- (OFArray<T> *)whereIndexed: (bool (^)(T object, size_t index))predicate;
- (OFArray<id> *)select: (id (^)(T object))selector;
- (OFArray<id> *)selectIndexed: (id (^)(T object, size_t index))selector;
- (OFArray<id> *)selectMany: (OFArray<id> *(^)(T object))selector;
- (OFArray<id> *)selectMany: (OFArray<id> *(^)(T object))selector resultSelector: (id (^)(T outer, id inner))resultSelector;
- (OFArray<id> *)ofType: (Class)class;
- (OFArray<id> *)castToClass: (Class)class;

/* Element lookup. */
- (T)elementAt: (size_t)index;
- (T nillable)elementAtOrDefault: (size_t)index;
- (T)first;
- (T nillable)firstOrDefault;
- (T)firstWhere: (bool (^)(T object))predicate;
- (T nillable)firstOrDefaultWhere:
    (bool (^)(T object))predicate;
- (T)last;
- (T nillable)lastOrDefault;
- (T)lastWhere: (bool (^)(T object))predicate;
- (T nillable)lastOrDefaultWhere: (bool (^)(T object))predicate;
- (T)single;
- (T nillable)singleOrDefault;
- (T)singleWhere: (bool (^)(T object))predicate;
- (T nillable)singleOrDefaultWhere: (bool (^)(T object))predicate;

/* Quantifiers and aggregation. */
- (bool)any;
- (bool)any: (bool (^)(T object))predicate;
- (bool)all: (bool (^)(T object))predicate;
- (bool)none: (bool (^)(T object))predicate;
- (bool)contains: (T)object;
- (bool)contains: (T)object usingEquality: (bool (^nillable)(T left, T right))equality;
- (bool)sequenceEqual: (OFArray<T> *)other;
- (bool)sequenceEqual: (OFArray<T> *)other usingEquality: (bool (^nillable)(T left, T right))equality;
- (size_t)countWhere: (bool (^)(T object))predicate;
- (id nillable)aggregate: (id (^)(id accumulator, T object))accumulator;
- (id)aggregateWithSeed: (id)seed accumulator: (id (^)(id accumulator, T object))accumulator;
- (id)aggregateWithSeed: (id)seed accumulator: (id (^)(id accumulator, T object))accumulator resultSelector: (id (^)(id result))resultSelector;
- (double)sum;
- (double)sumBy: (OFNumber *(^)(T object))selector;
- (double)average;
- (double)averageBy: (OFNumber *(^)(T object))selector;
- (T nillable)min;
- (T nillable)max;
- (T nillable)minBy: (id nillable (^)(T object))keySelector;
- (T nillable)maxBy: (id nillable (^)(T object))keySelector;

/* Ordering. */
- (OFArrayLINQOrdered<T> *)orderBy: (id nillable (^)(T object))keySelector;
- (OFArrayLINQOrdered<T> *)orderBy: (id nillable (^)(T object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator;
- (OFArrayLINQOrdered<T> *)orderByDescending: (id nillable (^)(T object))keySelector;
- (OFArrayLINQOrdered<T> *)orderByDescending: (id nillable (^)(T object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator;

/* Grouping, joining and zipping. */
- (OFArray<OFArrayLINQGroup<id, T> *> *)groupBy: (id nillable (^)(T object))keySelector;
- (OFArray<OFArrayLINQGroup<id, id> *> *)groupBy: (id nillable (^)(T object))keySelector elementSelector: (id (^)(T object))elementSelector;
- (OFArray<id> *)groupBy: (id nillable (^)(T object))keySelector resultSelector: (id (^)(id key, OFArray<id> *elements))resultSelector;
- (OFArray<id> *)join: (OFArray *)inner outerKeySelector: (id nillable (^)(T outer))outerKeySelector innerKeySelector: (id nillable (^)(id inner))innerKeySelector resultSelector: (id (^)(T outer, id inner))resultSelector;
- (OFArray<id> *)groupJoin: (OFArray *)inner outerKeySelector: (id nillable (^)(id outer))outerKeySelector innerKeySelector: (id nillable (^)(id inner))innerKeySelector resultSelector: (id (^)(id outer, OFArray<id> *matches))resultSelector;
- (OFArray<OFPair<T, id> *> *)zip: (OFArray *)other;
- (OFArray<id> *)zip: (OFArray *)other resultSelector: (id (^)(T left, id right))resultSelector;

/* Set-like operations. */
- (OFArray<T> *)distinct;
- (OFArray<T> *)distinctBy: (id nillable (^)(T object))keySelector;
- (OFArray<T> *)distinctUsingEquality: (bool (^nillable)(T left, T right))equality;
- (OFArray<T> *)union: (OFArray<T> *)other;
- (OFArray<T> *)union: (OFArray<T> *)other by: (id nillable (^)(T object))keySelector;
- (OFArray<T> *)unionWith: (OFArray<T> *)other;
- (OFArray<T> *)unionWith: (OFArray<T> *)other usingEquality: (bool (^nillable)(T left, T right))equality;
- (OFArray<T> *)intersectWith: (OFArray<T> *)other;
- (OFArray<T> *)intersect: (OFArray<T> *)other;
- (OFArray<T> *)intersect: (OFArray<T> *)other by: (id nillable (^)(T object))keySelector;
- (OFArray<T> *)intersectWith: (OFArray<T> *)other usingEquality: (bool (^nillable)(T left, T right))equality;
- (OFArray<T> *)exceptWith: (OFArray<T> *)other;
- (OFArray<T> *)except: (OFArray<T> *)other;
- (OFArray<T> *)except: (OFArray<T> *)other by: (id nillable (^)(T object))keySelector;
- (OFArray<T> *)exceptWith: (OFArray<T> *)other usingEquality: (bool (^nillable)(T left, T right))equality;

/* Paging and conversion. */
- (OFArray<T> *)skip: (size_t)count;
- (OFArray<T> *)skipLast: (size_t)count;
- (OFArray<T> *)skipWhile: (bool (^)(T object))predicate;
- (OFArray<T> *)take: (size_t)count;
- (OFArray<T> *)takeLast: (size_t)count;
- (OFArray<T> *)takeWhile: (bool (^)(T object))predicate;
- (OFArray<OFArray<T> *> *)chunk: (size_t)size;
- (OFSet<T> *)toSet;
- (OFSet<T> *)toHashSet;
- (OFDictionary *)toDictionaryWithKeySelector: (id nillable (^)(T object))keySelector;
- (OFDictionary *)toDictionaryWithKeySelector: (id nillable (^)(T object))keySelector elementSelector: (id (^)(T object))elementSelector;

@end

#pragma clang assume_nonnull end
