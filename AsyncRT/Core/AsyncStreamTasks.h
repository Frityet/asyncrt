#pragma once

#import <AsyncRT/Core/AsyncUnit.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@class AsyncScheduler;

void AsyncRTLinkAsyncStreamTasks(void);

@interface OFStream (AsyncStreamTasks)

- (AsyncTask<OFData *> *)taskToReadAtMost: (size_t)length
                          onScheduler: (AsyncScheduler *)scheduler;
- (AsyncTask<OFData *> *)taskToReadUntilEndWithMaximumLength: (size_t)maximumLength
                                            onScheduler: (AsyncScheduler *)scheduler;
- (AsyncTask<AsyncUnit *> *)taskToWriteData: (OFData *)data
                            onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
