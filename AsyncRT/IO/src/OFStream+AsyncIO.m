#import <OFStream+AsyncIO.h>

#pragma clang assume_nonnull begin

int AsyncIOOFStreamAnchor = 0;

constexpr size_t DEFAULT_READ_BUFFER_LEN = 64 * 1024;

@interface OFStream(AsyncIOPrivate)

- (OFException *)_asyncRTExceptionFromObject: (id nillable)exception;

@end

@implementation OFStream(AsyncIO)

- (AsyncTask<OFData *> *)taskToReadAtMostLength: (size_t)length
{
    if (length == 0)
        @throw [OFInvalidArgumentException exception];

    auto source = [[AsyncTaskCompletionSource<OFData *> alloc] init];
    auto buffer = [OFMutableData dataWithCapacity: length];
    [buffer increaseCountBy: length];
    OFData *retainedBuffer = buffer;
    void *nillable mutableItems = buffer.mutableItems;
    if (mutableItems == nullptr)
        @throw [OFOutOfMemoryException exception];
    void *readTarget = (void *nonnil)mutableItems;

    @try {
        [self asyncReadIntoBuffer: readTarget length: length handler: ^bool(OFStream *, void *readBuffer, size_t bytesRead, id nillable exception) {
            if (exception != nilptr) {
                [source rejectWithError: [self _asyncRTExceptionFromObject: exception]];
                return false;
            }

            if (retainedBuffer.count == 0)
                return false;

            [source resolveWithResult: [OFData dataWithItems: readBuffer count: bytesRead]];
            return false;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (AsyncTask<OFData *> *)taskToReadUntilEnd
{
    auto source = [[AsyncTaskCompletionSource<OFData *> alloc] init];
    auto buffer = [OFMutableData dataWithCapacity: DEFAULT_READ_BUFFER_LEN];
    auto body = [OFMutableData data];
    [buffer increaseCountBy: DEFAULT_READ_BUFFER_LEN];
    OFData *retainedBuffer = buffer;
    void *nillable mutableItems = buffer.mutableItems;
    if (mutableItems == NULL)
        @throw [OFOutOfMemoryException exception];
    void *readTarget = (void *nonnil)mutableItems;

    @try {
        [self asyncReadIntoBuffer: readTarget length: DEFAULT_READ_BUFFER_LEN handler: ^bool(OFStream *stream, void *readBuffer, size_t bytesRead, id nillable exception) {
            if (exception != nilptr) {
                [source rejectWithError: [self _asyncRTExceptionFromObject: exception]];
                return false;
            }

            if (retainedBuffer.count == 0)
                return false;

            if (bytesRead > 0)
                [body addItems: readBuffer count: bytesRead];

            if (not stream.atEndOfStream)
                return true;

            [body makeImmutable];
            [source resolveWithResult: body];
            return false;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (AsyncTask<OFString *> *)taskToReadString
{
    return [self taskToReadStringWithEncoding: self.encoding];
}

- (AsyncTask<OFString *> *)taskToReadStringWithEncoding: (OFStringEncoding)encoding
{
    if ([self isKindOfClass: OFFile.class])
        return [AsyncTask<OFString *> spawn: ^OFString *{
            return [self readStringWithEncoding: encoding];
        }];

    auto source = [[AsyncTaskCompletionSource<OFString *> alloc] init];

    @try {
        [self asyncReadStringWithEncoding: encoding handler: ^bool(OFStream *, OFString *nillable string, id nillable exception) {
            if (exception != nilptr)
                [source rejectWithError: [self _asyncRTExceptionFromObject: exception]];
            else
                [source resolveWithResult: string];

            return false;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (AsyncTask<OFNumber *> *)taskToWriteData: (OFData *)data
{
    auto source = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];

    @try {
        [self asyncWriteData: data handler: ^OFData *nillable(OFStream *, OFData *, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr)
                [source rejectWithError: [self _asyncRTExceptionFromObject: exception]];
            else
                [source resolveWithResult: @(bytesWritten)];
            return nilptr;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string
{
    return [self taskToWriteString: string encoding: OFStringEncodingUTF8];
}

- (AsyncTask<OFNumber *> *)taskToWriteString: (OFString *)string encoding: (OFStringEncoding)encoding
{
    if ([self isKindOfClass: OFFile.class])
        return [AsyncTask<OFNumber *> spawn: ^OFNumber *{
            [self writeString: string encoding: encoding];
            auto data = [string dataWithEncoding: encoding];
            return @(data.count * data.itemSize);
        }];

    auto source = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];

    @try {
        [self asyncWriteString: string encoding: encoding handler: ^OFString *nillable(OFStream *, OFString *, OFStringEncoding, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr)
                [source rejectWithError: [self _asyncRTExceptionFromObject: exception]];
            else
                [source resolveWithResult: @(bytesWritten)];
            return nilptr;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (OFException *)_asyncRTExceptionFromObject: (id nillable)exception
{
    if (exception != nilptr and [exception isKindOfClass: OFException.class])
        return (OFException *nonnil)exception;

    return [OFException exception];
}

@end

#pragma clang assume_nonnull end
