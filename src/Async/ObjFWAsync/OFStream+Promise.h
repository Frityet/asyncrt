#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFStream (PromiseAdditions)

- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncBufferReadResult *> *)promiseToReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<Optional<OFString *> *> *)promiseToReadStringOnScheduler: (AsyncScheduler *)scheduler;
- (Promise<Optional<OFString *> *> *)promiseToReadStringOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<Optional<OFString *> *> *)promiseToReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Promise<Optional<OFString *> *> *)promiseToReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<Optional<OFString *> *> *)promiseToReadLineOnScheduler: (AsyncScheduler *)scheduler;
- (Promise<Optional<OFString *> *> *)promiseToReadLineOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<Optional<OFString *> *> *)promiseToReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Promise<Optional<OFString *> *> *)promiseToReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Promise<AsyncUnit *> *)promiseToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
