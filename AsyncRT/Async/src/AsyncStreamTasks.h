#pragma once

#import "AsyncUnit.h"
#import "Task.h"

#pragma clang assume_nonnull begin

@class AsyncScheduler;

void AsyncRTLinkAsyncStreamTasks(void);

@interface OFStream (AsyncStreamTasks)

- (Task<OFData *> *)taskToReadAtMost: (size_t)length
                          onScheduler: (AsyncScheduler *)scheduler;
- (Task<OFData *> *)taskToReadUntilEndWithMaximumLength: (size_t)maximumLength
                                            onScheduler: (AsyncScheduler *)scheduler;
- (Task<AsyncUnit *> *)taskToWriteData: (OFData *)data
                            onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
