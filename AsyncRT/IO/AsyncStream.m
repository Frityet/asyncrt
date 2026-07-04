#import "AsyncStream.h"

#pragma clang assume_nonnull begin

static size_t const AsyncStreamDefaultReadBufferLength = 64 * 1024;

@implementation AsyncStream

+ (instancetype)streamWithStream: (OFStream *)stream
{
    return [[self alloc] initWithStream: stream];
}

- (instancetype)initWithStream: (OFStream *)stream
{
    self = [super init];
    _rawStream = stream;
    return self;
}

- (AsyncTask<OFData *> *)taskToReadAtMostLength: (size_t)length
{
    if (length == 0)
        @throw [OFInvalidArgumentException exception];

    auto source = [[AsyncTaskCompletionSource<OFData *> alloc] init];
    auto buffer = [OFMutableData dataWithCapacity: length];
    [buffer increaseCountBy: length];
    void *nillable mutableItems = buffer.mutableItems;
    if (mutableItems == NULL)
        @throw [OFOutOfMemoryException exception];
    void *readTarget = (void *nonnil)mutableItems;

    @try {
        [_rawStream asyncReadIntoBuffer: readTarget length: length handler: ^bool(OFStream *, void *readBuffer, size_t bytesRead, id nillable exception) {
            if (exception != nilptr) {
                [source rejectWithError: [self _exceptionFromObject: exception]];
                return false;
            }

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
    auto buffer = [OFMutableData dataWithCapacity: AsyncStreamDefaultReadBufferLength];
    auto body = [OFMutableData data];
    [buffer increaseCountBy: AsyncStreamDefaultReadBufferLength];
    void *nillable mutableItems = buffer.mutableItems;
    if (mutableItems == NULL)
        @throw [OFOutOfMemoryException exception];
    void *readTarget = (void *nonnil)mutableItems;

    @try {
        [_rawStream asyncReadIntoBuffer: readTarget length: AsyncStreamDefaultReadBufferLength handler: ^bool(OFStream *stream, void *readBuffer, size_t bytesRead, id nillable exception) {
            if (exception != nilptr) {
                [source rejectWithError: [self _exceptionFromObject: exception]];
                return false;
            }

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

- (AsyncTask<OFNumber *> *)taskToWriteData: (OFData *)data
{
    auto source = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];

    @try {
        [_rawStream asyncWriteData: data handler: ^OFData *nillable(OFStream *, OFData *, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr)
                [source rejectWithError: [self _exceptionFromObject: exception]];
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
    auto source = [[AsyncTaskCompletionSource<OFNumber *> alloc] init];

    @try {
        [_rawStream asyncWriteString: string encoding: encoding handler: ^OFString *nillable(OFStream *, OFString *, OFStringEncoding, size_t bytesWritten, id nillable exception) {
            if (exception != nilptr)
                [source rejectWithError: [self _exceptionFromObject: exception]];
            else
                [source resolveWithResult: @(bytesWritten)];
            return nilptr;
        }];
    } @catch (OFException *exception) {
        [source rejectWithError: exception];
    }

    return source.task;
}

- (OFException *)_exceptionFromObject: (id nillable)exception [[direct]]
{
    if (exception != nilptr and [exception isKindOfClass: OFException.class])
        return (OFException *nonnil)exception;

    return [OFException exception];
}

@end

#pragma clang assume_nonnull end
