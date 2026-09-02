#include <Common.h>

@implementation NamespaceClass

+ (Class)self { return self; }
+ (Class)class { return self; }

@end

@implementation NilReferenceException

- (instancetype)initWithExpression: (OFString *)expression
{
    self = [super init];
    _expression = expression;
    return self;
}

-(OFString *)description
{
    return [OFString stringWithFormat: @"Nil reference for expression: %@", _expression];
}

@end

@implementation CastFailureException

- (instancetype)initWithCastFrom:(Class)from to:(Class)to
{
    self = [super init];
    _from = from;
    _to = to;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"Cast failure from %@ to %@", _from, _to];
}

@end

