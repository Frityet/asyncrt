#pragma once

#import "AsyncUnit.h"
#import "AsyncCompletionSource.h"
#import "AsyncScheduler.h"
#import "AsyncTaskGroup.h"
#import "AsyncChannel.h"
#import "Task.h"
#import "AsyncApplication.h"

#pragma clang assume_nonnull begin

@class AsyncRuntime;
@class AsyncTaskGroup;
@class AsyncScheduler;
@class Task;

[[subclassing_restricted, direct_members]]
@interface AsyncRuntime : OFObject

+ (Task<id> *)run: (id (^)(AsyncTaskGroup *taskGroup))block;
+ (Task<id> *)runOnScheduler: (AsyncScheduler *)scheduler block: (id (^)(AsyncTaskGroup *taskGroup))block;

@end

#pragma clang assume_nonnull end
