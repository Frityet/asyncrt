#import <AsyncRT/Core/AsyncRuntime.h>
#import <AsyncRT/Application/Core/Application.h>

#pragma clang assume_nonnull begin

@namespace(AsyncApplicationExceptionLogging)

+ (void)logException: (OFException *)exception;

@end

@namespace_implementation(AsyncApplicationExceptionLogging)

+ (void)logException: (OFException *)exception
{
    OFArray<OFString *> *nillable stackTraceSymbols = exception.stackTraceSymbols;

    OFLog(@"Unhandled exception: %@", exception.className);
    OFLog(@"%@", exception.description);

    if (stackTraceSymbols == nilptr or $assert_nonnil(stackTraceSymbols).count == 0)
        return;

    OFLog(@"Stack trace:");
    for (OFString *symbol in $assert_nonnil(stackTraceSymbols))
        OFLog(@"  %@", symbol);
}

@end

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

    auto launchTask = [AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *rootTaskGroup) {
        return [self applicationDidFinishLaunchingAsync: notification taskGroup: rootTaskGroup];
    }];
    _launchTask = launchTask;

    (void)[AsyncRuntime runOnScheduler: scheduler block: ^id(AsyncTaskGroup *) {
        @try {
            id value = launchTask.await;

            [self asyncApplicationDidFinishWithValue: value];
            if (self.shouldTerminateAfterLaunchTaskCompletes)
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
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;
    (void)taskGroup;
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (bool)shouldTerminateAfterLaunchTaskCompletes
{
    return true;
}

- (void)asyncApplicationDidFinishWithValue: (id)value
{
    (void)value;
}

- (void)asyncApplicationDidFailWithException: (OFException *)exception
{
    [AsyncApplicationExceptionLogging logException: exception];
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
