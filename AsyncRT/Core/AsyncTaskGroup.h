#pragma once

#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@class AsyncTaskGroup;
@class AsyncScheduler;

[[subclassing_restricted, direct_members]]
@interface AsyncTaskGroupTimeoutException : OFException

@property(readonly, nonatomic) AsyncTaskGroup *nillable taskGroup;
@property(readonly, nonatomic) OFDate *deadline;

- (instancetype)initWithTaskGroup: (AsyncTaskGroup *)taskGroup deadline: (OFDate *)deadline [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncTaskGroup : OFObject

@property(class, readonly, nonatomic) AsyncTaskGroup *nillable currentTaskGroup;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncTaskGroup *nillable parentTaskGroup;
@property(readonly, nonatomic) AsyncTask *ownerTask;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) OFDate *nillable deadline;
@property(readonly, nonatomic) bool isCancellationRequested;

+ (AsyncTaskGroup *nillable)currentTaskGroup [[direct]];
- (AsyncTask<id> *)spawnTask: (id (^)(void))block [[direct]];
- (AsyncTask<id> *)spawnTask: (id (^)(void))block name: (OFString *nillable)name [[direct]];
- (AsyncTask<id> *)spawnTaskInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block [[direct]];
- (AsyncTask<id> *)spawnTaskInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block name: (OFString *nillable)name [[direct]];
- (AsyncTask<OFArray<id> *> *)spawnAllTasks: (OFArray<id (^)(void)> *)blocks [[direct]];
- (AsyncTask<OFArray<id> *> *)spawnAllTasks: (OFArray<id (^)(void)> *)blocks name: (OFString *nillable)name [[direct]];

- (id)performInChildTaskGroup: (id (^)(AsyncTaskGroup *taskGroup))block [[direct]];
- (id)performInChildTaskGroupNamed: (OFString *nillable)name block: (id (^)(AsyncTaskGroup *taskGroup))block [[direct]];
- (id)performWithTimeout: (OFTimeInterval)timeout block: (id (^)(AsyncTaskGroup *taskGroup))block [[direct]];
- (id)performWithDeadline: (OFDate *)deadline block: (id (^)(AsyncTaskGroup *taskGroup))block [[direct]];
- (void)cancel [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
