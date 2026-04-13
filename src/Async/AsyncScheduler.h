#pragma once

#import "Async/Promise.h"
#import "Async/Task.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncUnit;
@class AsyncTaskSnapshot;
@class AsyncSchedulerSnapshot;

@interface AsyncSchedulerException : OFException

@property(readonly, nonatomic) AsyncScheduler *nillable scheduler;

 - (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncSchedulerInvalidInitializationException : AsyncSchedulerException

@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncSchedulerUnsupportedYieldException : AsyncSchedulerException

@property(readonly, nonatomic) Task *nillable task;
@property(readonly, nonatomic) id nillable yieldedObject;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task yieldedObject: (id nillable)yieldedObject [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskSnapshot : OFObject

@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic) bool isCancellationRequested;
@property(readonly, nonatomic) OFString *nillable scopeName;

- (instancetype)initWithTaskID: (uint64_t)taskID name: (OFString *nillable)name executionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason cancellationRequested: (bool)cancellationRequested scopeName: (OFString *nillable)scopeName [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncSchedulerSnapshot : OFObject

@property(readonly, nonatomic) size_t queuedTaskCount;
@property(readonly, nonatomic) size_t runningTaskCount;
@property(readonly, nonatomic) uint64_t completedTaskCount;
@property(readonly, nonatomic) uint64_t cancelledTaskCount;
@property(readonly, nonatomic) OFArray<AsyncTaskSnapshot *> *tasks;

- (instancetype)initWithQueuedTaskCount: (size_t)queuedTaskCount runningTaskCount: (size_t)runningTaskCount completedTaskCount: (uint64_t)completedTaskCount cancelledTaskCount: (uint64_t)cancelledTaskCount tasks: (OFArray<AsyncTaskSnapshot *> *)tasks [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncScheduler : OFObject

@property(class, readonly, nonatomic) AsyncScheduler *defaultScheduler;
@property(readonly, nonatomic) OFRunLoop *runLoop;
@property(readonly, nonatomic) OFRunLoopMode mode;
@property(readonly, nonatomic) size_t maxWorkerCount;
@property(readonly, nonatomic) size_t maxDrainBatchSize;

+ (AsyncScheduler *)defaultScheduler;
+ (void)shutdownDefaultSchedulerForCurrentThread;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode maxWorkerCount: (size_t)maxWorkerCount maxDrainBatchSize: (size_t)maxDrainBatchSize [[designated_initailiser]];
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop;
- (OFString *)describe;
- (Promise<AsyncUnit *> *)sleepForTimeInterval: (OFTimeInterval)timeInterval;
- (Promise<AsyncUnit *> *)sleepUntilDate: (OFDate *)date;
- (Promise<id> *)offload: (id (^)(void))block;
- (AsyncSchedulerSnapshot *)snapshot;
- (void)shutdown;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
