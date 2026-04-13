#include "Utilities/common.h"

@implementation NamespaceClass

+ (Class)self { return self; }
+ (Class)class { return self; }

@end

@implementation TaggedPointer

+ (uintptr_t)registerClass: (Class)c
{
    return 0;
}

+ (id)createWithTag: (uintptr_t)tag payload: (id)payload
{
    return nilptr;
}

@end
