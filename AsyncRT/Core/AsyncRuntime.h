#pragma once

#import <AsyncRT/Core/AsyncUnit.h>
#import <AsyncRT/Core/AsyncCompletionSource.h>
#import <AsyncRT/Core/AsyncScheduler.h>
#import <AsyncRT/Core/AsyncChannel.h>
#import <AsyncRT/Core/AsyncStreamTasks.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@class AsyncRuntime;
@class AsyncScheduler;
@class AsyncTask;

[[subclassing_restricted, direct_members]]
@interface AsyncRuntime : OFObject

+ (AsyncTask<id> *)run: (id (^)(void))block;
+ (AsyncTask<id> *)spawn: (id (^)(void))block;
+ (AsyncTask<id> *)spawnNamed: (OFString *nillable)name block: (id (^)(void))block;
+ (AsyncTask<AsyncUnit *> *)sleepForTimeInterval: (OFTimeInterval)timeInterval;
+ (AsyncTask<AsyncUnit *> *)sleepUntilDate: (OFDate *)date;
+ (AsyncTask<id> *)offload: (id (^)(void))block;
+ (void)runUntilTaskCompletes: (AsyncTask *)task;
+ (bool)runUntilTaskCompletes: (AsyncTask *)task timeout: (OFTimeInterval)timeout;
+ (void)runUntilIdle;
+ (AsyncSchedulerSnapshot *)snapshot;
+ (void)shutdown;

@end

#pragma clang assume_nonnull end
