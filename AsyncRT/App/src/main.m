#import "CalculatorComponents.h"
#import "Coroutine.h"
#import "AUI.h"

#pragma clang assume_nonnull begin

static Coroutine<OFNumber *> *fibonacci(long base)
{
    return [Coroutine withBlock: ^(Coroutine<OFNumber *> *co) {
        long a = 0, b = 1;

        for (long i = 0; i < base; i++) {
            [co yield: @(a)];
            long next = a + b;
            a = b;
            b = next;
        }

        [co return];
        return nilptr;
    }];
}

[[subclassing_restricted]]
@interface App : AUIApplication @end

static bool is_tagged(id obj)
{
    auto ptr = (uintptr_t)obj;

    return (ptr & 1) == 1;
}

@implementation App

- (AUIViewComponent *)makeRootViewComponent
{
    return [[CalculatorRootComponent alloc] init];
}

- (AUIWindowOptions *)windowOptions
{
    return [AUIWindowOptions title: @"Scientific Calculator"
                              size: [AUI sizeWithWidth: 1360 height: 820]
                         resizable: true
         autoResizeToRootComponent: true
               scaleWithWindowSize: true
                      contentScale: 0.75];
}

- (id)applicationDidFinishLaunchingAsync:(OFNotification *)notification taskGroup:(AsyncTaskGroup *)taskGroup
{
    for (OFNumber *num in fibonacci(10)) {
        OFLog(@"%@ is tagged?: %@ (ptr: %p)", num, @(is_tagged(num)), num);
    }
    return [super applicationDidFinishLaunchingAsync: notification taskGroup: taskGroup];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
