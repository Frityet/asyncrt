#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncTaskGroup;
@class Task<T>;

@interface AsyncApplication : OFObject<OFApplicationDelegate>

@property(readonly, nonatomic) AsyncScheduler *nillable scheduler;
@property(readonly, nonatomic) Task<id> *nillable launchTask;

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup;
- (void)asyncApplicationDidFailWithException: (OFException *)exception;
- (void)asyncApplicationWillTerminate: (OFNotification *)notification;
- (int)applicationExitStatusForValue: (id)value;
- (int)applicationExitStatusForException: (OFException *)exception;

@end

#define ASYNC_APPLICATION_DELEGATE(class_) OF_APPLICATION_DELEGATE(class_)

#pragma clang assume_nonnull end
