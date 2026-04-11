#include <stdio.h>
#include <stdlib.h>
#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@interface OFApplication(AppTerm)

+ (void)scheduleApplicationTerminationWithStatus: (int)status;

@end

@implementation OFApplication(AppTerm)

+ (void)scheduleApplicationTerminationWithStatus: (int)status
{
    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: 0 repeats: false block: ^(OFTimer *unusedTimer) {
        (void)unusedTimer;

        if (status == 0)
            [self terminate];
        else
            [self terminateWithStatus: status];
    }];

    [OFRunLoop.currentRunLoop addTimer: timer forMode: OFDefaultRunLoopMode];
}

@end



@interface App : OFObject<OFApplicationDelegate> @end

@implementation App

- (void)applicationDidFinishLaunching:_
{
    OFLog(@"Hello, World!");

    [OFApplication scheduleApplicationTerminationWithStatus: 0];
}

- (void)applicationWillTerminate:_
{
    OFLog(@"Shutting off default scheduler for current thread...");
    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(App);
