#include "Utilities/Signal.h"



@implementation Signal

+ (instancetype)withValue: (id)value
{
    return [[self alloc] initWithValue: value];
}

- (instancetype)initWithValue: (id)value
{
    self = [super init];
    _value = value;
    _subscribers = [OFMutableArray array];
    return self;
}

- (id)value
{ return _value; }

- (void)setValue: (id)value
{
    if (_value == value)
        return;
    if (_value != nilptr and [_value isEqual: value])
        return;
    _value = value;
    for (void (^subscriber)(id) in _subscribers)
        subscriber(value);
}

- (void)subscribe: (void (^)(id))subscriber
{
    [_subscribers addObject: subscriber];
}

@end

@implementation Computed

+ (instancetype)withBlock: (id (^)(void))computeBlock
{ return [[self alloc] initWithBlock: computeBlock]; }

- (instancetype)initWithBlock: (id (^)(void))computeBlock 
{
    self = [super init];
    _computeBlock = computeBlock;
    _cached = nilptr;
    return self;
}

- (void)compute
{
    _cached = _computeBlock();
}

- (id)value
{
    [self compute];
    return _cached;
}

@end
