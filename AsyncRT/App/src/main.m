#import "CalculatorComponents.h"
#import "Coroutine.h"
#import "AUI.h"

#pragma clang assume_nonnull begin

static Coroutine<OFNumber *> *fibonacci(long base)
{
    return [Coroutine withBlock: ^id(Coroutine<OFNumber *> *co) {
        long a = 0, b = 1;

        for (long i = 0; i < base; i++) {
            [co yield: @(a)];
            long next = a + b;
            a = b;
            b = next;
        }

        [co return];
    }];
}

[[subclassing_restricted]]
@interface App : AUIApplication @end

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
         autoResizeToRootComponent: false
               scaleWithWindowSize: true
                      contentScale: 1];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
