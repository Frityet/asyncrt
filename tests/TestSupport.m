#import "TestSupport.h"

#pragma clang assume_nonnull begin

@namespace_implementation(AsyncRuntimeTestSupport)

+ (Promise<OFString *> *)timerResolvedStringForScheduler: (AsyncScheduler *)scheduler
                                                seconds: (OFTimeInterval)seconds
                                                  value: (OFString *)value
{
    auto resolver = [[PromiseResolver<OFString *> alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: seconds]
                                          interval: 0
                                            target: resolver
                                          selector: @selector(resolve:)
                                            object: value
                                           repeats: false];
    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return resolver.promise;
}

+ (Promise<OFString *> *)timerRejectedStringForScheduler: (AsyncScheduler *)scheduler
                                                seconds: (OFTimeInterval)seconds
                                              exception: (OFException *)exception
{
    auto resolver = [[PromiseResolver<OFString *> alloc] init];
    auto timer = [[OFTimer alloc] initWithFireDate: [OFDate dateWithTimeIntervalSinceNow: seconds]
                                          interval: 0
                                            target: resolver
                                          selector: @selector(reject:)
                                            object: exception
                                           repeats: false];
    [scheduler.runLoop addTimer: timer forMode: scheduler.mode];
    return resolver.promise;
}

+ (AsyncTaskSnapshot *nillable)findTaskSnapshotNamed: (OFString *)name inSnapshot: (AsyncSchedulerSnapshot *)snapshot
{
    for (AsyncTaskSnapshot *task_snapshot in snapshot.tasks) {
        if ([task_snapshot.name isEqual: name])
            return task_snapshot;
    }

    return nilptr;
}

+ (uintptr_t)pointerValueFromBytes: (const void *)bytes
{
    uintptr_t value = 0;
    memcpy(&value, bytes, sizeof(value));
    return value;
}

+ (void)assertCondition: (bool)condition message: (OFString *)message
{
    if (not condition)
        @throw [[TestFailureException alloc] initWithMessage: message];
}

@end

@implementation TestFailureException

@synthesize message = _message;

- (instancetype)initWithMessage: (OFString *)message
{
    self = [super init];
    _message = [message copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"TestFailureException: %@", self.message];
}

@end

@implementation TestRejectionException @end

@implementation CrossThreadResolverThread {
    PromiseResolver<OFString *> *_resolver;
    OFString *_value;
    OFTimeInterval _delay;
}

- (instancetype)initWithResolver: (PromiseResolver<OFString *> *)resolver value: (OFString *)value delay: (OFTimeInterval)delay
{
    self = [super init];
    _resolver = resolver;
    _value = value;
    _delay = delay;
    return self;
}

- (id nillable)main
{
    [OFThread sleepForTimeInterval: _delay];
    [_resolver resolve: _value];
    return nilptr;
}

@end

@implementation TaskCancellationThread {
    Task *_task;
    OFTimeInterval _delay;
    atomic_t(bool) *_cancelIssuedFlag;
}

- (instancetype)initWithTask: (Task *)task delay: (OFTimeInterval)delay cancelIssuedFlag: (atomic_t(bool) *)cancelIssuedFlag
{
    self = [super init];
    _task = task;
    _delay = delay;
    _cancelIssuedFlag = cancelIssuedFlag;
    return self;
}

- (id nillable)main
{
    [OFThread sleepForTimeInterval: _delay];
    [_task cancel];

    if (_cancelIssuedFlag != nullptr)
        atomic_store_explicit(_cancelIssuedFlag, true, memory_order_release);

    return nilptr;
}

@end

@implementation LocalHTTPTestServer {
    OFTCPSocket *_listener;
    OFThread *nillable _acceptThread;
    OFMutex *_lock;
    OFMutableArray<OFThread *> *_handlerThreads;
    bool _stopping;
}

@synthesize port = _port;

- (instancetype)init
{
    self = [super init];
    _listener = [[OFTCPSocket alloc] init];
    _lock = [OFMutex mutex];
    _handlerThreads = [OFMutableArray array];
    _stopping = false;

    OFSocketAddress boundAddress = [_listener bindToHost: @"127.0.0.1" port: 0];
    [_listener listen];
    _port = OFSocketAddressIPPort(&boundAddress);
    return self;
}

- (void)start
{
    unretained LocalHTTPTestServer *unsafeSelf = self;

    _acceptThread = [[OFThread alloc] initWithBlock: ^{
        [unsafeSelf _acceptLoop];
        return nilptr;
    }];
    [_acceptThread start];
}

- (void)stop
{
    OFArray<OFThread *> *handlerThreads;
    OFTCPSocket *wakeSocket;

    [_lock lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
        handlerThreads = [_handlerThreads copy];
    } @finally {
        [_lock unlock];
    }

    @try {
        wakeSocket = [[OFTCPSocket alloc] init];
        [wakeSocket connectToHost: @"127.0.0.1" port: self.port];
        [wakeSocket close];
    } @catch (OFException *) {
    }

    if (_acceptThread != nilptr)
        (void)[_acceptThread join];

    @try {
        [_listener close];
    } @catch (OFException *) {
    }

    for (OFThread *thread in handlerThreads)
        (void)[thread join];
}

- (OFIRI *)IRIForPath: (OFString *)path
{
    auto iri_string = [OFString stringWithFormat: @"http://127.0.0.1:%u%@", self.port, path];
    return [[OFIRI alloc] initWithString: iri_string];
}

- (void)_acceptLoop
{
    unretained LocalHTTPTestServer *unsafeSelf = self;

    while (true) {
        OFTCPSocket *acceptedSocket;
        OFThread *thread;

        @try {
            acceptedSocket = (OFTCPSocket *)[_listener accept];
        } @catch (OFException *exception) {
            [_lock lock];
            @try {
                if (_stopping)
                    return;
            } @finally {
                [_lock unlock];
            }

            @throw exception;
        }

        [_lock lock];
        @try {
            if (_stopping) {
                @try {
                    [acceptedSocket close];
                } @catch (OFException *) {
                }

                return;
            }
        } @finally {
            [_lock unlock];
        }

        thread = [[OFThread alloc] initWithBlock: ^{
            [unsafeSelf _handleAcceptedSocket: acceptedSocket];
            return nilptr;
        }];

        [_lock lock];
        @try {
            [_handlerThreads addObject: thread];
        } @finally {
            [_lock unlock];
        }

        [thread start];
    }
}

- (void)_handleAcceptedSocket: (OFTCPSocket *)acceptedSocket
{
    @try {
        OFString *requestLine = acceptedSocket.readLine;
        OFString *path;
        OFTimeInterval delay;
        OFString *body;
        const char *bodyUTF8String;
        OFString *response;

        if (requestLine == nilptr)
            return;

        while (true) {
            OFString *headerLine = acceptedSocket.readLine;

            if (headerLine == nilptr or headerLine.length == 0)
                break;
        }

        path = [self _pathFromRequestLine: requestLine];
        delay = [path containsString: @"slow"] ? 0.20 : 0.01;
        [OFThread sleepForTimeInterval: delay];

        body = (path.length > 1 ? [path substringFromIndex: 1] : @"root");
        bodyUTF8String = body.UTF8String;
        response = [OFString stringWithFormat: @"HTTP/1.1 200 OK\r\nContent-Length: %zu\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\n%@", strlen(bodyUTF8String), body];
        [acceptedSocket writeString: response];
    } @catch (OFException *) {
    } @finally {
        @try {
            [acceptedSocket close];
        } @catch (OFException *) {
        }
    }
}

- (OFString *)_pathFromRequestLine: (OFString *)requestLine
{
    OFArray<OFString *> *parts = [requestLine componentsSeparatedByString: @" "];

    if (parts.count < 2)
        return @"/invalid";

    return parts[1];
}

@end

#pragma clang assume_nonnull end
