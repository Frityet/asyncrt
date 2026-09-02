#import <objc/objc.h>

#include <stddef.h>

@interface OFConstantString
@end

/*
 * This image intentionally does not link ObjFW. Its constant strings resolve
 * against the host process, matching an AsyncRT plugin loaded with dlopen.
 */
__attribute__((visibility("default")))
size_t
AsyncRTConstantStringImageLiteralCount(void)
{
    return 8;
}

__attribute__((visibility("default")))
id
AsyncRTConstantStringImageLiteralAtIndex(size_t index)
{
    static id const literals[] = {
        @"async-rt-plugin-constant-00", @"async-rt-plugin-constant-01",
        @"async-rt-plugin-constant-02", @"async-rt-plugin-constant-03",
        @"async-rt-plugin-constant-04", @"async-rt-plugin-constant-05",
        @"async-rt-plugin-constant-06", @"async-rt-plugin-constant-07"
    };

    if (index >= sizeof(literals) / sizeof(*literals))
        return nullptr;
    return literals[index];
}
