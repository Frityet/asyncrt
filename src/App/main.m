#import "UI/AUI.h"
#import "Utilities/Signal.h"

#pragma clang assume_nonnull begin

@interface AppRootComponent : AUIComponent
@end

@implementation AppRootComponent {
    
}

+ (AUIColor)foregroundColor
{
    AUIRenderContext *nillable context = AUIRenderContext.currentContext;

    if (context != nilptr and context.window.isDarkMode)
        return [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255];

    return [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 255];
}

+ (AUITextStyle)heroTitleStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 32;
    style.color = self.foregroundColor;
    return style;
}

+ (AUITextStyle)bodyTextStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 18;
    style.color = self.foregroundColor;
    return style;
}

+ (AUITextStyle)metricTextStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 28;
    style.color = self.foregroundColor;
    return style;
}


- (id<AUIRenderable>)body
{
    return [AUIVStack gap: 10 children: @[
        [AUIText string: @"Hello, World!" style: self.class.heroTitleStyle]
    ]];
}

@end

[[subclassing_restricted]]
@interface App : AUIApplication @end

@implementation App

- (AUIComponent *)makeRootComponent
{
    return [[AppRootComponent alloc] init];
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                                   scope: (AsyncScope *)scope
{
    OFLog(@"Launching app!");

    return [super applicationDidFinishLaunchingAsync: notification scope: scope];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
