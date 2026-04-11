#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncScope;
@class Task<T>;

@interface AsyncApplication : OFObject<OFApplicationDelegate>

@property(readonly, nonatomic) AsyncScheduler *nillable scheduler;
@property(readonly, nonatomic) Task<id> *nillable launchTask;

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                                   scope: (AsyncScope *)scope;
- (void)asyncApplicationDidFinishWithValue: (id)value;
- (void)asyncApplicationDidFailWithException: (OFException *)exception;
- (void)asyncApplicationWillTerminate: (OFNotification *)notification;
- (int)applicationExitStatusForValue: (id)value;
- (int)applicationExitStatusForException: (OFException *)exception;

@end

#define ASYNC_APPLICATION_DELEGATE(class_) OF_APPLICATION_DELEGATE(class_)

#pragma clang assume_nonnull end
