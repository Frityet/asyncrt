#import "Async/AsyncRuntime.h"
#import "Async/AsyncApplication.h"

#pragma clang assume_nonnull begin

@interface OFApplication(AsyncApplicationDelegateSupport)

+ (void)async_scheduleTerminationWithStatus: (int)status;

@end

@implementation OFApplication(AsyncApplicationDelegateSupport)

+ (void)async_scheduleTerminationWithStatus: (int)status
{
    auto timer = [[OFTimer alloc] initWithFireDate: OFDate.date interval: 0 repeats: false block: ^(OFTimer *) {
        if (status == 0)
            [self terminate];
        else
            [self terminateWithStatus: status];
    }];

    [OFRunLoop.currentRunLoop addTimer: timer forMode: OFDefaultRunLoopMode];
}

@end

@implementation AsyncApplication


- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
    _scheduler = AsyncScheduler.defaultScheduler;
    auto scheduler = $assert_nonnil(_scheduler);

    auto launchTask = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncScope *rootScope) {
        return [self applicationDidFinishLaunchingAsync: notification scope: rootScope];
    }];
    _launchTask = launchTask;

    (void)[AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncScope *) {
        @try {
            id value = launchTask.await;

            [self asyncApplicationDidFinishWithValue: value];
            [OFApplication async_scheduleTerminationWithStatus: [self applicationExitStatusForValue: value]];
        } @catch (OFException *exception) {
            [self asyncApplicationDidFailWithException: exception];
            [OFApplication async_scheduleTerminationWithStatus: [self applicationExitStatusForException: exception]];
        }

        return AsyncUnit.unit;
    }];
}

- (void)applicationWillTerminate: (OFNotification *)notification
{
    [self asyncApplicationWillTerminate: notification];
    [AsyncScheduler shutdownDefaultSchedulerForCurrentThread];
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                                   scope: (AsyncScope *)scope
{
    (void)notification;
    (void)scope;
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)asyncApplicationDidFinishWithValue: (id)value
{
    (void)value;
}

- (void)asyncApplicationDidFailWithException: (OFException *)exception
{
    OFLog(@"%@", exception);
}

- (void)asyncApplicationWillTerminate: (OFNotification *)notification
{
    (void)notification;
}

- (int)applicationExitStatusForValue: (id)value
{
    if ([value isKindOfClass: OFNumber.class])
        return ((OFNumber *)value).intValue;

    return 0;
}

- (int)applicationExitStatusForException: (OFException *)exception
{
    (void)exception;
    return 1;
}

@end

#pragma clang assume_nonnull end
