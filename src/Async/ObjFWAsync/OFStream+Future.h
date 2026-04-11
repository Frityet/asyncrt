#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFStream (FutureAdditions)

- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer length: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncBufferReadResult *> *)futureReadIntoBuffer: (void *)buffer exactLength: (size_t)length onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<Optional<OFString *> *> *)futureReadStringOnScheduler: (AsyncScheduler *)scheduler;
- (Future<Optional<OFString *> *> *)futureReadStringOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<Optional<OFString *> *> *)futureReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Future<Optional<OFString *> *> *)futureReadStringWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<Optional<OFString *> *> *)futureReadLineOnScheduler: (AsyncScheduler *)scheduler;
- (Future<Optional<OFString *> *> *)futureReadLineOnScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<Optional<OFString *> *> *)futureReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Future<Optional<OFString *> *> *)futureReadLineWithEncoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureWriteData: (OFData *)data onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler;
- (Future<AsyncUnit *> *)futureWriteString: (OFString *)string encoding: (OFStringEncoding)encoding onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
