#include "Utilities/common.h"

@implementation NamespaceClass

+ (Class)self { return self; }
+ (Class)class { return self; }

@end

@implementation OFMutex(ScopedLock)

- (void)scopedLock: (void (^)(void)) [[clang::noescape]] block
{
    [self lock];
    @try {
        block();
    } 
    @finally {
        [self unlock];
    }
}

@end

void async_link_scoped_lock_support(void) {}
