#pragma once

#import <AsyncRT/Core/AsyncUnit.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

void AsyncRTLinkAsyncStreamTasks(void);

@interface OFStream (AsyncStreamTasks)

- (AsyncTask<OFData *> *)taskToReadAtMost: (size_t)length;
- (AsyncTask<OFData *> *)taskToReadUntilEndWithMaximumLength: (size_t)maximumLength;
- (AsyncTask<AsyncUnit *> *)taskToWriteData: (OFData *)data;

@end

#pragma clang assume_nonnull end
