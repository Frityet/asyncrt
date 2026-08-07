#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

extern int AsyncIOOFStreamAnchor;
static int *const ASYNCIO_OFSTREAM_ANCHOR_REFERENCE __attribute__((used)) = &AsyncIOOFStreamAnchor;

@interface OFStream(AsyncIO)

- (AsyncTask<OFData *> *)taskToReadAtMostLength: (size_t)length;
- (AsyncTask<OFData *> *)taskToReadUntilEnd;
- (AsyncTask<OFString *> *)taskToReadString;
- (AsyncTask<OFString *> *)taskToReadStringWithEncoding: (OFStringEncoding)encoding;
- (AsyncTask<OFNumber *> *)taskToWriteData: (OFData *)data;
- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string;
- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding;

@end

#pragma clang assume_nonnull end
