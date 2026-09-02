#import <OFData+AsyncIO.h>

#import <OFStream+AsyncIO.h>

#pragma clang assume_nonnull begin

int AsyncRT_OFData_AsyncIO_anchor = 0;

[[subclassing_restricted, direct_members]]
@interface OFDataAsyncIOMissingStreamException : OFException

@property(readonly, nonatomic) OFIRI *IRI;

- (instancetype)initWithIRI: (OFIRI *)IRI;
- (instancetype)init [[clang::unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface OFDataIRIReadOperation : OFObject <OFIRIHandlerDelegate>

@property(readonly, nonatomic) OFIRI *IRI;
@property(readonly, nonatomic) AsyncTask<OFData *> *task;

- (instancetype)initWithIRI: (OFIRI *)IRI;
- (instancetype)init [[clang::unavailable]];
- (void)start;
- (void)_startSynchronousReadFallback;
- (void)_readStream: (OFStream *)stream;
- (void)_complete;
- (void)_rejectWithObject: (id nillable)exception;
- (OFException *)_exceptionFromObject: (id nillable)exception;

@end

@implementation OFDataAsyncIOMissingStreamException

- (instancetype)initWithIRI: (OFIRI *)IRI
{
    self = [super init];
    _IRI = IRI;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"%@: missing stream for %@", self.className, _IRI.string];
}

@end

@implementation OFDataIRIReadOperation {
    AsyncTaskCompletionSource<OFData *> *_source;
    OFDataIRIReadOperation *nillable _retainedSelf;
    AsyncTask<OFNumber *> *nillable _readContinuationTask;
}

- (instancetype)initWithIRI: (OFIRI *)IRI
{
    self = [super init];
    _IRI = IRI;
    _source = [[AsyncTaskCompletionSource<OFData *> alloc] init];
    return self;
}

- (AsyncTask<OFData *> *)task
{
    return _source.task;
}

- (void)start
{
    _retainedSelf = self;

    @try {
        [OFIRIHandler asyncOpenItemAtIRI: _IRI mode: @"r" delegate: self];
    } @catch (OFException *) {
        [self _startSynchronousReadFallback];
    }
}

- (void)_startSynchronousReadFallback
{
    _readContinuationTask = [AsyncTask<OFNumber *> spawn: ^OFNumber *{
        @try {
            [_source resolveWithResult: [OFData dataWithContentsOfIRI: _IRI]];
        } @catch (OFException *exception) {
            [_source rejectWithError: exception];
        }

        [self _complete];
        return @0;
    }];
}

- (void)IRIHandler: (OFIRIHandler *)IRIHandler didOpenItemAtIRI: (OFIRI *)IRI stream: (__kindof OFStream *nillable)stream exception: (id nillable)exception
{
    if (exception != nilptr) {
        [self _rejectWithObject: exception];
        [self _complete];
        return;
    }

    if (stream == nilptr) {
        [_source rejectWithError: [[OFDataAsyncIOMissingStreamException alloc] initWithIRI: IRI]];
        [self _complete];
        return;
    }

    [self _readStream: $assert_nonnil(stream)];
}

- (void)_readStream: (OFStream *)stream
{
    _readContinuationTask = [AsyncTask<OFNumber *> spawn: ^OFNumber *{
        @try {
            [_source resolveWithResult: [[stream taskToReadUntilEnd] await]];
        } @catch (OFException *exception) {
            [_source rejectWithError: exception];
        }

        [self _complete];
        return @0;
    }];
}

- (void)_complete
{
    auto retainedSelf = _retainedSelf;
    if (retainedSelf == nilptr)
        return;
    _retainedSelf = nilptr;
}

- (void)_rejectWithObject: (id nillable)exception
{
    [_source rejectWithError: [self _exceptionFromObject: exception]];
}

- (OFException *)_exceptionFromObject: (id nillable)exception
{
    if (exception != nilptr and [exception isKindOfClass: OFException.class])
        return (OFException *nonnil)exception;

    return [OFException exception];
}

@end

@implementation OFData(AsyncIO)

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfFile: (OFString *)path
{
    return [self taskToReadDataWithContentsOfIRI: [OFIRI fileIRIWithPath: path]];
}

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfIRI: (OFIRI *)IRI
{
    auto operation = [[OFDataIRIReadOperation alloc] initWithIRI: IRI];
    [operation start];
    return operation.task;
}

@end

#pragma clang assume_nonnull end
