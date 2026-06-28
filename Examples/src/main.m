#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/Coroutine.h>

#pragma clang assume_nonnull begin

@interface Example : OFObject<OFApplicationDelegate>

@end

@implementation Example

- (Coroutine<OFNumber *> *)rangeFrom: (unsigned int)start to: (unsigned int)end
{
    return [Coroutine fromBlock: ^(unretained Coroutine *co) {
        for (unsigned int i = start; i < end; i++)
            [co yield: @(i)];

        return nilptr;
    }];
}
 
- (void)applicationDidFinishLaunching:_
{
    for (OFNumber *n in [self rangeFrom: 0 to: 10])
        OFLog(@"%d", n.intValue);
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(Example)
