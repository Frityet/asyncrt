#pragma once

#import "Async/Future.h"
#import "Async/Task.h"
#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;
@class AsyncUnit;
@class AsyncTaskSnapshot;
@class AsyncSchedulerSnapshot;

@interface AsyncSchedulerException : OFException {
@private
    unretained AsyncScheduler *nillable _scheduler;
}

@property(readonly, nonatomic) AsyncScheduler *nillable scheduler;

 - (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncSchedulerInvalidInitializationException : AsyncSchedulerException {
@private
    OFString *_reason;
}

@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncSchedulerUnsupportedYieldException : AsyncSchedulerException {
@private
    unretained Task *nillable _task;
    id nillable _yieldedObject;
}

@property(readonly, nonatomic) Task *nillable task;
@property(readonly, nonatomic) id nillable yieldedObject;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task yieldedObject: (id nillable)yieldedObject OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *nillable)scheduler OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncTaskSnapshot : OFObject {
@private
    uint64_t _taskID;
    OFString *nillable _name;
    enum AsyncTaskExecutionState _executionState;
    OFString *nillable _waitReason;
    bool _cancellationRequested;
    OFString *nillable _scopeName;
}

@property(readonly, nonatomic) uint64_t taskID;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) enum AsyncTaskExecutionState executionState;
@property(readonly, nonatomic) OFString *nillable waitReason;
@property(readonly, nonatomic, getter=isCancellationRequested) bool cancellationRequested;
@property(readonly, nonatomic) OFString *nillable scopeName;

- (instancetype)initWithTaskID: (uint64_t)taskID name: (OFString *nillable)name executionState: (enum AsyncTaskExecutionState)executionState waitReason: (OFString *nillable)waitReason cancellationRequested: (bool)cancellationRequested scopeName: (OFString *nillable)scopeName OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncSchedulerSnapshot : OFObject {
@private
    size_t _queuedTaskCount;
    size_t _runningTaskCount;
    uint64_t _completedTaskCount;
    uint64_t _cancelledTaskCount;
    OFArray<AsyncTaskSnapshot *> *_tasks;
}

@property(readonly, nonatomic) size_t queuedTaskCount;
@property(readonly, nonatomic) size_t runningTaskCount;
@property(readonly, nonatomic) uint64_t completedTaskCount;
@property(readonly, nonatomic) uint64_t cancelledTaskCount;
@property(readonly, nonatomic) OFArray<AsyncTaskSnapshot *> *tasks;

- (instancetype)initWithQueuedTaskCount: (size_t)queuedTaskCount runningTaskCount: (size_t)runningTaskCount completedTaskCount: (uint64_t)completedTaskCount cancelledTaskCount: (uint64_t)cancelledTaskCount tasks: (OFArray<AsyncTaskSnapshot *> *)tasks OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncScheduler : OFObject

@property(class, readonly, nonatomic) AsyncScheduler *defaultScheduler;
@property(readonly, nonatomic) OFRunLoop *runLoop;
@property(readonly, nonatomic) OFRunLoopMode mode;
@property(readonly, nonatomic) size_t maxWorkerCount;
@property(readonly, nonatomic) size_t maxDrainBatchSize;

+ (AsyncScheduler *)defaultScheduler;
+ (void)shutdownDefaultSchedulerForCurrentThread;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode maxWorkerCount: (size_t)maxWorkerCount maxDrainBatchSize: (size_t)maxDrainBatchSize OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop mode: (OFRunLoopMode)mode;
- (instancetype)initWithRunLoop: (OFRunLoop *)runLoop;
- (Future<AsyncUnit *> *)sleepForTimeInterval: (OFTimeInterval)timeInterval;
- (Future<AsyncUnit *> *)sleepUntilDate: (OFDate *)date;
- (Future<id> *)offload: (id (^)(void))block;
- (AsyncSchedulerSnapshot *)snapshot;
- (void)shutdown;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
