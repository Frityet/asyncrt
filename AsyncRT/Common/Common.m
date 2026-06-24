#include "Common.h"

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

@end

