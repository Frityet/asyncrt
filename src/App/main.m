#import "CalculatorComponents.h"
#import "UI/AUI.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface App : AUIApplication @end

@implementation App

- (AUIViewComponent *)makeRootViewComponent
{
    return [[AsyncRTCalculatorRootComponent alloc] init];
}

- (AUIWindowOptions *)windowOptions
{
    return [AUIWindowOptions title: @"AsyncRT Scientific Calculator"
                              size: [AUI sizeWithWidth: 1360 height: 820]
                         resizable: true
           autoResizeToRootComponent: false];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
