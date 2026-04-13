#pragma once

#import "Async/Awaitable.h"
#import "Async/AsyncUnit.h"
#import "Async/AsyncCompletionSource.h"
#import "Async/AsyncScheduler.h"
#import "Async/AsyncTaskGroup.h"
#import "Async/AsyncChannel.h"
#import "Async/Task.h"
#import "Async/AsyncApplication.h"

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
