#import <OFArray+LINQ.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface OFArrayLINQSupport<T> : OFObject
+ (bool)containsObject: (T)object inArray: (OFArray<T> *)array usingEquality: (bool (^nillable)(T left, T right))equality;
+ (T)keyOrNull: (T nillable)key;
+ (void)addObject: (T)object ifNotContainedIn: (OFMutableArray<T> *)array usingEquality: (bool (^nillable)(T left, T right))equality;
+ (OFArray<T> *)immutableArrayFromMutableArray: (OFMutableArray<T> *)array;
+ (OFComparisonResult (^)(T<OFComparing> left, T<OFComparing> right))defaultComparator;
@end

@implementation OFArrayLINQSupport

+ (bool)containsObject: (id)object inArray: (OFArray *)array usingEquality: (bool (^nillable)(id left, id right))equality
{
    for (id candidate in array) {
        if (equality != nilptr ? equality(candidate, object) : [candidate isEqual: object])
            return true;
    }

    return false;
}

+ (id)keyOrNull: (id nillable)key
{ return key ?: OFNull.null; }

+ (void)addObject: (id)object ifNotContainedIn: (OFMutableArray *)array usingEquality: (bool (^nillable)(id left, id right))equality
{
    if (not [self containsObject: object inArray: array usingEquality: equality])
        [array addObject: object];
}

+ (OFArray *)immutableArrayFromMutableArray: (OFMutableArray *)array
{
    [array makeImmutable];
    return array;
}

+ (OFComparisonResult (^)(id<OFComparing> left, id<OFComparing> right))defaultComparator
{
    return ^(id<OFComparing> left, id<OFComparing> right) { return [left compare: right]; };
}

@end

@interface OFArrayLINQGroup<KeyType, ElementType> ()
@end

@implementation OFArrayLINQGroup

- (instancetype)initWithKey: (id)key elements: (OFArray *)elements
{
    self = [super init];

    if (self == nilptr)
        return nilptr;

    _key = key;
    _elements = [elements copy];
    return self;
}

@end

[[subclassing_restricted, direct_members]]
@interface OFArrayLINQSortDescriptor: OFObject
@property (nonatomic, copy) id nillable (^keySelector)(id object);
@property (nonatomic, copy) OFComparisonResult (^comparator)(id left, id right);
@property (nonatomic) bool descending;

- (instancetype)initWithKeySelector: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator descending: (bool)descending;
@end

@implementation OFArrayLINQSortDescriptor

- (instancetype)initWithKeySelector: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator descending: (bool)descending
{
    self = [super init];

    if (self == nilptr)
        return nilptr;

    _keySelector = [keySelector copy];
    _comparator = [comparator copy];
    _descending = descending;
    return self;
}

@end

@interface OFArrayLINQOrdered<R> ()
- (instancetype)_initWithArray: (OFArray<R> *)array descriptors: (OFArray<OFArrayLINQSortDescriptor *> *)descriptors;
- (instancetype)_thenBy: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator descending: (bool)descending;
- (OFComparisonResult)_compareLeft: (id)left right: (id)right;
@end

@implementation OFArrayLINQOrdered {
    OFArray *_array;
    OFArray<OFArrayLINQSortDescriptor *> *_descriptors;
}

- (instancetype)_initWithArray: (OFArray *)array descriptors: (OFArray<OFArrayLINQSortDescriptor *> *)descriptors
{
    self = [super init];

    if (self == nilptr)
        return nilptr;

    _array = [array copy];
    _descriptors = [descriptors copy];
    return self;
}

- (OFComparisonResult)_compareLeft: (id)left right: (id)right
{
    for (OFArrayLINQSortDescriptor *descriptor in _descriptors) {
        id leftKey = descriptor.keySelector(left);
        id rightKey = descriptor.keySelector(right);
        leftKey = [OFArrayLINQSupport keyOrNull: leftKey];
        rightKey = [OFArrayLINQSupport keyOrNull: rightKey];

        auto result = descriptor.comparator(leftKey, rightKey);
        if (result == OFOrderedSame)
            continue;

        if (descriptor.descending)
            return result == OFOrderedAscending ? OFOrderedDescending : OFOrderedAscending;

        return result;
    }

    if (left != right) {
        size_t leftIndex = [_array indexOfObjectIdenticalTo: left];
        size_t rightIndex = [_array indexOfObjectIdenticalTo: right];
        if (leftIndex != OFNotFound and rightIndex != OFNotFound and leftIndex != rightIndex)
            return leftIndex < rightIndex ? OFOrderedAscending : OFOrderedDescending;
    }

    return OFOrderedSame;
}

- (OFArray *)toArray
{
    return [_array sortedArrayUsingComparator: ^(id left, id right) {
        return [self _compareLeft: left right: right];
    } options: (OFArraySortOptions)0];
}

- (instancetype)_thenBy: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator descending: (bool)descending
{
    auto descriptor = [[OFArrayLINQSortDescriptor alloc] initWithKeySelector: keySelector comparator: comparator descending: descending];
    auto descriptors = [OFMutableArray<OFArrayLINQSortDescriptor *> array];
    [descriptors addObjectsFromArray: _descriptors];
    [descriptors addObject: descriptor];
    [descriptors makeImmutable];

    return [[[self class] alloc] _initWithArray: _array descriptors: descriptors];
}

- (OFArrayLINQOrdered *)thenBy: (id nillable (^)(id object))keySelector
{
    return [self thenBy: keySelector comparator: OFArrayLINQSupport.defaultComparator];
}

- (OFArrayLINQOrdered *)thenBy: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator
{
    return [self _thenBy: keySelector comparator: comparator descending: false];
}

- (OFArrayLINQOrdered *)thenByDescending: (id nillable (^)(id object))keySelector
{
    return [self thenByDescending: keySelector comparator: [OFArrayLINQSupport defaultComparator]];
}

- (OFArrayLINQOrdered *)thenByDescending: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator
{
    return [self _thenBy: keySelector comparator: comparator descending: true];
}

@end

@interface OFArray<ObjectType> (LINQPrivate)
- (ObjectType nillable)_linqExtremeWithKeySelector: (id nillable (^)(id object))keySelector findMaximum: (bool)findMaximum;
@end

@implementation OFArray (LINQ)

+ (OFArray *)empty
{ return @[]; }

+ (OFArray *)repeat: (id)object count: (size_t)count
{ return [self repeatObject: object count: count]; }

+ (OFArray *)repeatObject: (id)object count: (size_t)count
{
    auto result = [OFMutableArray arrayWithCapacity: count];
    for (size_t i = 0; i < count; i++)
        [result addObject: object];

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

+ (OFArray<OFNumber *> *)rangeFrom: (int64_t)start count: (size_t)count
{
    if (count > 0 and start > INT64_MAX - (int64_t)(count - 1))
        @throw [OFOutOfRangeException exception];

    auto result = [OFMutableArray<OFNumber *> arrayWithCapacity: count];
    for (size_t i = 0; i < count; i++)
        [result addObject: @(start + (int64_t)i)];

    return (OFArray<OFNumber *> *)[OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

+ (OFArray<OFNumber *> *)range: (int64_t)start count: (size_t)count
{ return [self rangeFrom: start count: count]; }

- (OFArray *)toArray
{ return [OFArray arrayWithArray: self]; }

- (OFArray *)append: (id)object
{ return [self arrayByAddingObject: object]; }

- (OFArray *)prepend: (id)object
{
    auto result = [OFMutableArray arrayWithCapacity: self.count + 1];
    [result addObject: object];
    [result addObjectsFromArray: self];
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)concat: (OFArray *)other
{ return [self arrayByAddingObjectsFromArray: other]; }

- (OFArray *)defaultIfEmpty: (id)defaultValue
{
    return self.count == 0 ? @[ defaultValue ] : self;
}

- (OFArray *)reverse
{ return self.reversedArray; }

- (OFArray *)where: (bool (^)(id object))predicate
{
    auto result = [OFMutableArray array];
    for (id object in self) {
        if (predicate(object))
            [result addObject: object];
    }

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)whereIndexed: (bool (^)(id object, size_t index))predicate
{
    auto result = [OFMutableArray array];
    size_t index = 0;
    for (id object in self) {
        if (predicate(object, index))
            [result addObject: object];
        index++;
    }

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)select: (id (^)(id object))selector
{
    auto result = [OFMutableArray arrayWithCapacity: self.count];
    for (id object in self)
        [result addObject: selector(object)];

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)selectIndexed: (id (^)(id object, size_t index))selector
{
    auto result = [OFMutableArray arrayWithCapacity: self.count];
    size_t index = 0;
    for (id object in self)
        [result addObject: selector(object, index++)];

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)selectMany: (OFArray<id> *(^)(id object))selector
{
    auto result = [OFMutableArray array];
    for (id object in self)
        [result addObjectsFromArray: selector(object)];

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)selectMany: (OFArray<id> *(^)(id object))selector resultSelector: (id (^)(id outer, id inner))resultSelector
{
    auto result = [OFMutableArray array];
    for (id outer in self) {
        for (id inner in selector(outer))
            [result addObject: resultSelector(outer, inner)];
    }

    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray<id> *)ofType: (Class)class
{
    return [self filteredArrayUsingBlock: ^bool(id object, size_t index) {
        (void)index;
        return [object isKindOfClass: class];
    }];
}

- (OFArray<id> *)castToClass: (Class)class
{
    for (id object in self) {
        if (not [object isKindOfClass: class])
            @throw [OFInvalidArgumentException exception];
    }

    return self;
}

- (id)elementAt: (size_t)index
{
    if (index >= self.count)
        @throw [OFOutOfRangeException exception];

    return self[index];
}

- (id nillable)elementAtOrDefault: (size_t)index
{ return index < self.count ? self[index] : nilptr; }

- (id)first
{
    if (self.count == 0)
        @throw [OFOutOfRangeException exception];

    return self[0];
}

- (id nillable)firstOrDefault
{ return self.firstObject; }

- (id)firstWhere: (bool (^)(id object))predicate
{
    id nillable result = [self firstOrDefaultWhere: predicate];
    if (result == nilptr)
        @throw [OFOutOfRangeException exception];
    return $assert_nonnil(result);
}

- (id nillable)firstOrDefaultWhere: (bool (^)(id object))predicate
{
    for (id object in self) {
        if (predicate(object))
            return object;
    }
    return nilptr;
}

- (id)last
{
    if (self.count == 0)
        @throw [OFOutOfRangeException exception];

    return self[self.count - 1];
}

- (id nillable)lastOrDefault
{ return self.lastObject; }

- (id)lastWhere: (bool (^)(id object))predicate
{
    id nillable result = [self lastOrDefaultWhere: predicate];
    if (result == nilptr)
        @throw [OFOutOfRangeException exception];
    return $assert_nonnil(result);
}

- (id nillable)lastOrDefaultWhere: (bool (^)(id object))predicate
{
    id nillable result = nilptr;
    for (id object in self) {
        if (predicate(object))
            result = object;
    }
    return result;
}

- (id)single
{
    if (self.count != 1)
        @throw [OFInvalidArgumentException exception];
    return self[0];
}

- (id nillable)singleOrDefault
{
    if (self.count > 1)
        @throw [OFInvalidArgumentException exception];
    return self.firstObject;
}

- (id)singleWhere: (bool (^)(id object))predicate
{
    id nillable result = [self singleOrDefaultWhere: predicate];
    if (result == nilptr)
        @throw [OFOutOfRangeException exception];
    return $assert_nonnil(result);
}

- (id nillable)singleOrDefaultWhere: (bool (^)(id object))predicate
{
    id nillable result = nilptr;
    for (id object in self) {
        if (not predicate(object))
            continue;
        if (result != nilptr)
            @throw [OFInvalidArgumentException exception];
        result = object;
    }
    return result;
}

- (bool)any
{ return self.count != 0; }

- (bool)any: (bool (^)(id object))predicate
{
    for (id object in self) {
        if (predicate(object))
            return true;
    }
    return false;
}

- (bool)all: (bool (^)(id object))predicate
{
    for (id object in self) {
        if (not predicate(object))
            return false;
    }
    return true;
}

- (bool)none: (bool (^)(id object))predicate
{ return not [self any: predicate]; }

- (bool)contains: (id)object
{ return [self containsObject: object]; }

- (bool)contains: (id)object usingEquality: (bool (^nillable)(id left, id right))equality
{ return [OFArrayLINQSupport containsObject: object inArray: self usingEquality: equality]; }

- (bool)sequenceEqual: (OFArray *)other
{
    return [self sequenceEqual: other usingEquality: nilptr];
}

- (bool)sequenceEqual: (OFArray *)other usingEquality: (bool (^nillable)(id left, id right))equality
{
    if (self.count != other.count)
        return false;

    for (size_t i = 0; i < self.count; i++) {
        id left = self[i];
        id right = other[i];
        if (equality != nilptr ? not equality(left, right) : not [left isEqual: right])
            return false;
    }

    return true;
}

- (size_t)countWhere: (bool (^)(id object))predicate
{
    size_t count = 0;
    for (id object in self)
        if (predicate(object))
            count++;
    return count;
}

- (id nillable)aggregate: (id (^)(id accumulator, id object))accumulator
{
    if (self.count == 0)
        return nilptr;

    id result = self[0];
    for (size_t i = 1; i < self.count; i++)
        result = accumulator(result, self[i]);
    return result;
}

- (id)aggregateWithSeed: (id)seed accumulator: (id (^)(id accumulator, id object))accumulator
{
    id result = seed;
    for (id object in self)
        result = accumulator(result, object);
    return result;
}

- (id)aggregateWithSeed: (id)seed accumulator: (id (^)(id accumulator, id object))accumulator resultSelector: (id (^)(id result))resultSelector
{
    return resultSelector([self aggregateWithSeed: seed accumulator: accumulator]);
}

- (double)sum
{ return [self sumBy: ^id(id object) { return object; }]; }

- (double)sumBy: (OFNumber *(^)(id object))selector
{
    double result = 0;
    for (id object in self) {
        id value = selector(object);
        if (not [value isKindOfClass: OFNumber.class])
            @throw [OFInvalidArgumentException exception];
        result += ((OFNumber *)value).doubleValue;
    }
    return result;
}

- (double)average
{
    if (self.count == 0)
        @throw [OFInvalidArgumentException exception];
    return [self sum] / self.count;
}

- (double)averageBy: (OFNumber *(^)(id object))selector
{
    if (self.count == 0)
        @throw [OFInvalidArgumentException exception];
    return [self sumBy: selector] / self.count;
}

- (id nillable)_linqExtremeWithKeySelector: (id nillable (^)(id object))keySelector findMaximum: (bool)findMaximum
{
    if (self.count == 0)
        return nilptr;

    id result = self[0];
    id key = [OFArrayLINQSupport keyOrNull: keySelector(result)];
    for (size_t i = 1; i < self.count; i++) {
        id object = self[i];
        id objectKey = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        auto comparison = [objectKey compare: key];
        if ((findMaximum and comparison == OFOrderedDescending) or (not findMaximum and comparison == OFOrderedAscending)) {
            result = object;
            key = objectKey;
        }
    }
    return result;
}

- (id nillable)min
{ return [self _linqExtremeWithKeySelector: ^id(id object) { return object; } findMaximum: false]; }

- (id nillable)max
{ return [self _linqExtremeWithKeySelector: ^id(id object) { return object; } findMaximum: true]; }

- (id nillable)minBy: (id nillable (^)(id object))keySelector
{ return [self _linqExtremeWithKeySelector: keySelector findMaximum: false]; }

- (id nillable)maxBy: (id nillable (^)(id object))keySelector
{ return [self _linqExtremeWithKeySelector: keySelector findMaximum: true]; }

- (OFArrayLINQOrdered *)orderBy: (id nillable (^)(id object))keySelector
{
    return [self orderBy: keySelector comparator: [OFArrayLINQSupport defaultComparator]];
}

- (OFArrayLINQOrdered *)orderBy: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator
{
    auto descriptor = [[OFArrayLINQSortDescriptor alloc] initWithKeySelector: keySelector comparator: comparator descending: false];
    return [[OFArrayLINQOrdered alloc] _initWithArray: self descriptors: @[ descriptor ]];
}

- (OFArrayLINQOrdered *)orderByDescending: (id nillable (^)(id object))keySelector
{
    return [self orderByDescending: keySelector comparator: [OFArrayLINQSupport defaultComparator]];
}

- (OFArrayLINQOrdered *)orderByDescending: (id nillable (^)(id object))keySelector comparator: (OFComparisonResult (^)(id left, id right))comparator
{
    auto descriptor = [[OFArrayLINQSortDescriptor alloc] initWithKeySelector: keySelector comparator: comparator descending: true];
    return [[OFArrayLINQOrdered alloc] _initWithArray: self descriptors: @[ descriptor ]];
}

- (OFArray *)groupBy: (id nillable (^)(id object))keySelector
{
    return [self groupBy: keySelector elementSelector: ^id(id object) { return object; }];
}

- (OFArray *)groupBy: (id nillable (^)(id object))keySelector elementSelector: (id (^)(id object))elementSelector
{
    auto groups = [OFMutableDictionary dictionary];
    auto keys = [OFMutableArray array];

    for (id object in self) {
        id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        OFMutableArray *elements = [groups objectForKey: key];
        if (elements == nilptr) {
            elements = [OFMutableArray array];
            [groups setObject: elements forKey: key];
            [keys addObject: key];
        }
        [elements addObject: elementSelector(object)];
    }

    auto result = [OFMutableArray arrayWithCapacity: keys.count];
    for (id key in keys) {
        auto elements = [groups objectForKey: key];
        [elements makeImmutable];
        [result addObject: [[OFArrayLINQGroup alloc] initWithKey: key elements: $assert_nonnil(elements)]];
    }

    return (OFArray<OFArrayLINQGroup *> *)[OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)groupBy: (id nillable (^)(id object))keySelector resultSelector: (id (^)(id key, OFArray<id> *elements))resultSelector
{
    auto result = [OFMutableArray array];
    for (OFArrayLINQGroup *group in [self groupBy: keySelector])
        [result addObject: resultSelector(group.key, group.elements)];
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)join: (OFArray *)inner outerKeySelector: (id nillable (^)(id outer))outerKeySelector innerKeySelector: (id nillable (^)(id inner))innerKeySelector resultSelector: (id (^)(id outer, id inner))resultSelector
{
    auto result = [OFMutableArray array];
    for (id outer in self) {
        id outerKey = [OFArrayLINQSupport keyOrNull: outerKeySelector(outer)];
        for (id innerObject in inner) {
            id innerKey = [OFArrayLINQSupport keyOrNull: innerKeySelector(innerObject)];
            if ([outerKey isEqual: innerKey])
                [result addObject: resultSelector(outer, innerObject)];
        }
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)groupJoin: (OFArray *)inner outerKeySelector: (id nillable (^)(id outer))outerKeySelector innerKeySelector: (id nillable (^)(id inner))innerKeySelector resultSelector: (id (^)(id outer, OFArray<id> *matches))resultSelector
{
    auto result = [OFMutableArray array];
    for (id outer in self) {
        id outerKey = [OFArrayLINQSupport keyOrNull: outerKeySelector(outer)];
        auto matches = [OFMutableArray array];
        for (id innerObject in inner) {
            id innerKey = [OFArrayLINQSupport keyOrNull: innerKeySelector(innerObject)];
            if ([outerKey isEqual: innerKey])
                [matches addObject: innerObject];
        }
        [matches makeImmutable];
        [result addObject: resultSelector(outer, matches)];
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)zip: (OFArray *)other
{
    return [self zip: other resultSelector: ^id(id left, id right) {
        return [OFPair pairWithFirstObject: left secondObject: right];
    }];
}

- (OFArray *)zip: (OFArray *)other resultSelector: (id (^)(id left, id right))resultSelector
{
    size_t count = self.count < other.count ? self.count : other.count;
    auto result = [OFMutableArray arrayWithCapacity: count];
    for (size_t i = 0; i < count; i++)
        [result addObject: resultSelector(self[i], other[i])];
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)distinct
{ return [self distinctUsingEquality: nilptr]; }

- (OFArray *)distinctBy: (id nillable (^)(id object))keySelector
{
    auto result = [OFMutableArray array];
    auto keys = [OFMutableArray array];
    for (id object in self) {
        id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        if ([OFArrayLINQSupport containsObject: key inArray: keys usingEquality: nilptr])
            continue;
        [keys addObject: key];
        [result addObject: object];
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)distinctUsingEquality: (bool (^nillable)(id left, id right))equality
{
    auto result = [OFMutableArray array];
    for (id object in self)
        [OFArrayLINQSupport addObject: object ifNotContainedIn: result usingEquality: equality];
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)unionWith: (OFArray *)other
{ return [self unionWith: other usingEquality: nilptr]; }

- (OFArray *)union: (OFArray *)other
{ return [self unionWith: other]; }

- (OFArray *)union: (OFArray *)other by: (id nillable (^)(id object))keySelector
{
    auto result = [OFMutableArray array];
    auto keys = [OFMutableArray array];
    for (OFArray *source in @[ self, other ]) {
        for (id object in source) {
            id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
            if ([OFArrayLINQSupport containsObject: key inArray: keys usingEquality: nilptr])
                continue;
            [keys addObject: key];
            [result addObject: object];
        }
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)unionWith: (OFArray *)other usingEquality: (bool (^nillable)(id left, id right))equality
{
    auto result = [OFMutableArray array];
    for (id object in self)
        [OFArrayLINQSupport addObject: object ifNotContainedIn: result usingEquality: equality];
    for (id object in other)
        [OFArrayLINQSupport addObject: object ifNotContainedIn: result usingEquality: equality];
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)intersectWith: (OFArray *)other
{ return [self intersectWith: other usingEquality: nilptr]; }

- (OFArray *)intersect: (OFArray *)other
{ return [self intersectWith: other]; }

- (OFArray *)intersect: (OFArray *)other by: (id nillable (^)(id object))keySelector
{
    auto result = [OFMutableArray array];
    auto otherKeys = [OFMutableArray array];
    for (id object in other)
        [otherKeys addObject: [OFArrayLINQSupport keyOrNull: keySelector(object)]];

    auto resultKeys = [OFMutableArray array];
    for (id object in self) {
        id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        if ([OFArrayLINQSupport containsObject: key inArray: otherKeys usingEquality: nilptr] and not [OFArrayLINQSupport containsObject: key inArray: resultKeys usingEquality: nilptr]) {
            [resultKeys addObject: key];
            [result addObject: object];
        }
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)intersectWith: (OFArray *)other usingEquality: (bool (^nillable)(id left, id right))equality
{
    auto result = [OFMutableArray array];
    for (id object in self) {
        if ([OFArrayLINQSupport containsObject: object inArray: other usingEquality: equality])
            [OFArrayLINQSupport addObject: object ifNotContainedIn: result usingEquality: equality];
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)exceptWith: (OFArray *)other
{ return [self exceptWith: other usingEquality: nilptr]; }

- (OFArray *)except: (OFArray *)other
{ return [self exceptWith: other]; }

- (OFArray *)except: (OFArray *)other by: (id nillable (^)(id object))keySelector
{
    auto result = [OFMutableArray array];
    auto otherKeys = [OFMutableArray array];
    for (id object in other)
        [otherKeys addObject: [OFArrayLINQSupport keyOrNull: keySelector(object)]];

    auto resultKeys = [OFMutableArray array];
    for (id object in self) {
        id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        if ([OFArrayLINQSupport containsObject: key inArray: otherKeys usingEquality: nilptr] or [OFArrayLINQSupport containsObject: key inArray: resultKeys usingEquality: nilptr])
            continue;
        [resultKeys addObject: key];
        [result addObject: object];
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)exceptWith: (OFArray *)other usingEquality: (bool (^nillable)(id left, id right))equality
{
    auto result = [OFMutableArray array];
    for (id object in self) {
        if (not [OFArrayLINQSupport containsObject: object inArray: other usingEquality: equality])
            [OFArrayLINQSupport addObject: object ifNotContainedIn: result usingEquality: equality];
    }
    return [OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFArray *)skip: (size_t)count
{
    if (count >= self.count)
        return @[];
    return [self objectsInRange: (OFRange){ .location = count, .length = self.count - count }];
}

- (OFArray *)skipLast: (size_t)count
{
    if (count >= self.count)
        return @[];
    return [self objectsInRange: (OFRange){ .location = 0, .length = self.count - count }];
}

- (OFArray *)skipWhile: (bool (^)(id object))predicate
{
    size_t index = 0;
    while (index < self.count and predicate(self[index]))
        index++;
    return [self skip: index];
}

- (OFArray *)take: (size_t)count
{
    count = count < self.count ? count : self.count;
    return [self objectsInRange: (OFRange){ .location = 0, .length = count }];
}

- (OFArray *)takeLast: (size_t)count
{
    count = count < self.count ? count : self.count;
    return [self objectsInRange: (OFRange){ .location = self.count - count, .length = count }];
}

- (OFArray *)takeWhile: (bool (^)(id object))predicate
{
    size_t count = 0;
    while (count < self.count and predicate(self[count]))
        count++;
    return [self take: count];
}

- (OFArray<OFArray *> *)chunk: (size_t)size
{
    if (size == 0)
        @throw [OFInvalidArgumentException exception];

    auto result = [OFMutableArray array];
    for (size_t index = 0; index < self.count; index += size) {
        size_t remaining = self.count - index;
        size_t length = size < remaining ? size : remaining;
        [result addObject: [self objectsInRange: (OFRange){ .location = index, .length = length }]];
    }
    return (OFArray<OFArray *> *)[OFArrayLINQSupport immutableArrayFromMutableArray: result];
}

- (OFSet *)toSet
{ return [OFSet setWithArray: self]; }

- (OFSet *)toHashSet
{ return [self toSet]; }

- (OFDictionary<id, id> *)toDictionaryWithKeySelector: (id nillable (^)(id object))keySelector
{
    return [self toDictionaryWithKeySelector: keySelector elementSelector: ^id(id object) { return object; }];
}

- (OFDictionary<id, id> *)toDictionaryWithKeySelector: (id nillable (^)(id object))keySelector elementSelector: (id (^)(id object))elementSelector
{
    auto result = [OFMutableDictionary dictionary];
    for (id object in self) {
        id key = [OFArrayLINQSupport keyOrNull: keySelector(object)];
        if ([result objectForKey: key] != nilptr)
            @throw [OFInvalidArgumentException exception];
        [result setObject: elementSelector(object) forKey: key];
    }
    [result makeImmutable];
    return result;
}

@end

#pragma clang assume_nonnull end
