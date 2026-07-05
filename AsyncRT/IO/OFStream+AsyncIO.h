#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@interface OFStream(AsyncIO)

- (AsyncTask<OFData *> *)taskToReadAtMostLength: (size_t)length;
- (AsyncTask<OFData *> *)taskToReadUntilEnd;
- (AsyncTask<OFNumber *> *)taskToWriteData: (OFData *)data;
- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string;
- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding;

@end

#pragma clang assume_nonnull end
