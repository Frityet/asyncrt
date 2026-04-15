#import "CalculatorComponents.h"
#import "AUI.h"

#pragma clang assume_nonnull begin

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
