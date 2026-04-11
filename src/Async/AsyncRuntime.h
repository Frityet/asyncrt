#pragma once

#import "Async/Awaitable.h"
#import "Async/AsyncUnit.h"
#import "Async/Promise.h"
#import "Async/AsyncScheduler.h"
#import "Async/AsyncScope.h"
#import "Async/AsyncChannel.h"
#import "Async/Task.h"
#import "Async/AsyncApplication.h"
#import "Async/ObjFWAsync/ObjFWAsync.h"

#pragma clang assume_nonnull begin

@class AsyncRuntime;
@class AsyncScope;
@class AsyncScheduler;
@class Task;

@interface AsyncRuntime : OFObject

+ (Task<id> *)run: (id (^)(AsyncScope *scope))block;
+ (Task<id> *)runOnScheduler: (AsyncScheduler *)scheduler block: (id (^)(AsyncScope *scope))block;

@end

#pragma clang assume_nonnull end
