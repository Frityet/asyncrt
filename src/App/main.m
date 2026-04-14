#import "CalculatorComponents.h"
#import "UI/AUI.h"

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
    auto exec = $assert_nonnil(OFApplication.executableIRI);
    auto f = [exec;
    return [AUIWindowOptions title: @"Scientific Calculator"
                              size: [AUI sizeWithWidth: 1360 height: 820]
                         resizable: true
         autoResizeToRootComponent: false];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
