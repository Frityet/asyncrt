#include <errno.h>
#include <string.h>

#import "TestSupport.h"

#pragma clang assume_nonnull begin

@interface OTTestSkippedException : OFException
+ (instancetype)exceptionWithMessage: (OFString *)message;
@end

static OFString *AsyncRuntimeTemporaryPath(OFString *prefix)
{
    auto uuidString = [[OFUUID UUID] UUIDString];
    size_t suffixLength = 12;

    if (uuidString.length < suffixLength)
        suffixLength = uuidString.length;

    return [OFString stringWithFormat: @"/tmp/%@-%@", prefix, [uuidString substringToIndex: suffixLength]];
}

static void AsyncRuntimeWriteFile(OFString *path, OFString *contents)
{
    auto file = [[OFFile alloc] initWithPath: path mode: @"w"];

    @try {
        [file writeString: contents];
    } @finally {
        [file close];
    }
}

@interface LocalPlaintextTCPServer : OFObject

@property(readonly, nonatomic) uint16_t port;

- (void)start;
- (void)stop;

@end

@implementation LocalPlaintextTCPServer {
    OFTCPSocket *_listener;
    OFThread *nillable _thread;
    OFMutex *_lock;
    bool _stopping;
}

@synthesize port = _port;

- (instancetype)init
{
    self = [super init];
    _listener = [[OFTCPSocket alloc] init];
    _lock = [OFMutex mutex];
    _stopping = false;

    OFSocketAddress address = [_listener bindToHost: @"127.0.0.1" port: 0];
    [_listener listen];
    _port = OFSocketAddressIPPort(&address);
    return self;
}

- (void)start
{
    unretained LocalPlaintextTCPServer *unsafeSelf = self;

    _thread = [[OFThread alloc] initWithBlock: ^{
        [unsafeSelf _serveClient];
        return nilptr;
    }];
    [_thread start];
}

- (void)stop
{
    OFTCPSocket *wakeSocket;

    [_lock lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
    } @finally {
        [_lock unlock];
    }

    @try {
        wakeSocket = [[OFTCPSocket alloc] init];
        [wakeSocket connectToHost: @"127.0.0.1" port: self.port];
        [wakeSocket close];
    } @catch (OFException *) {
    }

    if (_thread != nilptr)
        (void)[_thread join];

    @try {
        [_listener close];
    } @catch (OFException *) {
    }
}

- (void)_serveClient
{
    OFTCPSocket *acceptedSocket;

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
            [acceptedSocket close];
            return;
        }
    } @finally {
        [_lock unlock];
    }

    @try {
        [acceptedSocket writeString: @"plain-text"];
    } @finally {
        [acceptedSocket close];
    }
}

@end

static bool AsyncRuntimeCanBindLoopbackDNSStub(void)
{
    auto socket = [[OFUDPSocket alloc] init];

    @try {
        (void)[socket bindToHost: @"127.0.0.1" port: 53];
        [socket close];
        return true;
    } @catch (OFBindSocketFailedException *) {
        return false;
    } @catch (OFException *) {
        return false;
    }
}

@interface LocalDNSQueryTestServer : OFObject

- (instancetype)initWithResponseText: (OFString *)responseText designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)stop;

@end

@implementation LocalDNSQueryTestServer {
    OFUDPSocket *_socket;
    OFThread *nillable _thread;
    OFMutex *_lock;
    OFString *_responseText;
    bool _stopping;
}

- (instancetype)initWithResponseText: (OFString *)responseText
{
    self = [super init];
    _socket = [[OFUDPSocket alloc] init];
    _lock = [OFMutex mutex];
    _responseText = [responseText copy];
    _stopping = false;
    (void)[_socket bindToHost: @"127.0.0.1" port: 53];
    return self;
}

- (void)start
{
    unretained LocalDNSQueryTestServer *unsafeSelf = self;

    _thread = [[OFThread alloc] initWithBlock: ^{
        [unsafeSelf _serveLoop];
        return nilptr;
    }];
    [_thread start];
}

- (void)stop
{
    OFUDPSocket *wakeSocket;
    OFSocketAddress loopback = OFSocketAddressParseIPv4(@"127.0.0.1", 53);
    static unsigned char const wakeByte = 0;

    [_lock lock];
    @try {
        if (_stopping)
            return;

        _stopping = true;
    } @finally {
        [_lock unlock];
    }

    @try {
        wakeSocket = [[OFUDPSocket alloc] init];
        (void)[wakeSocket bindToHost: @"127.0.0.1" port: 0];
        [wakeSocket sendBuffer: &wakeByte length: 1 receiver: &loopback];
        [wakeSocket close];
    } @catch (OFException *) {
    }

    if (_thread != nilptr)
        (void)[_thread join];

    @try {
        [_socket close];
    } @catch (OFException *) {
    }
}

- (void)_serveLoop
{
    while (true) {
        unsigned char buffer[512];
        OFSocketAddress sender;
        size_t length;
        OFData *nillable response;

        length = [_socket receiveIntoBuffer: buffer length: sizeof(buffer) sender: &sender];

        [_lock lock];
        @try {
            if (_stopping)
                return;
        } @finally {
            [_lock unlock];
        }

        response = [self _responseDataForQueryBuffer: buffer length: length];
        if (response == nilptr)
            continue;

        [_socket sendBuffer: response.items
                      length: response.count * response.itemSize
                    receiver: &sender];
    }
}

- (OFData *nillable)_responseDataForQueryBuffer: (const unsigned char *)queryBuffer length: (size_t)length
{
    const char *responseUTF8;
    size_t responseLength;
    size_t questionEnd = 12;
    unsigned char response[512];
    size_t position;

    if (length < 17)
        return nilptr;

    while (questionEnd < length and queryBuffer[questionEnd] != 0) {
        size_t labelLength = queryBuffer[questionEnd];

        questionEnd++;
        if (questionEnd + labelLength > length)
            return nilptr;

        questionEnd += labelLength;
    }

    if (questionEnd + 5 > length)
        return nilptr;

    questionEnd += 5;

    responseUTF8 = _responseText.UTF8String;
    responseLength = _responseText.UTF8StringLength;
    if (responseLength > 255)
        @throw [OFOutOfRangeException exception];

    response[0] = queryBuffer[0];
    response[1] = queryBuffer[1];
    response[2] = 0x81;
    response[3] = 0x80;
    response[4] = 0x00;
    response[5] = 0x01;
    response[6] = 0x00;
    response[7] = 0x01;
    response[8] = 0x00;
    response[9] = 0x00;
    response[10] = 0x00;
    response[11] = 0x00;

    memcpy(response + 12, queryBuffer + 12, questionEnd - 12);
    position = questionEnd;

    response[position++] = 0xC0;
    response[position++] = 0x0C;
    response[position++] = 0x00;
    response[position++] = 0x10;
    response[position++] = 0x00;
    response[position++] = 0x01;
    response[position++] = 0x00;
    response[position++] = 0x00;
    response[position++] = 0x00;
    response[position++] = 0x3C;
    response[position++] = 0x00;
    response[position++] = (unsigned char)(responseLength + 1);
    response[position++] = (unsigned char)responseLength;
    memcpy(response + position, responseUTF8, responseLength);
    position += responseLength;

    return [OFData dataWithItems: response count: position];
}

@end

static bool AsyncRuntimeErrNoIndicatesUnsupportedSocket(int errNo)
{
    switch (errNo) {
    case EAFNOSUPPORT:
    case EPERM:
    case EPROTONOSUPPORT:
#ifdef ENOPROTOOPT
    case ENOPROTOOPT:
#endif
#ifdef ESOCKTNOSUPPORT
    case ESOCKTNOSUPPORT:
#endif
        return true;
    default:
        return false;
    }
}

typedef void (^AsyncRuntimeConnectedTCPSocketsBlock)(OFTCPSocket *client, OFStreamSocket *acceptedSocket);

static void AsyncRuntimeCloseSocket(id nillable socket)
{
    if (socket == nilptr)
        return;

    @try {
        [socket close];
    } @catch (OFException *) {
    }
}

static void AsyncRuntimeWithConnectedTCPSockets(AsyncScheduler *scheduler, bool useConnectCancelSelector, bool useAcceptCancelSelector, AsyncRuntimeConnectedTCPSocketsBlock block)
{
    auto listener = [[OFTCPSocket alloc] init];
    auto client = [[OFTCPSocket alloc] init];
    OFStreamSocket *nillable acceptedSocket = nilptr;
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    Promise<OFStreamSocket *> *acceptPromise;

    [listener listen];

    @try {
        if (useAcceptCancelSelector)
            acceptPromise = [listener promiseToAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];
        else
            acceptPromise = [listener promiseToAcceptOnScheduler: scheduler];

        if (useConnectCancelSelector)
            [[client promiseToConnectToHost: @"127.0.0.1" port: OFSocketAddressIPPort(&address) onScheduler: scheduler cancelOnTaskCancellation: false] await];
        else
            [[client promiseToConnectToHost: @"127.0.0.1" port: OFSocketAddressIPPort(&address) onScheduler: scheduler] await];

        acceptedSocket = acceptPromise.await;
        block(client, acceptedSocket);
    } @finally {
        AsyncRuntimeCloseSocket(acceptedSocket);
        AsyncRuntimeCloseSocket(client);
        AsyncRuntimeCloseSocket(listener);
    }
}

static void objfw_tcp_stream_wrappers(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = OFThread.currentThread;
    auto listener = [[OFTCPSocket alloc] init];
    auto client = [[OFTCPSocket alloc] init];
    block_reference OFStreamSocket *nillable acceptedSocket = nilptr;
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    char serverBuffer[5] = { 0 };
    char clientBuffer[4] = { 0 };
    char *serverBufferPointer = serverBuffer;
    char *clientBufferPointer = clientBuffer;
    bool connectResumedOnScheduler = false;
    block_reference bool acceptResumedOnScheduler = false;

    [listener listen];

    @try {
        Task<AsyncUnit *> *acceptTask = [rootScope spawn: ^{
            AsyncBufferReadResult *serverRead;

            acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
            acceptResumedOnScheduler = (OFThread.currentThread == expectedThread);

            serverRead = [acceptedSocket promiseToReadIntoBuffer: serverBufferPointer exactLength: sizeof(serverBuffer) onScheduler: scheduler].await;

            [AsyncRuntimeTestSupport assertCondition: (serverRead.length == sizeof(serverBuffer))
                                            message: (@"exact-length TCP reads should report the full number of bytes read")];
            [AsyncRuntimeTestSupport assertCondition: (serverRead.buffer == serverBufferPointer)
                                            message: (@"TCP read results should preserve the caller buffer pointer")];

            [AsyncRuntimeTestSupport assertCondition: ([acceptedSocket promiseToWriteData: [OFData dataWithItems: "pong" count: sizeof(clientBuffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                            message: (@"TCP write promises should resolve to AsyncUnit.unit")];
            return AsyncUnit.unit;
        } name: @"objfw-tcp-accept"];
        AsyncBufferReadResult *clientRead;
        OFTCPSocket *connectedSocket = [client promiseToConnectToHost: @"127.0.0.1" port: OFSocketAddressIPPort(&address) onScheduler: scheduler].await;

        connectResumedOnScheduler = (OFThread.currentThread == expectedThread);

        [AsyncRuntimeTestSupport assertCondition: (connectedSocket == client)
                                        message: (@"TCP connect promises should resolve with the original socket")];
        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"ping!" onScheduler: scheduler].await == AsyncUnit.unit)
                                        message: (@"stream string writes should resolve to AsyncUnit.unit")];

        clientRead = [client promiseToReadIntoBuffer: clientBufferPointer exactLength: sizeof(clientBuffer) onScheduler: scheduler].await;
        [acceptTask await];

        [AsyncRuntimeTestSupport assertCondition: (clientRead.length == sizeof(clientBuffer))
                                        message: (@"client-side exact reads should report the full byte count")];
        [AsyncRuntimeTestSupport assertCondition: (clientRead.buffer == clientBufferPointer)
                                        message: (@"client-side read results should preserve the caller buffer pointer")];
        [AsyncRuntimeTestSupport assertCondition: (memcmp(serverBuffer, "ping!", sizeof(serverBuffer)) == 0)
                                        message: (@"accepted sockets should receive bytes written via the async stream wrappers")];
        [AsyncRuntimeTestSupport assertCondition: (memcmp(clientBuffer, "pong", sizeof(clientBuffer)) == 0)
                                        message: (@"clients should receive bytes written back by the accepted socket")];
        [AsyncRuntimeTestSupport assertCondition: (connectResumedOnScheduler)
                                        message: (@"awaiting TCP connect promises should resume on the scheduler thread")];
        [AsyncRuntimeTestSupport assertCondition: (acceptResumedOnScheduler)
                                        message: (@"awaiting TCP accept promises should resume on the scheduler thread")];
    } @finally {
        if (acceptedSocket != nilptr)
            [acceptedSocket close];
        [client close];
        [listener close];
    }
}

static void objfw_stream_eof_optionals(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto listener = [[OFTCPSocket alloc] init];
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    OFString *host = @"127.0.0.1";
    uint16_t port = OFSocketAddressIPPort(&address);

    [listener listen];

    @try {
        Task<AsyncUnit *> *stringTask = [rootScope spawn: ^{
            OFStreamSocket *acceptedSocket = nilptr;

            @try {
                Optional<OFString *> *firstString;
                Optional<OFString *> *eofString;

                acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
                firstString = [acceptedSocket promiseToReadStringOnScheduler: scheduler].await;
                eofString = [acceptedSocket promiseToReadStringOnScheduler: scheduler].await;

                [AsyncRuntimeTestSupport assertCondition: (firstString.hasValue and [firstString.value isEqual: @"payload"])
                                                message: (@"promiseToReadString should resolve the remaining stream contents")];
                [AsyncRuntimeTestSupport assertCondition: (not eofString.hasValue)
                                                message: (@"promiseToReadString should resolve EOF as Optional.none")];
                return AsyncUnit.unit;
            } @finally {
                if (acceptedSocket != nilptr)
                    [acceptedSocket close];
            }
        } name: @"objfw-string-eof"];
        auto stringClient = [[OFTCPSocket alloc] init];

        @try {
            [[stringClient promiseToConnectToHost: host port: port onScheduler: scheduler] await];
            [[stringClient promiseToWriteString: @"payload" onScheduler: scheduler] await];
            [stringClient close];
            [stringTask await];
        } @finally {
            @try {
                [stringClient close];
            } @catch (OFException *) {
            }
        }

        Task<AsyncUnit *> *lineTask = [rootScope spawn: ^{
            OFStreamSocket *acceptedSocket = nilptr;

            @try {
                Optional<OFString *> *firstLine;
                Optional<OFString *> *secondLine;
                Optional<OFString *> *eofLine;

                acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
                firstLine = [acceptedSocket promiseToReadLineOnScheduler: scheduler].await;
                secondLine = [acceptedSocket promiseToReadLineOnScheduler: scheduler].await;
                eofLine = [acceptedSocket promiseToReadLineOnScheduler: scheduler].await;

                [AsyncRuntimeTestSupport assertCondition: (firstLine.hasValue and [firstLine.value isEqual: @"alpha"])
                                                message: (@"promiseToReadLine should resolve the first available line")];
                [AsyncRuntimeTestSupport assertCondition: (secondLine.hasValue and [secondLine.value isEqual: @"beta"])
                                                message: (@"promiseToReadLine should continue reading later lines")];
                [AsyncRuntimeTestSupport assertCondition: (not eofLine.hasValue)
                                                message: (@"promiseToReadLine should resolve EOF as Optional.none")];
                return AsyncUnit.unit;
            } @finally {
                if (acceptedSocket != nilptr)
                    [acceptedSocket close];
            }
        } name: @"objfw-line-eof"];
        auto lineClient = [[OFTCPSocket alloc] init];

        @try {
            [[lineClient promiseToConnectToHost: host port: port onScheduler: scheduler] await];
            [[lineClient promiseToWriteString: @"alpha\nbeta\n" onScheduler: scheduler] await];
            [lineClient close];
            [lineTask await];
        } @finally {
            @try {
                [lineClient close];
            } @catch (OFException *) {
            }
        }
    } @finally {
        [listener close];
    }
}

static void objfw_datagram_send_receive(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto socket = [[OFUDPSocket alloc] init];
    OFSocketAddress boundAddress = [socket bindToHost: @"127.0.0.1" port: 0];
    char buffer[5] = { 0 };
    OFData *payload = [OFData dataWithItems: "hello" count: sizeof(buffer)];
    Promise<AsyncDatagramReceiveResult *> *receivePromise = [socket promiseToReceiveIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler];
    AsyncUnit *sendResult;
    AsyncDatagramReceiveResult *receiveResult;

    @try {
        sendResult = [socket promiseToSendData: payload receiver: &boundAddress onScheduler: scheduler].await;
        receiveResult = receivePromise.await;

        [AsyncRuntimeTestSupport assertCondition: (sendResult == AsyncUnit.unit)
                                        message: (@"datagram send promises should resolve to AsyncUnit.unit")];
        [AsyncRuntimeTestSupport assertCondition: (receiveResult.length == sizeof(buffer))
                                        message: (@"datagram receive promises should report the received datagram length")];
        [AsyncRuntimeTestSupport assertCondition: (receiveResult.buffer == buffer)
                                        message: (@"datagram receive results should preserve the caller buffer pointer")];
        [AsyncRuntimeTestSupport assertCondition: (memcmp(buffer, "hello", sizeof(buffer)) == 0)
                                        message: (@"datagram receive promises should deliver the sent bytes")];
        [AsyncRuntimeTestSupport assertCondition: ([OFSocketAddressString(receiveResult.sender) isEqual: @"127.0.0.1"])
                                        message: (@"datagram receive promises should preserve the sender address")];
        [AsyncRuntimeTestSupport assertCondition: (OFSocketAddressIPPort(receiveResult.sender) == OFSocketAddressIPPort(&boundAddress))
                                        message: (@"datagram receive promises should preserve the sender port")];
    } @finally {
        [socket close];
    }
}

static void objfw_stream_buffer_selector_coverage(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    AsyncRuntimeWithConnectedTCPSockets(scheduler, true, true, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        char serverBuffer[8] = { 0 };
        char clientBuffer[8] = { 0 };
        AsyncBufferReadResult *serverRead;
        AsyncBufferReadResult *clientRead;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteData: [OFData dataWithItems: "ab" count: 2] onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector stream data writes should resolve to AsyncUnit.unit")];
        serverRead = [acceptedSocket promiseToReadIntoBuffer: serverBuffer length: sizeof(serverBuffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (serverRead.length == 2 and memcmp(serverBuffer, "ab", 2) == 0)
                                        message: (@"cancel-selector stream reads should resolve available bytes without requiring an exact length")];

        [AsyncRuntimeTestSupport assertCondition: ([acceptedSocket promiseToWriteString: @"srv" encoding: OFStringEncodingUTF8 onScheduler: scheduler].await == AsyncUnit.unit)
                                        message: (@"explicit-encoding stream writes should resolve to AsyncUnit.unit")];
        clientRead = [client promiseToReadIntoBuffer: clientBuffer length: sizeof(clientBuffer) onScheduler: scheduler].await;
        [AsyncRuntimeTestSupport assertCondition: (clientRead.length == 3 and memcmp(clientBuffer, "srv", 3) == 0)
                                        message: (@"length-based stream read wrappers should round-trip server responses")];
    });

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        char serverBuffer[4] = { 0 };
        char clientBuffer[2] = { 0 };
        AsyncBufferReadResult *serverRead;
        AsyncBufferReadResult *clientRead;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteData: [OFData dataWithItems: "ping" count: sizeof(serverBuffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                        message: (@"default stream data writes should remain usable alongside overload coverage")];
        serverRead = [acceptedSocket promiseToReadIntoBuffer: serverBuffer exactLength: sizeof(serverBuffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (serverRead.length == sizeof(serverBuffer) and memcmp(serverBuffer, "ping", sizeof(serverBuffer)) == 0)
                                        message: (@"cancel-selector exact stream reads should preserve payload bytes")];

        [AsyncRuntimeTestSupport assertCondition: ([acceptedSocket promiseToWriteData: [OFData dataWithItems: "ok" count: sizeof(clientBuffer)] onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector stream data writes should support exact-length replies")];
        clientRead = [client promiseToReadIntoBuffer: clientBuffer exactLength: sizeof(clientBuffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (clientRead.length == sizeof(clientBuffer) and memcmp(clientBuffer, "ok", sizeof(clientBuffer)) == 0)
                                        message: (@"cancel-selector exact stream reads should resolve the requested reply length")];
    });

    {
        auto socket = [[OFUDPSocket alloc] init];
        OFSocketAddress boundAddress = [socket bindToHost: @"127.0.0.1" port: 0];
        char buffer[5] = { 0 };
        AsyncDatagramReceiveResult *receiveResult;

        @try {
            Promise<AsyncDatagramReceiveResult *> *receivePromise = [socket promiseToReceiveIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler cancelOnTaskCancellation: false];

            [AsyncRuntimeTestSupport assertCondition: ([socket promiseToSendData: [OFData dataWithItems: "hello" count: sizeof(buffer)] receiver: &boundAddress onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                            message: (@"cancel-selector datagram sends should resolve to AsyncUnit.unit")];
            receiveResult = receivePromise.await;

            [AsyncRuntimeTestSupport assertCondition: (receiveResult.length == sizeof(buffer) and memcmp(buffer, "hello", sizeof(buffer)) == 0)
                                            message: (@"cancel-selector datagram receives should preserve payload bytes")];
        } @finally {
            [socket close];
        }
    }
}

static void objfw_stream_string_cancel_selector_coverage(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto listener = [[OFTCPSocket alloc] init];
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    OFString *host = @"127.0.0.1";
    uint16_t port = OFSocketAddressIPPort(&address);

    [listener listen];

    @try {
        Task<AsyncUnit *> *stringTask = [rootScope spawn: ^{
            OFStreamSocket *acceptedSocket = nilptr;

            @try {
                Optional<OFString *> *readString;

                acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
                readString = [acceptedSocket promiseToReadStringOnScheduler: scheduler cancelOnTaskCancellation: false].await;

                [AsyncRuntimeTestSupport assertCondition: (readString.hasValue and [readString.value isEqual: @"payload-cancel"])
                                                message: (@"cancel-selector string reads should preserve the remaining stream contents")];
                return AsyncUnit.unit;
            } @finally {
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        } name: @"objfw-string-selector-default"];
        auto client = [[OFTCPSocket alloc] init];

        @try {
            [[client promiseToConnectToHost: host port: port onScheduler: scheduler] await];
            [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"payload-cancel" onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                            message: (@"cancel-selector default-encoding string writes should resolve to AsyncUnit.unit")];
            [client close];
            [stringTask await];
        } @finally {
            AsyncRuntimeCloseSocket(client);
        }
    } @finally {
        AsyncRuntimeCloseSocket(listener);
    }
}

static void objfw_stream_string_encoding_selector_coverage(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto listener = [[OFTCPSocket alloc] init];
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    OFString *host = @"127.0.0.1";
    uint16_t port = OFSocketAddressIPPort(&address);

    [listener listen];

    @try {
        Task<AsyncUnit *> *stringTask = [rootScope spawn: ^{
            OFStreamSocket *acceptedSocket = nilptr;

            @try {
                Optional<OFString *> *readString;

                acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
                readString = [acceptedSocket promiseToReadStringWithEncoding: OFStringEncodingUTF8 onScheduler: scheduler].await;

                [AsyncRuntimeTestSupport assertCondition: (readString.hasValue and [readString.value isEqual: @"utf8-default"])
                                                message: (@"explicit-encoding string reads should decode the transmitted payload")];
                return AsyncUnit.unit;
            } @finally {
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        } name: @"objfw-string-selector-encoding"];
        auto client = [[OFTCPSocket alloc] init];

        @try {
            [[client promiseToConnectToHost: host port: port onScheduler: scheduler] await];
            [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"utf8-default" encoding: OFStringEncodingUTF8 onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                            message: (@"cancel-selector explicit-encoding string writes should resolve to AsyncUnit.unit")];
            [client close];
            [stringTask await];
        } @finally {
            AsyncRuntimeCloseSocket(client);
        }
    } @finally {
        AsyncRuntimeCloseSocket(listener);
    }
}

static void objfw_stream_string_encoding_cancel_selector_coverage(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto listener = [[OFTCPSocket alloc] init];
    OFSocketAddress address = [listener bindToHost: @"127.0.0.1" port: 0];
    OFString *host = @"127.0.0.1";
    uint16_t port = OFSocketAddressIPPort(&address);

    [listener listen];

    @try {
        Task<AsyncUnit *> *stringTask = [rootScope spawn: ^{
            OFStreamSocket *acceptedSocket = nilptr;

            @try {
                Optional<OFString *> *readString;

                acceptedSocket = [listener promiseToAcceptOnScheduler: scheduler].await;
                readString = [acceptedSocket promiseToReadStringWithEncoding: OFStringEncodingUTF8 onScheduler: scheduler cancelOnTaskCancellation: false].await;

                [AsyncRuntimeTestSupport assertCondition: (readString.hasValue and [readString.value isEqual: @"utf8-cancel"])
                                                message: (@"cancel-selector explicit-encoding string reads should decode the transmitted payload")];
                return AsyncUnit.unit;
            } @finally {
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        } name: @"objfw-string-selector-encoding-cancel"];
        auto client = [[OFTCPSocket alloc] init];

        @try {
            [[client promiseToConnectToHost: host port: port onScheduler: scheduler] await];
            [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"utf8-cancel" encoding: OFStringEncodingUTF8 onScheduler: scheduler].await == AsyncUnit.unit)
                                            message: (@"default explicit-encoding string writes should remain usable alongside overload coverage")];
            [client close];
            [stringTask await];
        } @finally {
            AsyncRuntimeCloseSocket(client);
        }
    } @finally {
        AsyncRuntimeCloseSocket(listener);
    }
}

static void objfw_stream_line_selector_coverage(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        Optional<OFString *> *line;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"alpha\n" onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector line-write setup should resolve to AsyncUnit.unit")];
        line = [acceptedSocket promiseToReadLineOnScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (line.hasValue and [line.value isEqual: @"alpha"])
                                        message: (@"cancel-selector line reads should resolve the first available line")];
    });

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        Optional<OFString *> *line;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"beta\n" encoding: OFStringEncodingUTF8 onScheduler: scheduler].await == AsyncUnit.unit)
                                        message: (@"default explicit-encoding line writes should resolve to AsyncUnit.unit")];
        line = [acceptedSocket promiseToReadLineWithEncoding: OFStringEncodingUTF8 onScheduler: scheduler].await;
        [AsyncRuntimeTestSupport assertCondition: (line.hasValue and [line.value isEqual: @"beta"])
                                        message: (@"explicit-encoding line reads should decode the first line")];
    });

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        Optional<OFString *> *line;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"gamma\n" encoding: OFStringEncodingUTF8 onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector explicit-encoding line writes should resolve to AsyncUnit.unit")];
        line = [acceptedSocket promiseToReadLineWithEncoding: OFStringEncodingUTF8 onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (line.hasValue and [line.value isEqual: @"gamma"])
                                        message: (@"cancel-selector explicit-encoding line reads should decode the first line")];
    });
}

static void objfw_iri_handler_wrappers(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto server = [[LocalHTTPTestServer alloc] init];
    OFIRI *alphaIRI;
    OFIRI *betaIRI;
    OFStream *nillable classStream = nilptr;
    OFStream *nillable instanceStream = nilptr;

    [server start];

    @try {
        OFIRIHandler *handler;

        alphaIRI = [server IRIForPath: @"/alpha"];
        betaIRI = [server IRIForPath: @"/beta"];
        handler = [OFIRIHandler handlerForIRI: betaIRI];

        classStream = [OFIRIHandler promiseToOpenItemAtIRI: alphaIRI mode: @"r" onScheduler: scheduler].await;
        instanceStream = [handler promiseToOpenItemAtIRI: betaIRI mode: @"r" onScheduler: scheduler].await;

        [AsyncRuntimeTestSupport assertCondition: ([[classStream readString] isEqual: @"alpha"])
                                        message: (@"class IRI handler promises should open readable streams through async-capable handlers")];
        [AsyncRuntimeTestSupport assertCondition: ([[instanceStream readString] isEqual: @"beta"])
                                        message: (@"instance IRI handler promises should open readable streams through async-capable handlers")];
    } @finally {
        if (classStream != nilptr)
            [classStream close];
        if (instanceStream != nilptr)
            [instanceStream close];
        [server stop];
    }
}

static void objfw_dns_static_host_resolution(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto resolver = [[OFDNSResolver alloc] init];
    OFData *addresses;
    OFData *cancelAddresses;
    OFData *ipv4Addresses;
    OFData *ipv4CancelAddresses;
    const OFSocketAddress *items;

    resolver.configReloadInterval = 0;
    resolver.staticHosts = [OFDictionary dictionaryWithObject: [OFArray arrayWithObject: @"127.0.0.1"]
                                                       forKey: @"async-host.test"];

    @try {
        addresses = [resolver promiseToResolveAddressesForHost: @"async-host.test" onScheduler: scheduler].await;
        cancelAddresses = [resolver promiseToResolveAddressesForHost: @"async-host.test" onScheduler: scheduler cancelOnTaskCancellation: false].await;
        ipv4Addresses = [resolver promiseToResolveAddressesForHost: @"async-host.test" addressFamily: OFSocketAddressFamilyIPv4 onScheduler: scheduler].await;
        ipv4CancelAddresses = [resolver promiseToResolveAddressesForHost: @"async-host.test" addressFamily: OFSocketAddressFamilyIPv4 onScheduler: scheduler cancelOnTaskCancellation: false].await;
        items = (const OFSocketAddress *)addresses.items;

        [AsyncRuntimeTestSupport assertCondition: (addresses.itemSize == sizeof(OFSocketAddress))
                                        message: (@"host resolution promises should return OFData itemized as OFSocketAddress entries")];
        [AsyncRuntimeTestSupport assertCondition: (addresses.count == 1)
                                        message: (@"static host resolution should return exactly one configured address")];
        [AsyncRuntimeTestSupport assertCondition: ([OFSocketAddressString(&items[0]) isEqual: @"127.0.0.1"])
                                        message: (@"host resolution promises should preserve the configured IP address")];
        [AsyncRuntimeTestSupport assertCondition: (OFSocketAddressIPPort(&items[0]) == 0)
                                        message: (@"resolved static host addresses should retain port zero")];
        [AsyncRuntimeTestSupport assertCondition: ([cancelAddresses isEqual: addresses])
                                        message: (@"cancel-selector host resolution overloads should preserve resolved address data")];
        [AsyncRuntimeTestSupport assertCondition: ([ipv4Addresses isEqual: addresses])
                                        message: (@"address-family host resolution overloads should preserve IPv4 address data")];
        [AsyncRuntimeTestSupport assertCondition: ([ipv4CancelAddresses isEqual: addresses])
                                        message: (@"cancel-selector address-family host resolution overloads should preserve IPv4 address data")];
    } @finally {
        [resolver close];
    }
}

static void objfw_tls_client_handshake_failure(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = OFThread.currentThread;
    auto server = [[LocalPlaintextTCPServer alloc] init];
    auto client = [[OFTCPSocket alloc] init];
    auto cancelServer = [[LocalPlaintextTCPServer alloc] init];
    auto cancelClient = [[OFTCPSocket alloc] init];
    OFTLSStream *nillable TLSStream = nilptr;
    OFTLSStream *nillable cancelTLSStream = nilptr;
    bool caughtHandshakeFailure = false;
    bool caughtCancelSelectorFailure = false;

    [AsyncRuntimeTestSupport assertCondition: (OFTLSStreamImplementation != Nil)
                                    message: (@"ObjFWTLS should be loaded before the TLS wrapper tests run")];

    [server start];

    @try {
        [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToHost: @"127.0.0.1" port: server.port onScheduler: scheduler].await == client)
                                        message: (@"TCP connect promises should still resolve with the client socket before TLS setup")];

        TLSStream = [OFTLSStream streamWithStream: client];

        @try {
            [[TLSStream promiseToPerformClientHandshakeWithHost: @"127.0.0.1" onScheduler: scheduler] await];
        } @catch (OFException *) {
            caughtHandshakeFailure = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtHandshakeFailure)
                                        message: (@"TLS client handshake promises should reject when the peer is not speaking TLS")];
        [AsyncRuntimeTestSupport assertCondition: (OFThread.currentThread == expectedThread)
                                        message: (@"awaiting TLS handshake promises should resume on the scheduler thread")];
    } @finally {
        if (TLSStream != nilptr)
            [TLSStream close];
        else
            [client close];
        [server stop];
    }

    [cancelServer start];

    @try {
        [AsyncRuntimeTestSupport assertCondition: ([cancelClient promiseToConnectToHost: @"127.0.0.1" port: cancelServer.port onScheduler: scheduler].await == cancelClient)
                                        message: (@"a second plain TCP server should accept client connections for cancel-selector TLS coverage")];

        cancelTLSStream = [OFTLSStream streamWithStream: cancelClient];

        @try {
            [[cancelTLSStream promiseToPerformClientHandshakeWithHost: @"127.0.0.1" onScheduler: scheduler cancelOnTaskCancellation: false] await];
        } @catch (OFException *) {
            caughtCancelSelectorFailure = true;
        }

        [AsyncRuntimeTestSupport assertCondition: (caughtCancelSelectorFailure)
                                        message: (@"cancel-selector TLS client handshake promises should reject when the peer is not speaking TLS")];
    } @finally {
        if (cancelTLSStream != nilptr)
            [cancelTLSStream close];
        else
            [cancelClient close];
        [cancelServer stop];
    }
}

static void objfw_dns_query_local_stub(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto server = [[LocalDNSQueryTestServer alloc] initWithResponseText: @"async-query"];
    auto resolver = [[OFDNSResolver alloc] init];
    OFDNSQuery *query = [OFDNSQuery queryWithDomainName: @"promise-query.test"
                                               DNSClass: OFDNSClassIN
                                             recordType: OFDNSRecordTypeTXT];
    OFDNSQuery *cancelQuery = [OFDNSQuery queryWithDomainName: @"promise-query-cancel.test"
                                                     DNSClass: OFDNSClassIN
                                                   recordType: OFDNSRecordTypeTXT];
    OFData *expectedText = [OFData dataWithItems: "async-query" count: strlen("async-query")];
    OFDNSResponse *response;
    OFDNSResponse *cancelResponse;
    OFArray<OFDNSResourceRecord *> *nillable records;
    OFArray<OFDNSResourceRecord *> *nillable cancelRecords;
    OFTXTDNSResourceRecord *record;
    OFTXTDNSResourceRecord *cancelRecord;

    resolver.configReloadInterval = 0;
    resolver.nameServers = [OFArray arrayWithObject: @"127.0.0.1"];
    resolver.searchDomains = [OFArray array];
    resolver.timeout = 0.05;
    resolver.maxAttempts = 1;
    resolver.minNumberOfDotsInAbsoluteName = 0;

    [server start];

    @try {
        response = [resolver promiseToPerformQuery: query onScheduler: scheduler].await;
        cancelResponse = [resolver promiseToPerformQuery: cancelQuery onScheduler: scheduler cancelOnTaskCancellation: false].await;
        records = [response.answerRecords objectForKey: query.domainName];
        cancelRecords = [cancelResponse.answerRecords objectForKey: cancelQuery.domainName];

        [AsyncRuntimeTestSupport assertCondition: ([response.domainName isEqual: query.domainName])
                                        message: (@"DNS query promises should preserve the queried domain name")];
        [AsyncRuntimeTestSupport assertCondition: (records != nilptr and records.count == 1)
                                        message: (@"DNS query promises should expose the answer records returned by the resolver")];

        record = (OFTXTDNSResourceRecord *)[records objectAtIndex: 0];
        [AsyncRuntimeTestSupport assertCondition: (record.recordType == OFDNSRecordTypeTXT)
                                        message: (@"the local DNS stub should return a TXT record for the query promise")];
        [AsyncRuntimeTestSupport assertCondition: ([record.textStrings.count == 1 ? [record.textStrings objectAtIndex: 0] : nilptr isEqual: expectedText])
                                        message: (@"DNS query promises should preserve TXT record payload bytes")];

        [AsyncRuntimeTestSupport assertCondition: ([cancelResponse.domainName isEqual: cancelQuery.domainName])
                                        message: (@"cancel-selector DNS query promises should preserve the queried domain name")];
        [AsyncRuntimeTestSupport assertCondition: (cancelRecords != nilptr and cancelRecords.count == 1)
                                        message: (@"cancel-selector DNS query promises should expose the answer records returned by the resolver")];

        cancelRecord = (OFTXTDNSResourceRecord *)[cancelRecords objectAtIndex: 0];
        [AsyncRuntimeTestSupport assertCondition: (cancelRecord.recordType == OFDNSRecordTypeTXT)
                                        message: (@"cancel-selector DNS query promises should preserve the TXT record type")];
        [AsyncRuntimeTestSupport assertCondition: ([cancelRecord.textStrings.count == 1 ? [cancelRecord.textStrings objectAtIndex: 0] : nilptr isEqual: expectedText])
                                        message: (@"cancel-selector DNS query promises should preserve TXT record payload bytes")];
    } @finally {
        [resolver close];
        [server stop];
    }
}

static void objfw_tls_server_handshake_failure(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    [AsyncRuntimeTestSupport assertCondition: (OFTLSStreamImplementation != Nil)
                                    message: (@"ObjFWTLS should be loaded before the TLS server wrapper tests run")];

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        OFTLSStream *serverStream = [OFTLSStream streamWithStream: (OFStream<OFReadyForReadingObserving, OFReadyForWritingObserving> *)acceptedSocket];
        bool caughtFailure = false;

        @try {
            [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"plain-server" onScheduler: scheduler].await == AsyncUnit.unit)
                                            message: (@"plain-text clients should be able to trigger TLS server handshake failures")];
            [client close];

            @try {
                [[serverStream promiseToPerformServerHandshakeOnScheduler: scheduler] await];
            } @catch (OFException *) {
                caughtFailure = true;
            }

            [AsyncRuntimeTestSupport assertCondition: (caughtFailure)
                                            message: (@"TLS server handshake promises should reject when the peer is not speaking TLS")];
        } @finally {
            [serverStream close];
        }
    });

    AsyncRuntimeWithConnectedTCPSockets(scheduler, false, false, ^(OFTCPSocket *client, OFStreamSocket *acceptedSocket) {
        OFTLSStream *serverStream = [OFTLSStream streamWithStream: (OFStream<OFReadyForReadingObserving, OFReadyForWritingObserving> *)acceptedSocket];
        bool caughtFailure = false;

        @try {
            [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteString: @"plain-server-cancel" onScheduler: scheduler].await == AsyncUnit.unit)
                                            message: (@"plain-text clients should exercise the cancel-selector TLS server handshake wrapper")];
            [client close];

            @try {
                [[serverStream promiseToPerformServerHandshakeOnScheduler: scheduler cancelOnTaskCancellation: false] await];
            } @catch (OFException *) {
                caughtFailure = true;
            }

            [AsyncRuntimeTestSupport assertCondition: (caughtFailure)
                                            message: (@"cancel-selector TLS server handshake promises should reject when the peer is not speaking TLS")];
        } @finally {
            [serverStream close];
        }
    });
}

#ifdef OF_HAVE_IPX
static void objfw_spx_socket_connect_wrappers(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
    auto server = [[OFSPXSocket alloc] init];
    OFSocketAddress boundAddress;
    uint32_t network;
    unsigned char node[IPX_NODE_LEN];
    uint16_t port;

    @try {
        boundAddress = [server bindToNetwork: 0 node: zeroNode port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            @throw [OTTestSkippedException exceptionWithMessage: @"SPX message sockets unsupported at runtime"];

        @throw exception;
    }

    network = OFSocketAddressIPXNetwork(&boundAddress);
    OFSocketAddressGetIPXNode(&boundAddress, node);
    port = OFSocketAddressIPXPort(&boundAddress);
    [server listen];

    @try {
        {
            Promise<OFSequencedPacketSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSPXSocket alloc] init];
            OFSequencedPacketSocket *acceptedSocket;
            char buffer[4] = { 0 };
            AsyncBufferReadResult *readResult;

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToNetwork: network node: node port: port onScheduler: scheduler].await == client)
                                                message: (@"SPX message connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "ipx!" count: sizeof(buffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                                message: (@"accepted SPX message sockets should remain usable through inherited sequenced-packet wrappers")];
                readResult = [acceptedSocket promiseToReceiveIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "ipx!", sizeof(buffer)) == 0)
                                                message: (@"SPX message connect promises should establish a working connection")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }

        {
            Promise<OFSequencedPacketSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSPXSocket alloc] init];
            OFSequencedPacketSocket *acceptedSocket;
            char buffer[5] = { 0 };
            AsyncBufferReadResult *readResult;

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToNetwork: network node: node port: port onScheduler: scheduler cancelOnTaskCancellation: false].await == client)
                                                message: (@"cancel-selector SPX message connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "ipx-2" count: sizeof(buffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                                message: (@"cancel-selector SPX message connect promises should support subsequent sends")];
                readResult = [acceptedSocket promiseToReceiveIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "ipx-2", sizeof(buffer)) == 0)
                                                message: (@"cancel-selector SPX message connect promises should establish a working connection")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }
    } @finally {
        AsyncRuntimeCloseSocket(server);
    }
}

static void objfw_spx_stream_socket_connect_wrappers(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
    auto server = [[OFSPXStreamSocket alloc] init];
    OFSocketAddress boundAddress;
    uint32_t network;
    unsigned char node[IPX_NODE_LEN];
    uint16_t port;

    @try {
        boundAddress = [server bindToNetwork: 0 node: zeroNode port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            @throw [OTTestSkippedException exceptionWithMessage: @"SPX stream sockets unsupported at runtime"];

        @throw exception;
    }

    network = OFSocketAddressIPXNetwork(&boundAddress);
    OFSocketAddressGetIPXNode(&boundAddress, node);
    port = OFSocketAddressIPXPort(&boundAddress);
    [server listen];

    @try {
        {
            Promise<OFStreamSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSPXStreamSocket alloc] init];
            OFStreamSocket *acceptedSocket;
            char buffer[4] = { 0 };
            AsyncBufferReadResult *readResult;

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToNetwork: network node: node port: port onScheduler: scheduler].await == client)
                                                message: (@"SPX stream connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteData: [OFData dataWithItems: "spx!" count: sizeof(buffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                                message: (@"accepted SPX stream sockets should remain usable through inherited stream wrappers")];
                readResult = [acceptedSocket promiseToReadIntoBuffer: buffer exactLength: sizeof(buffer) onScheduler: scheduler].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "spx!", sizeof(buffer)) == 0)
                                                message: (@"SPX stream connect promises should establish a working connection")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }

        {
            Promise<OFStreamSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSPXStreamSocket alloc] init];
            OFStreamSocket *acceptedSocket;
            char buffer[5] = { 0 };
            AsyncBufferReadResult *readResult;

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToNetwork: network node: node port: port onScheduler: scheduler cancelOnTaskCancellation: false].await == client)
                                                message: (@"cancel-selector SPX stream connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToWriteData: [OFData dataWithItems: "spx-2" count: sizeof(buffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                                message: (@"cancel-selector SPX stream connect promises should support subsequent writes")];
                readResult = [acceptedSocket promiseToReadIntoBuffer: buffer exactLength: sizeof(buffer) onScheduler: scheduler].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "spx-2", sizeof(buffer)) == 0)
                                                message: (@"cancel-selector SPX stream connect promises should establish a working connection")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }
    } @finally {
        AsyncRuntimeCloseSocket(server);
    }
}
#endif

#ifndef OF_HAVE_IPX
static void objfw_spx_socket_connect_wrappers(AsyncScope *rootScope)
{
    (void)rootScope;
    @throw [OTTestSkippedException exceptionWithMessage: @"SPX message sockets unsupported at compile time"];
}

static void objfw_spx_stream_socket_connect_wrappers(AsyncScope *rootScope)
{
    (void)rootScope;
    @throw [OTTestSkippedException exceptionWithMessage: @"SPX stream sockets unsupported at compile time"];
}
#endif

#ifdef OF_HAVE_SCTP
static void objfw_sctp_wrapper_methods(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto server = [[OFSCTPSocket alloc] init];
    OFSocketAddress boundAddress;

    @try {
        boundAddress = [server bindToHost: @"127.0.0.1" port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            @throw [OTTestSkippedException exceptionWithMessage: @"SCTP sockets unsupported at runtime"];

        @throw exception;
    }

    [server listen];

    @try {
        {
            Promise<OFSequencedPacketSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSCTPSocket alloc] init];
            OFSequencedPacketSocket *acceptedSocket;
            char buffer[4] = { 0 };
            AsyncSCTPReceiveResult *readResult;
            OFSCTPMessageInfo info = [OFDictionary dictionaryWithObject: [OFNumber numberWithUnsignedShort: 5]
                                                                 forKey: OFSCTPStreamID];

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToHost: @"127.0.0.1" port: OFSocketAddressIPPort(&boundAddress) onScheduler: scheduler].await == client)
                                                message: (@"SCTP connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "sctp" count: sizeof(buffer)] info: info onScheduler: scheduler].await == AsyncUnit.unit)
                                                message: (@"SCTP send promises should resolve to AsyncUnit.unit")];
                readResult = [(OFSCTPSocket *)acceptedSocket promiseToReceiveWithInfoIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "sctp", sizeof(buffer)) == 0)
                                                message: (@"SCTP receive promises should preserve payload bytes")];
                [AsyncRuntimeTestSupport assertCondition: ([readResult.info objectForKey: OFSCTPStreamID] != nilptr)
                                                message: (@"SCTP receive promises should preserve message info")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }

        {
            Promise<OFSequencedPacketSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler];
            auto client = [[OFSCTPSocket alloc] init];
            OFSequencedPacketSocket *acceptedSocket;
            char buffer[5] = { 0 };
            AsyncSCTPReceiveResult *readResult;
            OFSCTPMessageInfo info = [OFDictionary dictionaryWithObjectsAndKeys:
                [OFNumber numberWithUnsignedShort: 7], OFSCTPStreamID,
                [OFNumber numberWithBool: true], OFSCTPUnordered,
                nil];

            @try {
                [AsyncRuntimeTestSupport assertCondition: ([client promiseToConnectToHost: @"127.0.0.1" port: OFSocketAddressIPPort(&boundAddress) onScheduler: scheduler cancelOnTaskCancellation: false].await == client)
                                                message: (@"cancel-selector SCTP connect promises should resolve with the original socket")];
                acceptedSocket = acceptPromise.await;

                [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "sctp2" count: sizeof(buffer)] info: info onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                                message: (@"cancel-selector SCTP send promises should resolve to AsyncUnit.unit")];
                readResult = [(OFSCTPSocket *)acceptedSocket promiseToReceiveWithInfoIntoBuffer: buffer length: sizeof(buffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
                [AsyncRuntimeTestSupport assertCondition: (readResult.length == sizeof(buffer) and memcmp(buffer, "sctp2", sizeof(buffer)) == 0)
                                                message: (@"cancel-selector SCTP receive promises should preserve payload bytes")];
                [AsyncRuntimeTestSupport assertCondition: ([[readResult.info objectForKey: OFSCTPUnordered] boolValue])
                                                message: (@"cancel-selector SCTP receive promises should preserve unordered message info")];
            } @finally {
                AsyncRuntimeCloseSocket(client);
                AsyncRuntimeCloseSocket(acceptedSocket);
            }
        }
    } @finally {
        AsyncRuntimeCloseSocket(server);
    }
}
#endif

#ifndef OF_HAVE_SCTP
static void objfw_sctp_wrapper_methods(AsyncScope *rootScope)
{
    (void)rootScope;
    @throw [OTTestSkippedException exceptionWithMessage: @"SCTP sockets unsupported at compile time"];
}
#endif

static void objfw_unix_sequenced_packet_wrappers(AsyncScope *rootScope, OFUNIXSequencedPacketSocket *server, OFString *path)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    OFThread *expectedThread = OFThread.currentThread;
    auto client = [[OFUNIXSequencedPacketSocket alloc] init];
    block_reference OFSequencedPacketSocket *nillable acceptedSocket = nilptr;
    char serverBuffer[5] = { 0 };
    char clientBuffer[4] = { 0 };
    char *serverBufferPointer = serverBuffer;
    char *clientBufferPointer = clientBuffer;
    block_reference bool acceptResumedOnScheduler = false;

    @try {
        Task<AsyncUnit *> *acceptTask = [rootScope spawn: ^{
            AsyncBufferReadResult *serverRead;

            acceptedSocket = [server promiseToAcceptOnScheduler: scheduler].await;
            acceptResumedOnScheduler = (OFThread.currentThread == expectedThread);
            serverRead = [acceptedSocket promiseToReceiveIntoBuffer: serverBufferPointer length: sizeof(serverBuffer) onScheduler: scheduler].await;

            [AsyncRuntimeTestSupport assertCondition: (serverRead.length == sizeof(serverBuffer))
                                            message: (@"sequenced packet receive promises should report the number of bytes received")];
            [AsyncRuntimeTestSupport assertCondition: (serverRead.buffer == serverBufferPointer)
                                            message: (@"sequenced packet receive promises should preserve the caller buffer pointer")];
            [AsyncRuntimeTestSupport assertCondition: ([acceptedSocket promiseToSendData: [OFData dataWithItems: "pong" count: sizeof(clientBuffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                            message: (@"sequenced packet send promises should resolve to AsyncUnit.unit")];
            return AsyncUnit.unit;
        } name: @"objfw-sequenced-accept"];
        AsyncBufferReadResult *clientRead;

        [client connectToPath: path];
        [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "hello" count: sizeof(serverBuffer)] onScheduler: scheduler].await == AsyncUnit.unit)
                                        message: (@"client-side sequenced packet sends should resolve to AsyncUnit.unit")];
        clientRead = [client promiseToReceiveIntoBuffer: clientBufferPointer length: sizeof(clientBuffer) onScheduler: scheduler].await;
        [acceptTask await];

        [AsyncRuntimeTestSupport assertCondition: (acceptResumedOnScheduler)
                                        message: (@"awaiting sequenced packet accept promises should resume on the scheduler thread")];
        [AsyncRuntimeTestSupport assertCondition: (clientRead.length == sizeof(clientBuffer))
                                        message: (@"sequenced packet reply reads should report the number of bytes received")];
        [AsyncRuntimeTestSupport assertCondition: (memcmp(serverBuffer, "hello", sizeof(serverBuffer)) == 0)
                                        message: (@"accepted UNIX sequenced packet sockets should receive client packets")];
        [AsyncRuntimeTestSupport assertCondition: (memcmp(clientBuffer, "pong", sizeof(clientBuffer)) == 0)
                                        message: (@"clients should receive packets sent back through accepted UNIX sequenced packet sockets")];
    } @finally {
        if (acceptedSocket != nilptr)
            [acceptedSocket close];
        [client close];
        [server close];
#ifdef OF_HAVE_FILES
        if (![path hasPrefix: @"@"])
            [[OFFileManager defaultManager] removeItemAtPath: path];
#endif
    }
}

static void objfw_unix_sequenced_packet_cancel_overloads(AsyncScope *rootScope, OFUNIXSequencedPacketSocket *server, OFString *path)
{
    AsyncScheduler *scheduler = rootScope.scheduler;
    auto client = [[OFUNIXSequencedPacketSocket alloc] init];
    OFSequencedPacketSocket *nillable acceptedSocket = nilptr;
    char serverBuffer[6] = { 0 };
    char clientBuffer[5] = { 0 };
    AsyncBufferReadResult *serverRead;
    AsyncBufferReadResult *clientRead;

    @try {
        Promise<OFSequencedPacketSocket *> *acceptPromise = [server promiseToAcceptOnScheduler: scheduler cancelOnTaskCancellation: false];

        [client connectToPath: path];
        acceptedSocket = acceptPromise.await;

        [AsyncRuntimeTestSupport assertCondition: ([client promiseToSendData: [OFData dataWithItems: "hello!" count: sizeof(serverBuffer)] onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector sequenced packet sends should resolve to AsyncUnit.unit")];
        serverRead = [acceptedSocket promiseToReceiveIntoBuffer: serverBuffer length: sizeof(serverBuffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (serverRead.length == sizeof(serverBuffer) and memcmp(serverBuffer, "hello!", sizeof(serverBuffer)) == 0)
                                        message: (@"cancel-selector sequenced packet receives should preserve payload bytes")];

        [AsyncRuntimeTestSupport assertCondition: ([acceptedSocket promiseToSendData: [OFData dataWithItems: "pong!" count: sizeof(clientBuffer)] onScheduler: scheduler cancelOnTaskCancellation: false].await == AsyncUnit.unit)
                                        message: (@"cancel-selector accepted sequenced packet sends should resolve to AsyncUnit.unit")];
        clientRead = [client promiseToReceiveIntoBuffer: clientBuffer length: sizeof(clientBuffer) onScheduler: scheduler cancelOnTaskCancellation: false].await;
        [AsyncRuntimeTestSupport assertCondition: (clientRead.length == sizeof(clientBuffer) and memcmp(clientBuffer, "pong!", sizeof(clientBuffer)) == 0)
                                        message: (@"cancel-selector sequenced packet receive overloads should preserve reply payloads")];
    } @finally {
        AsyncRuntimeCloseSocket(acceptedSocket);
        AsyncRuntimeCloseSocket(client);
        AsyncRuntimeCloseSocket(server);
#ifdef OF_HAVE_FILES
        if (![path hasPrefix: @"@"])
            [[OFFileManager defaultManager] removeItemAtPath: path];
#endif
    }
}

ASYNC_RUNTIME_ASYNC_TEST(objfw_tcp_stream_wrappers)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_eof_optionals)
ASYNC_RUNTIME_ASYNC_TEST(objfw_datagram_send_receive)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_buffer_selector_coverage)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_string_cancel_selector_coverage)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_string_encoding_selector_coverage)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_string_encoding_cancel_selector_coverage)
ASYNC_RUNTIME_ASYNC_TEST(objfw_stream_line_selector_coverage)
ASYNC_RUNTIME_ASYNC_TEST(objfw_iri_handler_wrappers)
ASYNC_RUNTIME_ASYNC_TEST(objfw_dns_static_host_resolution)
ASYNC_RUNTIME_ASYNC_TEST(objfw_tls_client_handshake_failure)
ASYNC_RUNTIME_ASYNC_TEST(objfw_tls_server_handshake_failure)

@interface test_objfw_unix_sequenced_packet_wrappers : AsyncRuntimeTestCase @end

@implementation test_objfw_unix_sequenced_packet_wrappers

- (void)test_case
{
#ifdef OF_HAVE_UNIX_SOCKETS
    OFString *path = AsyncRuntimeTemporaryPath(@"objfw-sequenced");
    auto server = [[OFUNIXSequencedPacketSocket alloc] init];

    @try {
        [server bindToPath: path];
    } @catch (OFBindSocketFailedException *exception) {
        switch (exception.errNo) {
        case EAFNOSUPPORT:
        case EPERM:
        case EPROTONOSUPPORT:
#ifdef ESOCKTNOSUPPORT
        case ESOCKTNOSUPPORT:
#endif
            OTSkip(@"UNIX sequenced packet sockets unsupported");
        default:
            @throw exception;
        }
    }

    [server listen];

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_unix_sequenced_packet_wrappers(rootScope, server, path);
    }];
#else
    OTSkip(@"UNIX sequenced packet sockets unsupported");
#endif
}

@end

@interface test_objfw_unix_sequenced_packet_cancel_overloads : AsyncRuntimeTestCase @end

@implementation test_objfw_unix_sequenced_packet_cancel_overloads

- (void)test_case
{
#ifdef OF_HAVE_UNIX_SOCKETS
    OFString *path = AsyncRuntimeTemporaryPath(@"objfw-sequenced-cancel");
    auto server = [[OFUNIXSequencedPacketSocket alloc] init];

    @try {
        [server bindToPath: path];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            OTSkip(@"UNIX sequenced packet sockets unsupported");

        @throw exception;
    }

    [server listen];

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_unix_sequenced_packet_cancel_overloads(rootScope, server, path);
    }];
#else
    OTSkip(@"UNIX sequenced packet sockets unsupported");
#endif
}

@end

@interface test_objfw_spx_socket_connect_wrappers : AsyncRuntimeTestCase @end

@implementation test_objfw_spx_socket_connect_wrappers

- (void)test_case
{
#ifdef OF_HAVE_IPX
    unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
    auto probe = [[OFSPXSocket alloc] init];

    @try {
        (void)[probe bindToNetwork: 0 node: zeroNode port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            OTSkip(@"SPX message sockets unsupported at runtime");

        @throw exception;
    } @finally {
        AsyncRuntimeCloseSocket(probe);
    }

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_spx_socket_connect_wrappers(rootScope);
    }];
#else
    OTSkip(@"SPX message sockets unsupported at compile time");
#endif
}

@end

@interface test_objfw_spx_stream_socket_connect_wrappers : AsyncRuntimeTestCase @end

@implementation test_objfw_spx_stream_socket_connect_wrappers

- (void)test_case
{
#ifdef OF_HAVE_IPX
    unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
    auto probe = [[OFSPXStreamSocket alloc] init];

    @try {
        (void)[probe bindToNetwork: 0 node: zeroNode port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            OTSkip(@"SPX stream sockets unsupported at runtime");

        @throw exception;
    } @finally {
        AsyncRuntimeCloseSocket(probe);
    }

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_spx_stream_socket_connect_wrappers(rootScope);
    }];
#else
    OTSkip(@"SPX stream sockets unsupported at compile time");
#endif
}

@end

@interface test_objfw_sctp_wrapper_methods : AsyncRuntimeTestCase @end

@implementation test_objfw_sctp_wrapper_methods

- (void)test_case
{
#ifdef OF_HAVE_SCTP
    auto probe = [[OFSCTPSocket alloc] init];

    @try {
        (void)[probe bindToHost: @"127.0.0.1" port: 0];
    } @catch (OFBindSocketFailedException *exception) {
        if (AsyncRuntimeErrNoIndicatesUnsupportedSocket(exception.errNo))
            OTSkip(@"SCTP sockets unsupported at runtime");

        @throw exception;
    } @finally {
        AsyncRuntimeCloseSocket(probe);
    }

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_sctp_wrapper_methods(rootScope);
    }];
#else
    OTSkip(@"SCTP sockets unsupported at compile time");
#endif
}

@end

@interface test_objfw_dns_query_local_stub : AsyncRuntimeTestCase @end

@implementation test_objfw_dns_query_local_stub

- (void)test_case
{
    if (not AsyncRuntimeCanBindLoopbackDNSStub())
        OTSkip(@"Local DNS query wrapper coverage requires binding UDP 127.0.0.1:53");

    [self runAsyncBlock: ^(AsyncScope *rootScope) {
        objfw_dns_query_local_stub(rootScope);
    }];
}

@end

#pragma clang assume_nonnull end
