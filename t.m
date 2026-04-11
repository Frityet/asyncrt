#include <stdint.h>
#include <stdio.h>

void __objc_exec_class(void *_) {}

[[clang::objc_root_class, clang::objc_direct_members]]
@interface Person {
    const char *_name;
    int _age;
}
+ (instancetype)allocTo: (void *)ptr;
- (instancetype)initWithName:(const char *)name age:(int)age;
- (void)printTo:(FILE *)f;
@end

@implementation Person

+ (instancetype)allocTo: (void *)ptr
{ return ptr; }

- (id)initWithName:(const char *)name age:(int)age
{
    _name = name;
    _age = age;
    return self;
}

- (void)printTo:(FILE *)f
{
    fprintf(f, "%s %d\n", _name, _age);
}

@end

int main(void)
{
    uint8_t storage[8 + 4];
    Person *p = [[Person allocTo: storage] initWithName:"Amrit" age:19];
    [p printTo:stdout];
}
