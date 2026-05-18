#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncTaskGroup;
@class AsyncTask<T>;

@interface AsyncApplication : OFObject<OFApplicationDelegate>

@property(readonly, nonatomic) AsyncScheduler *nillable scheduler;
@property(readonly, nonatomic) AsyncTask<id> *nillable launchTask;
@property(readonly, nonatomic) bool shouldTerminateAfterLaunchTaskCompletes;

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup;
- (void)asyncApplicationDidFailWithException: (OFException *)exception;
- (void)asyncApplicationWillTerminate: (OFNotification *)notification;
- (int)applicationExitStatusForValue: (id)value;
- (int)applicationExitStatusForException: (OFException *)exception;

@end

#pragma clang assume_nonnull end
