#import <AsyncRT/Application/UI/Application.h>

#pragma clang assume_nonnull begin

@implementation AsyncUIApplication

- (AsyncUIWindowConfiguration *)windowConfiguration
{
    return AsyncUIWindowConfiguration.defaults;
}

- (void)applicationDidStart
{}

- (void)setNeedsRender
{
}

@end

#pragma clang assume_nonnull end
