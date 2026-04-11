#import "Async/AsyncRuntimeInternal.h"

void async_link_objfw_ofstream_future_category(void);
void async_link_objfw_ofstreamsocket_future_category(void);
void async_link_objfw_ofdatagramsocket_future_category(void);
void async_link_objfw_ofsequencedpacketsocket_future_category(void);
void async_link_objfw_oftcpsocket_future_category(void);
void async_link_objfw_oftlsstream_future_category(void);
void async_link_objfw_ofdnsresolver_future_category(void);
void async_link_objfw_ofirihandler_future_category(void);
void async_link_objfw_ofhttpclient_future_category(void);
#ifdef OF_HAVE_SCTP
void async_link_objfw_ofsctpsocket_future_category(void);
#endif
#ifdef OF_HAVE_IPX
void async_link_objfw_ofspxsocket_future_category(void);
void async_link_objfw_ofspxstreamsocket_future_category(void);
#endif

#pragma clang assume_nonnull begin

@interface AsyncObjFWTimerTarget : OFObject

- (instancetype)initWithBlock: (void (^)(void))block OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;
- (void)fire;

@end

@implementation FutureObjFWOperationException

- (instancetype)initWithFuture: (Future *)future object: (id)object operation: (OFString *)operation
{
    self = [super initWithFuture: future];
    _object = object;
    _operation = [operation copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureObjFWOperationException: %@ %@ on %@", DescribeFuture(self.future), self.operation, self.object];
}

@end

@implementation FutureObjFWInvalidCompletionException

- (instancetype)initWithFuture: (Future *)future object: (id)object operation: (OFString *)operation reason: (OFString *)reason
{
    self = [super initWithFuture: future object: object operation: operation];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureObjFWInvalidCompletionException: %@ %@ on %@ completed invalidly: %@", DescribeFuture(self.future), self.operation, self.object, self.reason];
}

@end

@implementation FutureObjFWOperationCancelledException

- (instancetype)initWithFuture: (Future *)future object: (id)object operation: (OFString *)operation
{
    return [super initWithFuture: future object: object operation: operation];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"FutureObjFWOperationCancelledException: %@ cancelled %@ on %@", DescribeFuture(self.future), self.operation, self.object];
}

@end

@implementation AsyncBufferReadResult

@synthesize buffer = _buffer;
@synthesize length = _length;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length
{
    self = [super init];
    _buffer = buffer;
    _length = length;
    return self;
}

@end

@implementation AsyncDatagramReceiveResult

@synthesize senderAddressData = _senderAddressData;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length sender: (const OFSocketAddress *)sender
{
    self = [super initWithBuffer: buffer length: length];
    _senderAddressData = [AsyncObjFWSupport copySocketAddressData: sender];
    return self;
}

- (const OFSocketAddress *)sender
{
    return (const OFSocketAddress *)self.senderAddressData.items;
}

@end

#ifdef OF_HAVE_SCTP
@implementation AsyncSCTPReceiveResult

@synthesize info = _info;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length info: (OFSCTPMessageInfo nillable)info
{
    self = [super initWithBuffer: buffer length: length];
    _info = [info copy];
    return self;
}

@end
#endif

@implementation AsyncObjFWFutureBridge {
    OFMutex *_lock;
    void (^_startBlock)(AsyncObjFWFutureBridge *bridge);
    void (^nillable _cancelBlock)(AsyncObjFWFutureBridge *bridge);
    bool _started;
    bool _completed;
}

@synthesize object = _object;
@synthesize operation = _operation;
@synthesize scheduler = _scheduler;
@synthesize resolver = _resolver;
@synthesize started = _started;

- (instancetype)initWithObject: (id)object operation: (OFString *)operation scheduler: (AsyncScheduler *)scheduler resolver: (FutureResolver<id> *)resolver startBlock: (void (^)(AsyncObjFWFutureBridge *bridge))startBlock cancelBlock: (void (^ nillable)(AsyncObjFWFutureBridge *bridge))cancelBlock
{
    self = [super init];
    _object = object;
    _operation = [operation copy];
    _scheduler = scheduler;
    _resolver = resolver;
    _startBlock = [startBlock copy];
    _cancelBlock = [cancelBlock copy];
    _lock = [OFMutex mutex];
    _started = false;
    _completed = false;
    return self;
}

- (void)start
{
    block_reference bool shouldStart = false;
    block_reference void (^startBlock)(AsyncObjFWFutureBridge *bridge) = nilptr;

    [_lock scopedLock: ^{
        if (not _completed and not _started) {
            _started = true;
            shouldStart = true;
            startBlock = _startBlock;
            _startBlock = nilptr;
        }
    }];

    if (not shouldStart)
        return;

    @try {
        startBlock(self);
    } @catch (OFException *exception) {
        [self reject: exception];
    }
}

- (void)cancel
{
    block_reference bool shouldCancel = false;
    block_reference bool started = false;
    block_reference void (^nillable cancelBlock)(AsyncObjFWFutureBridge *bridge) = nilptr;

    [_lock scopedLock: ^{
        if (not _completed) {
            _completed = true;
            shouldCancel = true;
            started = _started;
            cancelBlock = _cancelBlock;
            _cancelBlock = nilptr;
            _startBlock = nilptr;
        }
    }];

    if (not shouldCancel)
        return;

    [_resolver reject: [[FutureObjFWOperationCancelledException alloc] initWithFuture: _resolver.future object: _object operation: _operation]];

    if (started and cancelBlock != nilptr)
        cancelBlock(self);
}

- (void)resolve: (id)value
{
    block_reference bool shouldResolve = false;

    [_lock scopedLock: ^{
        if (not _completed) {
            _completed = true;
            shouldResolve = true;
            _cancelBlock = nilptr;
            _startBlock = nilptr;
        }
    }];

    if (shouldResolve)
        [_resolver resolve: value];
}

- (void)reject: (OFException *)exception
{
    block_reference bool shouldReject = false;

    [_lock scopedLock: ^{
        if (not _completed) {
            _completed = true;
            shouldReject = true;
            _cancelBlock = nilptr;
            _startBlock = nilptr;
        }
    }];

    if (shouldReject)
        [_resolver reject: exception];
}

- (void)rejectInvalidCompletionWithReason: (OFString *)reason
{
    [self reject: [[FutureObjFWInvalidCompletionException alloc] initWithFuture: self.resolver.future object: self.object operation: self.operation reason: reason]];
}

@end

@implementation AsyncObjFWTimerTarget {
    void (^_block)(void);
}

- (instancetype)initWithBlock: (void (^)(void))block
{
    self = [super init];
    _block = [block copy];
    return self;
}

- (void)fire
{
    void (^block)(void) = _block;
    _block = nilptr;

    if (block != nilptr)
        block();
}

@end

void async_link_objfw_future_categories(void)
{
    async_link_objfw_ofstream_future_category();
    async_link_objfw_ofstreamsocket_future_category();
    async_link_objfw_ofdatagramsocket_future_category();
    async_link_objfw_ofsequencedpacketsocket_future_category();
    async_link_objfw_oftcpsocket_future_category();
    async_link_objfw_oftlsstream_future_category();
    async_link_objfw_ofdnsresolver_future_category();
    async_link_objfw_ofirihandler_future_category();
    async_link_objfw_ofhttpclient_future_category();
#ifdef OF_HAVE_SCTP
    async_link_objfw_ofsctpsocket_future_category();
#endif
#ifdef OF_HAVE_IPX
    async_link_objfw_ofspxsocket_future_category();
    async_link_objfw_ofspxstreamsocket_future_category();
#endif
}

@namespace_implementation(AsyncObjFWSupport)

+ (void)scheduleOnScheduler: (AsyncScheduler *)scheduler target: (id)target selector: (SEL)selector
{
    OFDate *fireDate = [[OFDate alloc] initWithTimeIntervalSinceNow: 0];
    OFTimer *timer = [[OFTimer alloc] initWithFireDate: fireDate interval: 0 target: target selector: selector repeats: false];
    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
}

+ (void)attachCancellationBridgeToFuture: (Future *)future cancelOnTaskCancellation: (bool)cancelOnTaskCancellation bridge: (AsyncObjFWFutureBridge *)bridge
{
    if (cancelOnTaskCancellation)
        [future _setPendingCancellationCallback: ^{ [bridge cancel]; }];
}

+ (OFData *)copySocketAddressData: (const OFSocketAddress *)socketAddress
{
    return [OFData dataWithItems: socketAddress count: sizeof(*socketAddress)];
}

@end

#pragma clang assume_nonnull end
