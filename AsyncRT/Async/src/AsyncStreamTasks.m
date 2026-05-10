#import "AsyncRuntimeInternal.h"
#import "AsyncStreamTasks.h"

#pragma clang assume_nonnull begin

static size_t const AsyncStreamDefaultBufferSize = 16 * 1024;

void AsyncRTLinkAsyncStreamTasks(void)
{
}

@interface AsyncStreamTaskBridge : OFObject

@property(readonly, nonatomic) OFStream *stream;
@property(readonly, nonatomic) AsyncScheduler *scheduler;

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler;
- (instancetype)init OF_UNAVAILABLE;
- (bool)_finishOnce;
- (void)cancel;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncStreamReadAtMostBridge : AsyncStreamTaskBridge

@property(readonly, nonatomic) AsyncCompletionSource<OFData *> *completionSource;
@property(readonly, nonatomic) size_t length;

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                         length: (size_t)length
               completionSource: (AsyncCompletionSource<OFData *> *)completionSource [[designated_initailiser]];
- (void)start;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncStreamReadUntilEndBridge : AsyncStreamTaskBridge

@property(readonly, nonatomic) AsyncCompletionSource<OFData *> *completionSource;
@property(readonly, nonatomic) size_t maximumLength;

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                 maximumLength: (size_t)maximumLength
               completionSource: (AsyncCompletionSource<OFData *> *)completionSource [[designated_initailiser]];
- (void)start;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncStreamWriteBridge : AsyncStreamTaskBridge

@property(readonly, nonatomic) AsyncCompletionSource<AsyncUnit *> *completionSource;
@property(readonly, nonatomic) OFData *data;

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                          data: (OFData *)data
              completionSource: (AsyncCompletionSource<AsyncUnit *> *)completionSource [[designated_initailiser]];
- (void)start;

@end

@implementation AsyncStreamTaskBridge {
    OFMutex *_lock;
    bool _finished;
}

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
{
    self = [super init];
    _stream = stream;
    _scheduler = scheduler;
    _lock = [OFMutex mutex];
    _finished = false;
    return self;
}

- (bool)_finishOnce
{
    bool shouldFinish = false;

    [_lock lock];
    @try {
        shouldFinish = not _finished;
        if (shouldFinish)
            _finished = true;
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    @try {
        [self.stream cancelAsyncRequests];
    } @catch (id) {
    }
}

@end

@implementation AsyncStreamReadAtMostBridge {
    void *_buffer;
}

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                         length: (size_t)length
               completionSource: (AsyncCompletionSource<OFData *> *)completionSource
{
    self = [super initWithStream: stream scheduler: scheduler];
    _length = length;
    _completionSource = completionSource;
    _buffer = malloc(length);

    if (_buffer == nullptr)
        @throw [OFOutOfMemoryException exceptionWithRequestedSize: length];

    return self;
}

- (void)dealloc
{
    free(_buffer);
}

- (void)start
{
    [self.stream asyncReadIntoBuffer: _buffer
                              length: self.length
                         runLoopMode: self.scheduler.mode
                             handler: ^bool(OFStream *stream, void *buffer, size_t length, id nillable exception) {
        (void)stream;

        if (not [self _finishOnce])
            return false;

        if (exception != nilptr) {
            if ([$assert_nonnil(exception) isKindOfClass: OFException.class])
                [self.completionSource reject: (OFException *)$assert_nonnil(exception)];
            else
                [self.completionSource reject: [OFInvalidArgumentException exception]];
            return false;
        }

        [self.completionSource fulfill: [OFData dataWithItems: buffer count: length]];
        return false;
    }];
}

@end

@implementation AsyncStreamReadUntilEndBridge {
    void *_buffer;
    OFMutableData *_data;
}

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                 maximumLength: (size_t)maximumLength
               completionSource: (AsyncCompletionSource<OFData *> *)completionSource
{
    self = [super initWithStream: stream scheduler: scheduler];
    _maximumLength = maximumLength;
    _completionSource = completionSource;
    _data = [OFMutableData dataWithCapacity: (maximumLength < AsyncStreamDefaultBufferSize
        ? maximumLength
        : AsyncStreamDefaultBufferSize)];
    _buffer = malloc(AsyncStreamDefaultBufferSize);

    if (_buffer == nullptr)
        @throw [OFOutOfMemoryException exceptionWithRequestedSize: AsyncStreamDefaultBufferSize];

    return self;
}

- (void)dealloc
{
    free(_buffer);
}

- (void)start
{
    [self.stream asyncReadIntoBuffer: _buffer
                              length: AsyncStreamDefaultBufferSize
                         runLoopMode: self.scheduler.mode
                             handler: ^bool(OFStream *stream, void *buffer, size_t length, id nillable exception) {
        if (exception != nilptr) {
            if ([self _finishOnce]) {
                if ([$assert_nonnil(exception) isKindOfClass: OFException.class])
                    [self.completionSource reject: (OFException *)$assert_nonnil(exception)];
                else
                    [self.completionSource reject: [OFInvalidArgumentException exception]];
            }
            return false;
        }

        if (length > 0) {
            [_data addItems: buffer count: length];

            if (_data.count > self.maximumLength) {
                if ([self _finishOnce])
                    [self.completionSource reject: [OFOutOfRangeException exception]];
                return false;
            }
        }

        if (stream.atEndOfStream) {
            if ([self _finishOnce])
                [self.completionSource fulfill: [_data copy]];
            return false;
        }

        return true;
    }];
}

@end

@implementation AsyncStreamWriteBridge

- (instancetype)initWithStream: (OFStream *)stream
                     scheduler: (AsyncScheduler *)scheduler
                          data: (OFData *)data
              completionSource: (AsyncCompletionSource<AsyncUnit *> *)completionSource
{
    self = [super initWithStream: stream scheduler: scheduler];
    _data = [data copy];
    _completionSource = completionSource;
    return self;
}

- (void)start
{
    [self.stream asyncWriteData: self.data
                    runLoopMode: self.scheduler.mode
                        handler: ^OFData *nillable(OFStream *stream, OFData *writtenData, size_t bytesWritten, id nillable exception) {
        (void)stream;

        if (not [self _finishOnce])
            return nilptr;

        if (exception != nilptr) {
            if ([$assert_nonnil(exception) isKindOfClass: OFException.class])
                [self.completionSource reject: (OFException *)$assert_nonnil(exception)];
            else
                [self.completionSource reject: [OFInvalidArgumentException exception]];
        } else if (bytesWritten != writtenData.count * writtenData.itemSize) {
            [self.completionSource reject: [OFTruncatedDataException exception]];
        } else {
            [self.completionSource fulfill: AsyncUnit.unit];
        }

        return nilptr;
    }];
}

@end

@implementation OFStream (AsyncStreamTasks)

- (Task<OFData *> *)taskToReadAtMost: (size_t)length
                          onScheduler: (AsyncScheduler *)scheduler
{
    if (length == 0)
        return [Task resolved: [OFData data]];

    auto completionSource = [[AsyncCompletionSource<OFData *> alloc] init];
    auto bridge = [[AsyncStreamReadAtMostBridge alloc] initWithStream: self
                                                            scheduler: scheduler
                                                                length: length
                                                      completionSource: completionSource];
    [completionSource setPendingTaskCancellationHandler: ^{ [bridge cancel]; }];
    [bridge start];
    return completionSource.task;
}

- (Task<OFData *> *)taskToReadUntilEndWithMaximumLength: (size_t)maximumLength
                                            onScheduler: (AsyncScheduler *)scheduler
{
    auto completionSource = [[AsyncCompletionSource<OFData *> alloc] init];
    auto bridge = [[AsyncStreamReadUntilEndBridge alloc] initWithStream: self
                                                              scheduler: scheduler
                                                          maximumLength: maximumLength
                                                        completionSource: completionSource];
    [completionSource setPendingTaskCancellationHandler: ^{ [bridge cancel]; }];
    [bridge start];
    return completionSource.task;
}

- (Task<AsyncUnit *> *)taskToWriteData: (OFData *)data
                            onScheduler: (AsyncScheduler *)scheduler
{
    if (data.count == 0)
        return [Task resolved: AsyncUnit.unit];

    auto completionSource = [[AsyncCompletionSource<AsyncUnit *> alloc] init];
    auto bridge = [[AsyncStreamWriteBridge alloc] initWithStream: self
                                                       scheduler: scheduler
                                                            data: data
                                                completionSource: completionSource];
    [completionSource setPendingTaskCancellationHandler: ^{ [bridge cancel]; }];
    [bridge start];
    return completionSource.task;
}

@end

#pragma clang assume_nonnull end
