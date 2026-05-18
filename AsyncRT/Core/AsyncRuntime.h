#pragma once

#import <AsyncRT/Core/AsyncUnit.h>
#import <AsyncRT/Core/AsyncCompletionSource.h>
#import <AsyncRT/Core/AsyncScheduler.h>
#import <AsyncRT/Core/AsyncTaskGroup.h>
#import <AsyncRT/Core/AsyncChannel.h>
#import <AsyncRT/Core/AsyncStreamTasks.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@class AsyncRuntime;
@class AsyncTaskGroup;
@class AsyncScheduler;
@class AsyncTask;

[[subclassing_restricted, direct_members]]
@interface AsyncRuntime : OFObject

+ (AsyncTask<id> *)run: (id (^)(AsyncTaskGroup *taskGroup))block;
+ (AsyncTask<id> *)runOnScheduler: (AsyncScheduler *)scheduler block: (id (^)(AsyncTaskGroup *taskGroup))block;

@end

#pragma clang assume_nonnull end
